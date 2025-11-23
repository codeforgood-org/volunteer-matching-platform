defmodule VolunteerMatch.Webhooks.WebhookDelivery do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "webhook_deliveries" do
    field :event_type, :string
    field :payload, :map
    field :status, :string, default: "pending"
    field :http_status, :integer
    field :response_body, :string
    field :error_message, :string
    field :attempts, :integer, default: 0
    field :delivered_at, :utc_datetime
    field :next_retry_at, :utc_datetime

    belongs_to :webhook, VolunteerMatch.Webhooks.Webhook

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(webhook_delivery, attrs) do
    webhook_delivery
    |> cast(attrs, [
      :webhook_id, :event_type, :payload, :status, :http_status,
      :response_body, :error_message, :attempts, :delivered_at, :next_retry_at
    ])
    |> validate_required([:webhook_id, :event_type, :payload])
    |> validate_inclusion(:status, ["pending", "delivered", "failed", "retrying"])
  end

  @doc """
  Changeset for marking a delivery as successful.
  """
  def success_changeset(delivery, http_status, response_body) do
    delivery
    |> change(%{
      status: "delivered",
      http_status: http_status,
      response_body: response_body,
      delivered_at: DateTime.utc_now()
    })
  end

  @doc """
  Changeset for marking a delivery as failed with retry.
  """
  def retry_changeset(delivery, error_message) do
    attempts = delivery.attempts + 1
    # Exponential backoff: 1min, 5min, 15min, 1hr, 6hr
    retry_delays = [60, 300, 900, 3600, 21600]
    delay_seconds = Enum.at(retry_delays, min(attempts - 1, length(retry_delays) - 1))
    next_retry = DateTime.add(DateTime.utc_now(), delay_seconds, :second)

    delivery
    |> change(%{
      status: if(attempts >= 5, do: "failed", else: "retrying"),
      error_message: error_message,
      attempts: attempts,
      next_retry_at: if(attempts < 5, do: next_retry, else: nil)
    })
  end

  @doc """
  Changeset for marking a delivery as permanently failed.
  """
  def failed_changeset(delivery, error_message) do
    delivery
    |> change(%{
      status: "failed",
      error_message: error_message,
      attempts: delivery.attempts + 1
    })
  end
end
