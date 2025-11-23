defmodule VolunteerMatch.Workers.DailyMatchWorker do
  @moduledoc """
  Daily worker that generates matches for all active volunteers.
  """
  use Oban.Worker, queue: :default, max_attempts: 3

  alias VolunteerMatch.{Repo, Volunteers, Matching}
  import Ecto.Query

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    # Get all active volunteers
    volunteers =
      Volunteers.Volunteer
      |> where([v], v.is_active == true)
      |> where([v], not is_nil(v.location))
      |> Repo.all()

    Enum.each(volunteers, fn volunteer ->
      Matching.create_matches_for_volunteer(volunteer.id, min_score: 60, limit: 10)
    end)

    {:ok, %{volunteers_processed: length(volunteers)}}
  end
end
