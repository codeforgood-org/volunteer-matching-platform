defmodule VolunteerMatch.Reviews do
  @moduledoc """
  The Reviews context manages reviews and ratings.
  """

  import Ecto.Query, warn: false
  alias VolunteerMatch.Repo
  alias VolunteerMatch.Reviews.Review

  @doc """
  Gets a review by ID.
  """
  def get_review(id), do: Repo.get(Review, id)

  @doc """
  Creates a review.
  """
  def create_review(attrs \\ %{}) do
    %Review{}
    |> Review.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a review.
  """
  def update_review(%Review{} = review, attrs) do
    review
    |> Review.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a review.
  """
  def delete_review(%Review{} = review) do
    Repo.delete(review)
  end

  @doc """
  Increments helpfulness count.
  """
  def increment_helpfulness(%Review{} = review) do
    review
    |> Review.increment_helpfulness_changeset()
    |> Repo.update()
  end

  @doc """
  Lists reviews for a user (received).
  """
  def list_user_reviews(user_id, opts \\ []) do
    is_public = Keyword.get(opts, :is_public, true)
    limit = Keyword.get(opts, :limit, 50)

    from(r in Review,
      where: r.reviewee_id == ^user_id and r.is_public == ^is_public,
      order_by: [desc: r.inserted_at],
      limit: ^limit,
      preload: [:reviewer, :reviewee, :opportunity]
    )
    |> Repo.all()
  end

  @doc """
  Lists reviews written by a user.
  """
  def list_reviews_by_user(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    from(r in Review,
      where: r.reviewer_id == ^user_id,
      order_by: [desc: r.inserted_at],
      limit: ^limit,
      preload: [:reviewer, :reviewee, :opportunity]
    )
    |> Repo.all()
  end

  @doc """
  Calculates average rating for a user.
  """
  def calculate_average_rating(user_id) do
    from(r in Review,
      where: r.reviewee_id == ^user_id,
      select: avg(r.rating)
    )
    |> Repo.one()
    |> case do
      nil -> Decimal.new("0.0")
      avg -> Decimal.new(avg)
    end
  end

  @doc """
  Gets rating distribution for a user.
  """
  def get_rating_distribution(user_id) do
    from(r in Review,
      where: r.reviewee_id == ^user_id,
      group_by: r.rating,
      select: {r.rating, count(r.id)}
    )
    |> Repo.all()
    |> Map.new()
  end
end
