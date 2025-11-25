defmodule Mydia.Repo do
  @moduledoc """
  Ecto repository for database operations.

  The database adapter is configurable via `:database_adapter` in config:
  - `Ecto.Adapters.SQLite3` (default) - SQLite database
  - `Ecto.Adapters.Postgres` - PostgreSQL database

  Set DATABASE_TYPE=postgres environment variable to use PostgreSQL.
  """
  use Ecto.Repo,
    otp_app: :mydia,
    adapter: Application.compile_env(:mydia, :database_adapter, Ecto.Adapters.SQLite3)
end
