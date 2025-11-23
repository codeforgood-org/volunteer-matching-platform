defmodule VolunteerMatch.Gamification do
  @moduledoc """
  The Gamification context manages badges, achievements, and leaderboards.
  """

  import Ecto.Query
  alias VolunteerMatch.Repo
  alias VolunteerMatch.Gamification.{Badge, UserBadge, Achievement, UserAchievement}
  alias VolunteerMatch.Notifications

  # Badge Management

  def award_badge(user_id, badge_id) do
    %UserBadge{}
    |> UserBadge.changeset(%{user_id: user_id, badge_id: badge_id})
    |> Repo.insert()
    |> case do
      {:ok, user_badge} ->
        badge = get_badge(badge_id)
        Notifications.create_notification(%{
          user_id: user_id,
          type: :badge_earned,
          title: "New Badge Earned! 🏅",
          message: "You earned the '#{badge.name}' badge!",
          action_url: "/profile/badges",
          metadata: %{badge_id: badge_id}
        })
        {:ok, user_badge}

      error ->
        error
    end
  end

  def list_user_badges(user_id) do
    from(ub in UserBadge,
      where: ub.user_id == ^user_id,
      preload: [:badge],
      order_by: [desc: ub.earned_at]
    )
    |> Repo.all()
  end

  def get_badge(id), do: Repo.get(Badge, id)

  # Achievement Management

  def update_achievement_progress(user_id, achievement_id, progress) do
    user_achievement =
      Repo.get_by(UserAchievement, user_id: user_id, achievement_id: achievement_id) ||
        %UserAchievement{user_id: user_id, achievement_id: achievement_id}

    achievement = get_achievement(achievement_id)

    changeset = UserAchievement.changeset(user_achievement, %{progress: progress})

    changeset =
      if progress >= achievement.progress_max and is_nil(user_achievement.unlocked_at) do
        UserAchievement.unlock_changeset(changeset)
      else
        changeset
      end

    case Repo.insert_or_update(changeset) do
      {:ok, ua} when not is_nil(ua.unlocked_at) ->
        Notifications.notify_achievement_unlocked(user_id, achievement)
        {:ok, ua}

      result ->
        result
    end
  end

  def list_user_achievements(user_id) do
    from(ua in UserAchievement,
      where: ua.user_id == ^user_id,
      preload: [:achievement],
      order_by: [desc: ua.unlocked_at]
    )
    |> Repo.all()
  end

  def get_achievement(id), do: Repo.get(Achievement, id)

  # Leaderboard

  def get_leaderboard(type \\ :top_volunteers, limit \\ 10) do
    case type do
      :top_volunteers ->
        top_volunteers_leaderboard(limit)

      :most_hours ->
        most_hours_leaderboard(limit)

      :top_ngos ->
        top_ngos_leaderboard(limit)

      :recent_activity ->
        recent_activity_leaderboard(limit)
    end
  end

  defp top_volunteers_leaderboard(limit) do
    from(v in VolunteerMatch.Volunteers.Volunteer,
      join: u in assoc(v, :user),
      where: v.is_active == true,
      order_by: [desc: v.completed_opportunities, desc: v.total_hours],
      limit: ^limit,
      select: %{
        user_id: u.id,
        name: fragment("? || ' ' || ?", u.first_name, u.last_name),
        avatar_url: u.avatar_url,
        score: v.completed_opportunities,
        total_hours: v.total_hours,
        average_rating: v.average_rating
      }
    )
    |> Repo.all()
  end

  defp most_hours_leaderboard(limit) do
    from(v in VolunteerMatch.Volunteers.Volunteer,
      join: u in assoc(v, :user),
      where: v.is_active == true,
      order_by: [desc: v.total_hours],
      limit: ^limit,
      select: %{
        user_id: u.id,
        name: fragment("? || ' ' || ?", u.first_name, u.last_name),
        avatar_url: u.avatar_url,
        score: v.total_hours,
        completed_opportunities: v.completed_opportunities,
        average_rating: v.average_rating
      }
    )
    |> Repo.all()
  end

  defp top_ngos_leaderboard(limit) do
    from(n in VolunteerMatch.NGOs.NGO,
      join: u in assoc(n, :user),
      where: n.is_active == true,
      order_by: [desc: n.total_volunteers, desc: n.active_opportunities],
      limit: ^limit,
      select: %{
        user_id: u.id,
        name: n.name,
        logo_url: n.logo_url,
        score: n.total_volunteers,
        active_opportunities: n.active_opportunities,
        average_rating: n.average_rating
      }
    )
    |> Repo.all()
  end

  defp recent_activity_leaderboard(limit) do
    one_month_ago = DateTime.add(DateTime.utc_now(), -30, :day)

    from(a in VolunteerMatch.Opportunities.Application,
      join: v in assoc(a, :volunteer),
      join: u in assoc(v, :user),
      where: a.status == :completed,
      where: a.completed_at >= ^one_month_ago,
      group_by: [u.id, u.first_name, u.last_name, u.avatar_url],
      order_by: [desc: count(a.id)],
      limit: ^limit,
      select: %{
        user_id: u.id,
        name: fragment("? || ' ' || ?", u.first_name, u.last_name),
        avatar_url: u.avatar_url,
        score: count(a.id),
        period: "Last 30 days"
      }
    )
    |> Repo.all()
  end

  # Auto-award badges based on criteria

  def check_and_award_badges(user_id) do
    volunteer = VolunteerMatch.Volunteers.get_volunteer_by_user_id(user_id)

    if volunteer do
      check_hours_badges(user_id, volunteer)
      check_opportunity_badges(user_id, volunteer)
      check_rating_badges(user_id, volunteer)
    end
  end

  defp check_hours_badges(user_id, volunteer) do
    cond do
      volunteer.total_hours >= 500 ->
        award_badge_if_not_exists(user_id, "500_hours_hero")

      volunteer.total_hours >= 250 ->
        award_badge_if_not_exists(user_id, "250_hours_champion")

      volunteer.total_hours >= 100 ->
        award_badge_if_not_exists(user_id, "100_hours_veteran")

      volunteer.total_hours >= 50 ->
        award_badge_if_not_exists(user_id, "50_hours_committed")

      volunteer.total_hours >= 10 ->
        award_badge_if_not_exists(user_id, "10_hours_starter")

      true ->
        :ok
    end
  end

  defp check_opportunity_badges(user_id, volunteer) do
    cond do
      volunteer.completed_opportunities >= 50 ->
        award_badge_if_not_exists(user_id, "50_opportunities_legend")

      volunteer.completed_opportunities >= 25 ->
        award_badge_if_not_exists(user_id, "25_opportunities_expert")

      volunteer.completed_opportunities >= 10 ->
        award_badge_if_not_exists(user_id, "10_opportunities_regular")

      volunteer.completed_opportunities >= 5 ->
        award_badge_if_not_exists(user_id, "5_opportunities_active")

      volunteer.completed_opportunities >= 1 ->
        award_badge_if_not_exists(user_id, "first_opportunity")

      true ->
        :ok
    end
  end

  defp check_rating_badges(user_id, volunteer) do
    if Decimal.compare(volunteer.average_rating, Decimal.new("4.5")) != :lt do
      award_badge_if_not_exists(user_id, "highly_rated")
    end
  end

  defp award_badge_if_not_exists(user_id, badge_identifier) do
    badge = Repo.get_by(Badge, name: badge_identifier)

    if badge do
      existing = Repo.get_by(UserBadge, user_id: user_id, badge_id: badge.id)

      if is_nil(existing) do
        award_badge(user_id, badge.id)
      else
        {:ok, existing}
      end
    end
  end
end
