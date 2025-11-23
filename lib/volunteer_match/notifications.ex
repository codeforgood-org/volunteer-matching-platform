defmodule VolunteerMatch.Notifications do
  @moduledoc """
  The Notifications context manages real-time notifications for users.
  """

  import Ecto.Query
  alias VolunteerMatch.Repo
  alias VolunteerMatch.Notifications.Notification
  alias VolunteerMatchWeb.Endpoint

  @doc """
  Creates a notification and broadcasts it via Phoenix PubSub.
  """
  def create_notification(attrs) do
    %Notification{}
    |> Notification.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, notification} ->
        broadcast_notification(notification)
        {:ok, notification}

      error ->
        error
    end
  end

  @doc """
  Lists notifications for a user.
  """
  def list_user_notifications(user_id, opts \\ []) do
    unread_only = Keyword.get(opts, :unread_only, false)
    limit = Keyword.get(opts, :limit, 50)

    query =
      from n in Notification,
        where: n.user_id == ^user_id,
        order_by: [desc: n.inserted_at],
        limit: ^limit,
        preload: [:related_opportunity, :related_application]

    query =
      if unread_only do
        where(query, [n], n.is_read == false)
      else
        query
      end

    Repo.all(query)
  end

  @doc """
  Gets unread notification count.
  """
  def unread_count(user_id) do
    from(n in Notification,
      where: n.user_id == ^user_id and n.is_read == false,
      select: count(n.id)
    )
    |> Repo.one()
  end

  @doc """
  Marks a notification as read.
  """
  def mark_as_read(%Notification{} = notification) do
    notification
    |> Notification.mark_as_read_changeset()
    |> Repo.update()
  end

  @doc """
  Marks all notifications as read for a user.
  """
  def mark_all_as_read(user_id) do
    from(n in Notification,
      where: n.user_id == ^user_id and n.is_read == false
    )
    |> Repo.update_all(set: [is_read: true, read_at: DateTime.utc_now() |> DateTime.truncate(:second)])
  end

  @doc """
  Deletes a notification.
  """
  def delete_notification(%Notification{} = notification) do
    Repo.delete(notification)
  end

  # Notification Templates

  def notify_new_match(volunteer_id, opportunity, match_score) do
    volunteer = VolunteerMatch.Volunteers.get_volunteer!(volunteer_id)

    create_notification(%{
      user_id: volunteer.user_id,
      type: :new_match,
      title: "New Opportunity Match!",
      message: "We found a #{trunc(match_score)}% match: #{opportunity.title}",
      action_url: "/opportunities/#{opportunity.id}",
      related_opportunity_id: opportunity.id,
      metadata: %{match_score: match_score}
    })
  end

  def notify_application_received(application) do
    application = Repo.preload(application, [:opportunity, volunteer: :user])
    ngo = VolunteerMatch.NGOs.get_ngo_by_user_id(application.opportunity.ngo_id)

    create_notification(%{
      user_id: ngo.user_id,
      type: :application_received,
      title: "New Volunteer Application",
      message: "#{application.volunteer.user.first_name} applied to #{application.opportunity.title}",
      action_url: "/ngo/applications/#{application.id}",
      related_application_id: application.id,
      related_opportunity_id: application.opportunity_id
    })
  end

  def notify_application_accepted(application) do
    application = Repo.preload(application, [:opportunity, volunteer: :user])

    create_notification(%{
      user_id: application.volunteer.user_id,
      type: :application_accepted,
      title: "Application Accepted! 🎉",
      message: "Your application for #{application.opportunity.title} was accepted!",
      action_url: "/volunteer/applications/#{application.id}",
      related_application_id: application.id,
      related_opportunity_id: application.opportunity_id
    })
  end

  def notify_application_rejected(application) do
    application = Repo.preload(application, [:opportunity, volunteer: :user])

    create_notification(%{
      user_id: application.volunteer.user_id,
      type: :application_rejected,
      title: "Application Update",
      message: "Your application for #{application.opportunity.title} was not accepted this time.",
      action_url: "/volunteer/applications/#{application.id}",
      related_application_id: application.id
    })
  end

  def notify_new_message(message) do
    message = Repo.preload(message, [:sender])

    create_notification(%{
      user_id: message.recipient_id,
      type: :new_message,
      title: "New Message",
      message: "#{message.sender.first_name} sent you a message",
      action_url: "/messages/#{message.id}",
      metadata: %{message_id: message.id}
    })
  end

  def notify_review_received(review) do
    review = Repo.preload(review, [:reviewer])

    create_notification(%{
      user_id: review.reviewee_id,
      type: :review_received,
      title: "New Review",
      message: "#{review.reviewer.first_name} left you a #{review.rating}-star review",
      action_url: "/reviews",
      metadata: %{review_id: review.id, rating: review.rating}
    })
  end

  def notify_achievement_unlocked(user_id, achievement) do
    create_notification(%{
      user_id: user_id,
      type: :achievement_unlocked,
      title: "Achievement Unlocked! 🏆",
      message: "You earned the '#{achievement.name}' achievement!",
      action_url: "/profile/achievements",
      metadata: %{achievement_id: achievement.id}
    })
  end

  defp broadcast_notification(notification) do
    Endpoint.broadcast("notifications:#{notification.user_id}", "new_notification", %{
      id: notification.id,
      type: notification.type,
      title: notification.title,
      message: notification.message,
      action_url: notification.action_url,
      inserted_at: notification.inserted_at
    })
  end
end
