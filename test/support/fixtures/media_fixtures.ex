defmodule Mydia.MediaFixtures do
  @moduledoc """
  This module defines test helpers for creating entities via the `Mydia.Media` context.
  """

  @doc """
  Generate a media item.
  """
  def media_item_fixture(attrs \\ %{}) do
    {:ok, media_item} =
      attrs
      |> Enum.into(%{
        type: "movie",
        title: "Test Movie #{System.unique_integer([:positive])}",
        year: 2024,
        monitored: true
      })
      |> Mydia.Media.create_media_item()

    media_item
  end

  @doc """
  Generate an episode.
  """
  def episode_fixture(attrs \\ %{}) do
    # Convert keyword list to map if needed
    attrs = Map.new(attrs)

    # Create a media item if not provided
    media_item_id =
      case Map.get(attrs, :media_item_id) do
        nil ->
          media_item = media_item_fixture(%{type: "tv_show"})
          media_item.id

        id ->
          id
      end

    {:ok, episode} =
      attrs
      |> Enum.into(%{
        media_item_id: media_item_id,
        season_number: 1,
        episode_number: System.unique_integer([:positive]),
        title: "Test Episode",
        monitored: true
      })
      |> Mydia.Media.create_episode()

    episode
  end

  @doc """
  Generate a media file.
  """
  def media_file_fixture(attrs \\ %{}) do
    # Convert keyword list to map if needed
    attrs = Map.new(attrs)

    # Ensure either media_item_id or episode_id is provided
    attrs =
      cond do
        Map.has_key?(attrs, :media_item_id) or Map.has_key?(attrs, :episode_id) ->
          attrs

        true ->
          # Create a movie by default
          media_item = media_item_fixture(%{type: "movie"})
          Map.put(attrs, :media_item_id, media_item.id)
      end

    {:ok, media_file} =
      attrs
      |> Enum.into(%{
        path: "/media/test/file-#{System.unique_integer([:positive])}.mkv",
        size: 1_000_000_000,
        resolution: "1080p",
        codec: "h264"
      })
      |> Mydia.Library.create_media_file()

    media_file
  end
end
