defmodule VolunteerMatch.Events.Event do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "events" do
    field :title, :string
    field :description, :string
    field :event_type, :string
    field :start_time, :utc_datetime
    field :end_time, :utc_datetime
    field :location_name, :string
    field :location, Geo.PostGIS.Geometry
    field :city, :string
    field :state, :string
    field :country, :string, default: "USA"
    field :is_virtual, :boolean, default: false
    field :virtual_link, :string
    field :max_attendees, :integer
    field :registration_deadline, :utc_datetime
    field :status, :string, default: "upcoming"
    field :image_url, :string
    field :is_public, :boolean, default: true
    field :tags, {:array, :string}, default: []

    belongs_to :ngo, VolunteerMatch.NGOs.NGO
    has_many :event_attendees, VolunteerMatch.Events.EventAttendee
    has_many :attendees, through: [:event_attendees, :user]

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(event, attrs) do
    event
    |> cast(attrs, [
      :title, :description, :event_type, :start_time, :end_time,
      :location_name, :city, :state, :country, :is_virtual, :virtual_link,
      :max_attendees, :registration_deadline, :status, :image_url,
      :is_public, :tags, :ngo_id
    ])
    |> validate_required([:title, :event_type, :start_time, :end_time, :ngo_id])
    |> validate_length(:title, min: 5, max: 200)
    |> validate_length(:description, max: 5000)
    |> validate_inclusion(:event_type, [
      "fundraiser", "workshop", "training", "community_meeting",
      "awareness_campaign", "volunteer_orientation", "celebration", "other"
    ])
    |> validate_inclusion(:status, ["upcoming", "ongoing", "completed", "cancelled"])
    |> validate_event_times()
    |> validate_virtual_or_physical()
  end

  defp validate_event_times(changeset) do
    start_time = get_field(changeset, :start_time)
    end_time = get_field(changeset, :end_time)

    cond do
      is_nil(start_time) or is_nil(end_time) ->
        changeset

      DateTime.compare(start_time, end_time) != :lt ->
        add_error(changeset, :end_time, "must be after start time")

      true ->
        changeset
    end
  end

  defp validate_virtual_or_physical(changeset) do
    is_virtual = get_field(changeset, :is_virtual)
    virtual_link = get_field(changeset, :virtual_link)
    city = get_field(changeset, :city)

    cond do
      is_virtual and is_nil(virtual_link) ->
        add_error(changeset, :virtual_link, "is required for virtual events")

      !is_virtual and is_nil(city) ->
        add_error(changeset, :city, "is required for physical events")

      true ->
        changeset
    end
  end
end
