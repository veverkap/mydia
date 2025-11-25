defmodule Mydia.Repo.Migrations.ChangeEventActorIdToString do
  use Ecto.Migration

  @doc """
  Change actor_id from binary_id (UUID) to string to support both:
  - UUIDs for user actors
  - Descriptive strings for system/job actors (e.g., "media_context", "download_monitor")
  """
  def change do
    alter table(:events) do
      modify :actor_id, :string, from: :binary_id
    end
  end
end
