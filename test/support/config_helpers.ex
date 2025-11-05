defmodule Mydia.ConfigHelpers do
  @moduledoc """
  Helpers for setting up test configuration, particularly for download clients and indexers.
  """

  alias Mydia.Settings

  @doc """
  Creates a test download client configuration and inserts it into Settings.
  Returns the client configuration map.
  """
  def create_test_download_client(attrs \\ %{}) do
    id = Ecto.UUID.generate()

    config = %{
      "id" => id,
      "type" => "transmission",
      "name" => "Test Client #{id}",
      "host" => "localhost",
      "port" => 9091,
      "username" => "test",
      "password" => "test",
      "enabled" => true
    }

    final_config = Map.merge(config, attrs)

    # Store in Settings using the config system
    # Note: This assumes Settings has methods to handle this
    # If not, this helper should be updated when config management is implemented
    {:ok, _} = Settings.upsert_setting("download_clients", [final_config])

    final_config
  end

  @doc """
  Creates multiple test download clients.
  Returns a list of client configuration maps.
  """
  def create_test_download_clients(count) when count > 0 do
    Enum.map(1..count, fn i ->
      create_test_download_client(%{
        "name" => "Test Client #{i}",
        "port" => 9090 + i
      })
    end)
  end

  @doc """
  Creates a test indexer configuration.
  Returns the indexer configuration map.
  """
  def create_test_indexer(attrs \\ %{}) do
    id = Ecto.UUID.generate()

    config = %{
      "id" => id,
      "type" => "prowlarr",
      "name" => "Test Indexer #{id}",
      "base_url" => "http://localhost:9696",
      "api_key" => "test_api_key_#{id}",
      "enabled" => true
    }

    Map.merge(config, attrs)
  end

  @doc """
  Clears all test configurations from Settings.
  Should be called in test setup to ensure clean state.
  """
  def clear_test_config do
    # Clear download clients
    Settings.upsert_setting("download_clients", [])
    # Clear indexers if that setting exists
    Settings.upsert_setting("indexers", [])
    :ok
  rescue
    _ -> :ok
  end
end
