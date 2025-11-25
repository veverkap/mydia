import Config

# Configure your database based on DATABASE_TYPE environment variable
# Use DATABASE_TYPE=postgres to use PostgreSQL, otherwise SQLite is used
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
database_type =
  case System.get_env("DATABASE_TYPE") do
    "postgres" -> :postgres
    "postgresql" -> :postgres
    _ -> :sqlite
  end

# Set database_type for runtime helpers (used by Mydia.DB and migrations)
config :mydia, :database_type, database_type

case database_type do
  :postgres ->
    config :mydia, Mydia.Repo,
      hostname: System.get_env("DATABASE_HOST") || "localhost",
      port: String.to_integer(System.get_env("DATABASE_PORT") || "5433"),
      database:
        System.get_env("DATABASE_NAME") || "mydia_test#{System.get_env("MIX_TEST_PARTITION")}",
      username: System.get_env("DATABASE_USER") || "postgres",
      password: System.get_env("DATABASE_PASSWORD") || "postgres",
      pool_size: 5,
      pool: Ecto.Adapters.SQL.Sandbox,
      pool_timeout: 60_000,
      timeout: 60_000

  :sqlite ->
    config :mydia, Mydia.Repo,
      database: Path.expand("../mydia_test.db", __DIR__),
      pool_size: 5,
      pool: Ecto.Adapters.SQL.Sandbox,
      # SQLite-specific settings for better test concurrency
      journal_mode: :wal,
      cache_size: -64000,
      temp_store: :memory,
      pool_timeout: 60_000,
      timeout: 60_000,
      # Increase busy timeout to handle concurrent writes
      busy_timeout: 30_000
end

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :mydia, MydiaWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "CuiGpJ9j+jd1Xb0aq51rBSKLxBYwqr3tvwvMyS2aXBUAlHRtSCT3/GX8fxFcV6UE",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Disable crash reporter logger backend in test to avoid SQL Sandbox issues
config :logger, backends: [:console]

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Disable Oban during testing to prevent pool conflicts with SQL Sandbox
# Using engine: false disables Oban's engine entirely in test mode
config :mydia, Oban,
  testing: :manual,
  engine: false,
  queues: false,
  plugins: false

# Disable health monitoring processes in test mode
config :mydia,
  start_health_monitors: false
