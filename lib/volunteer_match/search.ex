defmodule VolunteerMatch.Search do
  @moduledoc """
  The Search context provides advanced full-text search functionality.
  """

  import Ecto.Query
  alias VolunteerMatch.{Repo, Opportunities.Opportunity, NGOs.NGO, Volunteers.Volunteer}

  @doc """
  Searches opportunities using full-text search and trigram similarity.

  Options:
  - query: Search term
  - location: Filter by location
  - cause: Filter by cause
  - min_similarity: Minimum similarity score (0.0 to 1.0, default 0.3)
  - limit: Maximum results (default 20)
  """
  def search_opportunities(opts \\\\ []) do
    query = opts[:query] || ""
    min_similarity = opts[:min_similarity] || 0.3
    limit = opts[:limit] || 20

    base_query = from(o in Opportunity, as: :opportunity)

    base_query
    |> apply_opportunity_search(query, min_similarity)
    |> apply_location_filter(opts[:location])
    |> apply_cause_filter(opts[:cause])
    |> apply_status_filter(opts[:status] || :active)
    |> order_by_relevance(query)
    |> limit(^limit)
    |> preload(:ngo)
    |> Repo.all()
  end

  @doc """
  Searches NGOs using full-text search.
  """
  def search_ngos(opts \\\\ []) do
    query = opts[:query] || ""
    min_similarity = opts[:min_similarity] || 0.3
    limit = opts[:limit] || 20

    base_query = from(n in NGO, as: :ngo)

    base_query
    |> apply_ngo_search(query, min_similarity)
    |> apply_location_filter(opts[:location])
    |> apply_verification_filter(opts[:verified])
    |> order_by([n], desc: fragment("similarity(?, ?) + similarity(?, ?)",
         n.name, ^query, n.mission, ^query))
    |> limit(^limit)
    |> Repo.all()
  end

  @doc """
  Searches volunteers by skills and causes.
  """
  def search_volunteers(opts \\\\ []) do
    skills = opts[:skills] || []
    causes = opts[:causes] || []
    limit = opts[:limit] || 20

    base_query = from(v in Volunteer, as: :volunteer)

    base_query
    |> apply_skills_filter(skills)
    |> apply_causes_filter(causes)
    |> apply_location_filter(opts[:location])
    |> limit(^limit)
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  Global search across opportunities, NGOs, and volunteers.
  Returns a map with results for each category.
  """
  def global_search(query, opts \\\\ []) do
    limit = opts[:limit] || 10

    %{
      opportunities: search_opportunities([query: query, limit: limit]),
      ngos: search_ngos([query: query, limit: limit]),
      volunteers: []  # Privacy: Don't include volunteers in global search
    }
  end

  @doc """
  Suggests search terms based on partial input.
  """
  def suggest_search_terms(partial, type \\\\ :all, limit \\\\ 10) do
    case type do
      :opportunities ->
        suggest_opportunity_terms(partial, limit)

      :ngos ->
        suggest_ngo_terms(partial, limit)

      :all ->
        suggest_opportunity_terms(partial, limit) ++ suggest_ngo_terms(partial, limit)
        |> Enum.take(limit)
    end
  end

  # Private functions

  defp apply_opportunity_search(query, "", _min_similarity), do: query

  defp apply_opportunity_search(query, search_term, min_similarity) do
    query
    |> where([o],
      fragment(
        "similarity(?, ?) > ? OR similarity(?, ?) > ? OR to_tsvector('english', ? || ' ' || ?) @@ plainto_tsquery('english', ?)",
        o.title, ^search_term, ^min_similarity,
        o.description, ^search_term, ^min_similarity,
        o.title, o.description, ^search_term
      )
    )
  end

  defp apply_ngo_search(query, "", _min_similarity), do: query

  defp apply_ngo_search(query, search_term, min_similarity) do
    query
    |> where([n],
      fragment(
        "similarity(?, ?) > ? OR similarity(?, ?) > ? OR to_tsvector('english', ? || ' ' || ?) @@ plainto_tsquery('english', ?)",
        n.name, ^search_term, ^min_similarity,
        n.mission, ^search_term, ^min_similarity,
        n.name, n.mission, ^search_term
      )
    )
  end

  defp apply_location_filter(query, nil), do: query

  defp apply_location_filter(query, %{city: city, state: state}) do
    query
    |> where([q], q.city == ^city and q.state == ^state)
  end

  defp apply_location_filter(query, %{state: state}) do
    query
    |> where([q], q.state == ^state)
  end

  defp apply_cause_filter(query, nil), do: query

  defp apply_cause_filter(query, cause) do
    query
    |> where([o], ^cause in o.causes)
  end

  defp apply_status_filter(query, status) do
    query
    |> where([o], o.status == ^status)
  end

  defp apply_verification_filter(query, nil), do: query

  defp apply_verification_filter(query, true) do
    query
    |> where([n], n.is_verified == true)
  end

  defp apply_skills_filter(query, []), do: query

  defp apply_skills_filter(query, skills) do
    query
    |> where([v], fragment("? && ?", v.skills, ^skills))
  end

  defp apply_causes_filter(query, []), do: query

  defp apply_causes_filter(query, causes) do
    query
    |> where([v], fragment("? && ?", v.causes, ^causes))
  end

  defp order_by_relevance(query, ""), do: query |> order_by([o], desc: o.inserted_at)

  defp order_by_relevance(query, search_term) do
    query
    |> order_by([o], desc: fragment(
      "similarity(?, ?) + similarity(?, ?) + ts_rank(to_tsvector('english', ? || ' ' || ?), plainto_tsquery('english', ?))",
      o.title, ^search_term,
      o.description, ^search_term,
      o.title, o.description, ^search_term
    ))
  end

  defp suggest_opportunity_terms(partial, limit) do
    from(o in Opportunity,
      select: o.title,
      where: fragment("? % ?", o.title, ^partial),
      order_by: fragment("similarity(?, ?) DESC", o.title, ^partial),
      limit: ^limit,
      distinct: true
    )
    |> Repo.all()
  end

  defp suggest_ngo_terms(partial, limit) do
    from(n in NGO,
      select: n.name,
      where: fragment("? % ?", n.name, ^partial),
      order_by: fragment("similarity(?, ?) DESC", n.name, ^partial),
      limit: ^limit,
      distinct: true
    )
    |> Repo.all()
  end
end
