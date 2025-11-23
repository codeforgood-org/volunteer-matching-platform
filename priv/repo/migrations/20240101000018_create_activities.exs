defmodule VolunteerMatch.Repo.Migrations.CreateActivities do
  use Ecto.Migration

  def change do
    create table(:activities, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :type, :string, null: false
      add :description, :text, null: false
      add :metadata, :map, default: %{}
      add :related_opportunity_id, references(:opportunities, type: :binary_id, on_delete: :delete_all)
      add :related_user_id, references(:users, type: :binary_id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:activities, [:user_id])
    create index(:activities, [:type])
    create index(:activities, [:inserted_at])
    create index(:activities, [:related_opportunity_id])
  end
end
