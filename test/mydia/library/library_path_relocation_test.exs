defmodule Mydia.Library.LibraryPathRelocationTest do
  @moduledoc """
  Integration tests for library path relocation workflow.

  These tests verify that media files remain accessible when a library path
  is updated, which is the primary goal of the relative path migration.
  """

  use Mydia.DataCase, async: true

  alias Mydia.Settings
  alias Mydia.Library.MediaFile
  alias Mydia.Repo

  import Mydia.MediaFixtures

  @moduletag :tmp_dir

  describe "library path relocation" do
    test "media files remain accessible after library path update", %{tmp_dir: tmp_dir} do
      # Setup: Create original library path
      old_library_path = Path.join(tmp_dir, "old_movies")
      new_library_path = Path.join(tmp_dir, "new_movies")

      # Create directory structure and test file
      File.mkdir_p!(old_library_path)
      test_file_relative = "The Matrix (1999)/The Matrix (1999) [1080p].mkv"
      test_file_full_path = Path.join([old_library_path, test_file_relative])
      File.mkdir_p!(Path.dirname(test_file_full_path))
      File.write!(test_file_full_path, "fake video content")

      # Create library path record
      {:ok, library_path} =
        Settings.create_library_path(%{
          path: old_library_path,
          type: :movies,
          monitored: true
        })

      # Create media file using relative path
      movie = insert(:media_item, type: "movie")

      media_file =
        media_file_fixture(%{
          library_path_id: library_path.id,
          relative_path: test_file_relative,
          media_item_id: movie.id,
          size: 1_000_000
        })

      # Verify file is accessible at old location
      media_file = Repo.preload(media_file, :library_path, force: true)
      old_absolute_path = MediaFile.absolute_path(media_file)
      assert old_absolute_path == test_file_full_path
      assert File.exists?(old_absolute_path)

      # Simulate library relocation: Move files to new location
      File.mkdir_p!(new_library_path)
      new_file_full_path = Path.join([new_library_path, test_file_relative])
      File.mkdir_p!(Path.dirname(new_file_full_path))
      File.cp!(test_file_full_path, new_file_full_path)

      # Update library path in database
      {:ok, updated_library_path} =
        Settings.update_library_path(library_path, %{path: new_library_path})

      # Verify: Media file should now resolve to new location
      media_file = Repo.preload(media_file, :library_path, force: true)
      new_absolute_path = MediaFile.absolute_path(media_file)

      assert new_absolute_path == new_file_full_path
      assert File.exists?(new_absolute_path)
      assert media_file.relative_path == test_file_relative
      assert media_file.library_path_id == updated_library_path.id

      # Verify the relative path is unchanged
      assert media_file.relative_path == test_file_relative
    end

    test "multiple files remain accessible after path update", %{tmp_dir: tmp_dir} do
      old_path = Path.join(tmp_dir, "old_series")
      new_path = Path.join(tmp_dir, "new_series")

      File.mkdir_p!(old_path)

      {:ok, library_path} =
        Settings.create_library_path(%{
          path: old_path,
          type: :series,
          monitored: true
        })

      tv_show = insert(:tv_show)

      # Create multiple episode files
      files = [
        "Breaking Bad/Season 01/S01E01.mkv",
        "Breaking Bad/Season 01/S01E02.mkv",
        "Breaking Bad/Season 02/S02E01.mkv"
      ]

      media_files =
        Enum.map(files, fn relative_path ->
          full_path = Path.join(old_path, relative_path)
          File.mkdir_p!(Path.dirname(full_path))
          File.write!(full_path, "fake video #{relative_path}")

          episode = insert(:episode, media_item: tv_show)

          media_file_fixture(%{
            library_path_id: library_path.id,
            relative_path: relative_path,
            episode_id: episode.id,
            size: 500_000
          })
        end)

      # Verify all files are accessible at old location
      Enum.each(media_files, fn media_file ->
        media_file = Repo.preload(media_file, :library_path, force: true)
        old_full_path = MediaFile.absolute_path(media_file)
        assert File.exists?(old_full_path)
      end)

      # Move all files to new location
      File.mkdir_p!(new_path)

      Enum.each(files, fn relative_path ->
        old_full = Path.join(old_path, relative_path)
        new_full = Path.join(new_path, relative_path)
        File.mkdir_p!(Path.dirname(new_full))
        File.cp!(old_full, new_full)
      end)

      # Update library path
      {:ok, _updated_library_path} =
        Settings.update_library_path(library_path, %{path: new_path})

      # Verify all files are accessible at new location
      Enum.zip(media_files, files)
      |> Enum.each(fn {media_file, relative_path} ->
        media_file = Repo.preload(media_file, :library_path, force: true)
        new_full_path = MediaFile.absolute_path(media_file)

        assert new_full_path == Path.join(new_path, relative_path)
        assert File.exists?(new_full_path)
        assert media_file.relative_path == relative_path
      end)
    end

    test "handles nested directory structures", %{tmp_dir: tmp_dir} do
      old_path = Path.join(tmp_dir, "media/old/movies")
      new_path = Path.join(tmp_dir, "storage/new/movies")

      File.mkdir_p!(old_path)

      {:ok, library_path} =
        Settings.create_library_path(%{
          path: old_path,
          type: :movies,
          monitored: true
        })

      movie = insert(:media_item, type: "movie")
      relative_path = "Inception (2010)/Inception (2010) - 4K HDR.mkv"

      old_full_path = Path.join(old_path, relative_path)
      File.mkdir_p!(Path.dirname(old_full_path))
      File.write!(old_full_path, "4K content")

      media_file =
        media_file_fixture(%{
          library_path_id: library_path.id,
          relative_path: relative_path,
          media_item_id: movie.id,
          size: 10_000_000_000
        })

      # Move to new nested location
      File.mkdir_p!(new_path)
      new_full_path = Path.join(new_path, relative_path)
      File.mkdir_p!(Path.dirname(new_full_path))
      File.cp!(old_full_path, new_full_path)

      {:ok, _} = Settings.update_library_path(library_path, %{path: new_path})

      # Verify
      media_file = Repo.preload(media_file, :library_path, force: true)
      resolved_path = MediaFile.absolute_path(media_file)

      assert resolved_path == new_full_path
      assert File.exists?(resolved_path)
    end

    test "path resolution works immediately after update without app restart", %{
      tmp_dir: tmp_dir
    } do
      # This test verifies that the relocation works without requiring
      # an application restart (no startup sync needed for this case)

      old_path = Path.join(tmp_dir, "old")
      new_path = Path.join(tmp_dir, "new")

      File.mkdir_p!(old_path)

      {:ok, library_path} =
        Settings.create_library_path(%{
          path: old_path,
          type: :movies,
          monitored: true
        })

      movie = insert(:media_item, type: "movie")
      relative_path = "movie.mkv"

      old_full = Path.join(old_path, relative_path)
      File.write!(old_full, "content")

      media_file =
        media_file_fixture(%{
          library_path_id: library_path.id,
          relative_path: relative_path,
          media_item_id: movie.id
        })

      # Move file
      File.mkdir_p!(new_path)
      new_full = Path.join(new_path, relative_path)
      File.cp!(old_full, new_full)

      # Update path and immediately verify (no restart)
      {:ok, _} = Settings.update_library_path(library_path, %{path: new_path})

      # Force reload to get updated library_path
      media_file = Repo.preload(media_file, :library_path, force: true)
      resolved = MediaFile.absolute_path(media_file)

      # Should resolve to new location immediately
      assert resolved == new_full
      assert File.exists?(resolved)
    end
  end

  describe "edge cases" do
    test "handles library path with trailing slash", %{tmp_dir: tmp_dir} do
      old_path = Path.join(tmp_dir, "movies")
      new_path = Path.join(tmp_dir, "new_movies")

      File.mkdir_p!(old_path)

      # Create with trailing slash
      {:ok, library_path} =
        Settings.create_library_path(%{
          path: old_path <> "/",
          type: :movies,
          monitored: true
        })

      movie = insert(:media_item, type: "movie")
      relative_path = "test.mkv"

      old_full = Path.join(old_path, relative_path)
      File.write!(old_full, "content")

      media_file =
        media_file_fixture(%{
          library_path_id: library_path.id,
          relative_path: relative_path,
          media_item_id: movie.id
        })

      # Move and update (with trailing slash)
      File.mkdir_p!(new_path)
      new_full = Path.join(new_path, relative_path)
      File.cp!(old_full, new_full)

      {:ok, _} = Settings.update_library_path(library_path, %{path: new_path <> "/"})

      media_file = Repo.preload(media_file, :library_path, force: true)
      resolved = MediaFile.absolute_path(media_file)

      # Should still work correctly
      assert File.exists?(resolved)
    end

    test "relative_path never needs to change during relocation", %{tmp_dir: tmp_dir} do
      # This test verifies the key invariant: relative paths are stable
      # across library relocations

      old_path = Path.join(tmp_dir, "old")
      new_path = Path.join(tmp_dir, "new")

      File.mkdir_p!(old_path)

      {:ok, library_path} =
        Settings.create_library_path(%{
          path: old_path,
          type: :movies,
          monitored: true
        })

      movie = insert(:media_item, type: "movie")
      original_relative_path = "Some Movie (2024)/movie.mkv"

      old_full = Path.join(old_path, original_relative_path)
      File.mkdir_p!(Path.dirname(old_full))
      File.write!(old_full, "content")

      media_file =
        media_file_fixture(%{
          library_path_id: library_path.id,
          relative_path: original_relative_path,
          media_item_id: movie.id
        })

      original_file_id = media_file.id

      # Move files
      File.mkdir_p!(new_path)
      new_full = Path.join(new_path, original_relative_path)
      File.mkdir_p!(Path.dirname(new_full))
      File.cp!(old_full, new_full)

      # Update library path
      {:ok, _} = Settings.update_library_path(library_path, %{path: new_path})

      # Reload media file
      media_file = Repo.get!(MediaFile, original_file_id)
      media_file = Repo.preload(media_file, :library_path)

      # Verify: relative_path is UNCHANGED
      assert media_file.relative_path == original_relative_path

      # Verify: absolute path correctly resolves to new location
      assert MediaFile.absolute_path(media_file) == new_full
    end
  end
end
