defmodule VolunteerMatch.Gamification.UserAchievement do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "user_achievements" do
    field :progress, :integer, default: 0
    field :unlocked_at, :utc_datetime

    belongs_to :user, VolunteerMatch.Accounts.User
    belongs_to :achievement, VolunteerMatch.Gamification.Achievement

    timestamps(type: :utc_datetime)
  end

  def changeset(user_achievement, attrs) do
    user_achievement
    |> cast(attrs, [:user_id, :achievement_id, :progress])
    |> validate_required([:user_id, :achievement_id])
    |> unique_constraint([:user_id, :achievement_id])
  end

  def unlock_changeset(user_achievement) do
    user_achievement
    |> change(unlocked_at: DateTime.utc_now() |> DateTime.truncate(:second))
  end
end
