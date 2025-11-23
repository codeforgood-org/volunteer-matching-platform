defmodule VolunteerMatchWeb.Schema.MessageTypes do
  use Absinthe.Schema.Notation

  object :message do
    field :id, non_null(:id)
    field :subject, :string
    field :body, non_null(:string)
    field :is_read, :boolean
    field :read_at, :datetime
    field :sender, :user
    field :recipient, :user
    field :inserted_at, :datetime
  end

  object :review do
    field :id, non_null(:id)
    field :rating, non_null(:integer)
    field :comment, :string
    field :review_type, :review_type
    field :reviewer, :user
    field :reviewee, :user
    field :opportunity, :opportunity
    field :inserted_at, :datetime
  end

  object :notification do
    field :id, non_null(:id)
    field :type, :notification_type
    field :title, :string
    field :message, :string
    field :is_read, :boolean
    field :read_at, :datetime
    field :metadata, :json
    field :inserted_at, :datetime
  end

  enum :review_type do
    value(:volunteer_to_ngo)
    value(:ngo_to_volunteer)
  end

  enum :notification_type do
    value(:new_match)
    value(:application_received)
    value(:application_accepted)
    value(:application_rejected)
    value(:new_message)
    value(:opportunity_reminder)
    value(:review_received)
    value(:achievement_unlocked)
  end

  input_object :review_input do
    field :rating, non_null(:integer)
    field :comment, :string
    field :reviewee_id, non_null(:id)
    field :application_id, :id
    field :review_type, non_null(:review_type)
  end

  scalar :json do
    parse(fn
      %{value: value} -> {:ok, value}
      _ -> :error
    end)

    serialize(&(&1))
  end
end
