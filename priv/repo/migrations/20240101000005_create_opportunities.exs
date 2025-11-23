defmodule VolunteerMatch.Repo.Migrations.CreateOpportunities do
  use Ecto.Migration

  def change do
    create table(:opportunities, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :ngo_id, references(:ngos, type: :binary_id, on_delete: :delete_all), null: false
      add :title, :string, null: false
      add :description, :text, null: false
      add :causes, {:array, :string}, default: [], null: false
      add :skills_required, {:array, :string}, default: []
      add :location, :geometry
      add :address, :string
      add :city, :string
      add :state, :string
      add :country, :string
      add :postal_code, :string
      add :latitude, :float
      add :longitude, :float
      add :is_remote, :boolean, default: false
      add :is_virtual, :boolean, default: false
      add :start_date, :date, null: false
      add :end_date, :date
      add :application_deadline, :date
      add :schedule, :map
      add :time_commitment, :string
      add :frequency, :string, default: "flexible"
      add :duration_hours, :integer
      add :volunteers_needed, :integer
      add :volunteers_registered, :integer, default: 0
      add :experience_level, :string, default: "any"
      add :min_age, :integer
      add :max_age, :integer
      add :requirements, {:array, :string}, default: []
      add :benefits, {:array, :string}, default: []
      add :contact_email, :string
      add :contact_phone, :string
      add :image_url, :string
      add :status, :string, default: "draft"
      add :featured, :boolean, default: false
      add :priority, :string, default: "medium"
      add :application_count, :integer, default: 0
      add :view_count, :integer, default: 0
      add :tags, {:array, :string}, default: []

      timestamps(type: :utc_datetime)
    end

    create index(:opportunities, [:ngo_id])
    create index(:opportunities, [:location], using: :gist)
    create index(:opportunities, [:city])
    create index(:opportunities, [:state])
    create index(:opportunities, [:country])
    create index(:opportunities, [:causes], using: :gin)
    create index(:opportunities, [:skills_required], using: :gin)
    create index(:opportunities, [:status])
    create index(:opportunities, [:featured])
    create index(:opportunities, [:start_date])
    create index(:opportunities, [:application_deadline])
    create index(:opportunities, [:is_remote])
    create index(:opportunities, [:is_virtual])
  end
end
