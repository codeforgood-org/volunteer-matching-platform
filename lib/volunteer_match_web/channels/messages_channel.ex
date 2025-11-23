defmodule VolunteerMatchWeb.MessagesChannel do
  use VolunteerMatchWeb, :channel

  alias VolunteerMatch.Messages
  alias VolunteerMatchWeb.Presence

  @impl true
  def join("messages:" <> user_id, _payload, socket) do
    if authorized?(socket, user_id) do
      send(self(), :after_join)
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(socket, socket.assigns.current_user.id, %{
      online_at: inspect(System.system_time(:second))
    })

    push(socket, "presence_state", Presence.list(socket))
    {:noreply, socket}
  end

  @impl true
  def handle_in("new_message", %{"recipient_id" => recipient_id, "body" => body} = payload, socket) do
    user = socket.assigns.current_user

    message_params = %{
      sender_id: user.id,
      recipient_id: recipient_id,
      body: body,
      subject: Map.get(payload, "subject"),
      message_type: :direct
    }

    case Messages.create_message(message_params) do
      {:ok, message} ->
        broadcast!(socket, "new_message", %{
          id: message.id,
          sender_id: message.sender_id,
          recipient_id: message.recipient_id,
          body: message.body,
          inserted_at: message.inserted_at
        })

        {:reply, {:ok, %{message_id: message.id}}, socket}

      {:error, _changeset} ->
        {:reply, {:error, %{reason: "failed to send message"}}, socket}
    end
  end

  @impl true
  def handle_in("typing", _payload, socket) do
    broadcast_from!(socket, "typing", %{
      user_id: socket.assigns.current_user.id
    })

    {:noreply, socket}
  end

  defp authorized?(socket, user_id) do
    socket.assigns.current_user.id == user_id
  end
end
