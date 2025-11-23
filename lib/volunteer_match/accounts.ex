defmodule VolunteerMatch.Accounts do
  @moduledoc """
  The Accounts context manages user authentication and user data.
  """

  import Ecto.Query, warn: false
  alias VolunteerMatch.Repo
  alias VolunteerMatch.Accounts.User
  alias VolunteerMatch.Guardian

  @doc """
  Gets a user by ID.
  """
  def get_user(id) when is_binary(id) do
    Repo.get(User, id)
  end

  def get_user(_), do: nil

  @doc """
  Gets a user by email.
  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.
  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = get_user_by_email(email)

    if User.valid_password?(user, password) do
      {:ok, user}
    else
      {:error, :invalid_credentials}
    end
  end

  @doc """
  Registers a new user.
  """
  def register_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.
  """
  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates the user password.
  """
  def update_user_password(user, password) do
    user
    |> User.password_changeset(%{password: password})
    |> Repo.update()
  end

  @doc """
  Deletes a user.
  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  @doc """
  Confirms a user account.
  """
  def confirm_user(%User{} = user) do
    user
    |> User.confirm_changeset()
    |> Repo.update()
  end

  @doc """
  Authenticates a user and generates a token.
  """
  def authenticate(email, password) do
    with {:ok, user} <- get_user_by_email_and_password(email, password),
         {:ok, token, _claims} <- Guardian.encode_and_sign(user) do
      update_last_sign_in(user)
      {:ok, user, token}
    end
  end

  defp update_last_sign_in(user) do
    user
    |> Ecto.Changeset.change(last_sign_in_at: DateTime.utc_now() |> DateTime.truncate(:second))
    |> Repo.update()
  end

  @doc """
  Revokes a token.
  """
  def revoke_token(token) do
    Guardian.revoke(token)
  end

  @doc """
  Lists all users with optional filters.
  """
  def list_users(params \\ %{}) do
    User
    |> apply_user_filters(params)
    |> Repo.all()
  end

  defp apply_user_filters(query, params) do
    Enum.reduce(params, query, fn
      {:role, role}, query ->
        where(query, [u], u.role == ^role)

      {:is_active, is_active}, query ->
        where(query, [u], u.is_active == ^is_active)

      {:search, search}, query ->
        search_term = "%#{search}%"
        where(query, [u], ilike(u.email, ^search_term) or
                          ilike(u.first_name, ^search_term) or
                          ilike(u.last_name, ^search_term))

      _, query ->
        query
    end)
  end

  @doc """
  Counts users by role.
  """
  def count_users_by_role do
    User
    |> group_by([u], u.role)
    |> select([u], {u.role, count(u.id)})
    |> Repo.all()
    |> Map.new()
  end

  @doc """
  Preloads associations for a user.
  """
  def preload_user_associations(user, associations \\ [:volunteer, :ngo]) do
    Repo.preload(user, associations)
  end
end
