defmodule VolunteerMatch.Repo.Migrations.CreateNotifications do
  use Ecto.Migration

  def change do
    create table(:notifications, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :type, :string, null: false
      add :title, :string, null: false
      add :message, :text, null: false
      add :is_read, :boolean, default: false
      add :read_at, :utc_datetime
      add :metadata, :map, default: %{}
      add :action_url, :string
      add :related_opportunity_id, references(:opportunities, type: :binary_id, on_delete: :delete_all)
      add :related_application_id, references(:applications, type: :binary_id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:notifications, [:user_id])
    create index(:notifications, [:is_read])
    create index(:notifications, [:type])
    create index(:notifications, [:inserted_at])
  end
end
