defmodule VolunteerMatch.Opportunities do
  @moduledoc """
  The Opportunities context manages volunteer opportunities and applications.
  """

  import Ecto.Query, warn: false
  import Geo.PostGIS

  alias VolunteerMatch.Repo
  alias VolunteerMatch.Opportunities.{Opportunity, Application}
  alias VolunteerMatch.Volunteers

  @doc """
  Gets an opportunity by ID.
  """
  def get_opportunity(id), do: Repo.get(Opportunity, id)

  @doc """
  Gets an opportunity with preloaded associations.
  """
  def get_opportunity!(id) do
    Opportunity
    |> Repo.get!(id)
    |> Repo.preload([:ngo, :applications, :matches])
  end

  @doc """
  Creates an opportunity.
  """
  def create_opportunity(attrs \\ %{}) do
    %Opportunity{}
    |> Opportunity.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an opportunity.
  """
  def update_opportunity(%Opportunity{} = opportunity, attrs) do
    opportunity
    |> Opportunity.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Publishes an opportunity.
  """
  def publish_opportunity(%Opportunity{} = opportunity) do
    opportunity
    |> Opportunity.publish_changeset()
    |> Repo.update()
  end

  @doc """
  Updates opportunity statistics.
  """
  def update_opportunity_stats(%Opportunity{} = opportunity, attrs) do
    opportunity
    |> Opportunity.update_stats_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Increments view count.
  """
  def increment_view_count(%Opportunity{} = opportunity) do
    update_opportunity_stats(opportunity, %{view_count: opportunity.view_count + 1})
  end

  @doc """
  Deletes an opportunity.
  """
  def delete_opportunity(%Opportunity{} = opportunity) do
    Repo.delete(opportunity)
  end

  @doc """
  Lists opportunities with optional filters.
  """
  def list_opportunities(params \\ %{}) do
    Opportunity
    |> apply_opportunity_filters(params)
    |> Repo.all()
    |> Repo.preload(:ngo)
  end

  defp apply_opportunity_filters(query, params) do
    Enum.reduce(params, query, fn
      {:ngo_id, ngo_id}, query ->
        where(query, [o], o.ngo_id == ^ngo_id)

      {:status, status}, query ->
        where(query, [o], o.status == ^status)

      {:causes, causes}, query when is_list(causes) ->
        where(query, [o], fragment("? && ?", o.causes, ^causes))

      {:skills, skills}, query when is_list(skills) ->
        where(query, [o], fragment("? && ?", o.skills_required, ^skills))

      {:city, city}, query ->
        where(query, [o], o.city == ^city)

      {:state, state}, query ->
        where(query, [o], o.state == ^state)

      {:is_remote, is_remote}, query ->
        where(query, [o], o.is_remote == ^is_remote)

      {:is_virtual, is_virtual}, query ->
        where(query, [o], o.is_virtual == ^is_virtual)

      {:featured, featured}, query ->
        where(query, [o], o.featured == ^featured)

      {:start_date_after, date}, query ->
        where(query, [o], o.start_date >= ^date)

      {:near, {lat, lng, distance_km}}, query ->
        point = %Geo.Point{coordinates: {lng, lat}, srid: 4326}
        where(query, [o], st_dwithin_in_meters(o.location, ^point, ^(distance_km * 1000)))

      {:search, search}, query ->
        search_term = "%#{search}%"
        where(query, [o], ilike(o.title, ^search_term) or ilike(o.description, ^search_term))

      _, query ->
        query
    end)
  end

  @doc """
  Searches opportunities near a location.
  """
  def search_opportunities_near(latitude, longitude, radius_km, filters \\ %{}) do
    point = %Geo.Point{coordinates: {longitude, latitude}, srid: 4326}

    Opportunity
    |> where([o], o.status == :published)
    |> where([o], not is_nil(o.location))
    |> where([o], st_dwithin_in_meters(o.location, ^point, ^(radius_km * 1000)))
    |> select([o], %{
      opportunity: o,
      distance: st_distance_in_meters(o.location, ^point) / 1000.0
    })
    |> apply_opportunity_filters(filters)
    |> order_by([o], asc: st_distance(o.location, ^point))
    |> Repo.all()
    |> Repo.preload(opportunity: :ngo)
  end

  ## Applications

  @doc """
  Gets an application by ID.
  """
  def get_application(id), do: Repo.get(Application, id)

  @doc """
  Creates an application.
  """
  def create_application(attrs \\ %{}) do
    result =
      %Application{}
      |> Application.changeset(attrs)
      |> Repo.insert()

    case result do
      {:ok, application} ->
        opportunity = get_opportunity(application.opportunity_id)
        increment_application_count(opportunity)
        {:ok, application}

      error ->
        error
    end
  end

  @doc """
  Updates an application.
  """
  def update_application(%Application{} = application, attrs) do
    application
    |> Application.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Reviews an application (accept/reject).
  """
  def review_application(%Application{} = application, attrs) do
    result =
      application
      |> Application.review_changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, %Application{status: :accepted} = app} ->
        opportunity = get_opportunity(app.opportunity_id)
        increment_volunteers_registered(opportunity)
        {:ok, app}

      result ->
        result
    end
  end

  @doc """
  Completes an application.
  """
  def complete_application(%Application{} = application, attrs) do
    result =
      application
      |> Application.complete_changeset(attrs)
      |> Repo.update()

    case result do
      {:ok, app} ->
        volunteer = Volunteers.get_volunteer(app.volunteer_id)
        Volunteers.increment_completed_opportunities(volunteer, app.volunteer_hours)
        {:ok, app}

      error ->
        error
    end
  end

  @doc """
  Withdraws an application.
  """
  def withdraw_application(%Application{} = application) do
    application
    |> Application.withdraw_changeset()
    |> Repo.update()
  end

  @doc """
  Lists applications with optional filters.
  """
  def list_applications(params \\ %{}) do
    Application
    |> apply_application_filters(params)
    |> Repo.all()
    |> Repo.preload([:volunteer, :opportunity])
  end

  defp apply_application_filters(query, params) do
    Enum.reduce(params, query, fn
      {:volunteer_id, volunteer_id}, query ->
        where(query, [a], a.volunteer_id == ^volunteer_id)

      {:opportunity_id, opportunity_id}, query ->
        where(query, [a], a.opportunity_id == ^opportunity_id)

      {:status, status}, query ->
        where(query, [a], a.status == ^status)

      _, query ->
        query
    end)
  end

  defp increment_application_count(%Opportunity{} = opportunity) do
    update_opportunity_stats(opportunity, %{
      application_count: opportunity.application_count + 1
    })
  end

  defp increment_volunteers_registered(%Opportunity{} = opportunity) do
    update_opportunity_stats(opportunity, %{
      volunteers_registered: opportunity.volunteers_registered + 1
    })
  end
end
