defmodule Mydia.Streaming.Compatibility do
  @moduledoc """
  Determines browser compatibility for media files to decide between
  direct play and HLS transcoding.

  Browser compatibility is based on modern web standards (Chrome, Firefox, Safari, Edge).
  """

  alias Mydia.Library.MediaFile

  @type streaming_mode :: :direct_play | :needs_transcoding

  @doc """
  Checks if a media file can be played directly in the browser or needs transcoding.

  Returns:
  - `:direct_play` - Browser can handle the file natively
  - `:needs_transcoding` - File needs HLS transcoding

  ## Examples

      iex> media_file = %MediaFile{codec: "h264", audio_codec: "aac", metadata: %{"container" => "mp4"}}
      iex> check_compatibility(media_file)
      :direct_play

      iex> media_file = %MediaFile{codec: "hevc", audio_codec: "aac", metadata: %{"container" => "mkv"}}
      iex> check_compatibility(media_file)
      :needs_transcoding
  """
  @spec check_compatibility(MediaFile.t()) :: streaming_mode()
  def check_compatibility(%MediaFile{} = media_file) do
    container = get_container_format(media_file)
    video_codec = media_file.codec
    audio_codec = media_file.audio_codec

    if browser_compatible?(container, video_codec, audio_codec) do
      :direct_play
    else
      :needs_transcoding
    end
  end

  # Determines if the given combination of container, video codec, and audio codec
  # is compatible with modern browsers
  defp browser_compatible?(container, video_codec, audio_codec) do
    compatible_container?(container) and
      compatible_video_codec?(video_codec) and
      compatible_audio_codec?(audio_codec)
  end

  # Containers that browsers can play directly
  defp compatible_container?(nil), do: false

  defp compatible_container?(container) do
    normalized = String.downcase(container)

    normalized in [
      "mp4",
      "webm",
      # Browser may handle these via video element
      "m4v"
    ]
  end

  # Video codecs that browsers support natively
  defp compatible_video_codec?(nil), do: false

  defp compatible_video_codec?(codec) do
    normalized = String.downcase(codec)

    # Normalize common variations
    codec_name =
      cond do
        normalized in ["h264", "avc", "avc1"] -> "h264"
        normalized in ["h265", "hevc"] -> "hevc"
        normalized in ["vp9", "vp09"] -> "vp9"
        normalized in ["av1", "av01"] -> "av1"
        true -> normalized
      end

    codec_name in [
      "h264",
      "vp9",
      "av1"
    ]
  end

  # Audio codecs that browsers support natively
  defp compatible_audio_codec?(nil), do: false

  defp compatible_audio_codec?(codec) do
    normalized = String.downcase(codec)

    normalized in [
      "aac",
      "mp3",
      "opus",
      "vorbis"
    ]
  end

  # Extracts container format from metadata or file path
  defp get_container_format(%MediaFile{metadata: metadata} = media_file) do
    # First try to get from metadata
    case metadata do
      %{"container" => container} when is_binary(container) ->
        container

      %{"format_name" => format_name} when is_binary(format_name) ->
        # FFprobe may return comma-separated formats like "mov,mp4,m4a"
        # Take the first one
        format_name
        |> String.split(",")
        |> List.first()
        |> String.trim()

      _ ->
        # Fall back to file extension from absolute path
        case MediaFile.absolute_path(media_file) do
          nil ->
            "unknown"

          absolute_path ->
            absolute_path
            |> Path.extname()
            |> String.trim_leading(".")
            |> String.downcase()
        end
    end
  end

  @doc """
  Returns a human-readable description of why transcoding is needed.

  ## Examples

      iex> media_file = %MediaFile{codec: "hevc", audio_codec: "aac", metadata: %{"container" => "mkv"}}
      iex> transcoding_reason(media_file)
      "Incompatible container format (mkv)"
  """
  @spec transcoding_reason(MediaFile.t()) :: String.t()
  def transcoding_reason(%MediaFile{} = media_file) do
    container = get_container_format(media_file)
    video_codec = media_file.codec
    audio_codec = media_file.audio_codec

    cond do
      not compatible_container?(container) ->
        "Incompatible container format (#{container || "unknown"})"

      not compatible_video_codec?(video_codec) ->
        "Incompatible video codec (#{video_codec || "unknown"})"

      not compatible_audio_codec?(audio_codec) ->
        "Incompatible audio codec (#{audio_codec || "unknown"})"

      true ->
        "Unknown compatibility issue"
    end
  end
end
