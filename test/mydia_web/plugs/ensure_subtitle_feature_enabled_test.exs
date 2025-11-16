defmodule MydiaWeb.Plugs.EnsureSubtitleFeatureEnabledTest do
  use MydiaWeb.ConnCase, async: false

  alias MydiaWeb.Plugs.EnsureSubtitleFeatureEnabled

  describe "call/2 when subtitle feature is disabled" do
    setup do
      original_features = Application.get_env(:mydia, :features, [])

      Application.put_env(:mydia, :features, subtitle_enabled: false)

      on_exit(fn ->
        Application.put_env(:mydia, :features, original_features)
      end)

      :ok
    end

    test "returns 404 for API requests", %{conn: conn} do
      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> Map.put(:path_info, ["api", "subtitles", "search"])
        |> EnsureSubtitleFeatureEnabled.call([])

      assert conn.halted
      assert conn.status == 404

      response = Jason.decode!(conn.resp_body)
      assert response["error"] == "Not Found"
      assert response["message"] == "Subtitle feature is not enabled on this server"
    end

    test "returns 404 for web requests", %{conn: conn} do
      conn =
        conn
        |> Map.put(:path_info, ["subtitles", "search"])
        |> EnsureSubtitleFeatureEnabled.call([])

      assert conn.halted
      assert conn.status == 404
    end
  end

  describe "call/2 when subtitle feature is enabled" do
    setup do
      original_features = Application.get_env(:mydia, :features, [])

      Application.put_env(:mydia, :features, subtitle_enabled: true)

      on_exit(fn ->
        Application.put_env(:mydia, :features, original_features)
      end)

      :ok
    end

    test "allows request to proceed for API requests", %{conn: conn} do
      conn =
        conn
        |> put_req_header("accept", "application/json")
        |> Map.put(:path_info, ["api", "subtitles", "search"])
        |> EnsureSubtitleFeatureEnabled.call([])

      refute conn.halted
      assert conn.status in [nil, 200]
    end

    test "allows request to proceed for web requests", %{conn: conn} do
      conn =
        conn
        |> Map.put(:path_info, ["subtitles", "search"])
        |> EnsureSubtitleFeatureEnabled.call([])

      refute conn.halted
      assert conn.status in [nil, 200]
    end
  end

  describe "init/1" do
    test "returns options unchanged" do
      opts = [some: :option]
      assert EnsureSubtitleFeatureEnabled.init(opts) == opts
    end
  end
end
