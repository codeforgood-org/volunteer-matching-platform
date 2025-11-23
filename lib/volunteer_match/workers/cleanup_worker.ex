defmodule VolunteerMatch.Workers.CleanupWorker do
  @moduledoc """
  Cleans up old data and expired tokens.
  """
  use Oban.Worker, queue: :default, max_attempts: 3

  alias VolunteerMatch.Repo
  import Ecto.Query

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    # Delete expired guardian tokens
    expired_tokens_count =
      from(t in "guardian_tokens",
        where: t.exp < ^System.system_time(:second)
      )
      |> Repo.delete_all()

    # Archive old completed applications (older than 1 year)
    one_year_ago = DateTime.add(DateTime.utc_now(), -365, :day)

    old_applications_count =
      from(a in VolunteerMatch.Opportunities.Application,
        where: a.status == :completed,
        where: a.completed_at < ^one_year_ago
      )
      |> Repo.delete_all()

    {:ok, %{
      expired_tokens_deleted: elem(expired_tokens_count, 0),
      old_applications_archived: elem(old_applications_count, 0)
    }}
  end
end
