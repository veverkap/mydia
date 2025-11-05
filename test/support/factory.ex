defmodule Mydia.Factory do
  @moduledoc """
  Factory module for generating test data using ExMachina.
  """

  use ExMachina.Ecto, repo: Mydia.Repo

  alias Mydia.Media.{MediaItem, Episode}
  alias Mydia.Library.MediaFile
  alias Mydia.Downloads.Download

  def media_item_factory do
    %MediaItem{
      type: "movie",
      title: sequence(:title, &"Test Movie #{&1}"),
      year: 2024,
      monitored: true
    }
  end

  def tv_show_factory do
    struct!(
      media_item_factory(),
      %{
        type: "tv_show",
        title: sequence(:tv_title, &"Test TV Show #{&1}")
      }
    )
  end

  def episode_factory do
    %Episode{
      media_item: build(:tv_show),
      season_number: 1,
      episode_number: sequence(:episode_number, & &1),
      title: sequence(:episode_title, &"Episode #{&1}"),
      monitored: true
    }
  end

  def media_file_factory do
    %MediaFile{
      episode: build(:episode),
      path: sequence(:file_path, &"/media/shows/episode#{&1}.mkv"),
      size: 1_000_000_000,
      resolution: "1080p",
      codec: "h264"
    }
  end

  def download_factory do
    %Download{
      media_item: build(:media_item),
      title: sequence(:download_title, &"Download #{&1}"),
      download_client_id: Ecto.UUID.generate(),
      status: "downloading",
      progress: 50.0,
      indexer: "test-indexer"
    }
  end
end
