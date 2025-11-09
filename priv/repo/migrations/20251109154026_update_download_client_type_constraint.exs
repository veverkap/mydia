defmodule Mydia.Repo.Migrations.UpdateDownloadClientTypeConstraint do
  use Ecto.Migration

  def up do
    # Rename old table
    rename table(:download_client_configs), to: table(:download_client_configs_old)

    # Create new table with updated constraint (adding 'sabnzbd' and 'nzbget')
    execute(
      """
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
    )

    # Copy data from old table
    execute("INSERT INTO download_client_configs SELECT * FROM download_client_configs_old")

    # Drop old table
    drop table(:download_client_configs_old)

    # Recreate indexes
    create index(:download_client_configs, [:enabled])
    create index(:download_client_configs, [:priority])
    create index(:download_client_configs, [:type])
  end

  def down do
    # Rename current table
    rename table(:download_client_configs), to: table(:download_client_configs_new)

    # Recreate table with old constraint (only qbittorrent, transmission, http)
    execute(
      """
      CREATE TABLE download_client_configs (
        id TEXT PRIMARY KEY NOT NULL,
        name TEXT NOT NULL UNIQUE,
        type TEXT NOT NULL CHECK(type IN ('qbittorrent', 'transmission', 'http')),
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
    )

    # Copy data from new table (excluding sabnzbd and nzbget entries)
    execute(
      "INSERT INTO download_client_configs SELECT * FROM download_client_configs_new WHERE type IN ('qbittorrent', 'transmission', 'http')"
    )

    # Drop new table
    drop table(:download_client_configs_new)

    # Recreate indexes
    create index(:download_client_configs, [:enabled])
    create index(:download_client_configs, [:priority])
    create index(:download_client_configs, [:type])
  end
end
