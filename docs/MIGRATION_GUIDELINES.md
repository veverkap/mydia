# Migration Guidelines

This document establishes best practices for writing database-agnostic migrations that support both SQLite and PostgreSQL.

## Important: All Migrations Must Be Database-Agnostic

Since Mydia is a self-hosted application, users can choose either SQLite or PostgreSQL. **ALL migrations must work with both databases** - this includes both new migrations and all existing ones in the codebase.

## General Principles

1. **Use Ecto DSL** - Always use Ecto's migration DSL instead of raw SQL
2. **No database-specific syntax** - No SQLite `TEXT` types, no PostgreSQL `jsonb`, no database-specific functions
3. **Application-layer validation** - Use Ecto changesets for validation instead of CHECK constraints
4. **Keep migrations reversible** - Prefer `change/0` over `up/0` and `down/0`
5. **Test migrations** - Ensure they work on fresh installs of both databases

## Quick Reference

| SQLite Syntax | Ecto DSL Equivalent |
|---------------|---------------------|
| `TEXT PRIMARY KEY NOT NULL` | `add :id, :binary_id, primary_key: true` |
| `INTEGER` | `:integer` |
| `REAL` | `:float` |
| `TEXT` | `:string` or `:text` |
| `INTEGER CHECK(x IN (0,1))` | `:boolean` |
| `TEXT NOT NULL` | `add :field, :string, null: false` |
| `DEFAULT 'value'` | `default: "value"` |
| `REFERENCES table(id)` | `references(:table, type: :binary_id)` |
| `ON DELETE CASCADE` | `on_delete: :delete_all` |
| `ON DELETE SET NULL` | `on_delete: :nilify_all` |
| `UNIQUE` | `create unique_index(:table, [:field])` |

## Table Creation

### Bad: Raw SQL (SQLite-specific)

```elixir
def change do
  execute(
    """
    CREATE TABLE users (
      id TEXT PRIMARY KEY NOT NULL,
      username TEXT UNIQUE,
      email TEXT UNIQUE,
      role TEXT NOT NULL DEFAULT 'user' CHECK(role IN ('admin', 'user')),
      active INTEGER DEFAULT 1 CHECK(active IN (0, 1)),
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    """,
    "DROP TABLE IF EXISTS users"
  )
end
```

### Good: Ecto DSL (Database-agnostic)

```elixir
def change do
  create table(:users, primary_key: false) do
    add :id, :binary_id, primary_key: true
    add :username, :string
    add :email, :string
    add :role, :string, null: false, default: "user"
    add :active, :boolean, default: true

    timestamps(type: :utc_datetime)
  end

  create unique_index(:users, [:username])
  create unique_index(:users, [:email])
end
```

## Primary Keys

Always use `:binary_id` for UUID primary keys:

```elixir
create table(:my_table, primary_key: false) do
  add :id, :binary_id, primary_key: true
  # ... other fields
end
```

## Foreign Keys

Use `references/2` with proper options:

```elixir
create table(:api_keys, primary_key: false) do
  add :id, :binary_id, primary_key: true
  add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
  add :name, :string, null: false

  timestamps(type: :utc_datetime)
end
```

### On Delete Options

| Option | Behavior |
|--------|----------|
| `:nothing` | (default) Raise error if referenced row exists |
| `:delete_all` | Delete referencing rows (CASCADE) |
| `:nilify_all` | Set foreign key to NULL (SET NULL) |
| `:restrict` | Prevent deletion if referenced |

## Booleans

Use `:boolean` type - Ecto handles the translation:

```elixir
# This works for both SQLite (INTEGER 0/1) and PostgreSQL (BOOLEAN)
add :enabled, :boolean, default: true, null: false
add :is_admin, :boolean, default: false
```

## Timestamps

Always use `:utc_datetime` type:

```elixir
# Automatic timestamps with correct type
timestamps(type: :utc_datetime)

# Manual timestamp fields
add :last_login_at, :utc_datetime
add :expires_at, :utc_datetime
```

## String vs Text

- Use `:string` for short text (username, email, etc.) - typically VARCHAR(255)
- Use `:text` for long content (descriptions, JSON, etc.) - unlimited length

```elixir
add :name, :string, null: false        # Short text
add :description, :text                 # Long text
add :metadata, :text                    # JSON storage
```

## Indexes

Create indexes using the DSL:

```elixir
# Simple index
create index(:users, [:email])

# Unique index
create unique_index(:users, [:username])

# Composite index
create index(:events, [:actor_type, :actor_id])

# Named index
create index(:downloads, [:status], name: "downloads_status_idx")
```

## Check Constraints

### Avoid When Possible

Check constraints should be handled at the application level when possible. However, if you need them:

### Database-Agnostic Approach

```elixir
def change do
  create table(:items, primary_key: false) do
    add :id, :binary_id, primary_key: true
    add :status, :string, null: false
    # Validate status values in Ecto changeset instead
  end
end
```

### When Raw SQL is Necessary

If a check constraint is truly required, use conditional execution:

```elixir
def change do
  create table(:items, primary_key: false) do
    add :id, :binary_id, primary_key: true
    add :status, :string, null: false
  end

  # Add check constraint (syntax differs by database)
  execute(
    fn ->
      repo().query!(check_constraint_sql(repo().__adapter__))
    end,
    fn ->
      repo().query!(drop_check_constraint_sql(repo().__adapter__))
    end
  )
end

defp check_constraint_sql(Ecto.Adapters.SQLite3) do
  # SQLite doesn't support adding CHECK constraints after table creation
  # The constraint must be in the CREATE TABLE statement
  "SELECT 1" # No-op for SQLite
end

defp check_constraint_sql(Ecto.Adapters.Postgres) do
  """
  ALTER TABLE items
  ADD CONSTRAINT items_status_check
  CHECK (status IN ('pending', 'active', 'done'))
  """
end
```

## Altering Tables

Use `alter/2` for modifications:

```elixir
def change do
  alter table(:quality_profiles) do
    add :description, :text
    add :is_system, :boolean, default: false
    add :version, :integer, default: 1
  end

  create index(:quality_profiles, [:is_system])
end
```

## Complete Example

Here's a complete example of a well-structured, database-agnostic migration:

```elixir
defmodule Mydia.Repo.Migrations.CreateSubtitleProviders do
  use Ecto.Migration

  def change do
    create table(:subtitle_providers, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :type, :string, null: false
      add :enabled, :boolean, default: true, null: false
      add :priority, :integer, default: 0, null: false

      # Optional fields
      add :username, :string
      add :api_key, :string

      # Quota tracking
      add :quota_remaining, :integer
      add :quota_reset_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    # Unique constraint
    create unique_index(:subtitle_providers, [:user_id, :name])

    # Query optimization index
    create index(:subtitle_providers, [:user_id, :enabled, :priority])
  end
end
```

## When Raw SQL is Acceptable

Raw SQL should only be used when:

1. **Data migrations** - Complex data transformations that can't be expressed in Ecto
2. **Performance-critical operations** - Bulk updates that need specific SQL optimizations
3. **Database-specific features** - When you explicitly need a feature only available in one database

When using raw SQL:

1. Always provide both `up` and `down` SQL statements
2. Use `execute/2` for reversible migrations
3. Consider using conditional logic based on the adapter
4. Document why raw SQL was necessary

```elixir
def change do
  # Clearly document why raw SQL is needed
  # This data migration transforms legacy data and can't use Ecto DSL
  execute(
    """
    UPDATE downloads
    SET status = 'completed'
    WHERE status = 'done'
    """,
    """
    UPDATE downloads
    SET status = 'done'
    WHERE status = 'completed'
    """
  )
end
```

## Validation Strategy

All database CHECK constraints have been moved to the application layer:

- **Enum validation** (status, type, category, etc.) - Validated in Ecto changesets
- **Complex constraints** (exactly one of field A or B) - Validated in Ecto changesets
- **Range validation** (progress 0-100) - Validated in Ecto changesets

This approach provides:
- Consistent behavior across databases
- Better error messages
- Easier testing
- No need for table recreation when constraints change

## New Migration Template

When creating a new migration, start with this template:

```elixir
defmodule Mydia.Repo.Migrations.CreateYourTable do
  use Ecto.Migration

  def change do
    create table(:your_table, primary_key: false) do
      add :id, :binary_id, primary_key: true
      # Add your fields here using Ecto types

      timestamps(type: :utc_datetime)
    end

    # Add indexes as needed
    create index(:your_table, [:commonly_queried_field])
  end
end
```

## Checklist for New Migrations

Before committing a migration, verify:

- [ ] Uses Ecto DSL (not raw SQL)
- [ ] Uses `:binary_id` for primary keys
- [ ] Uses `:boolean` instead of integer checks
- [ ] Uses `:utc_datetime` for timestamps
- [ ] Uses `references/2` for foreign keys
- [ ] Has appropriate indexes
- [ ] Is reversible (uses `change/0`)
- [ ] Contains no SQLite or PostgreSQL specific syntax
- [ ] Foreign key references only tables that already exist (see Migration Ordering below)

## Migration Ordering

**PostgreSQL enforces foreign key constraints immediately during table creation**, unlike SQLite which is more lenient. When a migration creates a table with a foreign key reference, the referenced table must already exist.

### Common Issues

If you see an error like:
```
** (Postgrex.Error) ERROR 42P01 (undefined_table) relation "users" does not exist
```

This means a migration is trying to reference a table that hasn't been created yet.

### Solution

Ensure migrations are ordered so that:
1. Tables with no foreign keys are created first
2. Tables are created before any table references them

For example, if `config_settings` references `users`:
- `create_users` migration timestamp should be earlier than `create_config_tables`

### Dependency Chain Example

```
users (no deps)                    → 20251103225446
quality_profiles (no deps)         → 20251103225445
config_tables (→ users, quality)   → 20251103225447
media_items (→ quality_profiles)   → 20251104023000
episodes (→ media_items)           → 20251104023001
```

## Testing with PostgreSQL

To test migrations with PostgreSQL:

1. **Start PostgreSQL container:**
   ```bash
   docker compose --profile postgres up -d postgres
   ```

2. **Configure app for PostgreSQL** (via compose.override.yml):
   ```yaml
   services:
     app:
       environment:
         DATABASE_TYPE: postgres
         DATABASE_HOST: postgres
         DATABASE_PORT: "5432"
   ```

3. **Start app and run migrations:**
   ```bash
   docker compose --profile postgres up -d app
   docker compose --profile postgres exec app mix ecto.migrate
   ```

4. **Verify tables:**
   ```bash
   docker exec mydia-postgres-1 psql -U postgres -d mydia_dev -c "\dt"
   ```

### Notes

- The app needs to be recompiled when switching between SQLite and PostgreSQL (the adapter is a compile-time setting)
- Use `mix deps.clean mydia --build && mix compile` to force recompilation
- The `--profile postgres` flag is required to start the PostgreSQL container
