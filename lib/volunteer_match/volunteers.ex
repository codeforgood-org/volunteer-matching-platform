defmodule VolunteerMatch.Volunteers do
  @moduledoc """
  The Volunteers context manages volunteer profiles and related operations.
  """

  import Ecto.Query, warn: false
  import Geo.PostGIS

  alias VolunteerMatch.Repo
  alias VolunteerMatch.Volunteers.Volunteer
  alias VolunteerMatch.Accounts.User

  @doc """
  Gets a volunteer by ID.
  """
  def get_volunteer(id), do: Repo.get(Volunteer, id)

  @doc """
  Gets a volunteer by user ID.
  """
  def get_volunteer_by_user_id(user_id) do
    Repo.get_by(Volunteer, user_id: user_id)
  end

  @doc """
  Gets a volunteer with preloaded associations.
  """
  def get_volunteer!(id) do
    Volunteer
    |> Repo.get!(id)
    |> Repo.preload([:user, :applications, :matches])
  end

  @doc """
  Creates a volunteer profile.
  """
  def create_volunteer(attrs \\ %{}) do
    %Volunteer{}
    |> Volunteer.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a volunteer profile.
  """
  def update_volunteer(%Volunteer{} = volunteer, attrs) do
    volunteer
    |> Volunteer.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates volunteer statistics.
  """
  def update_volunteer_stats(%Volunteer{} = volunteer, attrs) do
    volunteer
    |> Volunteer.update_stats_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a volunteer.
  """
  def delete_volunteer(%Volunteer{} = volunteer) do
    Repo.delete(volunteer)
  end

  @doc """
  Lists volunteers with optional filters.
  """
  def list_volunteers(params \\ %{}) do
    Volunteer
    |> apply_volunteer_filters(params)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  defp apply_volunteer_filters(query, params) do
    Enum.reduce(params, query, fn
      {:causes, causes}, query when is_list(causes) ->
        where(query, [v], fragment("? && ?", v.causes, ^causes))

      {:skills, skills}, query when is_list(skills) ->
        where(query, [v], fragment("? && ?", v.skills, ^skills))

      {:city, city}, query ->
        where(query, [v], v.city == ^city)

      {:state, state}, query ->
        where(query, [v], v.state == ^state)

      {:is_active, is_active}, query ->
        where(query, [v], v.is_active == ^is_active)

      {:experience_level, level}, query ->
        where(query, [v], v.experience_level == ^level)

      {:near, {lat, lng, distance_km}}, query ->
        point = %Geo.Point{coordinates: {lng, lat}, srid: 4326}
        where(query, [v], st_dwithin_in_meters(v.location, ^point, ^(distance_km * 1000)))

      _, query ->
        query
    end)
  end

  @doc """
  Searches volunteers near a location.
  """
  def search_volunteers_near(latitude, longitude, radius_km, filters \\ %{}) do
    point = %Geo.Point{coordinates: {longitude, latitude}, srid: 4326}

    Volunteer
    |> where([v], v.is_active == true)
    |> where([v], not is_nil(v.location))
    |> where([v], st_dwithin_in_meters(v.location, ^point, ^(radius_km * 1000)))
    |> select([v], %{
      volunteer: v,
      distance: st_distance_in_meters(v.location, ^point) / 1000.0
    })
    |> apply_volunteer_filters(filters)
    |> order_by([v], asc: st_distance(v.location, ^point))
    |> Repo.all()
    |> Repo.preload(volunteer: :user)
  end

  @doc """
  Calculates and updates average rating for a volunteer.
  """
  def recalculate_volunteer_rating(volunteer_id) do
    avg_rating =
      from(r in VolunteerMatch.Reviews.Review,
        where: r.reviewee_id == ^volunteer_id,
        select: avg(r.rating)
      )
      |> Repo.one()
      |> Decimal.new()

    volunteer = get_volunteer(volunteer_id)
    update_volunteer_stats(volunteer, %{average_rating: avg_rating})
  end

  @doc """
  Increments completed opportunities count.
  """
  def increment_completed_opportunities(%Volunteer{} = volunteer, hours) do
    new_completed = volunteer.completed_opportunities + 1
    new_hours = volunteer.total_hours + hours

    update_volunteer_stats(volunteer, %{
      completed_opportunities: new_completed,
      total_hours: new_hours
    })
  end
end
