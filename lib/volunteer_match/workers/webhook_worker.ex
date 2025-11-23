defmodule VolunteerMatch.Workers.WebhookWorker do
  @moduledoc """
  Worker for delivering webhooks asynchronously.
  """

  use Oban.Worker, queue: :webhooks, max_attempts: 5

  alias VolunteerMatch.Webhooks

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"delivery_id" => delivery_id}}) do
    case Webhooks.deliver_webhook(delivery_id) do
      {:ok, _delivery} -> :ok
      {:error, _} -> {:error, "Webhook delivery failed"}
    end
  end
end
