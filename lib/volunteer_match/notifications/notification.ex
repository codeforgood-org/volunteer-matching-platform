defmodule VolunteerMatch.Notifications.Notification do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "notifications" do
    field :type, Ecto.Enum,
      values: [
        :new_match,
        :application_received,
        :application_accepted,
        :application_rejected,
        :new_message,
        :opportunity_reminder,
        :review_received,
        :achievement_unlocked,
        :badge_earned,
        :milestone_reached
      ]

    field :title, :string
    field :message, :string
    field :is_read, :boolean, default: false
    field :read_at, :utc_datetime
    field :metadata, :map, default: %{}
    field :action_url, :string

    belongs_to :user, VolunteerMatch.Accounts.User
    belongs_to :related_opportunity, VolunteerMatch.Opportunities.Opportunity
    belongs_to :related_application, VolunteerMatch.Opportunities.Application

    timestamps(type: :utc_datetime)
  end

  def changeset(notification, attrs) do
    notification
    |> cast(attrs, [:user_id, :type, :title, :message, :metadata, :action_url, :related_opportunity_id, :related_application_id])
    |> validate_required([:user_id, :type, :title, :message])
    |> foreign_key_constraint(:user_id)
  end

  def mark_as_read_changeset(notification) do
    notification
    |> change(is_read: true, read_at: DateTime.utc_now() |> DateTime.truncate(:second))
  end
end
