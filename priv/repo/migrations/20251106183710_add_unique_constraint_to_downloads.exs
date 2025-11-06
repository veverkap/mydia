defmodule Mydia.Repo.Migrations.AddUniqueConstraintToDownloads do
  use Ecto.Migration

  def up do
    # Clear all existing downloads to avoid constraint violations
    # Since downloads table is ephemeral (active downloads only), this is safe
    execute("DELETE FROM downloads")

    # Add unique constraint on (download_client, download_client_id)
    # This ensures no duplicate entries for the same torrent
    # Let Ecto generate the default index name
    create unique_index(:downloads, [:download_client, :download_client_id])
  end

  def down do
    drop index(:downloads, [:download_client, :download_client_id])
  end
end
