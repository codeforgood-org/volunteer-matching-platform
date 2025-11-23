defmodule VolunteerMatch.Opportunities.Opportunity do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "opportunities" do
    field :title, :string
    field :description, :string
    field :causes, {:array, :string}, default: []
    field :skills_required, {:array, :string}, default: []
    field :location, Geo.PostGIS.Geometry
    field :address, :string
    field :city, :string
    field :state, :string
    field :country, :string
    field :postal_code, :string
    field :latitude, :float
    field :longitude, :float
    field :is_remote, :boolean, default: false
    field :is_virtual, :boolean, default: false
    field :start_date, :date
    field :end_date, :date
    field :application_deadline, :date
    field :schedule, :map
    field :time_commitment, :string
    field :frequency, Ecto.Enum,
      values: [:one_time, :weekly, :monthly, :flexible],
      default: :flexible
    field :duration_hours, :integer
    field :volunteers_needed, :integer
    field :volunteers_registered, :integer, default: 0
    field :experience_level, Ecto.Enum,
      values: [:beginner, :intermediate, :advanced, :any],
      default: :any
    field :min_age, :integer
    field :max_age, :integer
    field :requirements, {:array, :string}, default: []
    field :benefits, {:array, :string}, default: []
    field :contact_email, :string
    field :contact_phone, :string
    field :image_url, :string
    field :status, Ecto.Enum,
      values: [:draft, :published, :filled, :cancelled, :completed],
      default: :draft
    field :featured, :boolean, default: false
    field :priority, Ecto.Enum,
      values: [:low, :medium, :high, :urgent],
      default: :medium
    field :application_count, :integer, default: 0
    field :view_count, :integer, default: 0
    field :tags, {:array, :string}, default: []

    belongs_to :ngo, VolunteerMatch.NGOs.NGO
    has_many :applications, VolunteerMatch.Opportunities.Application
    has_many :matches, VolunteerMatch.Matching.Match

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(opportunity, attrs) do
    opportunity
    |> cast(attrs, [
      :ngo_id,
      :title,
      :description,
      :causes,
      :skills_required,
      :address,
      :city,
      :state,
      :country,
      :postal_code,
      :latitude,
      :longitude,
      :is_remote,
      :is_virtual,
      :start_date,
      :end_date,
      :application_deadline,
      :schedule,
      :time_commitment,
      :frequency,
      :duration_hours,
      :volunteers_needed,
      :experience_level,
      :min_age,
      :max_age,
      :requirements,
      :benefits,
      :contact_email,
      :contact_phone,
      :image_url,
      :status,
      :featured,
      :priority,
      :tags
    ])
    |> validate_required([:ngo_id, :title, :description, :causes, :start_date])
    |> validate_length(:title, min: 5, max: 200)
    |> validate_length(:description, min: 20)
    |> validate_number(:volunteers_needed, greater_than: 0)
    |> validate_number(:duration_hours, greater_than: 0)
    |> validate_dates()
    |> foreign_key_constraint(:ngo_id)
    |> put_location()
  end

  defp validate_dates(changeset) do
    start_date = get_field(changeset, :start_date)
    end_date = get_field(changeset, :end_date)
    deadline = get_field(changeset, :application_deadline)

    changeset
    |> validate_end_date_after_start_date(start_date, end_date)
    |> validate_deadline_before_start(start_date, deadline)
  end

  defp validate_end_date_after_start_date(changeset, start_date, end_date) do
    if start_date && end_date && Date.compare(end_date, start_date) == :lt do
      add_error(changeset, :end_date, "must be after start date")
    else
      changeset
    end
  end

  defp validate_deadline_before_start(changeset, start_date, deadline) do
    if start_date && deadline && Date.compare(deadline, start_date) == :gt do
      add_error(changeset, :application_deadline, "must be before start date")
    else
      changeset
    end
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

  def publish_changeset(opportunity) do
    change(opportunity, status: :published)
  end

  def update_stats_changeset(opportunity, attrs) do
    opportunity
    |> cast(attrs, [:volunteers_registered, :application_count, :view_count])
    |> validate_number(:volunteers_registered, greater_than_or_equal_to: 0)
    |> validate_number(:application_count, greater_than_or_equal_to: 0)
    |> validate_number(:view_count, greater_than_or_equal_to: 0)
  end
end
