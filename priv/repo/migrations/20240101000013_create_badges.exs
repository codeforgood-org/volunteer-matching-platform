defmodule VolunteerMatch.Repo.Migrations.CreateBadges do
  use Ecto.Migration

  def change do
    create table(:badges, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :text, null: false
      add :icon, :string
      add :category, :string, null: false
      add :rarity, :string, default: "common"
      add :points, :integer, default: 10
      add :criteria, :map

      timestamps(type: :utc_datetime)
    end

    create unique_index(:badges, [:name])
    create index(:badges, [:category])
    create index(:badges, [:rarity])
  end
end
