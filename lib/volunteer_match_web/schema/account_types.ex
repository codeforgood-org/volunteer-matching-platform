defmodule VolunteerMatchWeb.Schema.AccountTypes do
  use Absinthe.Schema.Notation

  object :user do
    field :id, non_null(:id)
    field :email, non_null(:string)
    field :first_name, non_null(:string)
    field :last_name, non_null(:string)
    field :full_name, :string do
      resolve(fn user, _, _ ->
        {:ok, "#{user.first_name} #{user.last_name}"}
      end)
    end
    field :role, non_null(:user_role)
    field :avatar_url, :string
    field :phone, :string
    field :confirmed_at, :datetime
    field :inserted_at, non_null(:datetime)

    field :volunteer, :volunteer
    field :ngo, :ngo
    field :statistics, :user_statistics
  end

  object :volunteer do
    field :id, non_null(:id)
    field :bio, :string
    field :skills, list_of(:string)
    field :interests, list_of(:string)
    field :causes, list_of(:string)
    field :city, :string
    field :state, :string
    field :latitude, :float
    field :longitude, :float
    field :max_distance, :integer
    field :hours_per_week, :integer
    field :experience_level, :experience_level
    field :total_hours, :integer
    field :completed_opportunities, :integer
    field :average_rating, :float
    field :badges, list_of(:badge)
    field :achievements, list_of(:achievement)
  end

  object :ngo do
    field :id, non_null(:id)
    field :name, non_null(:string)
    field :description, :string
    field :mission, :string
    field :website, :string
    field :logo_url, :string
    field :causes, list_of(:string)
    field :city, :string
    field :state, :string
    field :is_verified, :boolean
    field :verified_at, :datetime
    field :total_volunteers, :integer
    field :active_opportunities, :integer
    field :average_rating, :float
    field :impact_stats, :impact_statistics
  end

  object :auth_payload do
    field :token, non_null(:string)
    field :user, non_null(:user)
  end

  object :user_statistics do
    field :applications_count, :integer
    field :active_applications, :integer
    field :completed_opportunities, :integer
    field :total_hours, :integer
    field :average_rating, :float
    field :reviews_count, :integer
    field :impact_score, :integer
  end

  object :impact_statistics do
    field :volunteers_helped, :integer
    field :hours_contributed, :integer
    field :opportunities_created, :integer
    field :completed_opportunities, :integer
    field :community_impact_score, :integer
  end

  enum :user_role do
    value(:volunteer)
    value(:ngo)
    value(:admin)
  end

  enum :experience_level do
    value(:beginner)
    value(:intermediate)
    value(:advanced)
  end

  input_object :profile_input do
    field :volunteer, :volunteer_input
    field :ngo, :ngo_input
  end

  input_object :volunteer_input do
    field :bio, :string
    field :skills, list_of(:string)
    field :interests, list_of(:string)
    field :causes, list_of(:string)
    field :city, :string
    field :state, :string
    field :latitude, :float
    field :longitude, :float
  end

  input_object :ngo_input do
    field :name, non_null(:string)
    field :description, non_null(:string)
    field :mission, :string
    field :website, :string
    field :causes, list_of(:string)
  end
end
