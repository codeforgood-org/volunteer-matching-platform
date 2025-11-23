defmodule VolunteerMatchWeb.UserSocket do
  use Phoenix.Socket

  channel "messages:*", VolunteerMatchWeb.MessagesChannel
  channel "opportunities:*", VolunteerMatchWeb.OpportunitiesChannel
  channel "notifications:*", VolunteerMatchWeb.NotificationsChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    case VolunteerMatch.Guardian.decode_and_verify(token) do
      {:ok, claims} ->
        case VolunteerMatch.Guardian.resource_from_claims(claims) do
          {:ok, user} ->
            {:ok, assign(socket, :current_user, user)}

          {:error, _reason} ->
            :error
        end

      {:error, _reason} ->
        :error
    end
  end

  def connect(_params, _socket, _connect_info), do: :error

  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.current_user.id}"
end
