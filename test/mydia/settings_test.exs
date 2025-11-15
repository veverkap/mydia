defmodule Mydia.SettingsTest do
  use Mydia.DataCase, async: false

  alias Mydia.Settings
  alias Mydia.Settings.QualityProfile

  describe "ensure_default_quality_profiles/0" do
    test "creates default quality profiles when none exist" do
      # Ensure we start with a clean slate
      Repo.delete_all(QualityProfile)

      # Call the function
      assert {:ok, count} = Settings.ensure_default_quality_profiles()
      assert count == 8

      # Verify all profiles were created
      profiles = Settings.list_quality_profiles()
      assert length(profiles) == 8

      # Verify specific profiles exist with expected properties
      profile_names = Enum.map(profiles, & &1.name) |> MapSet.new()

      expected_names =
        MapSet.new([
          "Any",
          "SD",
          "HD-720p",
          "HD-1080p",
          "Full HD",
          "4K/UHD",
          "Remux-1080p",
          "Remux-2160p"
        ])

      assert profile_names == expected_names
    end

    test "is idempotent - does not create duplicates" do
      # Ensure we start with a clean slate
      Repo.delete_all(QualityProfile)

      # First call creates profiles
      assert {:ok, 8} = Settings.ensure_default_quality_profiles()

      # Second call should not create any new profiles
      assert {:ok, 0} = Settings.ensure_default_quality_profiles()

      # Should still have exactly 8 profiles
      profiles = Settings.list_quality_profiles()
      assert length(profiles) == 8
    end

    test "only creates missing profiles when some already exist" do
      # Ensure we start with a clean slate
      Repo.delete_all(QualityProfile)

      # Manually create one of the default profiles
      {:ok, _profile} =
        Settings.create_quality_profile(%{
          name: "Any",
          qualities: ["360p", "480p", "720p", "1080p"]
        })

      # Call the function - should create 7 more profiles
      assert {:ok, 7} = Settings.ensure_default_quality_profiles()

      # Verify we now have 8 profiles
      profiles = Settings.list_quality_profiles()
      assert length(profiles) == 8
    end

    test "profiles have correct structure and required fields" do
      # Ensure we start with a clean slate
      Repo.delete_all(QualityProfile)

      # Create default profiles
      {:ok, _count} = Settings.ensure_default_quality_profiles()

      # Check the "Any" profile
      any_profile = Settings.get_quality_profile_by_name("Any")
      assert any_profile.name == "Any"
      assert is_list(any_profile.qualities)
      assert length(any_profile.qualities) > 0
      assert is_boolean(any_profile.upgrades_allowed)
      assert is_map(any_profile.rules)
      assert Map.has_key?(any_profile.rules, "description")

      # Check the "HD-1080p" profile
      hd_profile = Settings.get_quality_profile_by_name("HD-1080p")
      assert hd_profile.name == "HD-1080p"
      assert "1080p" in hd_profile.qualities
      assert is_map(hd_profile.rules)
      assert Map.has_key?(hd_profile.rules, "max_size_mb")
      assert Map.has_key?(hd_profile.rules, "preferred_sources")

      # Check the "4K/UHD" profile
      uhd_profile = Settings.get_quality_profile_by_name("4K/UHD")
      assert uhd_profile.name == "4K/UHD"
      assert "2160p" in uhd_profile.qualities
      assert is_map(uhd_profile.rules)
    end

    test "profiles have size constraints in rules" do
      # Ensure we start with a clean slate
      Repo.delete_all(QualityProfile)

      # Create default profiles
      {:ok, _count} = Settings.ensure_default_quality_profiles()

      # Check SD profile has max size
      sd_profile = Settings.get_quality_profile_by_name("SD")
      assert sd_profile.rules["max_size_mb"] == 2048

      # Check HD-720p profile has size range
      hd720_profile = Settings.get_quality_profile_by_name("HD-720p")
      assert hd720_profile.rules["min_size_mb"] == 1024
      assert hd720_profile.rules["max_size_mb"] == 5120

      # Check 4K/UHD profile has size constraints
      uhd_profile = Settings.get_quality_profile_by_name("4K/UHD")
      assert uhd_profile.rules["min_size_mb"] == 15360
      assert uhd_profile.rules["max_size_mb"] == 81920
    end

    test "Any profile allows upgrades, others do not" do
      # Ensure we start with a clean slate
      Repo.delete_all(QualityProfile)

      # Create default profiles
      {:ok, _count} = Settings.ensure_default_quality_profiles()

      # Any and SD allow upgrades
      any_profile = Settings.get_quality_profile_by_name("Any")
      assert any_profile.upgrades_allowed == true
      assert any_profile.upgrade_until_quality == "2160p"

      sd_profile = Settings.get_quality_profile_by_name("SD")
      assert sd_profile.upgrades_allowed == true
      assert sd_profile.upgrade_until_quality == "576p"

      # Others don't allow upgrades
      hd_profile = Settings.get_quality_profile_by_name("HD-1080p")
      assert hd_profile.upgrades_allowed == false

      uhd_profile = Settings.get_quality_profile_by_name("4K/UHD")
      assert uhd_profile.upgrades_allowed == false
    end
  end

  describe "default_quality_profiles module" do
    test "returns list of profile definitions" do
      profiles = Settings.DefaultQualityProfiles.defaults()

      assert is_list(profiles)
      assert length(profiles) == 8

      # Each profile should have required keys
      Enum.each(profiles, fn profile ->
        assert Map.has_key?(profile, :name)
        assert Map.has_key?(profile, :qualities)
        assert Map.has_key?(profile, :upgrades_allowed)
        assert Map.has_key?(profile, :rules)
        assert is_list(profile.qualities)
        assert is_boolean(profile.upgrades_allowed)
        assert is_map(profile.rules)
      end)
    end

    test "profile names are unique" do
      profiles = Settings.DefaultQualityProfiles.defaults()
      names = Enum.map(profiles, & &1.name)

      # Check for uniqueness
      assert length(names) == length(Enum.uniq(names))
    end

    test "all profiles have valid qualities arrays" do
      profiles = Settings.DefaultQualityProfiles.defaults()

      Enum.each(profiles, fn profile ->
        assert is_list(profile.qualities)
        assert length(profile.qualities) > 0

        # All quality strings should be valid resolutions
        valid_resolutions = ["360p", "480p", "576p", "720p", "1080p", "2160p"]

        Enum.each(profile.qualities, fn quality ->
          assert quality in valid_resolutions,
                 "Invalid quality #{quality} in profile #{profile.name}"
        end)
      end)
    end
  end

  describe "runtime library paths" do
    setup do
      # Set up runtime config with library paths
      runtime_config = %Mydia.Config.Schema{
        media: %{
          movies_path: "/media/movies",
          tv_path: "/media/tv"
        }
      }

      Application.put_env(:mydia, :runtime_config, runtime_config)

      on_exit(fn ->
        Application.delete_env(:mydia, :runtime_config)
      end)

      :ok
    end

    test "get_runtime_library_paths returns paths with runtime IDs" do
      paths = Settings.get_runtime_library_paths()

      assert length(paths) == 2

      movies_path = Enum.find(paths, &(&1.type == :movies))
      assert movies_path.id == "runtime::library_path::/media/movies"
      assert movies_path.path == "/media/movies"

      tv_path = Enum.find(paths, &(&1.type == :series))
      assert tv_path.id == "runtime::library_path::/media/tv"
      assert tv_path.path == "/media/tv"
    end

    test "get_library_path! can retrieve runtime library paths by runtime ID" do
      runtime_id = "runtime::library_path::/media/movies"
      library_path = Settings.get_library_path!(runtime_id)

      assert library_path.id == runtime_id
      assert library_path.path == "/media/movies"
      assert library_path.type == :movies
    end

    test "get_library_path! raises for non-existent runtime library path" do
      runtime_id = "runtime::library_path::/nonexistent"

      assert_raise RuntimeError, "Runtime library path not found: /nonexistent", fn ->
        Settings.get_library_path!(runtime_id)
      end
    end

    test "list_library_paths merges database and runtime paths" do
      # Create a database library path
      {:ok, db_path} =
        Settings.create_library_path(%{
          path: "/db/path",
          type: :movies,
          monitored: true
        })

      # List should include both database paths and paths synced from runtime
      all_paths = Settings.list_library_paths()

      # Should have at least 3 paths (1 DB + 2 runtime that were synced to DB)
      assert length(all_paths) >= 3

      # Database path should be included
      assert Enum.any?(all_paths, &(&1.id == db_path.id))

      # Runtime paths should be synced to database and included
      # Note: Runtime paths are synced to database on startup, so they have DB IDs
      assert Enum.any?(all_paths, &(&1.path == "/media/movies"))
      assert Enum.any?(all_paths, &(&1.path == "/media/tv"))
    end
  end

  describe "runtime download clients" do
    setup do
      # Set up runtime config with download clients
      runtime_config = %Mydia.Config.Schema{
        download_clients: [
          %{
            name: "qbittorrent",
            type: :qbittorrent,
            enabled: true,
            priority: 10,
            host: "localhost",
            port: 8080
          }
        ]
      }

      Application.put_env(:mydia, :runtime_config, runtime_config)

      on_exit(fn ->
        Application.delete_env(:mydia, :runtime_config)
      end)

      :ok
    end

    test "get_runtime_download_clients returns clients with runtime IDs" do
      clients = Settings.get_runtime_download_clients()

      assert length(clients) == 1

      client = List.first(clients)
      assert client.id == "runtime::download_client::qbittorrent"
      assert client.name == "qbittorrent"
      assert client.type == :qbittorrent
    end

    test "get_download_client_config! can retrieve runtime clients by runtime ID" do
      runtime_id = "runtime::download_client::qbittorrent"
      client = Settings.get_download_client_config!(runtime_id)

      assert client.id == runtime_id
      assert client.name == "qbittorrent"
      assert client.type == :qbittorrent
    end

    test "get_download_client_config! raises for non-existent runtime client" do
      runtime_id = "runtime::download_client::nonexistent"

      assert_raise RuntimeError, "Runtime download client not found: nonexistent", fn ->
        Settings.get_download_client_config!(runtime_id)
      end
    end
  end

  describe "runtime indexers" do
    setup do
      # Set up runtime config with indexers
      runtime_config = %Mydia.Config.Schema{
        indexers: [
          %{
            name: "prowlarr",
            type: :prowlarr,
            enabled: true,
            priority: 10,
            base_url: "http://localhost:9696",
            api_key: "test-key"
          }
        ]
      }

      Application.put_env(:mydia, :runtime_config, runtime_config)

      on_exit(fn ->
        Application.delete_env(:mydia, :runtime_config)
      end)

      :ok
    end

    test "get_runtime_indexers returns indexers with runtime IDs" do
      indexers = Settings.get_runtime_indexers()

      assert length(indexers) == 1

      indexer = List.first(indexers)
      assert indexer.id == "runtime::indexer::prowlarr"
      assert indexer.name == "prowlarr"
      assert indexer.type == :prowlarr
    end

    test "get_indexer_config! can retrieve runtime indexers by runtime ID" do
      runtime_id = "runtime::indexer::prowlarr"
      indexer = Settings.get_indexer_config!(runtime_id)

      assert indexer.id == runtime_id
      assert indexer.name == "prowlarr"
      assert indexer.type == :prowlarr
    end

    test "get_indexer_config! raises for non-existent runtime indexer" do
      runtime_id = "runtime::indexer::nonexistent"

      assert_raise RuntimeError, "Runtime indexer not found: nonexistent", fn ->
        Settings.get_indexer_config!(runtime_id)
      end
    end
  end

  describe "get_*! with string database IDs" do
    test "get_library_path! works with string integer IDs" do
      # Create a database library path
      {:ok, db_path} =
        Settings.create_library_path(%{
          path: "/test/path",
          type: :movies,
          monitored: true
        })

      # Should be able to retrieve with string ID
      library_path = Settings.get_library_path!(to_string(db_path.id))

      assert library_path.id == db_path.id
      assert library_path.path == "/test/path"
    end

    test "get_download_client_config! works with string integer IDs" do
      # Create a database download client config
      {:ok, db_client} =
        Settings.create_download_client_config(%{
          name: "test-client",
          type: :qbittorrent,
          enabled: true,
          priority: 10,
          host: "localhost",
          port: 8080
        })

      # Should be able to retrieve with string ID
      client = Settings.get_download_client_config!(to_string(db_client.id))

      assert client.id == db_client.id
      assert client.name == "test-client"
    end

    test "get_indexer_config! works with string integer IDs" do
      # Create a database indexer config
      {:ok, db_indexer} =
        Settings.create_indexer_config(%{
          name: "test-indexer",
          type: :prowlarr,
          enabled: true,
          priority: 10,
          base_url: "http://localhost:9696",
          api_key: "test-key"
        })

      # Should be able to retrieve with string ID
      indexer = Settings.get_indexer_config!(to_string(db_indexer.id))

      assert indexer.id == db_indexer.id
      assert indexer.name == "test-indexer"
    end
  end

  describe "library path validation on update" do
    setup do
      # Create a library path with a unique test path
      test_id = :crypto.strong_rand_bytes(8) |> Base.encode16()
      test_path = "/media/test_movies_#{test_id}"

      {:ok, library_path} =
        Settings.create_library_path(%{
          path: test_path,
          type: :movies,
          monitored: true
        })

      %{library_path: library_path}
    end

    test "allows path update when no media files exist", %{library_path: library_path} do
      # Update the path (no files to validate)
      assert {:ok, updated} =
               Settings.update_library_path(library_path, %{path: "/new/media/movies"})

      assert updated.path == "/new/media/movies"
    end

    test "allows path update when all files exist at new location", %{
      library_path: library_path
    } do
      # Create test directory structure
      test_dir = System.tmp_dir!()
      old_path = Path.join(test_dir, "old_movies")
      new_path = Path.join(test_dir, "new_movies")

      File.mkdir_p!(old_path)
      File.mkdir_p!(new_path)

      # Update library path to use test directory
      {:ok, library_path} = Settings.update_library_path(library_path, %{path: old_path})

      # Create some test files in both old and new locations
      test_files = ["Movie1.mkv", "Movie2.mkv", "Movie3.mkv"]

      for file <- test_files do
        File.touch!(Path.join(old_path, file))
        File.touch!(Path.join(new_path, file))
      end

      # Create media file records with relative paths
      for file <- test_files do
        {:ok, _media_file} =
          %Mydia.Library.MediaFile{}
          |> Mydia.Library.MediaFile.scan_changeset(%{
            library_path_id: library_path.id,
            relative_path: file,
            size: 1000
          })
          |> Ecto.Changeset.put_change(:path, Path.join(old_path, file))
          |> Repo.insert()
      end

      # Update path should succeed because files exist at new location
      assert {:ok, updated} = Settings.update_library_path(library_path, %{path: new_path})
      assert updated.path == new_path

      # Cleanup
      File.rm_rf!(old_path)
      File.rm_rf!(new_path)
    end

    test "prevents path update when files don't exist at new location", %{
      library_path: library_path
    } do
      # Create test directory structure
      test_dir = System.tmp_dir!()
      old_path = Path.join(test_dir, "old_movies")
      new_path = Path.join(test_dir, "new_movies")

      File.mkdir_p!(old_path)
      File.mkdir_p!(new_path)

      # Update library path to use test directory
      {:ok, library_path} = Settings.update_library_path(library_path, %{path: old_path})

      # Create test files only in old location
      test_files = ["Movie1.mkv", "Movie2.mkv", "Movie3.mkv"]

      for file <- test_files do
        File.touch!(Path.join(old_path, file))
      end

      # Create media file records with relative paths
      for file <- test_files do
        {:ok, _media_file} =
          %Mydia.Library.MediaFile{}
          |> Mydia.Library.MediaFile.scan_changeset(%{
            library_path_id: library_path.id,
            relative_path: file,
            size: 1000
          })
          |> Ecto.Changeset.put_change(:path, Path.join(old_path, file))
          |> Repo.insert()
      end

      # Update path should fail because files don't exist at new location
      assert {:error, changeset} =
               Settings.update_library_path(library_path, %{path: new_path})

      assert changeset.errors[:path] != nil

      {message, _} = changeset.errors[:path]

      assert message =~ "Files not accessible at new location"
      assert message =~ "Checked 3 files, 0 found"

      # Cleanup
      File.rm_rf!(old_path)
      File.rm_rf!(new_path)
    end

    test "prevents path update when some files missing at new location", %{
      library_path: library_path
    } do
      # Create test directory structure
      test_dir = System.tmp_dir!()
      old_path = Path.join(test_dir, "old_movies")
      new_path = Path.join(test_dir, "new_movies")

      File.mkdir_p!(old_path)
      File.mkdir_p!(new_path)

      # Update library path to use test directory
      {:ok, library_path} = Settings.update_library_path(library_path, %{path: old_path})

      # Create test files in old location
      test_files = ["Movie1.mkv", "Movie2.mkv", "Movie3.mkv"]

      for file <- test_files do
        File.touch!(Path.join(old_path, file))
      end

      # Only create some files in new location
      File.touch!(Path.join(new_path, "Movie1.mkv"))
      # Movie2.mkv and Movie3.mkv are missing

      # Create media file records with relative paths
      for file <- test_files do
        {:ok, _media_file} =
          %Mydia.Library.MediaFile{}
          |> Mydia.Library.MediaFile.scan_changeset(%{
            library_path_id: library_path.id,
            relative_path: file,
            size: 1000
          })
          |> Ecto.Changeset.put_change(:path, Path.join(old_path, file))
          |> Repo.insert()
      end

      # Update path should fail because not all files exist at new location
      assert {:error, changeset} =
               Settings.update_library_path(library_path, %{path: new_path})

      assert changeset.errors[:path] != nil

      {message, _} = changeset.errors[:path]

      assert message =~ "Files not accessible at new location"
      assert message =~ "Checked 3 files, 1 found"

      # Cleanup
      File.rm_rf!(old_path)
      File.rm_rf!(new_path)
    end

    test "allows other field updates without path validation", %{library_path: library_path} do
      # Update monitored status (not the path)
      assert {:ok, updated} =
               Settings.update_library_path(library_path, %{monitored: false})

      assert updated.monitored == false
      assert updated.path == library_path.path
    end

    test "samples up to 10 files for validation", %{library_path: library_path} do
      # Create test directory structure
      test_dir = System.tmp_dir!()
      old_path = Path.join(test_dir, "old_movies")
      new_path = Path.join(test_dir, "new_movies")

      File.mkdir_p!(old_path)
      File.mkdir_p!(new_path)

      # Update library path to use test directory
      {:ok, library_path} = Settings.update_library_path(library_path, %{path: old_path})

      # Create 15 test files (more than the sample size)
      test_files = for i <- 1..15, do: "Movie#{i}.mkv"

      for file <- test_files do
        File.touch!(Path.join(old_path, file))
        File.touch!(Path.join(new_path, file))
      end

      # Create media file records for all 15 files
      for file <- test_files do
        {:ok, _media_file} =
          %Mydia.Library.MediaFile{}
          |> Mydia.Library.MediaFile.scan_changeset(%{
            library_path_id: library_path.id,
            relative_path: file,
            size: 1000
          })
          |> Ecto.Changeset.put_change(:path, Path.join(old_path, file))
          |> Repo.insert()
      end

      # Update path should succeed
      # The validation should only check a sample of 10 files
      assert {:ok, updated} = Settings.update_library_path(library_path, %{path: new_path})
      assert updated.path == new_path

      # Cleanup
      File.rm_rf!(old_path)
      File.rm_rf!(new_path)
    end
  end

  describe "validate_new_library_path/2" do
    setup do
      # Create a library path with a unique test path
      test_id = :crypto.strong_rand_bytes(8) |> Base.encode16()
      test_path = "/media/test_validate_#{test_id}"

      {:ok, library_path} =
        Settings.create_library_path(%{
          path: test_path,
          type: :movies,
          monitored: true
        })

      %{library_path: library_path}
    end

    test "returns :ok when no media files exist", %{library_path: library_path} do
      assert :ok = Settings.validate_new_library_path(library_path, "/new/path")
    end

    test "returns :ok when all files are accessible", %{library_path: library_path} do
      # Create test directory structure
      test_dir = System.tmp_dir!()
      old_path = Path.join(test_dir, "old_movies")
      new_path = Path.join(test_dir, "new_movies")

      File.mkdir_p!(old_path)
      File.mkdir_p!(new_path)

      # Update library path to use test directory
      {:ok, library_path} = Settings.update_library_path(library_path, %{path: old_path})

      # Create test files in both locations
      test_files = ["Movie1.mkv", "Movie2.mkv"]

      for file <- test_files do
        File.touch!(Path.join(old_path, file))
        File.touch!(Path.join(new_path, file))
      end

      # Create media file records
      for file <- test_files do
        {:ok, _media_file} =
          %Mydia.Library.MediaFile{}
          |> Mydia.Library.MediaFile.scan_changeset(%{
            library_path_id: library_path.id,
            relative_path: file,
            size: 1000
          })
          |> Ecto.Changeset.put_change(:path, Path.join(old_path, file))
          |> Repo.insert()
      end

      assert :ok = Settings.validate_new_library_path(library_path, new_path)

      # Cleanup
      File.rm_rf!(old_path)
      File.rm_rf!(new_path)
    end

    test "returns error when files are not accessible", %{library_path: library_path} do
      # Create test directory structure
      test_dir = System.tmp_dir!()
      old_path = Path.join(test_dir, "old_movies")
      new_path = Path.join(test_dir, "new_movies")

      File.mkdir_p!(old_path)
      File.mkdir_p!(new_path)

      # Update library path to use test directory
      {:ok, library_path} = Settings.update_library_path(library_path, %{path: old_path})

      # Create test files only in old location
      test_files = ["Movie1.mkv", "Movie2.mkv"]

      for file <- test_files do
        File.touch!(Path.join(old_path, file))
      end

      # Create media file records
      for file <- test_files do
        {:ok, _media_file} =
          %Mydia.Library.MediaFile{}
          |> Mydia.Library.MediaFile.scan_changeset(%{
            library_path_id: library_path.id,
            relative_path: file,
            size: 1000
          })
          |> Ecto.Changeset.put_change(:path, Path.join(old_path, file))
          |> Repo.insert()
      end

      assert {:error, message} = Settings.validate_new_library_path(library_path, new_path)
      assert message =~ "Files not accessible at new location"
      assert message =~ "Checked 2 files, 0 found"

      # Cleanup
      File.rm_rf!(old_path)
      File.rm_rf!(new_path)
    end

    test "returns error with helpful message when some files are missing", %{
      library_path: library_path
    } do
      # Create test directory structure
      test_dir = System.tmp_dir!()
      old_path = Path.join(test_dir, "old_movies")
      new_path = Path.join(test_dir, "new_movies")

      File.mkdir_p!(old_path)
      File.mkdir_p!(new_path)

      # Update library path to use test directory
      {:ok, library_path} = Settings.update_library_path(library_path, %{path: old_path})

      # Create test files
      test_files = ["Movie1.mkv", "Movie2.mkv", "Movie3.mkv"]

      for file <- test_files do
        File.touch!(Path.join(old_path, file))
      end

      # Only create one file in new location
      File.touch!(Path.join(new_path, "Movie1.mkv"))

      # Create media file records
      for file <- test_files do
        {:ok, _media_file} =
          %Mydia.Library.MediaFile{}
          |> Mydia.Library.MediaFile.scan_changeset(%{
            library_path_id: library_path.id,
            relative_path: file,
            size: 1000
          })
          |> Ecto.Changeset.put_change(:path, Path.join(old_path, file))
          |> Repo.insert()
      end

      assert {:error, message} = Settings.validate_new_library_path(library_path, new_path)
      assert message =~ "Checked 3 files, 1 found"
      assert message =~ "Ensure files have been moved to the new location"

      # Cleanup
      File.rm_rf!(old_path)
      File.rm_rf!(new_path)
    end
  end
end
