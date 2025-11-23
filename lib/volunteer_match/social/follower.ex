defmodule VolunteerMatch.Social.Follower do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "followers" do
    belongs_to :follower, VolunteerMatch.Accounts.User
    belongs_to :following, VolunteerMatch.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(follower, attrs) do
    follower
    |> cast(attrs, [:follower_id, :following_id])
    |> validate_required([:follower_id, :following_id])
    |> validate_not_self_follow()
    |> unique_constraint([:follower_id, :following_id])
  end

  defp validate_not_self_follow(changeset) do
    follower_id = get_field(changeset, :follower_id)
    following_id = get_field(changeset, :following_id)

    if follower_id == following_id do
      add_error(changeset, :following_id, "cannot follow yourself")
    else
      changeset
    end
  end
end
