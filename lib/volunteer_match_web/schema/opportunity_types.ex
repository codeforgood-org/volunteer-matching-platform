defmodule VolunteerMatchWeb.Schema.OpportunityTypes do
  use Absinthe.Schema.Notation

  object :opportunity do
    field :id, non_null(:id)
    field :title, non_null(:string)
    field :description, non_null(:string)
    field :causes, list_of(:string)
    field :skills_required, list_of(:string)
    field :city, :string
    field :state, :string
    field :latitude, :float
    field :longitude, :float
    field :is_remote, :boolean
    field :is_virtual, :boolean
    field :start_date, :date
    field :end_date, :date
    field :application_deadline, :date
    field :volunteers_needed, :integer
    field :volunteers_registered, :integer
    field :status, :opportunity_status
    field :featured, :boolean
    field :view_count, :integer
    field :ngo, :ngo
    field :applications, list_of(:application)
    field :inserted_at, :datetime
  end

  object :opportunity_with_distance do
    field :opportunity, :opportunity
    field :distance, :float
  end

  object :application do
    field :id, non_null(:id)
    field :message, :string
    field :status, :application_status
    field :applied_at, :datetime
    field :reviewed_at, :datetime
    field :volunteer, :volunteer
    field :opportunity, :opportunity
  end

  enum :opportunity_status do
    value(:draft)
    value(:published)
    value(:filled)
    value(:cancelled)
    value(:completed)
  end

  enum :application_status do
    value(:pending)
    value(:accepted)
    value(:rejected)
    value(:withdrawn)
    value(:completed)
  end

  input_object :opportunity_input do
    field :title, non_null(:string)
    field :description, non_null(:string)
    field :causes, list_of(:string)
    field :skills_required, list_of(:string)
    field :city, :string
    field :state, :string
    field :latitude, :float
    field :longitude, :float
    field :is_remote, :boolean
    field :is_virtual, :boolean
    field :start_date, non_null(:date)
    field :end_date, :date
    field :application_deadline, :date
    field :volunteers_needed, :integer
  end

  input_object :opportunity_filter do
    field :causes, list_of(:string)
    field :skills, list_of(:string)
    field :city, :string
    field :state, :string
    field :is_remote, :boolean
    field :status, :opportunity_status
  end
end
