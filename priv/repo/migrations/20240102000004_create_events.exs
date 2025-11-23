defmodule VolunteerMatch.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    create table(:events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :description, :text
      add :event_type, :string, null: false
      add :start_time, :utc_datetime, null: false
      add :end_time, :utc_datetime, null: false
      add :location_name, :string
      add :location, :geometry
      add :city, :string
      add :state, :string
      add :country, :string, default: "USA"
      add :is_virtual, :boolean, default: false
      add :virtual_link, :string
      add :max_attendees, :integer
      add :registration_deadline, :utc_datetime
      add :status, :string, default: "upcoming"
      add :image_url, :string
      add :is_public, :boolean, default: true
      add :tags, {:array, :string}, default: []
      add :ngo_id, references(:ngos, type: :binary_id, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:events, [:ngo_id])
    create index(:events, [:status])
    create index(:events, [:event_type])
    create index(:events, [:start_time])
    create index(:events, [:is_public])
    create index(:events, [:location], using: :gist)

    create table(:event_attendees, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :event_id, references(:events, type: :binary_id, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :status, :string, default: "registered"
      add :registered_at, :utc_datetime
      add :attended_at, :utc_datetime
      add :notes, :text

      timestamps(type: :utc_datetime)
    end

    create unique_index(:event_attendees, [:event_id, :user_id])
    create index(:event_attendees, [:event_id])
    create index(:event_attendees, [:user_id])
    create index(:event_attendees, [:status])
  end
end
