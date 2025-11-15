defmodule MetadataRelay.Router do
  @moduledoc """
  HTTP router for the metadata relay service.
  """

  use Plug.Router

  alias MetadataRelay.TMDB.Handler
  alias MetadataRelay.TVDB.Handler, as: TVDBHandler

  plug(Plug.Logger)
  plug(Plug.Parsers, parsers: [:urlencoded, :json], json_decoder: Jason)
  plug(MetadataRelay.Plug.Cache)
  plug(:match)
  plug(:dispatch)

  # Health check endpoint
  get "/health" do
    response = %{
      status: "ok",
      service: "metadata-relay",
      version: MetadataRelay.version()
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(response))
  end

  # Cache statistics endpoint
  get "/stats" do
    cache_stats = MetadataRelay.Cache.stats()

    response = %{
      service: "metadata-relay",
      version: MetadataRelay.version(),
      cache: cache_stats
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(response))
  end

  # TMDB Configuration
  get "/configuration" do
    handle_tmdb_request(conn, fn -> Handler.configuration() end)
  end

  # TMDB Movie Search
  get "/tmdb/movies/search" do
    params = extract_query_params(conn)
    handle_tmdb_request(conn, fn -> Handler.search_movies(params) end)
  end

  # TMDB TV Search
  get "/tmdb/tv/search" do
    params = extract_query_params(conn)
    handle_tmdb_request(conn, fn -> Handler.search_tv(params) end)
  end

  # TMDB Trending Movies (must come before /tmdb/movies/:id)
  get "/tmdb/movies/trending" do
    params = extract_query_params(conn)
    handle_tmdb_request(conn, fn -> Handler.trending_movies(params) end)
  end

  # TMDB Trending TV (must come before /tmdb/tv/shows/:id)
  get "/tmdb/tv/trending" do
    params = extract_query_params(conn)
    handle_tmdb_request(conn, fn -> Handler.trending_tv(params) end)
  end

  # TMDB Movie Details
  get "/tmdb/movies/:id" do
    params = extract_query_params(conn)
    handle_tmdb_request(conn, fn -> Handler.get_movie(id, params) end)
  end

  # TMDB TV Show Details
  get "/tmdb/tv/shows/:id" do
    params = extract_query_params(conn)
    handle_tmdb_request(conn, fn -> Handler.get_tv_show(id, params) end)
  end

  # TMDB Movie Images
  get "/tmdb/movies/:id/images" do
    params = extract_query_params(conn)
    handle_tmdb_request(conn, fn -> Handler.get_movie_images(id, params) end)
  end

  # TMDB TV Show Images
  get "/tmdb/tv/shows/:id/images" do
    params = extract_query_params(conn)
    handle_tmdb_request(conn, fn -> Handler.get_tv_images(id, params) end)
  end

  # TMDB TV Season Details
  get "/tmdb/tv/shows/:id/:season" do
    params = extract_query_params(conn)
    handle_tmdb_request(conn, fn -> Handler.get_season(id, season, params) end)
  end

  # TVDB Search
  get "/tvdb/search" do
    params = extract_query_params(conn)
    handle_tvdb_request(conn, fn -> TVDBHandler.search(params) end)
  end

  # TVDB Series Details
  get "/tvdb/series/:id" do
    params = extract_query_params(conn)
    handle_tvdb_request(conn, fn -> TVDBHandler.get_series(id, params) end)
  end

  # TVDB Series Extended Details
  get "/tvdb/series/:id/extended" do
    params = extract_query_params(conn)
    handle_tvdb_request(conn, fn -> TVDBHandler.get_series_extended(id, params) end)
  end

  # TVDB Series Episodes
  get "/tvdb/series/:id/episodes" do
    params = extract_query_params(conn)
    handle_tvdb_request(conn, fn -> TVDBHandler.get_series_episodes(id, params) end)
  end

  # TVDB Season Details
  get "/tvdb/seasons/:id" do
    params = extract_query_params(conn)
    handle_tvdb_request(conn, fn -> TVDBHandler.get_season(id, params) end)
  end

  # TVDB Season Extended Details
  get "/tvdb/seasons/:id/extended" do
    params = extract_query_params(conn)
    handle_tvdb_request(conn, fn -> TVDBHandler.get_season_extended(id, params) end)
  end

  # TVDB Episode Details
  get "/tvdb/episodes/:id" do
    params = extract_query_params(conn)
    handle_tvdb_request(conn, fn -> TVDBHandler.get_episode(id, params) end)
  end

  # TVDB Episode Extended Details
  get "/tvdb/episodes/:id/extended" do
    params = extract_query_params(conn)
    handle_tvdb_request(conn, fn -> TVDBHandler.get_episode_extended(id, params) end)
  end

  # TVDB Artwork
  get "/tvdb/artwork/:id" do
    params = extract_query_params(conn)
    handle_tvdb_request(conn, fn -> TVDBHandler.get_artwork(id, params) end)
  end

  # Crash Report Ingestion
  post "/crashes/report" do
    handle_crash_report(conn)
  end

  # 404 catch-all
  match _ do
    send_resp(conn, 404, "Not found")
  end

  # Private helpers

  defp handle_tmdb_request(conn, handler_fn) do
    case handler_fn.() do
      {:ok, body} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(body))

      {:error, {:http_error, status, body}} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(status, Jason.encode!(body))

      {:error, reason} ->
        error_response = %{
          error: "Internal server error",
          message: inspect(reason)
        }

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(error_response))
    end
  end

  defp handle_tvdb_request(conn, handler_fn) do
    case handler_fn.() do
      {:ok, body} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(body))

      {:error, {:http_error, status, body}} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(status, Jason.encode!(body))

      {:error, {:authentication_failed, reason}} ->
        error_response = %{
          error: "Authentication failed",
          message: "Failed to authenticate with TVDB: #{inspect(reason)}"
        }

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(error_response))

      {:error, reason} ->
        error_response = %{
          error: "Internal server error",
          message: inspect(reason)
        }

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(error_response))
    end
  end

  defp extract_query_params(conn) do
    conn.query_params
    |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
  end

  defp handle_crash_report(conn) do
    # Check rate limit first (by IP address)
    client_ip = get_client_ip(conn)

    case MetadataRelay.RateLimiter.check_rate_limit(client_ip) do
      {:error, :rate_limited} ->
        error_response = %{
          error: "Too many requests",
          message: "Rate limit exceeded. Please try again later."
        }

        conn
        |> put_resp_header("retry-after", "60")
        |> put_resp_content_type("application/json")
        |> send_resp(429, Jason.encode!(error_response))

      {:ok, _remaining} ->
        # Check API authentication
        api_key = get_req_header(conn, "authorization") |> List.first()
        expected_key = Application.get_env(:metadata_relay, :crash_report_api_key)

        cond do
          is_nil(expected_key) or expected_key == "" ->
            # API key not configured - reject requests
            error_response = %{
              error: "Service unavailable",
              message: "Crash reporting is not configured"
            }

            conn
            |> put_resp_content_type("application/json")
            |> send_resp(503, Jason.encode!(error_response))

          is_nil(api_key) or api_key != "Bearer #{expected_key}" ->
            # Authentication failed
            error_response = %{
              error: "Unauthorized",
              message: "Invalid or missing API key"
            }

            conn
            |> put_resp_content_type("application/json")
            |> send_resp(401, Jason.encode!(error_response))

          true ->
            # Authentication successful - process the report
            process_crash_report(conn)
        end
    end
  end

  defp get_client_ip(conn) do
    # Get the client IP from the connection
    # Check X-Forwarded-For header first (for proxied requests)
    case get_req_header(conn, "x-forwarded-for") do
      [forwarded | _] ->
        forwarded
        |> String.split(",")
        |> List.first()
        |> String.trim()

      [] ->
        # Fall back to remote_ip
        conn.remote_ip
        |> :inet.ntoa()
        |> to_string()
    end
  end

  defp process_crash_report(conn) do
    with {:ok, body} <- validate_crash_report(conn.body_params),
         {:ok, _occurrence} <- store_crash_report(body) do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(201, Jason.encode!(%{status: "created", message: "Crash report received"}))
    else
      {:error, :invalid_json} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{error: "Invalid JSON", message: "Request body must be valid JSON"}))

      {:error, {:validation, errors}} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{error: "Validation failed", errors: errors}))

      {:error, reason} ->
        error_response = %{
          error: "Internal server error",
          message: "Failed to store crash report: #{inspect(reason)}"
        }

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(error_response))
    end
  end

  defp validate_crash_report(params) when is_map(params) do
    required_fields = ["error_type", "error_message", "stacktrace"]

    errors =
      required_fields
      |> Enum.reject(&Map.has_key?(params, &1))
      |> Enum.map(&"Missing required field: #{&1}")

    # Validate stacktrace is a list
    stacktrace_errors =
      case Map.get(params, "stacktrace") do
        st when is_list(st) -> []
        _ -> ["stacktrace must be a list"]
      end

    all_errors = errors ++ stacktrace_errors

    if all_errors == [] do
      {:ok, params}
    else
      {:error, {:validation, all_errors}}
    end
  end

  defp validate_crash_report(_), do: {:error, :invalid_json}

  defp store_crash_report(body) do
    # Create a runtime error from the crash report data
    error_type = Map.get(body, "error_type", "RuntimeError")
    error_message = Map.get(body, "error_message", "Unknown error")

    # Reconstruct stacktrace from the crash report
    stacktrace =
      body
      |> Map.get("stacktrace", [])
      |> Enum.map(&parse_stacktrace_entry/1)
      |> Enum.filter(& &1)

    # Create context from additional metadata
    context = %{
      version: Map.get(body, "version"),
      environment: Map.get(body, "environment"),
      occurred_at: Map.get(body, "occurred_at"),
      metadata: Map.get(body, "metadata", %{})
    }

    # Create exception struct
    exception = %RuntimeError{message: "#{error_type}: #{error_message}"}

    # Report to ErrorTracker
    case ErrorTracker.report(exception, stacktrace, context) do
      :noop ->
        {:error, :error_tracker_disabled}

      occurrence ->
        {:ok, occurrence}
    end
  end

  defp parse_stacktrace_entry(%{"file" => file, "line" => line, "function" => function}) do
    # Convert crash report format to Elixir stacktrace format
    # Format: {module, function, arity, [file: path, line: number]}
    {String.to_atom(function), 0, [file: String.to_charlist(file), line: line]}
  end

  defp parse_stacktrace_entry(%{"file" => file, "line" => line}) do
    # Minimal format without function
    {:unknown, 0, [file: String.to_charlist(file), line: line]}
  end

  defp parse_stacktrace_entry(_), do: nil
end
