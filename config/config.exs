import Config

config :volunteer_match,
  ecto_repos: [VolunteerMatch.Repo],
  generators: [timestamp_type: :utc_datetime]

config :volunteer_match, VolunteerMatch.Repo,
  adapter: Ecto.Adapters.Postgres,
  types: VolunteerMatch.PostgresTypes

config :volunteer_match, VolunteerMatchWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: VolunteerMatchWeb.ErrorHTML, json: VolunteerMatchWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: VolunteerMatch.PubSub,
  live_view: [signing_salt: "volunteer_match_live_view"]

config :volunteer_match, VolunteerMatch.Mailer, adapter: Swoosh.Adapters.Local

config :swoosh, :api_client, false

config :esbuild,
  version: "0.17.11",
  default: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :tailwind,
  version: "3.3.5",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

config :volunteer_match, VolunteerMatch.Guardian,
  issuer: "volunteer_match",
  ttl: {30, :days},
  verify_issuer: true,
  secret_key: "your-guardian-secret-key-change-in-prod"

config :volunteer_match, VolunteerMatch.Guardian.DB,
  repo: VolunteerMatch.Repo,
  schema_name: "guardian_tokens",
  sweep_interval: 60

config :oban, Oban,
  repo: VolunteerMatch.Repo,
  plugins: [
    {Oban.Plugins.Pruner, max_age: 86400},
    {Oban.Plugins.Cron,
     crontab: [
       {"0 2 * * *", VolunteerMatch.Workers.DailyMatchWorker},
       {"0 * * * *", VolunteerMatch.Workers.ReminderWorker},
       {"*/15 * * * *", VolunteerMatch.Workers.CleanupWorker}
     ]}
  ],
  queues: [default: 10, mailers: 20, events: 50]

config :cors_plug,
  origin: ["http://localhost:4000"],
  max_age: 86400,
  methods: ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]

config :hammer,
  backend: {Hammer.Backend.ETS, [expiry_ms: 60_000 * 60 * 4, cleanup_interval_ms: 60_000 * 10]}

import_config "#{config_env()}.exs"
