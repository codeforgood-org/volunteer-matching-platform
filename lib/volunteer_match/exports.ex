defmodule VolunteerMatch.Exports do
  @moduledoc """
  The Exports context provides data export functionality in various formats.
  """

  alias VolunteerMatch.{Opportunities, Volunteers, NGOs, Repo}

  @doc """
  Exports opportunities to CSV.
  """
  def export_opportunities_csv(filters \\ %{}) do
    opportunities = Opportunities.list_opportunities(filters)

    headers = [
      "ID",
      "Title",
      "Description",
      "NGO",
      "City",
      "State",
      "Start Date",
      "Status",
      "Volunteers Needed",
      "Volunteers Registered",
      "Created At"
    ]

    rows =
      Enum.map(opportunities, fn opp ->
        opp = Repo.preload(opp, :ngo)

        [
          opp.id,
          opp.title,
          opp.description,
          opp.ngo.name,
          opp.city,
          opp.state,
          opp.start_date,
          opp.status,
          opp.volunteers_needed,
          opp.volunteers_registered,
          opp.inserted_at
        ]
      end)

    {:ok, generate_csv([headers | rows])}
  end

  @doc """
  Exports volunteers to CSV.
  """
  def export_volunteers_csv(filters \\ %{}) do
    volunteers = Volunteers.list_volunteers(filters)

    headers = [
      "ID",
      "Name",
      "Email",
      "City",
      "State",
      "Skills",
      "Causes",
      "Total Hours",
      "Completed Opportunities",
      "Average Rating",
      "Joined At"
    ]

    rows =
      Enum.map(volunteers, fn vol ->
        vol = Repo.preload(vol, :user)

        [
          vol.id,
          "#{vol.user.first_name} #{vol.user.last_name}",
          vol.user.email,
          vol.city,
          vol.state,
          Enum.join(vol.skills || [], "; "),
          Enum.join(vol.causes || [], "; "),
          vol.total_hours,
          vol.completed_opportunities,
          vol.average_rating,
          vol.inserted_at
        ]
      end)

    {:ok, generate_csv([headers | rows])}
  end

  @doc """
  Exports applications to CSV.
  """
  def export_applications_csv(filters \\ %{}) do
    applications = Opportunities.list_applications(filters)

    headers = [
      "ID",
      "Volunteer",
      "Opportunity",
      "Status",
      "Applied At",
      "Reviewed At",
      "Hours Completed",
      "Completed At"
    ]

    rows =
      Enum.map(applications, fn app ->
        app = Repo.preload(app, [volunteer: :user, opportunity: :ngo])

        [
          app.id,
          "#{app.volunteer.user.first_name} #{app.volunteer.user.last_name}",
          app.opportunity.title,
          app.status,
          app.applied_at,
          app.reviewed_at,
          app.volunteer_hours,
          app.completed_at
        ]
      end)

    {:ok, generate_csv([headers | rows])}
  end

  @doc """
  Exports volunteer impact report.
  """
  def export_volunteer_impact_report(volunteer_id) do
    volunteer = Volunteers.get_volunteer!(volunteer_id)
    volunteer = Repo.preload(volunteer, [:user, applications: [opportunity: :ngo]])

    stats = VolunteerMatch.Analytics.get_volunteer_stats(volunteer_id)

    report = """
    VOLUNTEER IMPACT REPORT
    =======================

    Volunteer Information:
    - Name: #{volunteer.user.first_name} #{volunteer.user.last_name}
    - Email: #{volunteer.user.email}
    - Location: #{volunteer.city}, #{volunteer.state}
    - Member Since: #{volunteer.inserted_at}

    Impact Summary:
    - Total Volunteer Hours: #{volunteer.total_hours}
    - Opportunities Completed: #{volunteer.completed_opportunities}
    - Average Rating: #{volunteer.average_rating}
    - Impact Score: #{stats.impact_score}
    - Badges Earned: #{stats.badges_earned}
    - Achievements Unlocked: #{stats.achievements_unlocked}

    Causes Contributed To:
    #{Enum.map_join(stats.causes_contributed, "\n", &"- #{&1}")}

    Skills:
    #{Enum.map_join(volunteer.skills || [], "\n", &"- #{&1}")}

    Recent Activities:
    #{format_recent_applications(volunteer.applications)}

    Generated: #{DateTime.utc_now()}
    """

    {:ok, report}
  end

  @doc """
  Exports NGO report.
  """
  def export_ngo_report(ngo_id) do
    ngo = NGOs.get_ngo!(ngo_id)
    ngo = Repo.preload(ngo, [:user, :opportunities])

    stats = VolunteerMatch.Analytics.get_ngo_stats(ngo_id)

    report = """
    NGO IMPACT REPORT
    =================

    Organization Information:
    - Name: #{ngo.name}
    - Mission: #{ngo.mission}
    - Location: #{ngo.city}, #{ngo.state}
    - Verified: #{if ngo.is_verified, do: "Yes", else: "No"}
    - Member Since: #{ngo.inserted_at}

    Impact Summary:
    - Total Volunteers: #{ngo.total_volunteers}
    - Total Opportunities Created: #{stats.total_opportunities}
    - Active Opportunities: #{ngo.active_opportunities}
    - Completed Opportunities: #{stats.completed_opportunities}
    - Total Volunteer Hours Contributed: #{stats.total_volunteer_hours}
    - Average Rating: #{ngo.average_rating}
    - Volunteer Retention Rate: #{stats.volunteer_retention_rate}%

    Top Causes:
    #{Enum.map_join(stats.top_causes, "\n", fn %{cause: c, count: n} -> "- #{c}: #{n} opportunities" end)}

    Recent Performance:
    - Monthly Volunteers: #{stats.monthly_volunteers}
    - Pending Applications: #{stats.pending_applications}

    Generated: #{DateTime.utc_now()}
    """

    {:ok, report}
  end

  # Private helpers

  defp generate_csv(rows) do
    rows
    |> Enum.map(fn row ->
      row
      |> Enum.map(&format_csv_field/1)
      |> Enum.join(",")
    end)
    |> Enum.join("\n")
  end

  defp format_csv_field(value) when is_binary(value) do
    escaped = String.replace(value, "\"", "\"\"")
    "\"#{escaped}\""
  end

  defp format_csv_field(value) when is_nil(value), do: ""
  defp format_csv_field(value), do: "\"#{value}\""

  defp format_recent_applications(applications) do
    applications
    |> Enum.take(5)
    |> Enum.map(fn app ->
      "- #{app.opportunity.title} (#{app.opportunity.ngo.name}) - #{app.status} - #{app.applied_at}"
    end)
    |> Enum.join("\n")
  end
end
