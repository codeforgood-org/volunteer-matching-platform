defmodule VolunteerMatch.NGOs do
  @moduledoc """
  The NGOs context manages NGO profiles and verification.
  """

  import Ecto.Query, warn: false
  import Geo.PostGIS

  alias VolunteerMatch.Repo
  alias VolunteerMatch.NGOs.NGO

  @doc """
  Gets an NGO by ID.
  """
  def get_ngo(id), do: Repo.get(NGO, id)

  @doc """
  Gets an NGO by user ID.
  """
  def get_ngo_by_user_id(user_id) do
    Repo.get_by(NGO, user_id: user_id)
  end

  @doc """
  Gets an NGO with preloaded associations.
  """
  def get_ngo!(id) do
    NGO
    |> Repo.get!(id)
    |> Repo.preload([:user, :opportunities])
  end

  @doc """
  Creates an NGO profile.
  """
  def create_ngo(attrs \\ %{}) do
    %NGO{}
    |> NGO.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates an NGO profile.
  """
  def update_ngo(%NGO{} = ngo, attrs) do
    ngo
    |> NGO.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates NGO statistics.
  """
  def update_ngo_stats(%NGO{} = ngo, attrs) do
    ngo
    |> NGO.update_stats_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Verifies an NGO.
  """
  def verify_ngo(%NGO{} = ngo, documents \\ []) do
    ngo
    |> NGO.verification_changeset(%{
      is_verified: true,
      verified_at: DateTime.utc_now() |> DateTime.truncate(:second),
      verification_documents: documents
    })
    |> Repo.update()
  end

  @doc """
  Deletes an NGO.
  """
  def delete_ngo(%NGO{} = ngo) do
    Repo.delete(ngo)
  end

  @doc """
  Lists NGOs with optional filters.
  """
  def list_ngos(params \\ %{}) do
    NGO
    |> apply_ngo_filters(params)
    |> Repo.all()
    |> Repo.preload(:user)
  end

  defp apply_ngo_filters(query, params) do
    Enum.reduce(params, query, fn
      {:causes, causes}, query when is_list(causes) ->
        where(query, [n], fragment("? && ?", n.causes, ^causes))

      {:city, city}, query ->
        where(query, [n], n.city == ^city)

      {:state, state}, query ->
        where(query, [n], n.state == ^state)

      {:is_verified, is_verified}, query ->
        where(query, [n], n.is_verified == ^is_verified)

      {:is_active, is_active}, query ->
        where(query, [n], n.is_active == ^is_active)

      {:search, search}, query ->
        search_term = "%#{search}%"
        where(query, [n], ilike(n.name, ^search_term) or ilike(n.description, ^search_term))

      {:near, {lat, lng, distance_km}}, query ->
        point = %Geo.Point{coordinates: {lng, lat}, srid: 4326}
        where(query, [n], st_dwithin_in_meters(n.location, ^point, ^(distance_km * 1000)))

      _, query ->
        query
    end)
  end

  @doc """
  Searches NGOs near a location.
  """
  def search_ngos_near(latitude, longitude, radius_km, filters \\ %{}) do
    point = %Geo.Point{coordinates: {longitude, latitude}, srid: 4326}

    NGO
    |> where([n], n.is_active == true)
    |> where([n], not is_nil(n.location))
    |> where([n], st_dwithin_in_meters(n.location, ^point, ^(radius_km * 1000)))
    |> select([n], %{
      ngo: n,
      distance: st_distance_in_meters(n.location, ^point) / 1000.0
    })
    |> apply_ngo_filters(filters)
    |> order_by([n], asc: st_distance(n.location, ^point))
    |> Repo.all()
    |> Repo.preload(ngo: :user)
  end

  @doc """
  Calculates and updates average rating for an NGO.
  """
  def recalculate_ngo_rating(ngo_id) do
    avg_rating =
      from(r in VolunteerMatch.Reviews.Review,
        where: r.reviewee_id == ^ngo_id,
        select: avg(r.rating)
      )
      |> Repo.one()
      |> Decimal.new()

    ngo = get_ngo(ngo_id)
    update_ngo_stats(ngo, %{average_rating: avg_rating})
  end

  @doc """
  Recalculates active opportunities count.
  """
  def recalculate_active_opportunities(%NGO{} = ngo) do
    count =
      from(o in VolunteerMatch.Opportunities.Opportunity,
        where: o.ngo_id == ^ngo.id and o.status == :published,
        select: count(o.id)
      )
      |> Repo.one()

    update_ngo_stats(ngo, %{active_opportunities: count})
  end
end
