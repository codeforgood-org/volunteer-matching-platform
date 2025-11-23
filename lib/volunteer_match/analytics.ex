defmodule VolunteerMatch.Analytics do
  @moduledoc """
  The Analytics context provides insights and statistics for the platform.
  """

  import Ecto.Query
  alias VolunteerMatch.Repo

  @doc """
  Gets platform-wide statistics dashboard data.
  """
  def get_dashboard_stats do
    %{
      total_users: total_users(),
      total_volunteers: total_volunteers(),
      total_ngos: total_ngos(),
      total_opportunities: total_opportunities(),
      total_applications: total_applications(),
      total_volunteer_hours: total_volunteer_hours(),
      active_opportunities: active_opportunities(),
      success_rate: application_success_rate(),
      average_match_score: average_match_score(),
      recent_growth: recent_growth_stats()
    }
  end

  @doc """
  Gets volunteer statistics.
  """
  def get_volunteer_stats(volunteer_id) do
    volunteer = Repo.get!(VolunteerMatch.Volunteers.Volunteer, volunteer_id)

    %{
      total_hours: volunteer.total_hours,
      completed_opportunities: volunteer.completed_opportunities,
      active_applications: active_applications_count(volunteer_id),
      pending_applications: pending_applications_count(volunteer_id),
      average_rating: volunteer.average_rating,
      badges_earned: badges_earned_count(volunteer.user_id),
      achievements_unlocked: achievements_unlocked_count(volunteer.user_id),
      impact_score: calculate_impact_score(volunteer),
      monthly_hours: monthly_hours(volunteer_id),
      causes_contributed: causes_contributed(volunteer_id)
    }
  end

  @doc """
  Gets NGO statistics.
  """
  def get_ngo_stats(ngo_id) do
    ngo = Repo.get!(VolunteerMatch.NGOs.NGO, ngo_id)

    %{
      total_volunteers: ngo.total_volunteers,
      active_opportunities: ngo.active_opportunities,
      total_opportunities: total_ngo_opportunities(ngo_id),
      completed_opportunities: completed_ngo_opportunities(ngo_id),
      pending_applications: pending_ngo_applications(ngo_id),
      average_rating: ngo.average_rating,
      total_volunteer_hours: total_ngo_volunteer_hours(ngo_id),
      volunteer_retention_rate: volunteer_retention_rate(ngo_id),
      monthly_volunteers: monthly_volunteers(ngo_id),
      top_causes: top_causes(ngo_id)
    }
  end

  @doc """
  Gets geographic distribution of volunteers.
  """
  def geographic_distribution do
    from(v in VolunteerMatch.Volunteers.Volunteer,
      where: not is_nil(v.state),
      group_by: v.state,
      select: %{state: v.state, count: count(v.id)}
    )
    |> Repo.all()
  end

  @doc """
  Gets most popular causes.
  """
  def popular_causes(limit \\ 10) do
    # Aggregate causes from opportunities
    from(o in VolunteerMatch.Opportunities.Opportunity,
      where: o.status == :published,
      select: %{causes: o.causes}
    )
    |> Repo.all()
    |> Enum.flat_map(& &1.causes)
    |> Enum.frequencies()
    |> Enum.sort_by(fn {_cause, count} -> count end, :desc)
    |> Enum.take(limit)
    |> Enum.map(fn {cause, count} -> %{cause: cause, count: count} end)
  end

  @doc """
  Gets trends over time.
  """
  def get_trends(period \\ :month) do
    days = case period do
      :week -> 7
      :month -> 30
      :quarter -> 90
      :year -> 365
    end

    start_date = Date.add(Date.utc_today(), -days)

    %{
      new_volunteers: new_volunteers_trend(start_date),
      new_opportunities: new_opportunities_trend(start_date),
      applications_trend: applications_trend(start_date),
      completion_rate: completion_rate_trend(start_date)
    }
  end

  # Private Helper Functions

  defp total_users do
    Repo.aggregate(VolunteerMatch.Accounts.User, :count)
  end

  defp total_volunteers do
    Repo.aggregate(VolunteerMatch.Volunteers.Volunteer, :count)
  end

  defp total_ngos do
    Repo.aggregate(VolunteerMatch.NGOs.NGO, :count)
  end

  defp total_opportunities do
    Repo.aggregate(VolunteerMatch.Opportunities.Opportunity, :count)
  end

  defp total_applications do
    Repo.aggregate(VolunteerMatch.Opportunities.Application, :count)
  end

  defp total_volunteer_hours do
    from(v in VolunteerMatch.Volunteers.Volunteer, select: sum(v.total_hours))
    |> Repo.one()
    |> Kernel.||(0)
  end

  defp active_opportunities do
    from(o in VolunteerMatch.Opportunities.Opportunity,
      where: o.status == :published,
      select: count(o.id)
    )
    |> Repo.one()
  end

  defp application_success_rate do
    total = Repo.aggregate(VolunteerMatch.Opportunities.Application, :count)

    accepted =
      from(a in VolunteerMatch.Opportunities.Application,
        where: a.status in [:accepted, :completed],
        select: count(a.id)
      )
      |> Repo.one()

    if total > 0, do: Float.round(accepted / total * 100, 2), else: 0.0
  end

  defp average_match_score do
    from(m in VolunteerMatch.Matching.Match,
      select: avg(m.match_score)
    )
    |> Repo.one()
    |> case do
      nil -> 0.0
      score -> Decimal.to_float(score)
    end
  end

  defp recent_growth_stats do
    thirty_days_ago = DateTime.add(DateTime.utc_now(), -30, :day)

    %{
      new_volunteers: new_users_since(thirty_days_ago, :volunteer),
      new_ngos: new_users_since(thirty_days_ago, :ngo),
      new_opportunities: new_opportunities_since(thirty_days_ago)
    }
  end

  defp new_users_since(date, role) do
    from(u in VolunteerMatch.Accounts.User,
      where: u.inserted_at >= ^date and u.role == ^role,
      select: count(u.id)
    )
    |> Repo.one()
  end

  defp new_opportunities_since(date) do
    from(o in VolunteerMatch.Opportunities.Opportunity,
      where: o.inserted_at >= ^date,
      select: count(o.id)
    )
    |> Repo.one()
  end

  defp active_applications_count(volunteer_id) do
    from(a in VolunteerMatch.Opportunities.Application,
      where: a.volunteer_id == ^volunteer_id and a.status in [:pending, :accepted],
      select: count(a.id)
    )
    |> Repo.one()
  end

  defp pending_applications_count(volunteer_id) do
    from(a in VolunteerMatch.Opportunities.Application,
      where: a.volunteer_id == ^volunteer_id and a.status == :pending,
      select: count(a.id)
    )
    |> Repo.one()
  end

  defp badges_earned_count(user_id) do
    from(ub in VolunteerMatch.Gamification.UserBadge,
      where: ub.user_id == ^user_id,
      select: count(ub.id)
    )
    |> Repo.one()
  end

  defp achievements_unlocked_count(user_id) do
    from(ua in VolunteerMatch.Gamification.UserAchievement,
      where: ua.user_id == ^user_id and not is_nil(ua.unlocked_at),
      select: count(ua.id)
    )
    |> Repo.one()
  end

  defp calculate_impact_score(volunteer) do
    # Simple impact score calculation
    hours_score = volunteer.total_hours * 2
    opportunities_score = volunteer.completed_opportunities * 50
    rating_score = Decimal.to_float(volunteer.average_rating) * 100

    round(hours_score + opportunities_score + rating_score)
  end

  defp monthly_hours(volunteer_id) do
    thirty_days_ago = DateTime.add(DateTime.utc_now(), -30, :day)

    from(a in VolunteerMatch.Opportunities.Application,
      where: a.volunteer_id == ^volunteer_id,
      where: a.status == :completed,
      where: a.completed_at >= ^thirty_days_ago,
      select: sum(a.volunteer_hours)
    )
    |> Repo.one()
    |> Kernel.||(0)
  end

  defp causes_contributed(volunteer_id) do
    from(a in VolunteerMatch.Opportunities.Application,
      join: o in assoc(a, :opportunity),
      where: a.volunteer_id == ^volunteer_id,
      where: a.status == :completed,
      select: o.causes
    )
    |> Repo.all()
    |> Enum.flat_map(& &1)
    |> Enum.uniq()
  end

  defp total_ngo_opportunities(ngo_id) do
    from(o in VolunteerMatch.Opportunities.Opportunity,
      where: o.ngo_id == ^ngo_id,
      select: count(o.id)
    )
    |> Repo.one()
  end

  defp completed_ngo_opportunities(ngo_id) do
    from(o in VolunteerMatch.Opportunities.Opportunity,
      where: o.ngo_id == ^ngo_id and o.status == :completed,
      select: count(o.id)
    )
    |> Repo.one()
  end

  defp pending_ngo_applications(ngo_id) do
    from(a in VolunteerMatch.Opportunities.Application,
      join: o in assoc(a, :opportunity),
      where: o.ngo_id == ^ngo_id and a.status == :pending,
      select: count(a.id)
    )
    |> Repo.one()
  end

  defp total_ngo_volunteer_hours(ngo_id) do
    from(a in VolunteerMatch.Opportunities.Application,
      join: o in assoc(a, :opportunity),
      where: o.ngo_id == ^ngo_id and a.status == :completed,
      select: sum(a.volunteer_hours)
    )
    |> Repo.one()
    |> Kernel.||(0)
  end

  defp volunteer_retention_rate(ngo_id) do
    # Volunteers who completed multiple opportunities
    repeat_volunteers =
      from(a in VolunteerMatch.Opportunities.Application,
        join: o in assoc(a, :opportunity),
        where: o.ngo_id == ^ngo_id and a.status == :completed,
        group_by: a.volunteer_id,
        having: count(a.id) > 1,
        select: count(a.volunteer_id)
      )
      |> Repo.one()
      |> Kernel.||(0)

    total_volunteers =
      from(a in VolunteerMatch.Opportunities.Application,
        join: o in assoc(a, :opportunity),
        where: o.ngo_id == ^ngo_id and a.status == :completed,
        select: count(fragment("DISTINCT ?", a.volunteer_id))
      )
      |> Repo.one()
      |> Kernel.||(0)

    if total_volunteers > 0 do
      Float.round(repeat_volunteers / total_volunteers * 100, 2)
    else
      0.0
    end
  end

  defp monthly_volunteers(ngo_id) do
    thirty_days_ago = DateTime.add(DateTime.utc_now(), -30, :day)

    from(a in VolunteerMatch.Opportunities.Application,
      join: o in assoc(a, :opportunity),
      where: o.ngo_id == ^ngo_id,
      where: a.status in [:accepted, :completed],
      where: a.inserted_at >= ^thirty_days_ago,
      select: count(fragment("DISTINCT ?", a.volunteer_id))
    )
    |> Repo.one()
  end

  defp top_causes(ngo_id) do
    from(o in VolunteerMatch.Opportunities.Opportunity,
      where: o.ngo_id == ^ngo_id,
      select: o.causes
    )
    |> Repo.all()
    |> Enum.flat_map(& &1)
    |> Enum.frequencies()
    |> Enum.sort_by(fn {_cause, count} -> count end, :desc)
    |> Enum.take(5)
    |> Enum.map(fn {cause, count} -> %{cause: cause, count: count} end)
  end

  defp new_volunteers_trend(start_date) do
    from(v in VolunteerMatch.Volunteers.Volunteer,
      where: v.inserted_at >= ^start_date,
      group_by: fragment("DATE(?)", v.inserted_at),
      select: %{
        date: fragment("DATE(?)", v.inserted_at),
        count: count(v.id)
      },
      order_by: fragment("DATE(?)", v.inserted_at)
    )
    |> Repo.all()
  end

  defp new_opportunities_trend(start_date) do
    from(o in VolunteerMatch.Opportunities.Opportunity,
      where: o.inserted_at >= ^start_date,
      group_by: fragment("DATE(?)", o.inserted_at),
      select: %{
        date: fragment("DATE(?)", o.inserted_at),
        count: count(o.id)
      },
      order_by: fragment("DATE(?)", o.inserted_at)
    )
    |> Repo.all()
  end

  defp applications_trend(start_date) do
    from(a in VolunteerMatch.Opportunities.Application,
      where: a.inserted_at >= ^start_date,
      group_by: fragment("DATE(?)", a.inserted_at),
      select: %{
        date: fragment("DATE(?)", a.inserted_at),
        count: count(a.id)
      },
      order_by: fragment("DATE(?)", a.inserted_at)
    )
    |> Repo.all()
  end

  defp completion_rate_trend(start_date) do
    from(a in VolunteerMatch.Opportunities.Application,
      where: a.inserted_at >= ^start_date,
      group_by: fragment("DATE(?)", a.inserted_at),
      select: %{
        date: fragment("DATE(?)", a.inserted_at),
        total: count(a.id),
        completed: count(fragment("CASE WHEN ? = 'completed' THEN 1 END", a.status))
      },
      order_by: fragment("DATE(?)", a.inserted_at)
    )
    |> Repo.all()
    |> Enum.map(fn %{date: date, total: total, completed: completed} ->
      rate = if total > 0, do: Float.round(completed / total * 100, 2), else: 0.0
      %{date: date, rate: rate}
    end)
  end
end
