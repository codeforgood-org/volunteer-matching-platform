defmodule VolunteerMatch.NGOs.NGO do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "ngos" do
    field :name, :string
    field :description, :string
    field :mission, :string
    field :website, :string
    field :logo_url, :string
    field :cover_image_url, :string
    field :causes, {:array, :string}, default: []
    field :location, Geo.PostGIS.Geometry
    field :address, :string
    field :city, :string
    field :state, :string
    field :country, :string
    field :postal_code, :string
    field :latitude, :float
    field :longitude, :float
    field :phone, :string
    field :email, :string
    field :registration_number, :string
    field :tax_id, :string
    field :year_founded, :integer
    field :organization_size, Ecto.Enum,
      values: [:small, :medium, :large],
      default: :small
    field :is_verified, :boolean, default: false
    field :verified_at, :utc_datetime
    field :verification_documents, {:array, :string}, default: []
    field :social_media, :map, default: %{}
    field :operating_hours, :map
    field :languages_supported, {:array, :string}, default: ["English"]
    field :total_volunteers, :integer, default: 0
    field :active_opportunities, :integer, default: 0
    field :average_rating, :decimal, default: Decimal.new("0.0")
    field :is_active, :boolean, default: true

    belongs_to :user, VolunteerMatch.Accounts.User
    has_many :opportunities, VolunteerMatch.Opportunities.Opportunity
    has_many :reviews_received, VolunteerMatch.Reviews.Review, foreign_key: :reviewee_id
    has_many :reviews_given, VolunteerMatch.Reviews.Review, foreign_key: :reviewer_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(ngo, attrs) do
    ngo
    |> cast(attrs, [
      :user_id,
      :name,
      :description,
      :mission,
      :website,
      :logo_url,
      :cover_image_url,
      :causes,
      :address,
      :city,
      :state,
      :country,
      :postal_code,
      :latitude,
      :longitude,
      :phone,
      :email,
      :registration_number,
      :tax_id,
      :year_founded,
      :organization_size,
      :social_media,
      :operating_hours,
      :languages_supported,
      :is_active
    ])
    |> validate_required([:user_id, :name, :description, :causes])
    |> validate_length(:name, min: 2, max: 200)
    |> validate_length(:description, min: 10)
    |> validate_format(:website, ~r/^https?:\/\//, message: "must be a valid URL")
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must be a valid email")
    |> validate_number(:year_founded, greater_than: 1800, less_than_or_equal_to: DateTime.utc_now().year)
    |> unique_constraint(:user_id)
    |> unique_constraint(:registration_number)
    |> put_location()
  end

  defp put_location(changeset) do
    lat = get_change(changeset, :latitude)
    lng = get_change(changeset, :longitude)

    if lat && lng do
      point = %Geo.Point{coordinates: {lng, lat}, srid: 4326}
      put_change(changeset, :location, point)
    else
      changeset
    end
  end

  def verification_changeset(ngo, attrs) do
    ngo
    |> cast(attrs, [:is_verified, :verified_at, :verification_documents])
    |> validate_required([:is_verified])
  end

  def update_stats_changeset(ngo, attrs) do
    ngo
    |> cast(attrs, [:total_volunteers, :active_opportunities, :average_rating])
    |> validate_number(:total_volunteers, greater_than_or_equal_to: 0)
    |> validate_number(:active_opportunities, greater_than_or_equal_to: 0)
    |> validate_number(:average_rating, greater_than_or_equal_to: 0, less_than_or_equal_to: 5)
  end
end
