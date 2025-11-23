defmodule VolunteerMatchWeb.API.AuthController do
  use VolunteerMatchWeb, :controller

  alias VolunteerMatch.{Accounts, Volunteers, NGOs, Guardian}

  action_fallback VolunteerMatchWeb.FallbackController

  def register(conn, %{"user" => user_params}) do
    with {:ok, user} <- Accounts.register_user(user_params),
         {:ok, profile} <- create_profile(user, user_params),
         {:ok, token, _claims} <- Guardian.encode_and_sign(user) do
      conn
      |> put_status(:created)
      |> render(:user, %{user: user, token: token, profile: profile})
    end
  end

  def login(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate(email, password) do
      {:ok, user, token} ->
        profile = get_user_profile(user)
        render(conn, :user, %{user: user, token: token, profile: profile})

      {:error, :invalid_credentials} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid email or password"})
    end
  end

  def logout(conn, _params) do
    token = Guardian.Plug.current_token(conn)

    case Guardian.revoke(token) do
      {:ok, _} ->
        conn
        |> put_status(:ok)
        |> json(%{message: "Successfully logged out"})

      {:error, _} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: "Failed to logout"})
    end
  end

  def refresh(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    old_token = Guardian.Plug.current_token(conn)

    with {:ok, _} <- Guardian.revoke(old_token),
         {:ok, new_token, _claims} <- Guardian.encode_and_sign(user) do
      render(conn, :token, %{token: new_token})
    end
  end

  defp create_profile(%{role: :volunteer} = user, params) do
    volunteer_params =
      params
      |> Map.get("volunteer", %{})
      |> Map.put("user_id", user.id)

    Volunteers.create_volunteer(volunteer_params)
  end

  defp create_profile(%{role: :ngo} = user, params) do
    ngo_params =
      params
      |> Map.get("ngo", %{})
      |> Map.put("user_id", user.id)

    NGOs.create_ngo(ngo_params)
  end

  defp create_profile(_user, _params), do: {:ok, nil}

  defp get_user_profile(%{role: :volunteer} = user) do
    Volunteers.get_volunteer_by_user_id(user.id)
  end

  defp get_user_profile(%{role: :ngo} = user) do
    NGOs.get_ngo_by_user_id(user.id)
  end

  defp get_user_profile(_user), do: nil
end
