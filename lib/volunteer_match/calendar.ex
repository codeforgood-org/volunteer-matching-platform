defmodule VolunteerMatch.Calendar do
  @moduledoc """
  The Calendar context provides iCal export functionality for events and opportunities.
  """

  alias VolunteerMatch.{Repo, Events.Event, Opportunities.Opportunity}

  @doc """
  Exports an event to iCal format.
  """
  def export_event_ical(event_id) do
    event =
      Event
      |> Repo.get!(event_id)
      |> Repo.preload(:ngo)

    generate_ical_event(event)
  end

  @doc """
  Exports multiple events to a single iCal file.
  """
  def export_events_ical(event_ids) do
    events =
      Event
      |> Repo.all()
      |> Enum.filter(&(&1.id in event_ids))
      |> Repo.preload(:ngo)

    events_ical = Enum.map(events, &build_event_component/1) |> Enum.join("\n")

    """
    BEGIN:VCALENDAR
    VERSION:2.0
    PRODID:-//VolunteerMatch//Event Calendar//EN
    CALSCALE:GREGORIAN
    METHOD:PUBLISH
    X-WR-CALNAME:VolunteerMatch Events
    X-WR-TIMEZONE:UTC
    #{events_ical}
    END:VCALENDAR
    """
  end

  @doc """
  Exports an opportunity to iCal format.
  """
  def export_opportunity_ical(opportunity_id) do
    opportunity =
      Opportunity
      |> Repo.get!(opportunity_id)
      |> Repo.preload(:ngo)

    generate_ical_opportunity(opportunity)
  end

  @doc """
  Exports a volunteer's schedule (accepted opportunities) to iCal.
  """
  def export_volunteer_schedule(volunteer_id) do
    import Ecto.Query

    applications =
      from(a in VolunteerMatch.Opportunities.Application,
        where: a.volunteer_id == ^volunteer_id and a.status in [:accepted, :in_progress],
        preload: [opportunity: :ngo]
      )
      |> Repo.all()

    opportunities_ical =
      applications
      |> Enum.map(& &1.opportunity)
      |> Enum.map(&build_opportunity_component/1)
      |> Enum.join("\n")

    """
    BEGIN:VCALENDAR
    VERSION:2.0
    PRODID:-//VolunteerMatch//Volunteer Schedule//EN
    CALSCALE:GREGORIAN
    METHOD:PUBLISH
    X-WR-CALNAME:My Volunteer Schedule
    X-WR-TIMEZONE:UTC
    #{opportunities_ical}
    END:VCALENDAR
    """
  end

  @doc """
  Exports all upcoming events for an NGO to iCal.
  """
  def export_ngo_events(ngo_id) do
    import Ecto.Query

    events =
      from(e in Event,
        where: e.ngo_id == ^ngo_id and e.status == "upcoming",
        preload: [:ngo]
      )
      |> Repo.all()

    events_ical = Enum.map(events, &build_event_component/1) |> Enum.join("\n")

    """
    BEGIN:VCALENDAR
    VERSION:2.0
    PRODID:-//VolunteerMatch//NGO Events//EN
    CALSCALE:GREGORIAN
    METHOD:PUBLISH
    X-WR-CALNAME:Organization Events
    X-WR-TIMEZONE:UTC
    #{events_ical}
    END:VCALENDAR
    """
  end

  # Private functions

  defp generate_ical_event(event) do
    """
    BEGIN:VCALENDAR
    VERSION:2.0
    PRODID:-//VolunteerMatch//Event//EN
    CALSCALE:GREGORIAN
    METHOD:PUBLISH
    #{build_event_component(event)}
    END:VCALENDAR
    """
  end

  defp generate_ical_opportunity(opportunity) do
    """
    BEGIN:VCALENDAR
    VERSION:2.0
    PRODID:-//VolunteerMatch//Opportunity//EN
    CALSCALE:GREGORIAN
    METHOD:PUBLISH
    #{build_opportunity_component(opportunity)}
    END:VCALENDAR
    """
  end

  defp build_event_component(event) do
    uid = "event-#{event.id}@volunteermatch.org"
    dtstamp = format_ical_datetime(DateTime.utc_now())
    dtstart = format_ical_datetime(event.start_time)
    dtend = format_ical_datetime(event.end_time)
    summary = escape_ical_text(event.title)
    description = escape_ical_text(event.description || "")
    location = build_location_string(event)
    organizer = "CN=#{escape_ical_text(event.ngo.name)}"

    url =
      if event.is_virtual and event.virtual_link do
        "URL:#{event.virtual_link}"
      else
        ""
      end

    """
    BEGIN:VEVENT
    UID:#{uid}
    DTSTAMP:#{dtstamp}
    DTSTART:#{dtstart}
    DTEND:#{dtend}
    SUMMARY:#{summary}
    DESCRIPTION:#{description}
    LOCATION:#{location}
    ORGANIZER;#{organizer}
    STATUS:CONFIRMED
    TRANSP:OPAQUE
    #{url}
    END:VEVENT
    """
  end

  defp build_opportunity_component(opportunity) do
    uid = "opportunity-#{opportunity.id}@volunteermatch.org"
    dtstamp = format_ical_datetime(DateTime.utc_now())
    dtstart = format_ical_datetime(opportunity.start_date)

    # Calculate end date (assume 4 hours if duration not specified)
    dtend =
      if opportunity.end_date do
        format_ical_datetime(opportunity.end_date)
      else
        end_time = DateTime.add(opportunity.start_date, 4 * 3600, :second)
        format_ical_datetime(end_time)
      end

    summary = escape_ical_text(opportunity.title)
    description = escape_ical_text(opportunity.description || "")
    location = "#{opportunity.city}, #{opportunity.state}"
    organizer = "CN=#{escape_ical_text(opportunity.ngo.name)}"

    """
    BEGIN:VEVENT
    UID:#{uid}
    DTSTAMP:#{dtstamp}
    DTSTART:#{dtstart}
    DTEND:#{dtend}
    SUMMARY:#{summary}
    DESCRIPTION:#{description}
    LOCATION:#{location}
    ORGANIZER;#{organizer}
    STATUS:CONFIRMED
    TRANSP:OPAQUE
    END:VEVENT
    """
  end

  defp build_location_string(event) do
    cond do
      event.is_virtual and event.virtual_link ->
        "Virtual: #{event.virtual_link}"

      event.location_name ->
        "#{event.location_name}, #{event.city}, #{event.state}"

      event.city ->
        "#{event.city}, #{event.state}"

      true ->
        ""
    end
  end

  defp format_ical_datetime(datetime) do
    datetime
    |> DateTime.truncate(:second)
    |> Calendar.strftime("%Y%m%dT%H%M%SZ")
  end

  defp escape_ical_text(text) do
    text
    |> String.replace("\\", "\\\\")
    |> String.replace(",", "\\,")
    |> String.replace(";", "\\;")
    |> String.replace("\n", "\\n")
    # Fold long lines (RFC 5545 - max 75 octets per line)
    |> fold_ical_text()
  end

  defp fold_ical_text(text) do
    text
    |> String.graphemes()
    |> Enum.chunk_every(75)
    |> Enum.map(&Enum.join/1)
    |> Enum.join("\r\n ")
  end

  @doc """
  Generates an iCal feed URL for a user.
  """
  def generate_feed_token(user_id) do
    # Generate a secure token for accessing the calendar feed
    :crypto.strong_rand_bytes(32)
    |> Base.url_encode64(padding: false)
    |> String.slice(0..31)
  end

  @doc """
  Generates a webcal:// URL for subscribing to a calendar feed.
  """
  def generate_webcal_url(base_url, feed_token) do
    "webcal://#{base_url}/api/calendar/feed/#{feed_token}.ics"
  end

  @doc """
  Adds a reminder to an event (in minutes before event).
  """
  def add_reminder(ical_content, minutes_before) do
    reminder = """
    BEGIN:VALARM
    TRIGGER:-PT#{minutes_before}M
    DESCRIPTION:Reminder
    ACTION:DISPLAY
    END:VALARM
    """

    String.replace(ical_content, "END:VEVENT", "#{reminder}END:VEVENT")
  end
end
