defmodule VolunteerMatch.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      VolunteerMatch.Telemetry,
      VolunteerMatch.Repo,
      {DNSCluster, query: Application.get_env(:volunteer_match, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: VolunteerMatch.PubSub},
      {Oban, Application.fetch_env!(:volunteer_match, Oban)},
      VolunteerMatchWeb.Presence,
      VolunteerMatchWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: VolunteerMatch.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    VolunteerMatchWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
