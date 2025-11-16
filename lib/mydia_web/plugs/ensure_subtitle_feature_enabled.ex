defmodule MydiaWeb.Plugs.EnsureSubtitleFeatureEnabled do
  @moduledoc """
  Ensures that the subtitle feature is enabled before accessing subtitle resources.

  If the subtitle feature is disabled, returns a 404 response for both API and web requests.

  ## Usage

  In your router:

      scope "/api/subtitles", MydiaWeb do
        pipe_through [:api, :authenticated]
        plug MydiaWeb.Plugs.EnsureSubtitleFeatureEnabled

        get "/search", SubtitleController, :search
        post "/download", SubtitleController, :download
      end

  Or in a controller:

      defmodule MydiaWeb.SubtitleController do
        use MydiaWeb, :controller

        plug MydiaWeb.Plugs.EnsureSubtitleFeatureEnabled when action in [:search, :download]
        # ...
      end

  """
  import Plug.Conn
  import Phoenix.Controller, only: [json: 2]

  alias Mydia.Subtitles.FeatureFlags

  def init(opts), do: opts

  def call(conn, _opts) do
    if FeatureFlags.enabled?() do
      conn
    else
      handle_feature_disabled(conn)
    end
  end

  defp handle_feature_disabled(conn) do
    case get_format(conn) do
      "json" ->
        conn
        |> put_status(404)
        |> json(%{
          error: "Not Found",
          message: "Subtitle feature is not enabled on this server"
        })
        |> halt()

      _ ->
        conn
        |> put_status(404)
        |> put_resp_content_type("text/html")
        |> send_resp(404, """
        <!DOCTYPE html>
        <html>
        <head><title>404 - Not Found</title></head>
        <body>
        <h1>Not Found</h1>
        <p>Subtitle feature is not enabled on this server.</p>
        </body>
        </html>
        """)
        |> halt()
    end
  end

  defp get_format(conn) do
    case conn.path_info do
      ["api" | _] ->
        "json"

      _ ->
        case get_req_header(conn, "accept") do
          [accept | _] ->
            if String.contains?(accept, "application/json"), do: "json", else: "html"

          _ ->
            "html"
        end
    end
  end
end
