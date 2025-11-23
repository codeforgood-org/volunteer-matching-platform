defmodule VolunteerMatch.Repo.Migrations.CreateReviews do
  use Ecto.Migration

  def change do
    create table(:reviews, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :reviewer_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :reviewee_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :application_id, references(:applications, type: :binary_id, on_delete: :delete_all)
      add :opportunity_id, references(:opportunities, type: :binary_id, on_delete: :delete_all)
      add :rating, :integer, null: false
      add :comment, :text
      add :review_type, :string, null: false
      add :is_public, :boolean, default: true
      add :helpfulness_count, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:reviews, [:reviewer_id])
    create index(:reviews, [:reviewee_id])
    create index(:reviews, [:application_id])
    create index(:reviews, [:opportunity_id])
    create index(:reviews, [:review_type])
    create index(:reviews, [:rating])
    create unique_index(:reviews, [:reviewer_id, :application_id])
  end
end
