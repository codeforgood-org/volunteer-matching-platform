defmodule VolunteerMatch.Gamification.UserBadge do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "user_badges" do
    field :earned_at, :utc_datetime

    belongs_to :user, VolunteerMatch.Accounts.User
    belongs_to :badge, VolunteerMatch.Gamification.Badge

    timestamps(type: :utc_datetime)
  end

  def changeset(user_badge, attrs) do
    user_badge
    |> cast(attrs, [:user_id, :badge_id])
    |> validate_required([:user_id, :badge_id])
    |> unique_constraint([:user_id, :badge_id])
    |> put_earned_at()
  end

  defp put_earned_at(changeset) do
    put_change(changeset, :earned_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end
end
