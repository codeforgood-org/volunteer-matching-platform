defmodule VolunteerMatch.Repo.Migrations.CreateApplications do
  use Ecto.Migration

  def change do
    create table(:applications, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :volunteer_id, references(:volunteers, type: :binary_id, on_delete: :delete_all), null: false
      add :opportunity_id, references(:opportunities, type: :binary_id, on_delete: :delete_all), null: false
      add :message, :text
      add :availability_notes, :text
      add :status, :string, default: "pending", null: false
      add :applied_at, :utc_datetime
      add :reviewed_at, :utc_datetime
      add :reviewer_notes, :text
      add :volunteer_hours, :integer
      add :completion_notes, :text
      add :completed_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:applications, [:volunteer_id])
    create index(:applications, [:opportunity_id])
    create index(:applications, [:status])
    create unique_index(:applications, [:volunteer_id, :opportunity_id])
  end
end
