defmodule VolunteerMatchWeb.Schema.MatchTypes do
  use Absinthe.Schema.Notation

  object :match do
    field :id, non_null(:id)
    field :match_score, :float
    field :location_score, :float
    field :cause_score, :float
    field :skill_score, :float
    field :time_score, :float
    field :distance_km, :float
    field :status, :match_status
    field :opportunity, :opportunity
    field :volunteer, :volunteer
    field :inserted_at, :datetime
  end

  enum :match_status do
    value(:suggested)
    value(:viewed)
    value(:dismissed)
    value(:applied)
  end
end
