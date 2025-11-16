defmodule Mydia.Subtitles.FeatureFlagsTest do
  use ExUnit.Case, async: false

  alias Mydia.Subtitles.FeatureFlags

  describe "enabled?/0" do
    test "returns false when subtitle_enabled is not set" do
      original = Application.get_env(:mydia, :features, [])

      try do
        Application.put_env(:mydia, :features, [])
        assert FeatureFlags.enabled?() == false
      after
        Application.put_env(:mydia, :features, original)
      end
    end

    test "returns false when subtitle_enabled is explicitly false" do
      original = Application.get_env(:mydia, :features, [])

      try do
        Application.put_env(:mydia, :features, subtitle_enabled: false)
        assert FeatureFlags.enabled?() == false
      after
        Application.put_env(:mydia, :features, original)
      end
    end

    test "returns true when subtitle_enabled is true" do
      original = Application.get_env(:mydia, :features, [])

      try do
        Application.put_env(:mydia, :features, subtitle_enabled: true)
        assert FeatureFlags.enabled?() == true
      after
        Application.put_env(:mydia, :features, original)
      end
    end
  end
end
