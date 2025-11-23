defmodule VolunteerMatch.Repo.Migrations.CreateUserBadges do
  use Ecto.Migration

  def change do
    create table(:user_badges, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :badge_id, references(:badges, type: :binary_id, on_delete: :delete_all), null: false
      add :earned_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_badges, [:user_id, :badge_id])
    create index(:user_badges, [:user_id])
    create index(:user_badges, [:badge_id])
    create index(:user_badges, [:earned_at])
  end
end
