defmodule VolunteerMatch.Repo.Migrations.CreateGuardianDbTables do
  use Ecto.Migration

  def change do
    create table(:guardian_tokens, primary_key: false) do
      add :jti, :string, primary_key: true
      add :aud, :string, primary_key: true
      add :typ, :string
      add :iss, :string
      add :sub, :string
      add :exp, :bigint
      add :jwt, :text
      add :claims, :map

      timestamps(type: :utc_datetime)
    end

    create index(:guardian_tokens, [:sub])
    create index(:guardian_tokens, [:exp])
  end
end
