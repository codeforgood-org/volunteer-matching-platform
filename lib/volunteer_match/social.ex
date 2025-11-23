defmodule VolunteerMatch.Social do
  @moduledoc """
  The Social context manages following, activity feeds, and social interactions.
  """

  import Ecto.Query
  alias VolunteerMatch.Repo
  alias VolunteerMatch.Social.{Follower, Activity}

  # Following System

  def follow(follower_id, following_id) do
    %Follower{}
    |> Follower.changeset(%{follower_id: follower_id, following_id: following_id})
    |> Repo.insert()
    |> case do
      {:ok, follower} ->
        create_activity(%{
          user_id: follower_id,
          type: :followed_user,
          description: "started following a user",
          related_user_id: following_id
        })
        {:ok, follower}

      error ->
        error
    end
  end

  def unfollow(follower_id, following_id) do
    from(f in Follower,
      where: f.follower_id == ^follower_id and f.following_id == ^following_id
    )
    |> Repo.delete_all()
  end

  def is_following?(follower_id, following_id) do
    Repo.exists?(
      from f in Follower,
        where: f.follower_id == ^follower_id and f.following_id == ^following_id
    )
  end

  def list_followers(user_id) do
    from(f in Follower,
      where: f.following_id == ^user_id,
      preload: [follower: :volunteer],
      order_by: [desc: f.inserted_at]
    )
    |> Repo.all()
    |> Enum.map(& &1.follower)
  end

  def list_following(user_id) do
    from(f in Follower,
      where: f.follower_id == ^user_id,
      preload: [following: :volunteer],
      order_by: [desc: f.inserted_at]
    )
    |> Repo.all()
    |> Enum.map(& &1.following)
  end

  def follower_count(user_id) do
    from(f in Follower,
      where: f.following_id == ^user_id,
      select: count(f.id)
    )
    |> Repo.one()
  end

  def following_count(user_id) do
    from(f in Follower,
      where: f.follower_id == ^user_id,
      select: count(f.id)
    )
    |> Repo.one()
  end

  # Activity Feed

  def create_activity(attrs) do
    %Activity{}
    |> Activity.changeset(attrs)
    |> Repo.insert()
  end

  def get_activity_feed(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    # Get activities from users you follow
    following_ids =
      from(f in Follower, where: f.follower_id == ^user_id, select: f.following_id)
      |> Repo.all()

    # Include user's own activities
    all_user_ids = [user_id | following_ids]

    from(a in Activity,
      where: a.user_id in ^all_user_ids,
      order_by: [desc: a.inserted_at],
      limit: ^limit,
      preload: [:user, :related_opportunity, :related_user]
    )
    |> Repo.all()
  end

  def get_user_activities(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)

    from(a in Activity,
      where: a.user_id == ^user_id,
      order_by: [desc: a.inserted_at],
      limit: ^limit,
      preload: [:related_opportunity, :related_user]
    )
    |> Repo.all()
  end

  # Activity Creation Helpers

  def log_opportunity_created(user_id, opportunity) do
    create_activity(%{
      user_id: user_id,
      type: :opportunity_created,
      description: "created a new volunteer opportunity: #{opportunity.title}",
      related_opportunity_id: opportunity.id
    })
  end

  def log_application_submitted(user_id, application) do
    application = Repo.preload(application, :opportunity)

    create_activity(%{
      user_id: user_id,
      type: :application_submitted,
      description: "applied to volunteer for: #{application.opportunity.title}",
      related_opportunity_id: application.opportunity_id
    })
  end

  def log_application_accepted(user_id, application) do
    application = Repo.preload(application, :opportunity)

    create_activity(%{
      user_id: user_id,
      type: :application_accepted,
      description: "was accepted to volunteer for: #{application.opportunity.title}",
      related_opportunity_id: application.opportunity_id,
      metadata: %{application_id: application.id}
    })
  end

  def log_opportunity_completed(user_id, application) do
    application = Repo.preload(application, :opportunity)

    create_activity(%{
      user_id: user_id,
      type: :opportunity_completed,
      description: "completed volunteering for: #{application.opportunity.title}",
      related_opportunity_id: application.opportunity_id,
      metadata: %{hours: application.volunteer_hours}
    })
  end

  def log_badge_earned(user_id, badge) do
    create_activity(%{
      user_id: user_id,
      type: :badge_earned,
      description: "earned the '#{badge.name}' badge!",
      metadata: %{badge_id: badge.id, badge_name: badge.name}
    })
  end

  def log_milestone_reached(user_id, milestone_type, value) do
    description =
      case milestone_type do
        :hours -> "reached #{value} volunteer hours!"
        :opportunities -> "completed #{value} volunteer opportunities!"
        :rating -> "achieved a #{value} star rating!"
        _ -> "reached a new milestone!"
      end

    create_activity(%{
      user_id: user_id,
      type: :milestone_reached,
      description: description,
      metadata: %{milestone_type: milestone_type, value: value}
    })
  end
end
