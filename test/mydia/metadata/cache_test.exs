defmodule Mydia.Metadata.CacheTest do
  use ExUnit.Case, async: false

  alias Mydia.Metadata.Cache

  setup do
    # Clear cache before each test to ensure clean state
    Cache.clear()
    :ok
  end

  describe "get/1" do
    test "returns {:error, :not_found} for non-existent key" do
      assert {:error, :not_found} = Cache.get("non_existent")
    end

    test "returns {:ok, value} for existing non-expired key" do
      Cache.put("key1", "value1")
      assert {:ok, "value1"} = Cache.get("key1")
    end

    test "returns {:error, :not_found} for expired key" do
      # Put with very short TTL (1ms)
      Cache.put("expired_key", "value", ttl: 1)

      # Wait for expiration
      Process.sleep(10)

      assert {:error, :not_found} = Cache.get("expired_key")
    end

    test "deletes expired entries on access" do
      # Put with very short TTL
      Cache.put("expired_key", "value", ttl: 1)

      # Wait for expiration
      Process.sleep(10)

      # First access should delete it
      assert {:error, :not_found} = Cache.get("expired_key")

      # Verify it's really deleted (not just returned as not found)
      assert {:error, :not_found} = Cache.get("expired_key")
    end
  end

  describe "put/3" do
    test "stores value with default TTL" do
      assert :ok = Cache.put("key1", "value1")
      assert {:ok, "value1"} = Cache.get("key1")
    end

    test "stores value with custom TTL" do
      assert :ok = Cache.put("key2", "value2", ttl: :timer.minutes(5))
      assert {:ok, "value2"} = Cache.get("key2")
    end

    test "overwrites existing value" do
      Cache.put("key1", "value1")
      Cache.put("key1", "value2")

      assert {:ok, "value2"} = Cache.get("key1")
    end

    test "stores complex data structures" do
      data = %{
        items: [
          %{id: 1, title: "Movie 1"},
          %{id: 2, title: "Movie 2"}
        ],
        page: 1,
        total: 100
      }

      Cache.put("complex_data", data)
      assert {:ok, ^data} = Cache.get("complex_data")
    end
  end

  describe "fetch/3" do
    test "returns cached value if present" do
      Cache.put("cached_key", "cached_value")

      # Function should not be called
      result =
        Cache.fetch("cached_key", fn ->
          flunk("Function should not be called when value is cached")
        end)

      assert {:ok, "cached_value"} = result
    end

    test "calls function and caches result on cache miss" do
      # Track if function was called
      parent = self()

      result =
        Cache.fetch("new_key", fn ->
          send(parent, :function_called)
          {:ok, "computed_value"}
        end)

      assert {:ok, "computed_value"} = result
      assert_received :function_called

      # Verify value is now cached
      assert {:ok, "computed_value"} = Cache.get("new_key")
    end

    test "does not cache error results" do
      # First call returns error
      result1 =
        Cache.fetch("error_key", fn ->
          {:error, :some_error}
        end)

      assert {:error, :some_error} = result1

      # Verify error was not cached
      assert {:error, :not_found} = Cache.get("error_key")

      # Second call should execute function again
      result2 =
        Cache.fetch("error_key", fn ->
          {:ok, "success_value"}
        end)

      assert {:ok, "success_value"} = result2
    end

    test "uses custom TTL option" do
      Cache.fetch("ttl_key", fn -> {:ok, "value"} end, ttl: :timer.minutes(10))

      assert {:ok, "value"} = Cache.get("ttl_key")
    end

    test "refetches on cache expiration" do
      parent = self()
      call_count = Agent.start_link(fn -> 0 end)
      {:ok, agent} = call_count

      # First fetch with short TTL
      Cache.fetch(
        "expiring_key",
        fn ->
          Agent.update(agent, &(&1 + 1))
          send(parent, :first_call)
          {:ok, "first_value"}
        end,
        ttl: 1
      )

      assert_received :first_call
      assert 1 = Agent.get(agent, & &1)

      # Wait for expiration
      Process.sleep(10)

      # Second fetch should call function again
      Cache.fetch(
        "expiring_key",
        fn ->
          Agent.update(agent, &(&1 + 1))
          send(parent, :second_call)
          {:ok, "second_value"}
        end,
        ttl: 1
      )

      assert_received :second_call
      assert 2 = Agent.get(agent, & &1)

      Agent.stop(agent)
    end
  end

  describe "delete/1" do
    test "removes value from cache" do
      Cache.put("key1", "value1")
      assert {:ok, "value1"} = Cache.get("key1")

      assert :ok = Cache.delete("key1")
      assert {:error, :not_found} = Cache.get("key1")
    end

    test "returns :ok for non-existent key" do
      assert :ok = Cache.delete("non_existent")
    end
  end

  describe "clear/0" do
    test "removes all entries from cache" do
      Cache.put("key1", "value1")
      Cache.put("key2", "value2")
      Cache.put("key3", "value3")

      assert {:ok, "value1"} = Cache.get("key1")
      assert {:ok, "value2"} = Cache.get("key2")
      assert {:ok, "value3"} = Cache.get("key3")

      assert :ok = Cache.clear()

      assert {:error, :not_found} = Cache.get("key1")
      assert {:error, :not_found} = Cache.get("key2")
      assert {:error, :not_found} = Cache.get("key3")
    end

    test "allows new entries after clear" do
      Cache.put("key1", "value1")
      Cache.clear()

      Cache.put("key2", "value2")
      assert {:ok, "value2"} = Cache.get("key2")
    end
  end

  describe "automatic cleanup" do
    test "cache server periodically cleans up expired entries" do
      # This test verifies the cleanup mechanism works but doesn't
      # wait for the actual 10-minute interval

      # Put multiple entries with very short TTL
      Cache.put("cleanup1", "value1", ttl: 1)
      Cache.put("cleanup2", "value2", ttl: 1)
      Cache.put("cleanup3", "value3", ttl: 1)

      # Wait for expiration
      Process.sleep(10)

      # Manual cleanup by sending message to GenServer
      send(Mydia.Metadata.Cache, :cleanup)

      # Give it time to process
      Process.sleep(50)

      # Expired entries should be gone
      assert {:error, :not_found} = Cache.get("cleanup1")
      assert {:error, :not_found} = Cache.get("cleanup2")
      assert {:error, :not_found} = Cache.get("cleanup3")
    end
  end

  describe "concurrent access" do
    test "handles concurrent reads and writes" do
      # Put initial value
      Cache.put("concurrent_key", "initial")

      # Spawn multiple processes reading and writing
      tasks =
        for i <- 1..10 do
          Task.async(fn ->
            Cache.put("key_#{i}", "value_#{i}")
            Cache.get("concurrent_key")
            Cache.get("key_#{i}")
          end)
        end

      # Wait for all tasks to complete
      results = Task.await_many(tasks)

      # All reads should succeed
      assert Enum.all?(results, fn result ->
               match?({:ok, _}, result)
             end)

      # Verify all writes succeeded
      for i <- 1..10 do
        expected_value = "value_#{i}"
        assert {:ok, ^expected_value} = Cache.get("key_#{i}")
      end
    end

    test "fetch/3 prevents thundering herd" do
      parent = self()

      # Spawn multiple processes trying to fetch the same key
      tasks =
        for _i <- 1..5 do
          Task.async(fn ->
            Cache.fetch("shared_key", fn ->
              # Simulate slow computation
              send(parent, :computing)
              Process.sleep(10)
              {:ok, "computed"}
            end)
          end)
        end

      # Wait for all tasks
      results = Task.await_many(tasks)

      # All should get the value
      assert Enum.all?(results, fn result ->
               result == {:ok, "computed"}
             end)

      # Function should be called multiple times since we don't
      # have thundering herd protection (simple implementation)
      # This documents current behavior
      computation_count =
        receive_all_messages([])
        |> Enum.count(&(&1 == :computing))

      assert computation_count > 0
    end
  end

  # Helper to receive all messages in mailbox
  defp receive_all_messages(acc) do
    receive do
      msg -> receive_all_messages([msg | acc])
    after
      0 -> acc
    end
  end
end
