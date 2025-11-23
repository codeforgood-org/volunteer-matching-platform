defmodule VolunteerMatch.Events do
  @moduledoc """
  The Events context handles event management functionality.
  """

  import Ecto.Query
  alias VolunteerMatch.{Repo, Events.Event, Events.EventAttendee}

  @doc """
  Creates a new event.
  """
  def create_event(attrs) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an event.
  """
  def update_event(%Event{} = event, attrs) do
    event
    |> Event.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes an event.
  """
  def delete_event(%Event{} = event) do
    Repo.delete(event)
  end

  @doc """
  Gets a single event.
  """
  def get_event!(id) do
    Event
    |> Repo.get!(id)
    |> Repo.preload([:ngo, :event_attendees, :attendees])
  end

  @doc """
  Lists events with optional filters.
  """
  def list_events(filters \\\\ %{}) do
    Event
    |> apply_event_filters(filters)
    |> order_by([e], asc: e.start_time)
    |> Repo.all()
    |> Repo.preload([:ngo])
  end

  @doc """
  Lists upcoming events.
  """
  def list_upcoming_events(limit \\\\ 10) do
    now = DateTime.utc_now()

    from(e in Event,
      where: e.start_time > ^now and e.status == "upcoming" and e.is_public == true,
      order_by: [asc: e.start_time],
      limit: ^limit,
      preload: [:ngo]
    )
    |> Repo.all()
  end

  @doc """
  Lists events for an NGO.
  """
  def list_ngo_events(ngo_id) do
    from(e in Event,
      where: e.ngo_id == ^ngo_id,
      order_by: [desc: e.start_time],
      preload: [:event_attendees]
    )
    |> Repo.all()
  end

  @doc """
  Lists events a user is attending.
  """
  def list_user_events(user_id) do
    from(e in Event,
      join: ea in EventAttendee,
      on: ea.event_id == e.id,
      where: ea.user_id == ^user_id and ea.status in ["registered", "attended"],
      order_by: [asc: e.start_time],
      preload: [:ngo]
    )
    |> Repo.all()
  end

  @doc """
  Registers a user for an event.
  """
  def register_for_event(event_id, user_id) do
    event = get_event!(event_id)

    cond do
      event.status != "upcoming" ->
        {:error, :event_not_available}

      !is_nil(event.registration_deadline) and
          DateTime.compare(DateTime.utc_now(), event.registration_deadline) == :gt ->
        {:error, :registration_closed}

      !is_nil(event.max_attendees) and count_attendees(event_id) >= event.max_attendees ->
        # Add to waitlist
        create_attendee(%{
          event_id: event_id,
          user_id: user_id,
          status: "waitlist",
          registered_at: DateTime.utc_now()
        })

      true ->
        create_attendee(%{
          event_id: event_id,
          user_id: user_id,
          status: "registered",
          registered_at: DateTime.utc_now()
        })
    end
  end

  @doc """
  Cancels a user's event registration.
  """
  def cancel_registration(event_id, user_id) do
    attendee = get_attendee!(event_id, user_id)

    attendee
    |> EventAttendee.cancel_changeset()
    |> Repo.update()
  end

  @doc """
  Marks a user as attended for an event.
  """
  def mark_attended(event_id, user_id) do
    attendee = get_attendee!(event_id, user_id)

    attendee
    |> EventAttendee.attend_changeset()
    |> Repo.update()
  end

  @doc """
  Checks if a user is registered for an event.
  """
  def registered?(event_id, user_id) do
    from(ea in EventAttendee,
      where: ea.event_id == ^event_id and ea.user_id == ^user_id and
             ea.status in ["registered", "attended"]
    )
    |> Repo.exists?()
  end

  @doc """
  Counts attendees for an event.
  """
  def count_attendees(event_id) do
    from(ea in EventAttendee,
      where: ea.event_id == ^event_id and ea.status in ["registered", "attended"],
      select: count(ea.id)
    )
    |> Repo.one()
  end

  @doc """
  Gets event statistics.
  """
  def get_event_stats(event_id) do
    registered_count =
      from(ea in EventAttendee,
        where: ea.event_id == ^event_id and ea.status == "registered",
        select: count(ea.id)
      )
      |> Repo.one()

    attended_count =
      from(ea in EventAttendee,
        where: ea.event_id == ^event_id and ea.status == "attended",
        select: count(ea.id)
      )
      |> Repo.one()

    waitlist_count =
      from(ea in EventAttendee,
        where: ea.event_id == ^event_id and ea.status == "waitlist",
        select: count(ea.id)
      )
      |> Repo.one()

    %{
      registered: registered_count,
      attended: attended_count,
      waitlist: waitlist_count,
      total: registered_count + attended_count
    }
  end

  @doc """
  Searches events near a location.
  """
  def search_nearby_events(latitude, longitude, radius_km \\\\ 50) do
    point = %Geo.Point{coordinates: {longitude, latitude}, srid: 4326}

    from(e in Event,
      where: e.is_virtual == false and e.status == "upcoming" and e.is_public == true,
      where: fragment("ST_DWithin(?::geography, ?::geography, ?)", e.location, ^point, ^(radius_km * 1000)),
      order_by: [asc: fragment("ST_Distance(?::geography, ?::geography)", e.location, ^point)],
      preload: [:ngo]
    )
    |> Repo.all()
  end

  # Private functions

  defp create_attendee(attrs) do
    %EventAttendee{}
    |> EventAttendee.changeset(attrs)
    |> Repo.insert()
  end

  defp get_attendee!(event_id, user_id) do
    from(ea in EventAttendee,
      where: ea.event_id == ^event_id and ea.user_id == ^user_id
    )
    |> Repo.one!()
  end

  defp apply_event_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:ngo_id, value}, query ->
        where(query, [e], e.ngo_id == ^value)

      {:status, value}, query ->
        where(query, [e], e.status == ^value)

      {:event_type, value}, query ->
        where(query, [e], e.event_type == ^value)

      {:is_public, value}, query ->
        where(query, [e], e.is_public == ^value)

      {:is_virtual, value}, query ->
        where(query, [e], e.is_virtual == ^value)

      {:start_after, value}, query ->
        where(query, [e], e.start_time > ^value)

      {:start_before, value}, query ->
        where(query, [e], e.start_time < ^value)

      _, query ->
        query
    end)
  end
end
