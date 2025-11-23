defmodule VolunteerMatch.Teams.TeamMember do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "team_members" do
    field :role, :string, default: "member"
    field :status, :string, default: "active"
    field :joined_at, :utc_datetime

    belongs_to :team, VolunteerMatch.Teams.Team
    belongs_to :volunteer, VolunteerMatch.Volunteers.Volunteer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(team_member, attrs) do
    team_member
    |> cast(attrs, [:team_id, :volunteer_id, :role, :status, :joined_at])
    |> validate_required([:team_id, :volunteer_id])
    |> validate_inclusion(:role, ["leader", "co-leader", "member"])
    |> validate_inclusion(:status, ["active", "inactive", "pending", "removed"])
    |> unique_constraint([:team_id, :volunteer_id])
  end

  @doc """
  Changeset for accepting a team invitation.
  """
  def accept_changeset(team_member) do
    team_member
    |> change(%{status: "active", joined_at: DateTime.utc_now()})
  end

  @doc """
  Changeset for removing a member from a team.
  """
  def remove_changeset(team_member) do
    team_member
    |> change(%{status: "removed"})
  end
end
