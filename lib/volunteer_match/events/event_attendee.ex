defmodule VolunteerMatch.Events.EventAttendee do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "event_attendees" do
    field :status, :string, default: "registered"
    field :registered_at, :utc_datetime
    field :attended_at, :utc_datetime
    field :notes, :string

    belongs_to :event, VolunteerMatch.Events.Event
    belongs_to :user, VolunteerMatch.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(event_attendee, attrs) do
    event_attendee
    |> cast(attrs, [:event_id, :user_id, :status, :registered_at, :attended_at, :notes])
    |> validate_required([:event_id, :user_id])
    |> validate_inclusion(:status, ["registered", "waitlist", "attended", "no_show", "cancelled"])
    |> unique_constraint([:event_id, :user_id])
  end

  @doc """
  Changeset for registering for an event.
  """
  def register_changeset(event_attendee) do
    event_attendee
    |> change(%{status: "registered", registered_at: DateTime.utc_now()})
  end

  @doc """
  Changeset for marking attendance.
  """
  def attend_changeset(event_attendee) do
    event_attendee
    |> change(%{status: "attended", attended_at: DateTime.utc_now()})
  end

  @doc """
  Changeset for cancelling registration.
  """
  def cancel_changeset(event_attendee) do
    event_attendee
    |> change(%{status: "cancelled"})
  end
end
