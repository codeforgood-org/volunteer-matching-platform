defmodule VolunteerMatch.Repo do
  use Ecto.Repo,
    otp_app: :volunteer_match,
    adapter: Ecto.Adapters.Postgres

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  def init(_, opts) do
    {:ok, opts}
  end
end
