defmodule VolunteerMatch.Messages do
  @moduledoc """
  The Messages context manages direct messaging between users.
  """

  import Ecto.Query, warn: false
  alias VolunteerMatch.Repo
  alias VolunteerMatch.Messages.Message

  @doc """
  Gets a message by ID.
  """
  def get_message(id), do: Repo.get(Message, id)

  @doc """
  Creates a message.
  """
  def create_message(attrs \\ %{}) do
    %Message{}
    |> Message.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Marks a message as read.
  """
  def mark_as_read(%Message{} = message) do
    message
    |> Message.mark_as_read_changeset()
    |> Repo.update()
  end

  @doc """
  Lists messages for a user (sent or received).
  """
  def list_user_messages(user_id, opts \\ []) do
    type = Keyword.get(opts, :type, :all)
    limit = Keyword.get(opts, :limit, 50)

    query =
      case type do
        :sent ->
          from m in Message,
            where: m.sender_id == ^user_id

        :received ->
          from m in Message,
            where: m.recipient_id == ^user_id

        :all ->
          from m in Message,
            where: m.sender_id == ^user_id or m.recipient_id == ^user_id
      end

    query
    |> order_by([m], desc: m.inserted_at)
    |> limit(^limit)
    |> preload([:sender, :recipient, :opportunity, :application])
    |> Repo.all()
  end

  @doc """
  Lists conversation between two users.
  """
  def list_conversation(user_id_1, user_id_2, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)

    from(m in Message,
      where:
        (m.sender_id == ^user_id_1 and m.recipient_id == ^user_id_2) or
          (m.sender_id == ^user_id_2 and m.recipient_id == ^user_id_1),
      order_by: [asc: m.inserted_at],
      limit: ^limit,
      preload: [:sender, :recipient]
    )
    |> Repo.all()
  end

  @doc """
  Gets unread message count for a user.
  """
  def unread_count(user_id) do
    from(m in Message,
      where: m.recipient_id == ^user_id and m.is_read == false,
      select: count(m.id)
    )
    |> Repo.one()
  end

  @doc """
  Marks all messages as read for a recipient.
  """
  def mark_all_as_read(recipient_id) do
    from(m in Message,
      where: m.recipient_id == ^recipient_id and m.is_read == false
    )
    |> Repo.update_all(set: [is_read: true, read_at: DateTime.utc_now() |> DateTime.truncate(:second)])
  end

  @doc """
  Deletes a message.
  """
  def delete_message(%Message{} = message) do
    Repo.delete(message)
  end
end
