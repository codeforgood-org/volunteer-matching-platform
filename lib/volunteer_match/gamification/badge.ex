defmodule VolunteerMatch.Gamification.Badge do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "badges" do
    field :name, :string
    field :description, :string
    field :icon, :string
    field :category, Ecto.Enum,
      values: [:volunteer_hours, :opportunities_completed, :skills, :social, :impact, :special]
    field :rarity, Ecto.Enum,
      values: [:common, :uncommon, :rare, :epic, :legendary],
      default: :common
    field :points, :integer, default: 10
    field :criteria, :map

    timestamps(type: :utc_datetime)
  end

  def changeset(badge, attrs) do
    badge
    |> cast(attrs, [:name, :description, :icon, :category, :rarity, :points, :criteria])
    |> validate_required([:name, :description, :category, :points])
  end
end
