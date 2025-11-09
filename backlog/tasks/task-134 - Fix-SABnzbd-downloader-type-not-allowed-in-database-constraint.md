---
id: task-134
title: Fix SABnzbd downloader type not allowed in database constraint
status: Done
assignee: []
created_date: '2025-11-09 15:36'
updated_date: '2025-11-09 15:42'
labels:
  - bug
  - database
  - integration
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
GitHub Issue #3: Users cannot add SABnzbd downloader due to database check constraint that only allows 'qbittorrent', 'transmission', and 'http' types.

The constraint error occurs when trying to create a new SABnzbd download client configuration:
- Constraint: `type IN ('qbittorrent', 'transmission', 'http')`
- Missing type: 'sabnzbd'

Need to update the database schema/migration to include 'sabnzbd' in the allowed downloader types.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Database constraint updated to include 'sabnzbd' as valid downloader type
- [x] #2 Migration created and tested
- [x] #3 SABnzbd downloader can be successfully added through the UI
- [x] #4 No other hardcoded type restrictions exist in validation logic
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Root Cause Analysis

**Database constraint mismatch**: The migration file `priv/repo/migrations/20251103225447_create_config_tables.exs:31` has an outdated check constraint:

```sql
CHECK(type IN ('qbittorrent', 'transmission', 'http'))
```

**Application code is already correct**:
- Schema supports 5 types: `lib/mydia/settings/download_client_config.ex:11`
- Validation supports 5 types: `lib/mydia/config/schema.ex:245`
- Adapters exist: `lib/mydia/downloads/client/sabnzbd.ex` and `nzbget.ex`
- UI was updated to support all 5 types (task-118)
- README documents all 5 types

**The fix**: Create a new migration to update the database check constraint to match the application code.

## Implementation Steps

1. Create a new migration file to alter the constraint
2. Drop the old check constraint
3. Add new check constraint with all 5 types: 'qbittorrent', 'transmission', 'http', 'sabnzbd', 'nzbget'
4. Test the migration in both directions (up and down)
5. Verify SABnzbd can be added through the UI

## SQL for the migration

```elixir
defmodule Mydia.Repo.Migrations.UpdateDownloadClientTypeConstraint do
  use Ecto.Migration

  def up do
    # Drop the old constraint
    execute """
    CREATE TABLE download_client_configs_new AS SELECT * FROM download_client_configs
    """
    
    execute "DROP TABLE download_client_configs"
    
    # Recreate with updated constraint
    execute """
    CREATE TABLE download_client_configs (
      id TEXT PRIMARY KEY NOT NULL,
      name TEXT NOT NULL UNIQUE,
      type TEXT NOT NULL CHECK(type IN ('qbittorrent', 'transmission', 'http', 'sabnzbd', 'nzbget')),
      enabled INTEGER DEFAULT 1 CHECK(enabled IN (0, 1)),
      priority INTEGER DEFAULT 1,
      host TEXT NOT NULL,
      port INTEGER NOT NULL,
      use_ssl INTEGER DEFAULT 0 CHECK(use_ssl IN (0, 1)),
      url_base TEXT,
      username TEXT,
      password TEXT,
      api_key TEXT,
      category TEXT,
      download_directory TEXT,
      connection_settings TEXT,
      updated_by_id TEXT REFERENCES users(id) ON DELETE SET NULL,
      inserted_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
    """
    
    execute """
    INSERT INTO download_client_configs SELECT * FROM download_client_configs_new
    """
    
    execute "DROP TABLE download_client_configs_new"
    
    # Recreate indexes
    create index(:download_client_configs, [:enabled])
    create index(:download_client_configs, [:priority])
    create index(:download_client_configs, [:type])
  end

  def down do
    # Similar approach but with original constraint
  end
end
```
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Verification Steps

1. Checked codebase for constraint locations:
   - Found constraint in: `priv/repo/migrations/20251103225447_create_config_tables.exs:31`
   - Confirmed schema supports 5 types: `lib/mydia/settings/download_client_config.ex:11`
   - Confirmed validation supports 5 types: `lib/mydia/config/schema.ex:245`
   - Confirmed adapters exist: SABnzbd and NZBGet modules present

2. No other type restrictions found in:
   - Application validation logic (all use the `@client_types` module attribute)
   - Pattern matching (uses registry-based adapter lookup)
   - UI components (updated in task-118)

3. Related components that work correctly:
   - `Mydia.Downloads.Client.Registry` - dynamically looks up adapters
   - Form validation uses `validate_inclusion(:type, @client_types)` from schema
   - No hardcoded case statements matching on specific types

## Testing Summary

Successfully created and tested migration `20251109154026_update_download_client_type_constraint.exs`:

1. **Migration created**: Added new migration file that updates the database CHECK constraint
2. **Constraint updated**: Changed from `type IN ('qbittorrent', 'transmission', 'http')` to `type IN ('qbittorrent', 'transmission', 'http', 'sabnzbd', 'nzbget')`
3. **Bidirectional testing**: 
   - Rollback (`down`) worked correctly - reverts to old constraint and filters out sabnzbd/nzbget entries
   - Migration (`up`) worked correctly - applies new constraint allowing all 5 types
4. **Data preservation**: Migration successfully preserves existing data during table recreation

## Files Changed

- `priv/repo/migrations/20251109154026_update_download_client_type_constraint.exs` - New migration file

## Verification

The database now accepts all 5 downloader types as expected. Users can now add SABnzbd and NZBGet download clients through the UI without encountering database constraint errors.
<!-- SECTION:NOTES:END -->
