defmodule VolunteerMatch.Gamification.Achievement do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "achievements" do
    field :name, :string
    field :description, :string
    field :icon, :string
    field :tier, Ecto.Enum,
      values: [:bronze, :silver, :gold, :platinum],
      default: :bronze
    field :points, :integer, default: 50
    field :progress_max, :integer
    field :unlock_criteria, :map

    timestamps(type: :utc_datetime)
  end

  def changeset(achievement, attrs) do
    achievement
    |> cast(attrs, [:name, :description, :icon, :tier, :points, :progress_max, :unlock_criteria])
    |> validate_required([:name, :description, :tier, :points])
  end
end
