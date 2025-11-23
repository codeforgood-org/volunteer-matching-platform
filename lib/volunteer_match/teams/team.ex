defmodule VolunteerMatch.Teams.Team do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "teams" do
    field :name, :string
    field :description, :string
    field :team_type, :string, default: "volunteer"
    field :max_members, :integer, default: 10
    field :is_public, :boolean, default: true
    field :avatar_url, :string

    belongs_to :leader, VolunteerMatch.Volunteers.Volunteer
    has_many :team_members, VolunteerMatch.Teams.TeamMember
    has_many :members, through: [:team_members, :volunteer]
    has_many :applications, VolunteerMatch.Opportunities.Application

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name, :description, :team_type, :max_members, :is_public, :avatar_url, :leader_id])
    |> validate_required([:name, :leader_id])
    |> validate_length(:name, min: 3, max: 100)
    |> validate_length(:description, max: 1000)
    |> validate_number(:max_members, greater_than: 0, less_than_or_equal_to: 100)
    |> validate_inclusion(:team_type, ["volunteer", "corporate", "student", "family"])
  end
end
