defmodule VolunteerMatch.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :sender_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :recipient_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :opportunity_id, references(:opportunities, type: :binary_id, on_delete: :delete_all)
      add :application_id, references(:applications, type: :binary_id, on_delete: :delete_all)
      add :subject, :string
      add :body, :text, null: false
      add :read_at, :utc_datetime
      add :is_read, :boolean, default: false
      add :message_type, :string, default: "direct"
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:messages, [:sender_id])
    create index(:messages, [:recipient_id])
    create index(:messages, [:opportunity_id])
    create index(:messages, [:application_id])
    create index(:messages, [:is_read])
    create index(:messages, [:message_type])
    create index(:messages, [:inserted_at])
  end
end
