defmodule VolunteerMatch.Repo.Migrations.CreateVolunteers do
  use Ecto.Migration

  def change do
    create table(:volunteers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :bio, :text
      add :skills, {:array, :string}, default: []
      add :interests, {:array, :string}, default: []
      add :causes, {:array, :string}, default: []
      add :location, :geometry
      add :address, :string
      add :city, :string
      add :state, :string
      add :country, :string
      add :postal_code, :string
      add :latitude, :float
      add :longitude, :float
      add :max_distance, :integer, default: 25
      add :availability, :map
      add :preferred_days, {:array, :string}, default: []
      add :preferred_times, {:array, :string}, default: []
      add :hours_per_week, :integer
      add :experience_level, :string, default: "beginner"
      add :languages, {:array, :string}, default: ["English"]
      add :emergency_contact_name, :string
      add :emergency_contact_phone, :string
      add :background_check_completed, :boolean, default: false
      add :background_check_date, :date
      add :total_hours, :integer, default: 0
      add :completed_opportunities, :integer, default: 0
      add :average_rating, :decimal, default: 0.0
      add :is_active, :boolean, default: true

      timestamps(type: :utc_datetime)
    end

    create unique_index(:volunteers, [:user_id])
    create index(:volunteers, [:location], using: :gist)
    create index(:volunteers, [:city])
    create index(:volunteers, [:state])
    create index(:volunteers, [:country])
    create index(:volunteers, [:causes], using: :gin)
    create index(:volunteers, [:skills], using: :gin)
    create index(:volunteers, [:is_active])
  end
end
