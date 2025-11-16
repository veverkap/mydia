defmodule Mydia.Subtitles.FeatureFlags do
  @moduledoc """
  Helper module for checking subtitle feature flag.

  This module handles the SUBTITLE_FEATURE_ENABLED feature flag which controls
  whether subtitle functionality is available in the application.

  For subtitle configuration settings (mode, relay_url), see `Mydia.Subtitles.Config`.
  """

  @doc """
  Returns true if subtitle functionality is enabled, false otherwise.

  Reads from the :subtitle_enabled configuration under the :features key.

  ## Examples

      iex> Mydia.Subtitles.FeatureFlags.enabled?()
      false

      # After setting SUBTITLE_FEATURE_ENABLED=true environment variable
      iex> Mydia.Subtitles.FeatureFlags.enabled?()
      true

  """
  def enabled? do
    Application.get_env(:mydia, :features, [])
    |> Keyword.get(:subtitle_enabled, false)
  end
end
