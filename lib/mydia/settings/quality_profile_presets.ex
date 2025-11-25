defmodule Mydia.Settings.QualityProfilePresets do
  @moduledoc """
  Curated quality profile presets based on TRaSH Guides and community best practices.

  This module provides a library of pre-configured quality profiles that users can
  browse and import to quickly set up optimal quality settings without manual configuration.

  ## Preset Categories

  - **TRaSH Guides** - Community-vetted profiles based on TRaSH Guides recommendations
  - **Storage-optimized** - Profiles optimized for different storage constraints
  - **Use-case specific** - Profiles tailored for specific use cases

  ## Preset Structure

  Each preset includes:
  - `id` - Unique identifier for the preset
  - `name` - Display name
  - `category` - Category for grouping (trash_guides, storage_optimized, use_case)
  - `description` - Detailed description of the preset
  - `tags` - List of tags for filtering (4k, hdr, anime, web, remux, etc.)
  - `source` - Source of the preset (TRaSH Guides, Mydia, etc.)
  - `source_url` - URL to the source documentation if available
  - `updated_at` - Last update date
  - `profile_data` - The actual quality profile configuration
  """

  @doc """
  Returns all available quality profile presets.

  ## Examples

      iex> list_presets()
      [
        %{
          id: "trash-hd-bluray-web",
          name: "TRaSH - HD Bluray + WEB",
          category: :trash_guides,
          ...
        }
      ]
  """
  @spec list_presets() :: [map()]
  def list_presets do
    trash_guides_presets() ++ storage_optimized_presets() ++ use_case_presets()
  end

  @doc """
  Returns presets filtered by category.

  ## Categories

  - `:trash_guides` - TRaSH Guides community presets
  - `:storage_optimized` - Storage-conscious presets
  - `:use_case` - Use-case specific presets
  - `:all` - All presets (default)

  ## Examples

      iex> list_presets_by_category(:trash_guides)
      [%{id: "trash-hd-bluray-web", ...}, ...]
  """
  @spec list_presets_by_category(atom()) :: [map()]
  def list_presets_by_category(:all), do: list_presets()

  def list_presets_by_category(category) do
    list_presets()
    |> Enum.filter(&(&1.category == category))
  end

  @doc """
  Returns presets filtered by tags.

  ## Examples

      iex> list_presets_by_tags(["4k", "hdr"])
      [%{id: "trash-uhd-bluray-web", ...}, ...]
  """
  @spec list_presets_by_tags([String.t()]) :: [map()]
  def list_presets_by_tags(tags) when is_list(tags) do
    list_presets()
    |> Enum.filter(fn preset ->
      Enum.any?(tags, &(&1 in preset.tags))
    end)
  end

  @doc """
  Gets a specific preset by ID.

  ## Examples

      iex> get_preset("trash-hd-bluray-web")
      {:ok, %{id: "trash-hd-bluray-web", ...}}

      iex> get_preset("nonexistent")
      {:error, :not_found}
  """
  @spec get_preset(String.t()) :: {:ok, map()} | {:error, :not_found}
  def get_preset(preset_id) do
    case Enum.find(list_presets(), &(&1.id == preset_id)) do
      nil -> {:error, :not_found}
      preset -> {:ok, preset}
    end
  end

  ## TRaSH Guides Presets
  ## Based on https://trash-guides.info/

  defp trash_guides_presets do
    [
      # HD Bluray + WEB (Movies)
      %{
        id: "trash-hd-bluray-web",
        name: "TRaSH - HD Bluray + WEB",
        category: :trash_guides,
        description:
          "High-quality HD encodes prioritizing Blu-ray and streaming sources. Best for standard HD displays with moderate storage capacity. File size: 6-15 GB for 1080p movies.",
        tags: ["1080p", "hd", "bluray", "web", "movies"],
        source: "TRaSH Guides",
        source_url: "https://trash-guides.info/Radarr/radarr-setup-quality-profiles/",
        updated_at: ~D[2025-11-24],
        profile_data: %{
          name: "TRaSH - HD Bluray + WEB",
          upgrades_allowed: true,
          upgrade_until_quality: "1080p",
          qualities: ["720p", "1080p"],
          description:
            "TRaSH Guides: High-quality HD encodes for Blu-ray and streaming sources (6-15 GB)",
          quality_standards: %{
            min_resolution: "720p",
            max_resolution: "1080p",
            preferred_resolutions: ["1080p"],
            preferred_sources: ["BluRay", "WEB-DL"],
            preferred_video_codecs: ["h265", "h264"],
            preferred_audio_codecs: ["dts-hd", "ac3", "aac"],
            movie_min_size_mb: 6144,
            movie_max_size_mb: 15360,
            episode_min_size_mb: 1024,
            episode_max_size_mb: 3072
          }
        }
      },

      # UHD Bluray + WEB (Movies)
      %{
        id: "trash-uhd-bluray-web",
        name: "TRaSH - UHD Bluray + WEB",
        category: :trash_guides,
        description:
          "Ultra high-definition encodes with HDR support. Best for 4K displays and HDR-capable equipment. File size: 20-60 GB for 2160p movies.",
        tags: ["4k", "2160p", "uhd", "hdr", "bluray", "web", "movies"],
        source: "TRaSH Guides",
        source_url: "https://trash-guides.info/Radarr/radarr-setup-quality-profiles/",
        updated_at: ~D[2025-11-24],
        profile_data: %{
          name: "TRaSH - UHD Bluray + WEB",
          upgrades_allowed: true,
          upgrade_until_quality: "2160p",
          qualities: ["2160p"],
          description: "TRaSH Guides: Ultra HD 4K encodes with HDR support (20-60 GB)",
          quality_standards: %{
            min_resolution: "2160p",
            max_resolution: "2160p",
            preferred_resolutions: ["2160p"],
            preferred_sources: ["BluRay", "WEB-DL"],
            preferred_video_codecs: ["h265", "av1"],
            preferred_audio_codecs: ["atmos", "truehd", "dts-hd"],
            hdr_formats: ["dolby_vision", "hdr10+", "hdr10"],
            movie_min_size_mb: 20480,
            movie_max_size_mb: 61440,
            episode_min_size_mb: 5120,
            episode_max_size_mb: 15360
          }
        }
      },

      # Remux + WEB 1080p (Movies)
      %{
        id: "trash-remux-web-1080p",
        name: "TRaSH - Remux + WEB 1080p",
        category: :trash_guides,
        description:
          "High-fidelity 1080p releases with lossless audio. Best for users prioritizing audio quality with standard displays. File size: 20-40 GB for 1080p movies.",
        tags: ["1080p", "remux", "web", "lossless", "movies"],
        source: "TRaSH Guides",
        source_url: "https://trash-guides.info/Radarr/radarr-setup-quality-profiles/",
        updated_at: ~D[2025-11-24],
        profile_data: %{
          name: "TRaSH - Remux + WEB 1080p",
          upgrades_allowed: true,
          upgrade_until_quality: "1080p",
          qualities: ["1080p"],
          description: "TRaSH Guides: 1080p with lossless audio (20-40 GB)",
          quality_standards: %{
            min_resolution: "1080p",
            max_resolution: "1080p",
            preferred_resolutions: ["1080p"],
            preferred_sources: ["REMUX", "WEB-DL"],
            preferred_video_codecs: ["h265", "h264"],
            preferred_audio_codecs: ["truehd", "dts-hd", "atmos"],
            min_video_bitrate_mbps: 15.0,
            movie_min_size_mb: 20480,
            movie_max_size_mb: 40960,
            episode_min_size_mb: 5120,
            episode_max_size_mb: 10240
          }
        }
      },

      # Remux + WEB 2160p (Movies)
      %{
        id: "trash-remux-web-2160p",
        name: "TRaSH - Remux + WEB 2160p",
        category: :trash_guides,
        description:
          "Highest quality 4K releases with lossless audio and HDR. Best for users with premium equipment demanding maximum quality. File size: 40-100 GB for 2160p movies.",
        tags: ["4k", "2160p", "remux", "web", "hdr", "lossless", "movies"],
        source: "TRaSH Guides",
        source_url: "https://trash-guides.info/Radarr/radarr-setup-quality-profiles/",
        updated_at: ~D[2025-11-24],
        profile_data: %{
          name: "TRaSH - Remux + WEB 2160p",
          upgrades_allowed: true,
          upgrade_until_quality: "2160p",
          qualities: ["2160p"],
          description: "TRaSH Guides: 4K with lossless audio and HDR (40-100 GB)",
          quality_standards: %{
            min_resolution: "2160p",
            max_resolution: "2160p",
            preferred_resolutions: ["2160p"],
            preferred_sources: ["REMUX", "WEB-DL"],
            preferred_video_codecs: ["h265", "av1"],
            preferred_audio_codecs: ["atmos", "truehd", "dts-hd"],
            hdr_formats: ["dolby_vision", "hdr10+", "hdr10"],
            min_video_bitrate_mbps: 25.0,
            movie_min_size_mb: 40960,
            movie_max_size_mb: 102_400,
            episode_min_size_mb: 10240,
            episode_max_size_mb: 25600
          }
        }
      },

      # WEB-1080p (TV Shows)
      %{
        id: "trash-web-1080p",
        name: "TRaSH - WEB-1080p",
        category: :trash_guides,
        description:
          "Sweet spot between quality and size for TV content. Prefers 720p/1080p web releases with standard quality-to-size balance. Best for regular TV viewing.",
        tags: ["1080p", "web", "tv", "series"],
        source: "TRaSH Guides",
        source_url: "https://trash-guides.info/Sonarr/sonarr-setup-quality-profiles/",
        updated_at: ~D[2025-11-24],
        profile_data: %{
          name: "TRaSH - WEB-1080p",
          upgrades_allowed: true,
          upgrade_until_quality: "1080p",
          qualities: ["720p", "1080p"],
          description: "TRaSH Guides: Web releases optimized for TV shows (1-3 GB per episode)",
          quality_standards: %{
            min_resolution: "720p",
            max_resolution: "1080p",
            preferred_resolutions: ["1080p"],
            preferred_sources: ["WEB-DL", "WEBRip"],
            preferred_video_codecs: ["h264", "h265"],
            preferred_audio_codecs: ["aac", "ac3"],
            episode_min_size_mb: 1024,
            episode_max_size_mb: 3072,
            movie_min_size_mb: 4096,
            movie_max_size_mb: 12288
          }
        }
      },

      # WEB-2160p (TV Shows)
      %{
        id: "trash-web-2160p",
        name: "TRaSH - WEB-2160p",
        category: :trash_guides,
        description:
          "4K/UHD content with HDR support for TV shows. Targets WEB-2160p with Dolby Vision/HDR10+ options. Best for premium TV viewing on 4K displays.",
        tags: ["4k", "2160p", "web", "hdr", "tv", "series"],
        source: "TRaSH Guides",
        source_url: "https://trash-guides.info/Sonarr/sonarr-setup-quality-profiles/",
        updated_at: ~D[2025-11-24],
        profile_data: %{
          name: "TRaSH - WEB-2160p",
          upgrades_allowed: true,
          upgrade_until_quality: "2160p",
          qualities: ["2160p"],
          description:
            "TRaSH Guides: 4K web releases with HDR for TV shows (5-15 GB per episode)",
          quality_standards: %{
            min_resolution: "2160p",
            max_resolution: "2160p",
            preferred_resolutions: ["2160p"],
            preferred_sources: ["WEB-DL", "WEBRip"],
            preferred_video_codecs: ["h265", "av1"],
            preferred_audio_codecs: ["atmos", "dts-hd", "ac3"],
            hdr_formats: ["dolby_vision", "hdr10+", "hdr10"],
            episode_min_size_mb: 5120,
            episode_max_size_mb: 15360,
            movie_min_size_mb: 20480,
            movie_max_size_mb: 61440
          }
        }
      }
    ]
  end

  ## Storage-Optimized Presets

  defp storage_optimized_presets do
    [
      # Compact
      %{
        id: "storage-compact",
        name: "Storage - Compact",
        category: :storage_optimized,
        description:
          "Optimized for limited storage. Lower bitrates and smaller file sizes while maintaining watchable quality. File size: 1-4 GB for 1080p movies, 300-800 MB per episode.",
        tags: ["720p", "1080p", "compact", "storage", "small"],
        source: "Mydia",
        source_url: nil,
        updated_at: ~D[2025-11-24],
        profile_data: %{
          name: "Storage - Compact",
          upgrades_allowed: false,
          upgrade_until_quality: nil,
          qualities: ["720p", "1080p"],
          description:
            "Compact file sizes for limited storage (1-4 GB movies, 300-800 MB episodes)",
          quality_standards: %{
            max_resolution: "1080p",
            preferred_resolutions: ["720p", "1080p"],
            preferred_sources: ["WEB-DL", "WEBRip"],
            preferred_video_codecs: ["h265", "av1"],
            preferred_audio_codecs: ["aac"],
            max_video_bitrate_mbps: 8.0,
            movie_min_size_mb: 1024,
            movie_max_size_mb: 4096,
            episode_min_size_mb: 300,
            episode_max_size_mb: 800
          }
        }
      },

      # Balanced
      %{
        id: "storage-balanced",
        name: "Storage - Balanced",
        category: :storage_optimized,
        description:
          "Balanced quality vs size tradeoff. Good quality while being storage-conscious. File size: 4-10 GB for 1080p movies, 800-2 GB per episode.",
        tags: ["720p", "1080p", "balanced", "storage"],
        source: "Mydia",
        source_url: nil,
        updated_at: ~D[2025-11-24],
        profile_data: %{
          name: "Storage - Balanced",
          upgrades_allowed: true,
          upgrade_until_quality: "1080p",
          qualities: ["720p", "1080p"],
          description: "Balanced quality and size (4-10 GB movies, 800-2 GB episodes)",
          quality_standards: %{
            min_resolution: "720p",
            max_resolution: "1080p",
            preferred_resolutions: ["1080p"],
            preferred_sources: ["BluRay", "WEB-DL"],
            preferred_video_codecs: ["h265", "h264"],
            preferred_audio_codecs: ["ac3", "aac"],
            min_video_bitrate_mbps: 5.0,
            max_video_bitrate_mbps: 12.0,
            movie_min_size_mb: 4096,
            movie_max_size_mb: 10240,
            episode_min_size_mb: 800,
            episode_max_size_mb: 2048
          }
        }
      },

      # Archival
      %{
        id: "storage-archival",
        name: "Storage - Archival",
        category: :storage_optimized,
        description:
          "Maximum quality retention for long-term archival. Prioritizes lossless sources and high bitrates. File size: 30-80 GB for 1080p movies.",
        tags: ["1080p", "2160p", "archival", "remux", "lossless"],
        source: "Mydia",
        source_url: nil,
        updated_at: ~D[2025-11-24],
        profile_data: %{
          name: "Storage - Archival",
          upgrades_allowed: true,
          upgrade_until_quality: "2160p",
          qualities: ["1080p", "2160p"],
          description: "Maximum quality for archival (30-80 GB movies)",
          quality_standards: %{
            min_resolution: "1080p",
            preferred_resolutions: ["2160p", "1080p"],
            preferred_sources: ["REMUX", "BluRay"],
            preferred_video_codecs: ["h265", "av1", "h264"],
            preferred_audio_codecs: ["atmos", "truehd", "dts-hd"],
            hdr_formats: ["dolby_vision", "hdr10+", "hdr10"],
            min_video_bitrate_mbps: 20.0,
            movie_min_size_mb: 30720,
            movie_max_size_mb: 81920,
            episode_min_size_mb: 8192,
            episode_max_size_mb: 20480
          }
        }
      }
    ]
  end

  ## Use-Case Specific Presets

  defp use_case_presets do
    [
      # Streaming
      %{
        id: "usecase-streaming",
        name: "Use Case - Streaming",
        category: :use_case,
        description:
          "Optimized for streaming over the internet. Web codecs with moderate bitrates for smooth streaming. File size: 2-8 GB for 1080p movies.",
        tags: ["streaming", "web", "720p", "1080p"],
        source: "Mydia",
        source_url: nil,
        updated_at: ~D[2025-11-24],
        profile_data: %{
          name: "Use Case - Streaming",
          upgrades_allowed: true,
          upgrade_until_quality: "1080p",
          qualities: ["720p", "1080p"],
          description: "Optimized for streaming (2-8 GB movies)",
          quality_standards: %{
            min_resolution: "720p",
            max_resolution: "1080p",
            preferred_resolutions: ["1080p", "720p"],
            preferred_sources: ["WEB-DL", "WEBRip"],
            preferred_video_codecs: ["h264", "h265"],
            preferred_audio_codecs: ["aac", "ac3"],
            max_video_bitrate_mbps: 10.0,
            movie_min_size_mb: 2048,
            movie_max_size_mb: 8192,
            episode_min_size_mb: 512,
            episode_max_size_mb: 2048
          }
        }
      },

      # Local Playback
      %{
        id: "usecase-local-playback",
        name: "Use Case - Local Playback",
        category: :use_case,
        description:
          "High quality for local playback without streaming constraints. Accepts any codec with high bitrates. File size: 10-40 GB for 1080p movies.",
        tags: ["local", "high-quality", "1080p", "2160p"],
        source: "Mydia",
        source_url: nil,
        updated_at: ~D[2025-11-24],
        profile_data: %{
          name: "Use Case - Local Playback",
          upgrades_allowed: true,
          upgrade_until_quality: "2160p",
          qualities: ["1080p", "2160p"],
          description: "High quality for local playback (10-40 GB movies)",
          quality_standards: %{
            min_resolution: "1080p",
            preferred_resolutions: ["1080p", "2160p"],
            preferred_sources: ["BluRay", "REMUX"],
            min_video_bitrate_mbps: 10.0,
            movie_min_size_mb: 10240,
            movie_max_size_mb: 40960,
            episode_min_size_mb: 2560,
            episode_max_size_mb: 10240
          }
        }
      },

      # Mobile
      %{
        id: "usecase-mobile",
        name: "Use Case - Mobile",
        category: :use_case,
        description:
          "Optimized for mobile devices. Smaller sizes with h264 compatibility for broad device support. File size: 500 MB-2 GB for 720p movies.",
        tags: ["mobile", "720p", "h264", "small", "compatible"],
        source: "Mydia",
        source_url: nil,
        updated_at: ~D[2025-11-24],
        profile_data: %{
          name: "Use Case - Mobile",
          upgrades_allowed: false,
          upgrade_until_quality: nil,
          qualities: ["480p", "720p"],
          description: "Mobile-friendly sizes and codecs (500 MB-2 GB movies)",
          quality_standards: %{
            max_resolution: "720p",
            preferred_resolutions: ["720p", "480p"],
            preferred_sources: ["WEB-DL", "WEBRip"],
            preferred_video_codecs: ["h264"],
            preferred_audio_codecs: ["aac"],
            max_video_bitrate_mbps: 5.0,
            movie_min_size_mb: 512,
            movie_max_size_mb: 2048,
            episode_min_size_mb: 200,
            episode_max_size_mb: 500
          }
        }
      }
    ]
  end
end
