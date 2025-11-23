defmodule VolunteerMatch.AccountsTest do
  use VolunteerMatch.DataCase

  alias VolunteerMatch.Accounts
  alias VolunteerMatch.Accounts.User

  describe "users" do
    @valid_attrs %{
      email: "test@example.com",
      password: "Test1234!",
      first_name: "Test",
      last_name: "User",
      role: :volunteer
    }
    @invalid_attrs %{email: nil, password: nil}

    test "register_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Accounts.register_user(@valid_attrs)
      assert user.email == "test@example.com"
      assert user.first_name == "Test"
      assert user.role == :volunteer
      assert Bcrypt.verify_pass("Test1234!", user.password_hash)
    end

    test "register_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.register_user(@invalid_attrs)
    end

    test "register_user/1 requires unique email" do
      assert {:ok, _user} = Accounts.register_user(@valid_attrs)
      assert {:error, changeset} = Accounts.register_user(@valid_attrs)
      assert "has already been taken" in errors_on(changeset).email
    end

    test "authenticate/2 with valid credentials returns user and token" do
      {:ok, user} = Accounts.register_user(@valid_attrs)
      assert {:ok, auth_user, token} = Accounts.authenticate(@valid_attrs.email, @valid_attrs.password)
      assert auth_user.id == user.id
      assert is_binary(token)
    end

    test "authenticate/2 with invalid credentials returns error" do
      {:ok, _user} = Accounts.register_user(@valid_attrs)
      assert {:error, :invalid_credentials} = Accounts.authenticate(@valid_attrs.email, "wrong")
    end
  end
end
