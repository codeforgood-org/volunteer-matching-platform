defmodule VolunteerMatch.Repo.Migrations.CreateFollowers do
  use Ecto.Migration

  def change do
    create table(:followers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :follower_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :following_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:followers, [:follower_id, :following_id])
    create index(:followers, [:follower_id])
    create index(:followers, [:following_id])
  end
end
