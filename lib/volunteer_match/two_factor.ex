defmodule VolunteerMatch.TwoFactor do
  @moduledoc """
  The TwoFactor context handles two-factor authentication functionality.
  """

  import Ecto.Query
  alias VolunteerMatch.{Repo, Accounts.User}
  alias NimbleTOTP

  @backup_codes_count 10

  @doc """
  Generates a new 2FA secret for a user.
  Returns the secret and a QR code URI for scanning.
  """
  def generate_secret(user) do
    secret = NimbleTOTP.secret()

    # Generate QR code URI for authenticator apps
    uri = NimbleTOTP.otpauth_uri(
      "VolunteerMatch:#{user.email}",
      secret,
      issuer: "VolunteerMatch"
    )

    {:ok, %{secret: secret, uri: uri}}
  end

  @doc """
  Enables 2FA for a user after verifying the code.
  """
  def enable_two_factor(user, code, secret) do
    if verify_code(secret, code) do
      backup_codes = generate_backup_codes()

      user
      |> Ecto.Changeset.change(%{
        two_factor_enabled: true,
        two_factor_secret: secret,
        two_factor_backup_codes: Enum.map(backup_codes, &hash_backup_code/1),
        two_factor_enabled_at: DateTime.utc_now()
      })
      |> Repo.update()
      |> case do
        {:ok, updated_user} -> {:ok, updated_user, backup_codes}
        error -> error
      end
    else
      {:error, :invalid_code}
    end
  end

  @doc """
  Disables 2FA for a user after verifying their password.
  """
  def disable_two_factor(user) do
    user
    |> Ecto.Changeset.change(%{
      two_factor_enabled: false,
      two_factor_secret: nil,
      two_factor_backup_codes: [],
      two_factor_enabled_at: nil
    })
    |> Repo.update()
  end

  @doc """
  Verifies a 2FA code for a user.
  """
  def verify_user_code(user, code) do
    cond do
      !user.two_factor_enabled ->
        {:ok, :not_enabled}

      verify_code(user.two_factor_secret, code) ->
        {:ok, :valid}

      verify_backup_code(user, code) ->
        remove_used_backup_code(user, code)
        {:ok, :backup_code_used}

      true ->
        {:error, :invalid_code}
    end
  end

  @doc """
  Verifies a TOTP code against a secret.
  """
  def verify_code(secret, code) do
    # Allow 1 time step before and after for clock skew
    NimbleTOTP.valid?(secret, code, since: System.system_time(:second) - 30) ||
    NimbleTOTP.valid?(secret, code) ||
    NimbleTOTP.valid?(secret, code, since: System.system_time(:second) + 30)
  end

  @doc """
  Generates a list of backup codes.
  """
  def generate_backup_codes do
    for _ <- 1..@backup_codes_count do
      :crypto.strong_rand_bytes(4)
      |> Base.encode16(case: :lower)
    end
  end

  @doc """
  Regenerates backup codes for a user.
  """
  def regenerate_backup_codes(user) do
    if user.two_factor_enabled do
      backup_codes = generate_backup_codes()

      user
      |> Ecto.Changeset.change(%{
        two_factor_backup_codes: Enum.map(backup_codes, &hash_backup_code/1)
      })
      |> Repo.update()
      |> case do
        {:ok, updated_user} -> {:ok, updated_user, backup_codes}
        error -> error
      end
    else
      {:error, :two_factor_not_enabled}
    end
  end

  # Private functions

  defp verify_backup_code(user, code) do
    hashed_code = hash_backup_code(code)

    Enum.any?(user.two_factor_backup_codes || [], fn stored_code ->
      Bcrypt.verify_pass(code, stored_code) || stored_code == hashed_code
    end)
  end

  defp remove_used_backup_code(user, code) do
    hashed_code = hash_backup_code(code)

    updated_codes =
      Enum.reject(user.two_factor_backup_codes || [], fn stored_code ->
        Bcrypt.verify_pass(code, stored_code) || stored_code == hashed_code
      end)

    user
    |> Ecto.Changeset.change(%{two_factor_backup_codes: updated_codes})
    |> Repo.update()
  end

  defp hash_backup_code(code) do
    Bcrypt.hash_pwd_salt(code)
  end

  @doc """
  Returns the number of remaining backup codes for a user.
  """
  def remaining_backup_codes(user) do
    length(user.two_factor_backup_codes || [])
  end
end
