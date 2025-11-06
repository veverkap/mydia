defmodule Mydia.MediaTest do
  use Mydia.DataCase

  alias Mydia.Media

  describe "media_items" do
    alias Mydia.Media.MediaItem

    import Mydia.MediaFixtures

    @invalid_attrs %{type: nil, title: nil}

    test "list_media_items/0 returns all media items" do
      media_item = media_item_fixture()
      assert Media.list_media_items() == [media_item]
    end

    test "get_media_item!/1 returns the media item with given id" do
      media_item = media_item_fixture()
      assert Media.get_media_item!(media_item.id) == media_item
    end

    test "create_media_item/1 with valid data creates a media item" do
      valid_attrs = %{
        type: "movie",
        title: "Test Movie",
        year: 2024,
        tmdb_id: 12345,
        monitored: true
      }

      assert {:ok, %MediaItem{} = media_item} = Media.create_media_item(valid_attrs)
      assert media_item.type == "movie"
      assert media_item.title == "Test Movie"
      assert media_item.year == 2024
      assert media_item.tmdb_id == 12345
      assert media_item.monitored == true
    end

    test "create_media_item/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Media.create_media_item(@invalid_attrs)
    end

    test "create_media_item/1 requires year for movies" do
      attrs_without_year = %{
        type: "movie",
        title: "Test Movie",
        tmdb_id: 12345,
        monitored: true
      }

      assert {:error, %Ecto.Changeset{} = changeset} =
               Media.create_media_item(attrs_without_year)

      assert %{year: ["is required for movies"]} = errors_on(changeset)
    end

    test "create_media_item/1 allows tv_shows without year" do
      attrs_without_year = %{
        type: "tv_show",
        title: "Test Show",
        tmdb_id: 12345,
        monitored: true
      }

      assert {:ok, %MediaItem{} = media_item} = Media.create_media_item(attrs_without_year)
      assert media_item.type == "tv_show"
      assert media_item.title == "Test Show"
      assert media_item.year == nil
    end

    test "update_media_item/2 with valid data updates the media item" do
      media_item = media_item_fixture()
      update_attrs = %{title: "Updated Title", monitored: false}

      assert {:ok, %MediaItem{} = media_item} =
               Media.update_media_item(media_item, update_attrs)

      assert media_item.title == "Updated Title"
      assert media_item.monitored == false
    end

    test "delete_media_item/1 deletes the media item" do
      media_item = media_item_fixture()
      assert {:ok, %MediaItem{}} = Media.delete_media_item(media_item)
      assert_raise Ecto.NoResultsError, fn -> Media.get_media_item!(media_item.id) end
    end

    test "change_media_item/1 returns a media item changeset" do
      media_item = media_item_fixture()
      assert %Ecto.Changeset{} = Media.change_media_item(media_item)
    end
  end

  describe "episodes" do
    alias Mydia.Media.Episode

    import Mydia.MediaFixtures

    @invalid_attrs %{season_number: nil, episode_number: nil}

    test "list_episodes/1 returns all episodes for a media item" do
      media_item = media_item_fixture(%{type: "tv_show"})
      episode = episode_fixture(media_item_id: media_item.id)
      assert Media.list_episodes(media_item.id) == [episode]
    end

    test "get_episode!/1 returns the episode with given id" do
      media_item = media_item_fixture(%{type: "tv_show"})
      episode = episode_fixture(media_item_id: media_item.id)
      assert Media.get_episode!(episode.id) == episode
    end

    test "create_episode/1 with valid data creates an episode" do
      media_item = media_item_fixture(%{type: "tv_show"})

      valid_attrs = %{
        media_item_id: media_item.id,
        season_number: 1,
        episode_number: 1,
        title: "Pilot"
      }

      assert {:ok, %Episode{} = episode} = Media.create_episode(valid_attrs)
      assert episode.season_number == 1
      assert episode.episode_number == 1
      assert episode.title == "Pilot"
    end

    test "create_episode/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Media.create_episode(@invalid_attrs)
    end

    test "update_episode/2 with valid data updates the episode" do
      media_item = media_item_fixture(%{type: "tv_show"})
      episode = episode_fixture(media_item_id: media_item.id)
      update_attrs = %{title: "Updated Episode Title"}

      assert {:ok, %Episode{} = episode} = Media.update_episode(episode, update_attrs)
      assert episode.title == "Updated Episode Title"
    end

    test "delete_episode/1 deletes the episode" do
      media_item = media_item_fixture(%{type: "tv_show"})
      episode = episode_fixture(media_item_id: media_item.id)
      assert {:ok, %Episode{}} = Media.delete_episode(episode)
      assert_raise Ecto.NoResultsError, fn -> Media.get_episode!(episode.id) end
    end
  end
end
