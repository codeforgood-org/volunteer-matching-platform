defmodule VolunteerMatch.MixProject do
  use Mix.Project

  def project do
    [
      app: :volunteer_match,
      version: "1.0.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  def application do
    [
      mod: {VolunteerMatch.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      # Phoenix Framework
      {:phoenix, "~> 1.7.10"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 3.3"},
      {:phoenix_live_reload, "~> 1.4", only: :dev},
      {:phoenix_live_view, "~> 0.20.1"},
      {:phoenix_live_dashboard, "~> 0.8.2"},

      # Database
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:geo_postgis, "~> 3.4"},

      # Authentication & Authorization
      {:bcrypt_elixir, "~> 3.0"},
      {:guardian, "~> 2.3"},
      {:guardian_phoenix, "~> 2.0"},
      {:guardian_db, "~> 2.1"},

      # API
      {:cors_plug, "~> 3.0"},
      {:jason, "~> 1.4"},

      # Background Jobs
      {:oban, "~> 2.15"},

      # Email
      {:swoosh, "~> 1.11"},
      {:gen_smtp, "~> 1.2"},

      # File Uploads
      {:ex_aws, "~> 2.4"},
      {:ex_aws_s3, "~> 2.4"},
      {:sweet_xml, "~> 0.7"},

      # Utilities
      {:timex, "~> 3.7"},
      {:geo, "~> 3.5"},
      {:geocalc, "~> 0.8"},
      {:quantum, "~> 3.5"},
      {:ex_machina, "~> 2.7", only: :test},
      {:faker, "~> 0.17", only: [:test, :dev]},

      # Monitoring & Telemetry
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:phoenix_telemetry, "~> 1.0"},
      {:sentry, "~> 10.0"},

      # Testing
      {:excoveralls, "~> 0.18", only: :test},
      {:floki, ">= 0.30.0", only: :test},

      # Development
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},

      # Web Server
      {:plug_cowboy, "~> 2.6"},
      {:bandit, "~> 1.0"},

      # Assets
      {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2.0", runtime: Mix.env() == :dev},

      # GraphQL (optional)
      {:absinthe, "~> 1.7"},
      {:absinthe_plug, "~> 1.5"},
      {:absinthe_phoenix, "~> 2.0"},

      # Rate Limiting
      {:hammer, "~> 6.1"},
      {:hammer_plug, "~> 3.0"},

      # Search
      {:ecto_psql_extras, "~> 0.7"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind default", "esbuild default"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"]
    ]
  end
end
