defmodule VolunteerMatch.Repo.Migrations.CreateNGOs do
  use Ecto.Migration

  def change do
    create table(:ngos, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :description, :text, null: false
      add :mission, :text
      add :website, :string
      add :logo_url, :string
      add :cover_image_url, :string
      add :causes, {:array, :string}, default: [], null: false
      add :location, :geometry
      add :address, :string
      add :city, :string
      add :state, :string
      add :country, :string
      add :postal_code, :string
      add :latitude, :float
      add :longitude, :float
      add :phone, :string
      add :email, :string
      add :registration_number, :string
      add :tax_id, :string
      add :year_founded, :integer
      add :organization_size, :string, default: "small"
      add :is_verified, :boolean, default: false
      add :verified_at, :utc_datetime
      add :verification_documents, {:array, :string}, default: []
      add :social_media, :map, default: %{}
      add :operating_hours, :map
      add :languages_supported, {:array, :string}, default: ["English"]
      add :total_volunteers, :integer, default: 0
      add :active_opportunities, :integer, default: 0
      add :average_rating, :decimal, default: 0.0
      add :is_active, :boolean, default: true

      timestamps(type: :utc_datetime)
    end

    create unique_index(:ngos, [:user_id])
    create unique_index(:ngos, [:registration_number])
    create index(:ngos, [:location], using: :gist)
    create index(:ngos, [:city])
    create index(:ngos, [:state])
    create index(:ngos, [:country])
    create index(:ngos, [:causes], using: :gin)
    create index(:ngos, [:is_verified])
    create index(:ngos, [:is_active])
    create index(:ngos, [:name])
  end
end
