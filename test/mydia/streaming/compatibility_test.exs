defmodule Mydia.Streaming.CompatibilityTest do
  use ExUnit.Case, async: true

  alias Mydia.Library.MediaFile
  alias Mydia.Streaming.Compatibility

  describe "check_compatibility/1" do
    test "returns :direct_play for H.264 + AAC in MP4" do
      media_file = %MediaFile{
        codec: "h264",
        audio_codec: "aac",
        metadata: %{"container" => "mp4"},
        relative_path: "video.mp4",
        library_path: %Mydia.Settings.LibraryPath{path: "/path/to"}
      }

      assert Compatibility.check_compatibility(media_file) == :direct_play
    end

    test "returns :direct_play for VP9 + Opus in WebM" do
      media_file = %MediaFile{
        codec: "vp9",
        audio_codec: "opus",
        metadata: %{"container" => "webm"},
        path: "/path/to/video.webm"
      }

      assert Compatibility.check_compatibility(media_file) == :direct_play
    end

    test "returns :direct_play for AV1 + AAC in MP4" do
      media_file = %MediaFile{
        codec: "av1",
        audio_codec: "aac",
        metadata: %{"container" => "mp4"},
        path: "/path/to/video.mp4"
      }

      assert Compatibility.check_compatibility(media_file) == :direct_play
    end

    test "returns :direct_play for case-insensitive codec names" do
      media_file = %MediaFile{
        codec: "H264",
        audio_codec: "AAC",
        metadata: %{"container" => "MP4"},
        path: "/path/to/video.mp4"
      }

      assert Compatibility.check_compatibility(media_file) == :direct_play
    end

    test "returns :direct_play for AVC codec variant" do
      media_file = %MediaFile{
        codec: "avc1",
        audio_codec: "aac",
        metadata: %{"container" => "mp4"},
        path: "/path/to/video.mp4"
      }

      assert Compatibility.check_compatibility(media_file) == :direct_play
    end

    test "returns :needs_transcoding for HEVC codec" do
      media_file = %MediaFile{
        codec: "hevc",
        audio_codec: "aac",
        metadata: %{"container" => "mp4"},
        path: "/path/to/video.mp4"
      }

      assert Compatibility.check_compatibility(media_file) == :needs_transcoding
    end

    test "returns :needs_transcoding for H.265 codec" do
      media_file = %MediaFile{
        codec: "h265",
        audio_codec: "aac",
        metadata: %{"container" => "mp4"},
        path: "/path/to/video.mp4"
      }

      assert Compatibility.check_compatibility(media_file) == :needs_transcoding
    end

    test "returns :needs_transcoding for MKV container" do
      media_file = %MediaFile{
        codec: "h264",
        audio_codec: "aac",
        metadata: %{"container" => "mkv"},
        path: "/path/to/video.mkv"
      }

      assert Compatibility.check_compatibility(media_file) == :needs_transcoding
    end

    test "returns :needs_transcoding for AVI container" do
      media_file = %MediaFile{
        codec: "h264",
        audio_codec: "aac",
        metadata: %{"container" => "avi"},
        path: "/path/to/video.avi"
      }

      assert Compatibility.check_compatibility(media_file) == :needs_transcoding
    end

    test "returns :needs_transcoding for AC3 audio codec" do
      media_file = %MediaFile{
        codec: "h264",
        audio_codec: "ac3",
        metadata: %{"container" => "mp4"},
        path: "/path/to/video.mp4"
      }

      assert Compatibility.check_compatibility(media_file) == :needs_transcoding
    end

    test "returns :needs_transcoding for DTS audio codec" do
      media_file = %MediaFile{
        codec: "h264",
        audio_codec: "dts",
        metadata: %{"container" => "mp4"},
        path: "/path/to/video.mp4"
      }

      assert Compatibility.check_compatibility(media_file) == :needs_transcoding
    end

    test "returns :needs_transcoding when codec is nil" do
      media_file = %MediaFile{
        codec: nil,
        audio_codec: "aac",
        metadata: %{"container" => "mp4"},
        path: "/path/to/video.mp4"
      }

      assert Compatibility.check_compatibility(media_file) == :needs_transcoding
    end

    test "returns :needs_transcoding when audio_codec is nil" do
      media_file = %MediaFile{
        codec: "h264",
        audio_codec: nil,
        metadata: %{"container" => "mp4"},
        path: "/path/to/video.mp4"
      }

      assert Compatibility.check_compatibility(media_file) == :needs_transcoding
    end

    test "returns :needs_transcoding when container is nil and path has no extension" do
      media_file = %MediaFile{
        codec: "h264",
        audio_codec: "aac",
        metadata: %{},
        relative_path: "video",
        library_path: %Mydia.Settings.LibraryPath{path: "/path/to"}
      }

      assert Compatibility.check_compatibility(media_file) == :needs_transcoding
    end

    test "uses file extension when container not in metadata" do
      media_file = %MediaFile{
        codec: "h264",
        audio_codec: "aac",
        metadata: %{},
        relative_path: "video.mp4",
        library_path: %Mydia.Settings.LibraryPath{path: "/path/to"}
      }

      assert Compatibility.check_compatibility(media_file) == :direct_play
    end

    test "handles FFprobe format_name with comma-separated values" do
      media_file = %MediaFile{
        codec: "h264",
        audio_codec: "aac",
        metadata: %{"format_name" => "mov,mp4,m4a,3gp,3g2,mj2"},
        path: "/path/to/video.mov"
      }

      # Should use first format (mov) but mov isn't in compatible list
      # so it should fall back to file extension
      assert Compatibility.check_compatibility(media_file) == :needs_transcoding
    end

    test "handles FFprobe format_name with mp4" do
      media_file = %MediaFile{
        codec: "h264",
        audio_codec: "aac",
        metadata: %{"format_name" => "mp4"},
        path: "/path/to/video.mp4"
      }

      assert Compatibility.check_compatibility(media_file) == :direct_play
    end
  end

  describe "transcoding_reason/1" do
    test "returns container format reason for MKV" do
      media_file = %MediaFile{
        codec: "h264",
        audio_codec: "aac",
        metadata: %{"container" => "mkv"},
        path: "/path/to/video.mkv"
      }

      assert Compatibility.transcoding_reason(media_file) == "Incompatible container format (mkv)"
    end

    test "returns video codec reason for HEVC" do
      media_file = %MediaFile{
        codec: "hevc",
        audio_codec: "aac",
        metadata: %{"container" => "mp4"},
        path: "/path/to/video.mp4"
      }

      assert Compatibility.transcoding_reason(media_file) == "Incompatible video codec (hevc)"
    end

    test "returns audio codec reason for AC3" do
      media_file = %MediaFile{
        codec: "h264",
        audio_codec: "ac3",
        metadata: %{"container" => "mp4"},
        path: "/path/to/video.mp4"
      }

      assert Compatibility.transcoding_reason(media_file) == "Incompatible audio codec (ac3)"
    end

    test "returns unknown reason for nil codec" do
      media_file = %MediaFile{
        codec: nil,
        audio_codec: "aac",
        metadata: %{"container" => "mp4"},
        path: "/path/to/video.mp4"
      }

      assert Compatibility.transcoding_reason(media_file) == "Incompatible video codec (unknown)"
    end
  end
end
