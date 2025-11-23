defmodule VolunteerMatch.Repo.Migrations.CreateWebhooks do
  use Ecto.Migration

  def change do
    create table(:webhooks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :url, :string, null: false
      add :secret, :string, null: false
      add :description, :string
      add :events, {:array, :string}, default: [], null: false
      add :is_active, :boolean, default: true
      add :ngo_id, references(:ngos, type: :binary_id, on_delete: :delete_all)
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:webhooks, [:ngo_id])
    create index(:webhooks, [:user_id])
    create index(:webhooks, [:is_active])

    create table(:webhook_deliveries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :webhook_id, references(:webhooks, type: :binary_id, on_delete: :delete_all), null: false
      add :event_type, :string, null: false
      add :payload, :map, null: false
      add :status, :string, default: "pending"
      add :http_status, :integer
      add :response_body, :text
      add :error_message, :text
      add :attempts, :integer, default: 0
      add :delivered_at, :utc_datetime
      add :next_retry_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:webhook_deliveries, [:webhook_id])
    create index(:webhook_deliveries, [:status])
    create index(:webhook_deliveries, [:event_type])
    create index(:webhook_deliveries, [:next_retry_at])
  end
end
