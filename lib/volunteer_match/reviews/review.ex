defmodule VolunteerMatch.Reviews.Review do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "reviews" do
    field :rating, :integer
    field :comment, :string
    field :review_type, Ecto.Enum,
      values: [:volunteer_to_ngo, :ngo_to_volunteer],
      default: :volunteer_to_ngo
    field :is_public, :boolean, default: true
    field :helpfulness_count, :integer, default: 0

    belongs_to :reviewer, VolunteerMatch.Accounts.User
    belongs_to :reviewee, VolunteerMatch.Accounts.User
    belongs_to :application, VolunteerMatch.Opportunities.Application
    belongs_to :opportunity, VolunteerMatch.Opportunities.Opportunity

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(review, attrs) do
    review
    |> cast(attrs, [
      :reviewer_id,
      :reviewee_id,
      :application_id,
      :opportunity_id,
      :rating,
      :comment,
      :review_type,
      :is_public
    ])
    |> validate_required([:reviewer_id, :reviewee_id, :rating, :review_type])
    |> validate_number(:rating, greater_than_or_equal_to: 1, less_than_or_equal_to: 5)
    |> validate_length(:comment, max: 1000)
    |> unique_constraint([:reviewer_id, :application_id],
      name: :reviews_reviewer_id_application_id_index,
      message: "You have already reviewed this application"
    )
    |> foreign_key_constraint(:reviewer_id)
    |> foreign_key_constraint(:reviewee_id)
    |> foreign_key_constraint(:application_id)
    |> foreign_key_constraint(:opportunity_id)
  end

  def increment_helpfulness_changeset(review) do
    change(review, helpfulness_count: review.helpfulness_count + 1)
  end
end
