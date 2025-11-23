defmodule VolunteerMatch.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    create table(:teams, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :team_type, :string, default: "volunteer"
      add :max_members, :integer, default: 10
      add :is_public, :boolean, default: true
      add :avatar_url, :string
      add :leader_id, references(:volunteers, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:teams, [:leader_id])
    create index(:teams, [:is_public])
    create index(:teams, [:team_type])

    create table(:team_members, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :team_id, references(:teams, type: :binary_id, on_delete: :delete_all), null: false
      add :volunteer_id, references(:volunteers, type: :binary_id, on_delete: :delete_all), null: false
      add :role, :string, default: "member"
      add :status, :string, default: "active"
      add :joined_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:team_members, [:team_id, :volunteer_id])
    create index(:team_members, [:team_id])
    create index(:team_members, [:volunteer_id])
    create index(:team_members, [:status])

    # Add team_id to applications table to support team applications
    alter table(:applications) do
      add :team_id, references(:teams, type: :binary_id, on_delete: :nilify_all)
      add :is_team_application, :boolean, default: false
    end

    create index(:applications, [:team_id])
  end
end
