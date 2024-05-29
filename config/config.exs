import Config

# Use Jason for JSON parsing in Phoenix
# config :phoenix, :json_library, Jason

config :kaffy, ecto_repos: [KaffyTest.Repo]

config :logger, level: :warning

config :kaffy, KaffyTest.Repo,
  name: KaffyTest.Repo,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2,
  priv: "test/support/postgres",
  stacktrace: true,
  url: "postgres://postgres:postgres@localhost:5432/kaffy_test"
