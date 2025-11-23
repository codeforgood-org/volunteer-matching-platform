defmodule VolunteerMatch.Webhooks do
  @moduledoc """
  The Webhooks context provides webhook management and delivery functionality.
  """

  import Ecto.Query
  alias VolunteerMatch.{Repo, Webhooks.Webhook, Webhooks.WebhookDelivery}

  @doc """
  Creates a new webhook.
  """
  def create_webhook(attrs) do
    %Webhook{}
    |> Webhook.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a webhook.
  """
  def update_webhook(%Webhook{} = webhook, attrs) do
    webhook
    |> Webhook.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a webhook.
  """
  def delete_webhook(%Webhook{} = webhook) do
    Repo.delete(webhook)
  end

  @doc """
  Gets a single webhook.
  """
  def get_webhook!(id) do
    Repo.get!(Webhook, id)
  end

  @doc """
  Lists all webhooks.
  """
  def list_webhooks(filters \\\\ %{}) do
    Webhook
    |> apply_webhook_filters(filters)
    |> Repo.all()
  end

  @doc """
  Lists webhooks for an NGO.
  """
  def list_ngo_webhooks(ngo_id) do
    from(w in Webhook,
      where: w.ngo_id == ^ngo_id,
      order_by: [desc: w.inserted_at]
    )
    |> Repo.all()
  end

  @doc """
  Triggers a webhook event.
  """
  def trigger_event(event_type, payload) do
    # Find all active webhooks subscribed to this event
    webhooks =
      from(w in Webhook,
        where: w.is_active == true and ^event_type in w.events
      )
      |> Repo.all()

    # Create delivery records for each webhook
    Enum.each(webhooks, fn webhook ->
      create_delivery(%{
        webhook_id: webhook.id,
        event_type: event_type,
        payload: payload
      })
    end)

    :ok
  end

  @doc """
  Delivers a webhook asynchronously.
  """
  def deliver_webhook(delivery_id) do
    delivery = get_delivery!(delivery_id) |> Repo.preload(:webhook)

    # Sign the payload
    signature = sign_payload(delivery.payload, delivery.webhook.secret)

    # Make HTTP request
    headers = [
      {"Content-Type", "application/json"},
      {"X-Webhook-Signature", signature},
      {"X-Webhook-Event", delivery.event_type},
      {"X-Webhook-Delivery", delivery.id}
    ]

    body = Jason.encode!(delivery.payload)

    case HTTPoison.post(delivery.webhook.url, body, headers, recv_timeout: 10_000) do
      {:ok, %HTTPoison.Response{status_code: status_code, body: response_body}}
      when status_code in 200..299 ->
        delivery
        |> WebhookDelivery.success_changeset(status_code, response_body)
        |> Repo.update()

      {:ok, %HTTPoison.Response{status_code: status_code, body: response_body}} ->
        error = "HTTP #{status_code}: #{response_body}"

        delivery
        |> WebhookDelivery.retry_changeset(error)
        |> Repo.update()

      {:error, %HTTPoison.Error{reason: reason}} ->
        delivery
        |> WebhookDelivery.retry_changeset("Request failed: #{inspect(reason)}")
        |> Repo.update()
    end
  end

  @doc """
  Retries failed webhook deliveries.
  """
  def retry_failed_deliveries do
    now = DateTime.utc_now()

    deliveries =
      from(d in WebhookDelivery,
        where: d.status == "retrying" and d.next_retry_at <= ^now,
        preload: [:webhook]
      )
      |> Repo.all()

    Enum.each(deliveries, fn delivery ->
      deliver_webhook(delivery.id)
    end)

    length(deliveries)
  end

  @doc """
  Gets webhook delivery statistics.
  """
  def get_webhook_stats(webhook_id) do
    total =
      from(d in WebhookDelivery,
        where: d.webhook_id == ^webhook_id,
        select: count(d.id)
      )
      |> Repo.one()

    delivered =
      from(d in WebhookDelivery,
        where: d.webhook_id == ^webhook_id and d.status == "delivered",
        select: count(d.id)
      )
      |> Repo.one()

    failed =
      from(d in WebhookDelivery,
        where: d.webhook_id == ^webhook_id and d.status == "failed",
        select: count(d.id)
      )
      |> Repo.one()

    pending =
      from(d in WebhookDelivery,
        where: d.webhook_id == ^webhook_id and d.status in ["pending", "retrying"],
        select: count(d.id)
      )
      |> Repo.one()

    %{
      total: total,
      delivered: delivered,
      failed: failed,
      pending: pending,
      success_rate: if(total > 0, do: Float.round(delivered / total * 100, 2), else: 0.0)
    }
  end

  @doc """
  Lists recent deliveries for a webhook.
  """
  def list_webhook_deliveries(webhook_id, limit \\\\ 50) do
    from(d in WebhookDelivery,
      where: d.webhook_id == ^webhook_id,
      order_by: [desc: d.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  # Private functions

  defp create_delivery(attrs) do
    %WebhookDelivery{}
    |> WebhookDelivery.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, delivery} ->
        # Enqueue for async delivery
        %{delivery_id: delivery.id}
        |> VolunteerMatch.Workers.WebhookWorker.new()
        |> Oban.insert()

        {:ok, delivery}

      error ->
        error
    end
  end

  defp get_delivery!(id) do
    Repo.get!(WebhookDelivery, id)
  end

  defp sign_payload(payload, secret) do
    :crypto.mac(:hmac, :sha256, secret, Jason.encode!(payload))
    |> Base.encode16(case: :lower)
  end

  defp apply_webhook_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:ngo_id, value}, query ->
        where(query, [w], w.ngo_id == ^value)

      {:user_id, value}, query ->
        where(query, [w], w.user_id == ^value)

      {:is_active, value}, query ->
        where(query, [w], w.is_active == ^value)

      _, query ->
        query
    end)
  end
end
