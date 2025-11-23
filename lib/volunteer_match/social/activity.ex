defmodule VolunteerMatch.Social.Activity do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "activities" do
    field :type, Ecto.Enum,
      values: [
        :opportunity_created,
        :application_submitted,
        :application_accepted,
        :opportunity_completed,
        :review_posted,
        :badge_earned,
        :achievement_unlocked,
        :milestone_reached,
        :followed_user
      ]

    field :description, :string
    field :metadata, :map, default: %{}

    belongs_to :user, VolunteerMatch.Accounts.User
    belongs_to :related_opportunity, VolunteerMatch.Opportunities.Opportunity
    belongs_to :related_user, VolunteerMatch.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(activity, attrs) do
    activity
    |> cast(attrs, [:user_id, :type, :description, :metadata, :related_opportunity_id, :related_user_id])
    |> validate_required([:user_id, :type, :description])
  end
end
