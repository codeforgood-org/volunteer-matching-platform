defmodule VolunteerMatch.Volunteers.Volunteer do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "volunteers" do
    field :bio, :string
    field :skills, {:array, :string}, default: []
    field :interests, {:array, :string}, default: []
    field :causes, {:array, :string}, default: []
    field :location, Geo.PostGIS.Geometry
    field :address, :string
    field :city, :string
    field :state, :string
    field :country, :string
    field :postal_code, :string
    field :latitude, :float
    field :longitude, :float
    field :max_distance, :integer, default: 25
    field :availability, :map
    field :preferred_days, {:array, :string}, default: []
    field :preferred_times, {:array, :string}, default: []
    field :hours_per_week, :integer
    field :experience_level, Ecto.Enum, values: [:beginner, :intermediate, :advanced], default: :beginner
    field :languages, {:array, :string}, default: ["English"]
    field :emergency_contact_name, :string
    field :emergency_contact_phone, :string
    field :background_check_completed, :boolean, default: false
    field :background_check_date, :date
    field :total_hours, :integer, default: 0
    field :completed_opportunities, :integer, default: 0
    field :average_rating, :decimal, default: Decimal.new("0.0")
    field :is_active, :boolean, default: true

    belongs_to :user, VolunteerMatch.Accounts.User
    has_many :applications, VolunteerMatch.Opportunities.Application
    has_many :reviews_received, VolunteerMatch.Reviews.Review, foreign_key: :reviewee_id
    has_many :reviews_given, VolunteerMatch.Reviews.Review, foreign_key: :reviewer_id
    has_many :matches, VolunteerMatch.Matching.Match

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(volunteer, attrs) do
    volunteer
    |> cast(attrs, [
      :user_id,
      :bio,
      :skills,
      :interests,
      :causes,
      :address,
      :city,
      :state,
      :country,
      :postal_code,
      :latitude,
      :longitude,
      :max_distance,
      :availability,
      :preferred_days,
      :preferred_times,
      :hours_per_week,
      :experience_level,
      :languages,
      :emergency_contact_name,
      :emergency_contact_phone,
      :background_check_completed,
      :background_check_date,
      :is_active
    ])
    |> validate_required([:user_id])
    |> validate_number(:max_distance, greater_than: 0, less_than_or_equal_to: 100)
    |> validate_number(:hours_per_week, greater_than_or_equal_to: 0, less_than_or_equal_to: 168)
    |> unique_constraint(:user_id)
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

  def update_stats_changeset(volunteer, attrs) do
    volunteer
    |> cast(attrs, [:total_hours, :completed_opportunities, :average_rating])
    |> validate_number(:total_hours, greater_than_or_equal_to: 0)
    |> validate_number(:completed_opportunities, greater_than_or_equal_to: 0)
    |> validate_number(:average_rating, greater_than_or_equal_to: 0, less_than_or_equal_to: 5)
  end
end
