defmodule VolunteerMatch.Repo.Migrations.CreateAchievements do
  use Ecto.Migration

  def change do
    create table(:achievements, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :text, null: false
      add :icon, :string
      add :tier, :string, default: "bronze"
      add :points, :integer, default: 50
      add :progress_max, :integer
      add :unlock_criteria, :map

      timestamps(type: :utc_datetime)
    end

    create unique_index(:achievements, [:name])
    create index(:achievements, [:tier])
  end
end
