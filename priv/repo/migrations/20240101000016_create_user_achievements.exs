defmodule VolunteerMatch.Repo.Migrations.CreateUserAchievements do
  use Ecto.Migration

  def change do
    create table(:user_achievements, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :achievement_id, references(:achievements, type: :binary_id, on_delete: :delete_all), null: false
      add :progress, :integer, default: 0
      add :unlocked_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_achievements, [:user_id, :achievement_id])
    create index(:user_achievements, [:user_id])
    create index(:user_achievements, [:achievement_id])
    create index(:user_achievements, [:unlocked_at])
  end
end
