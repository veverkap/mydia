defmodule Mydia.Repo.Migrations.CreateEvents do
  use Ecto.Migration

  def change do
    execute(
      """
      CREATE TABLE events (
        id TEXT PRIMARY KEY NOT NULL,
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        actor_type TEXT,
        actor_id TEXT,
        resource_type TEXT,
        resource_id TEXT,
        severity TEXT NOT NULL DEFAULT 'info',
        metadata TEXT,
        inserted_at TEXT NOT NULL
      )
      """,
      "DROP TABLE IF EXISTS events"
    )

    # Index on type for filtering by specific event types
    create index(:events, [:type])

    # Index on category for filtering by event categories
    create index(:events, [:category])

    # Composite index on actor for filtering by actor
    create index(:events, [:actor_type, :actor_id])

    # Composite index on resource for filtering by resource
    create index(:events, [:resource_type, :resource_id])

    # Index on inserted_at for date-based queries and sorting
    create index(:events, [:inserted_at])

    # Composite index for common queries (category + type + time)
    create index(:events, [:category, :type, :inserted_at])
  end
end
