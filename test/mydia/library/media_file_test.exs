defmodule Mydia.Library.MediaFileTest do
  use Mydia.DataCase

  alias Mydia.Library.MediaFile
  alias Mydia.Settings.LibraryPath

  describe "library type compatibility validation" do
    setup do
      # Create library paths with different types
      {:ok, movies_library} =
        %LibraryPath{}
        |> LibraryPath.changeset(%{
          path: "/media/movies",
          type: :movies,
          monitored: true
        })
        |> Repo.insert()

      {:ok, series_library} =
        %LibraryPath{}
        |> LibraryPath.changeset(%{
          path: "/media/series",
          type: :series,
          monitored: true
        })
        |> Repo.insert()

      {:ok, mixed_library} =
        %LibraryPath{}
        |> LibraryPath.changeset(%{
          path: "/media/mixed",
          type: :mixed,
          monitored: true
        })
        |> Repo.insert()

      %{
        movies_library: movies_library,
        series_library: series_library,
        mixed_library: mixed_library
      }
    end

    test "allows movies in :movies library", %{movies_library: movies_library} do
      movie = insert(:media_item, type: "movie")

      changeset =
        %MediaFile{}
        |> MediaFile.changeset(%{
          path: "#{movies_library.path}/The Matrix (1999)/The Matrix (1999) [1080p].mkv",
          media_item_id: movie.id,
          size: 1_000_000_000
        })

      assert changeset.valid?
    end

    test "prevents movies in :series library", %{series_library: series_library} do
      movie = insert(:media_item, type: "movie")

      changeset =
        %MediaFile{}
        |> MediaFile.changeset(%{
          path: "#{series_library.path}/The Matrix (1999)/The Matrix (1999) [1080p].mkv",
          media_item_id: movie.id,
          size: 1_000_000_000
        })

      refute changeset.valid?
      errors = errors_on(changeset).media_item_id
      assert length(errors) == 1
      assert hd(errors) =~ "cannot add movies to a library path configured for TV series only"
    end

    test "allows TV episodes in :series library", %{series_library: series_library} do
      tv_show = insert(:tv_show)
      episode = insert(:episode, media_item: tv_show)

      changeset =
        %MediaFile{}
        |> MediaFile.changeset(%{
          path: "#{series_library.path}/Breaking Bad/Season 01/S01E01.mkv",
          episode_id: episode.id,
          size: 1_000_000_000
        })

      assert changeset.valid?
    end

    test "prevents TV episodes in :movies library", %{movies_library: movies_library} do
      tv_show = insert(:tv_show)
      episode = insert(:episode, media_item: tv_show)

      changeset =
        %MediaFile{}
        |> MediaFile.changeset(%{
          path: "#{movies_library.path}/Breaking Bad/Season 01/S01E01.mkv",
          episode_id: episode.id,
          size: 1_000_000_000
        })

      refute changeset.valid?
      errors = errors_on(changeset).episode_id
      assert length(errors) == 1
      assert hd(errors) =~ "cannot add TV episodes to a library path configured for movies only"
    end

    test "allows both movies and TV shows in :mixed library", %{mixed_library: mixed_library} do
      movie = insert(:media_item, type: "movie")

      movie_changeset =
        %MediaFile{}
        |> MediaFile.changeset(%{
          path: "#{mixed_library.path}/movies/The Matrix (1999).mkv",
          media_item_id: movie.id,
          size: 1_000_000_000
        })

      assert movie_changeset.valid?

      tv_show = insert(:tv_show)
      episode = insert(:episode, media_item: tv_show)

      episode_changeset =
        %MediaFile{}
        |> MediaFile.changeset(%{
          path: "#{mixed_library.path}/tv/Breaking Bad/S01E01.mkv",
          episode_id: episode.id,
          size: 1_000_000_000
        })

      assert episode_changeset.valid?
    end

    test "allows files outside configured library paths" do
      movie = insert(:media_item, type: "movie")

      changeset =
        %MediaFile{}
        |> MediaFile.changeset(%{
          path: "/some/other/path/movie.mkv",
          media_item_id: movie.id,
          size: 1_000_000_000
        })

      assert changeset.valid?
    end

    test "allows orphaned files (no parent association)" do
      changeset =
        %MediaFile{}
        |> MediaFile.scan_changeset(%{
          path: "/media/series/orphaned.mkv",
          size: 1_000_000_000
        })

      assert changeset.valid?
    end

    test "validates with scan_changeset when parent is set", %{series_library: series_library} do
      movie = insert(:media_item, type: "movie")

      changeset =
        %MediaFile{}
        |> MediaFile.scan_changeset(%{
          path: "#{series_library.path}/movie.mkv",
          media_item_id: movie.id,
          size: 1_000_000_000
        })

      refute changeset.valid?
      errors = errors_on(changeset).media_item_id
      assert length(errors) == 1
      assert hd(errors) =~ "cannot add movies to a library path configured for TV series only"
    end

    test "handles TV show type correctly in :movies library", %{movies_library: movies_library} do
      # Create a TV show media item
      tv_show = insert(:tv_show)

      # Try to add the TV show media item directly (not an episode) to movies library
      changeset =
        %MediaFile{}
        |> MediaFile.changeset(%{
          path: "#{movies_library.path}/Breaking Bad/series.mkv",
          media_item_id: tv_show.id,
          size: 1_000_000_000
        })

      # This should be allowed because media_item_id can point to TV shows
      # The validation only prevents episodes in :movies libraries
      assert changeset.valid?
    end

    test "finds library path with longest matching prefix", %{series_library: series_library} do
      # Create a nested library path
      {:ok, nested_library} =
        %LibraryPath{}
        |> LibraryPath.changeset(%{
          path: "#{series_library.path}/subcategory",
          type: :movies,
          monitored: true
        })
        |> Repo.insert()

      # File in the nested path should use nested library's rules
      movie = insert(:media_item, type: "movie")

      changeset =
        %MediaFile{}
        |> MediaFile.changeset(%{
          path: "#{nested_library.path}/movie.mkv",
          media_item_id: movie.id,
          size: 1_000_000_000
        })

      # Should pass because the nested library is :movies
      assert changeset.valid?
    end
  end

  describe "validation edge cases" do
    test "handles nil path gracefully" do
      movie = insert(:media_item, type: "movie")

      changeset =
        %MediaFile{}
        |> MediaFile.changeset(%{
          media_item_id: movie.id,
          size: 1_000_000_000
        })

      # Should fail on validate_required, not on library type validation
      refute changeset.valid?
      assert :path in Keyword.keys(changeset.errors)
    end

    test "handles missing media_item gracefully" do
      changeset =
        %MediaFile{}
        |> MediaFile.changeset(%{
          path: "/media/movies/movie.mkv",
          media_item_id: Ecto.UUID.generate(),
          size: 1_000_000_000
        })

      # Should be valid from schema validation perspective
      # Foreign key constraint will catch the missing media_item on insert
      assert changeset.valid?
    end
  end
end
