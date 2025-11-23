defmodule VolunteerMatch.Opportunities.Application do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "applications" do
    field :message, :string
    field :availability_notes, :string
    field :status, Ecto.Enum,
      values: [:pending, :accepted, :rejected, :withdrawn, :completed],
      default: :pending
    field :applied_at, :utc_datetime
    field :reviewed_at, :utc_datetime
    field :reviewer_notes, :string
    field :volunteer_hours, :integer
    field :completion_notes, :string
    field :completed_at, :utc_datetime

    belongs_to :volunteer, VolunteerMatch.Volunteers.Volunteer
    belongs_to :opportunity, VolunteerMatch.Opportunities.Opportunity

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(application, attrs) do
    application
    |> cast(attrs, [:volunteer_id, :opportunity_id, :message, :availability_notes])
    |> validate_required([:volunteer_id, :opportunity_id])
    |> validate_length(:message, min: 10, max: 1000)
    |> unique_constraint([:volunteer_id, :opportunity_id],
      name: :applications_volunteer_id_opportunity_id_index,
      message: "You have already applied to this opportunity"
    )
    |> foreign_key_constraint(:volunteer_id)
    |> foreign_key_constraint(:opportunity_id)
    |> put_applied_at()
  end

  defp put_applied_at(changeset) do
    if get_field(changeset, :applied_at) do
      changeset
    else
      put_change(changeset, :applied_at, DateTime.utc_now() |> DateTime.truncate(:second))
    end
  end

  def review_changeset(application, attrs) do
    application
    |> cast(attrs, [:status, :reviewer_notes])
    |> validate_required([:status])
    |> validate_inclusion(:status, [:accepted, :rejected])
    |> put_reviewed_at()
  end

  defp put_reviewed_at(changeset) do
    put_change(changeset, :reviewed_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  def complete_changeset(application, attrs) do
    application
    |> cast(attrs, [:volunteer_hours, :completion_notes])
    |> validate_required([:volunteer_hours])
    |> validate_number(:volunteer_hours, greater_than: 0)
    |> put_change(:status, :completed)
    |> put_completed_at()
  end

  defp put_completed_at(changeset) do
    put_change(changeset, :completed_at, DateTime.utc_now() |> DateTime.truncate(:second))
  end

  def withdraw_changeset(application) do
    change(application, status: :withdrawn)
  end
end
