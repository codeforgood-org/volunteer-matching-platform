defmodule VolunteerMatch.Matching.Match do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "matches" do
    field :match_score, :decimal
    field :location_score, :decimal
    field :cause_score, :decimal
    field :skill_score, :decimal
    field :time_score, :decimal
    field :distance_km, :float
    field :status, Ecto.Enum,
      values: [:suggested, :viewed, :dismissed, :applied],
      default: :suggested
    field :viewed_at, :utc_datetime
    field :dismissed_at, :utc_datetime
    field :metadata, :map, default: %{}

    belongs_to :volunteer, VolunteerMatch.Volunteers.Volunteer
    belongs_to :opportunity, VolunteerMatch.Opportunities.Opportunity

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(match, attrs) do
    match
    |> cast(attrs, [
      :volunteer_id,
      :opportunity_id,
      :match_score,
      :location_score,
      :cause_score,
      :skill_score,
      :time_score,
      :distance_km,
      :status,
      :metadata
    ])
    |> validate_required([:volunteer_id, :opportunity_id, :match_score])
    |> validate_number(:match_score, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> validate_number(:location_score, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> validate_number(:cause_score, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> validate_number(:skill_score, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> validate_number(:time_score, greater_than_or_equal_to: 0, less_than_or_equal_to: 100)
    |> unique_constraint([:volunteer_id, :opportunity_id],
      name: :matches_volunteer_id_opportunity_id_index
    )
    |> foreign_key_constraint(:volunteer_id)
    |> foreign_key_constraint(:opportunity_id)
  end

  def mark_as_viewed_changeset(match) do
    match
    |> change(status: :viewed, viewed_at: DateTime.utc_now() |> DateTime.truncate(:second))
  end

  def mark_as_dismissed_changeset(match) do
    match
    |> change(status: :dismissed, dismissed_at: DateTime.utc_now() |> DateTime.truncate(:second))
  end

  def mark_as_applied_changeset(match) do
    change(match, status: :applied)
  end
end
