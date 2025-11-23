defmodule VolunteerMatch.Repo.Migrations.AddTwoFactorAuth do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :two_factor_enabled, :boolean, default: false, null: false
      add :two_factor_secret, :string
      add :two_factor_backup_codes, {:array, :string}, default: []
      add :two_factor_enabled_at, :utc_datetime
    end

    create index(:users, [:two_factor_enabled])
  end
end
