defmodule VolunteerMatch.Repo.Migrations.CreateMatches do
  use Ecto.Migration

  def change do
    create table(:matches, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :volunteer_id, references(:volunteers, type: :binary_id, on_delete: :delete_all), null: false
      add :opportunity_id, references(:opportunities, type: :binary_id, on_delete: :delete_all), null: false
      add :match_score, :decimal, null: false
      add :location_score, :decimal
      add :cause_score, :decimal
      add :skill_score, :decimal
      add :time_score, :decimal
      add :distance_km, :float
      add :status, :string, default: "suggested"
      add :viewed_at, :utc_datetime
      add :dismissed_at, :utc_datetime
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:matches, [:volunteer_id])
    create index(:matches, [:opportunity_id])
    create index(:matches, [:status])
    create index(:matches, [:match_score])
    create unique_index(:matches, [:volunteer_id, :opportunity_id])
  end
end
