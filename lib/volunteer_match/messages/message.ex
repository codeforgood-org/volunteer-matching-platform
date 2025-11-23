defmodule VolunteerMatch.Messages.Message do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "messages" do
    field :subject, :string
    field :body, :string
    field :read_at, :utc_datetime
    field :is_read, :boolean, default: false
    field :message_type, Ecto.Enum,
      values: [:direct, :application, :opportunity, :system],
      default: :direct
    field :metadata, :map, default: %{}

    belongs_to :sender, VolunteerMatch.Accounts.User
    belongs_to :recipient, VolunteerMatch.Accounts.User
    belongs_to :opportunity, VolunteerMatch.Opportunities.Opportunity
    belongs_to :application, VolunteerMatch.Opportunities.Application

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(message, attrs) do
    message
    |> cast(attrs, [
      :sender_id,
      :recipient_id,
      :subject,
      :body,
      :message_type,
      :metadata,
      :opportunity_id,
      :application_id
    ])
    |> validate_required([:sender_id, :recipient_id, :body])
    |> validate_length(:body, min: 1, max: 5000)
    |> validate_length(:subject, max: 200)
    |> foreign_key_constraint(:sender_id)
    |> foreign_key_constraint(:recipient_id)
    |> foreign_key_constraint(:opportunity_id)
    |> foreign_key_constraint(:application_id)
  end

  def mark_as_read_changeset(message) do
    message
    |> change(is_read: true, read_at: DateTime.utc_now() |> DateTime.truncate(:second))
  end
end
