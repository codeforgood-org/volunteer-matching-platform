defmodule VolunteerMatch.Webhooks.Webhook do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @available_events [
    "application.created",
    "application.accepted",
    "application.rejected",
    "application.completed",
    "opportunity.created",
    "opportunity.updated",
    "opportunity.closed",
    "volunteer.registered",
    "event.created",
    "event.registered",
    "match.created"
  ]

  schema "webhooks" do
    field :url, :string
    field :secret, :string
    field :description, :string
    field :events, {:array, :string}, default: []
    field :is_active, :boolean, default: true

    belongs_to :ngo, VolunteerMatch.NGOs.NGO
    belongs_to :user, VolunteerMatch.Accounts.User
    has_many :webhook_deliveries, VolunteerMatch.Webhooks.WebhookDelivery

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(webhook, attrs) do
    webhook
    |> cast(attrs, [:url, :secret, :description, :events, :is_active, :ngo_id, :user_id])
    |> validate_required([:url, :events])
    |> validate_url(:url)
    |> validate_events()
    |> put_secret()
  end

  defp validate_url(changeset, field) do
    validate_change(changeset, field, fn _, url ->
      uri = URI.parse(url)

      if uri.scheme in ["http", "https"] and not is_nil(uri.host) do
        []
      else
        [{field, "must be a valid HTTP or HTTPS URL"}]
      end
    end)
  end

  defp validate_events(changeset) do
    case get_change(changeset, :events) do
      nil ->
        changeset

      events ->
        if Enum.all?(events, &(&1 in @available_events)) do
          changeset
        else
          add_error(changeset, :events, "contains invalid event types")
        end
    end
  end

  defp put_secret(changeset) do
    if get_field(changeset, :secret) do
      changeset
    else
      secret = :crypto.strong_rand_bytes(32) |> Base.encode64()
      put_change(changeset, :secret, secret)
    end
  end

  @doc """
  Returns list of available webhook events.
  """
  def available_events, do: @available_events
end
