defmodule VolunteerMatch.Matching do
  @moduledoc """
  The Matching context provides intelligent matching between volunteers and opportunities.
  Uses a weighted scoring algorithm based on location, causes, skills, and time availability.
  """

  import Ecto.Query, warn: false
  import Geo.PostGIS

  alias VolunteerMatch.Repo
  alias VolunteerMatch.Matching.Match
  alias VolunteerMatch.Volunteers.Volunteer
  alias VolunteerMatch.Opportunities.Opportunity

  @location_weight 0.35
  @cause_weight 0.30
  @skill_weight 0.25
  @time_weight 0.10

  @doc """
  Finds matches for a volunteer based on their profile.
  """
  def find_matches_for_volunteer(volunteer_id, opts \\ []) do
    volunteer = Repo.get!(Volunteer, volunteer_id) |> Repo.preload(:user)
    limit = Keyword.get(opts, :limit, 20)
    min_score = Keyword.get(opts, :min_score, 50)

    if volunteer.location do
      opportunities =
        Opportunity
        |> where([o], o.status == :published)
        |> where([o], not is_nil(o.location))
        |> where([o], o.start_date >= ^Date.utc_today())
        |> where([o], st_dwithin_in_meters(o.location, ^volunteer.location, ^(volunteer.max_distance * 1000)))
        |> limit(^(limit * 3))
        |> Repo.all()

      matches =
        opportunities
        |> Enum.map(&calculate_match(volunteer, &1))
        |> Enum.filter(fn match -> match.match_score >= min_score end)
        |> Enum.sort_by(& &1.match_score, :desc)
        |> Enum.take(limit)

      {:ok, matches}
    else
      {:error, :no_location}
    end
  end

  @doc """
  Finds matches for an opportunity.
  """
  def find_matches_for_opportunity(opportunity_id, opts \\ []) do
    opportunity = Repo.get!(Opportunity, opportunity_id) |> Repo.preload(:ngo)
    limit = Keyword.get(opts, :limit, 20)
    min_score = Keyword.get(opts, :min_score, 50)

    if opportunity.location do
      # Use a reasonable search radius (e.g., 50km)
      search_radius = 50_000

      volunteers =
        Volunteer
        |> where([v], v.is_active == true)
        |> where([v], not is_nil(v.location))
        |> where([v], st_dwithin_in_meters(v.location, ^opportunity.location, ^search_radius))
        |> limit(^(limit * 3))
        |> Repo.all()
        |> Repo.preload(:user)

      matches =
        volunteers
        |> Enum.map(&calculate_match(&1, opportunity))
        |> Enum.filter(fn match -> match.match_score >= min_score end)
        |> Enum.sort_by(& &1.match_score, :desc)
        |> Enum.take(limit)

      {:ok, matches}
    else
      {:error, :no_location}
    end
  end

  @doc """
  Calculates match score between a volunteer and opportunity.
  """
  def calculate_match(%Volunteer{} = volunteer, %Opportunity{} = opportunity) do
    location_score = calculate_location_score(volunteer, opportunity)
    cause_score = calculate_cause_score(volunteer, opportunity)
    skill_score = calculate_skill_score(volunteer, opportunity)
    time_score = calculate_time_score(volunteer, opportunity)

    match_score =
      location_score * @location_weight +
      cause_score * @cause_weight +
      skill_score * @skill_weight +
      time_score * @time_weight

    distance_km = calculate_distance(volunteer.location, opportunity.location)

    %{
      volunteer_id: volunteer.id,
      opportunity_id: opportunity.id,
      match_score: Decimal.new(Float.round(match_score, 2)),
      location_score: Decimal.new(Float.round(location_score, 2)),
      cause_score: Decimal.new(Float.round(cause_score, 2)),
      skill_score: Decimal.new(Float.round(skill_score, 2)),
      time_score: Decimal.new(Float.round(time_score, 2)),
      distance_km: Float.round(distance_km, 2),
      status: :suggested,
      metadata: %{
        volunteer_name: "#{volunteer.user.first_name} #{volunteer.user.last_name}",
        opportunity_title: opportunity.title
      }
    }
  end

  defp calculate_location_score(%Volunteer{location: v_loc, max_distance: max_dist}, %Opportunity{location: o_loc}) do
    distance_km = calculate_distance(v_loc, o_loc)

    cond do
      distance_km <= max_dist * 0.25 -> 100.0
      distance_km <= max_dist * 0.5 -> 80.0
      distance_km <= max_dist * 0.75 -> 60.0
      distance_km <= max_dist -> 40.0
      true -> 20.0
    end
  end

  defp calculate_distance(loc1, loc2) do
    query =
      from v in Volunteer,
        select: st_distance_in_meters(^loc1, ^loc2) / 1000.0,
        limit: 1

    Repo.one(query) || 0.0
  end

  defp calculate_cause_score(%Volunteer{causes: v_causes}, %Opportunity{causes: o_causes}) do
    intersection = MapSet.intersection(MapSet.new(v_causes || []), MapSet.new(o_causes || []))
    union = MapSet.union(MapSet.new(v_causes || []), MapSet.new(o_causes || []))

    if MapSet.size(union) > 0 do
      MapSet.size(intersection) / MapSet.size(union) * 100
    else
      0.0
    end
  end

  defp calculate_skill_score(%Volunteer{skills: v_skills}, %Opportunity{skills_required: o_skills}) do
    if Enum.empty?(o_skills || []) do
      100.0
    else
      intersection = MapSet.intersection(MapSet.new(v_skills || []), MapSet.new(o_skills))
      matched = MapSet.size(intersection)
      required = length(o_skills)

      (matched / required) * 100
    end
  end

  defp calculate_time_score(%Volunteer{} = volunteer, %Opportunity{} = opportunity) do
    # Simplified time matching - can be enhanced based on detailed availability
    cond do
      volunteer.hours_per_week && opportunity.duration_hours &&
          volunteer.hours_per_week >= opportunity.duration_hours -> 100.0

      volunteer.hours_per_week && opportunity.duration_hours -> 50.0
      true -> 75.0
    end
  end

  @doc """
  Saves a match to the database.
  """
  def create_match(attrs) do
    %Match{}
    |> Match.changeset(attrs)
    |> Repo.insert(
      on_conflict: {:replace, [:match_score, :location_score, :cause_score, :skill_score, :time_score, :distance_km, :updated_at]},
      conflict_target: [:volunteer_id, :opportunity_id]
    )
  end

  @doc """
  Bulk creates matches for a volunteer.
  """
  def create_matches_for_volunteer(volunteer_id, opts \\ []) do
    case find_matches_for_volunteer(volunteer_id, opts) do
      {:ok, matches} ->
        results = Enum.map(matches, &create_match/1)
        successful = Enum.count(results, fn {status, _} -> status == :ok end)
        {:ok, successful}

      error ->
        error
    end
  end

  @doc """
  Gets matches for a volunteer.
  """
  def list_volunteer_matches(volunteer_id, opts \\ []) do
    status = Keyword.get(opts, :status)
    limit = Keyword.get(opts, :limit, 20)

    query =
      from m in Match,
        where: m.volunteer_id == ^volunteer_id,
        order_by: [desc: m.match_score],
        limit: ^limit,
        preload: [opportunity: :ngo]

    query =
      if status do
        where(query, [m], m.status == ^status)
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Marks a match as viewed.
  """
  def mark_match_viewed(%Match{} = match) do
    match
    |> Match.mark_as_viewed_changeset()
    |> Repo.update()
  end

  @doc """
  Marks a match as dismissed.
  """
  def dismiss_match(%Match{} = match) do
    match
    |> Match.mark_as_dismissed_changeset()
    |> Repo.update()
  end

  @doc """
  Marks a match as applied.
  """
  def mark_match_applied(%Match{} = match) do
    match
    |> Match.mark_as_applied_changeset()
    |> Repo.update()
  end
end
