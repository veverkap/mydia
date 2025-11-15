defmodule MetadataRelay.Application do
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    # Determine cache adapter based on REDIS_URL environment variable
    {cache_adapter, cache_opts} = configure_cache()

    # Store the selected adapter in application env
    Application.put_env(:metadata_relay, :cache_adapter, cache_adapter)

    children = [
      # Database repository
      MetadataRelay.Repo,
      # PubSub for Phoenix LiveView
      {Phoenix.PubSub, name: MetadataRelay.PubSub},
      # Cache adapter (Redis or in-memory)
      {cache_adapter, cache_opts},
      # Rate limiter for crash reports
      MetadataRelay.RateLimiter,
      # TVDB authentication GenServer
      MetadataRelay.TVDB.Auth,
      # Phoenix endpoint (serves both API and ErrorTracker dashboard)
      MetadataRelayWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: MetadataRelay.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp configure_cache do
    case System.get_env("REDIS_URL") do
      nil ->
        Logger.info("REDIS_URL not set, using in-memory cache")
        {MetadataRelay.Cache.InMemory, []}

      redis_url ->
        Logger.info("REDIS_URL detected, attempting to connect to Redis")

        case parse_redis_url(redis_url) do
          {:ok, opts} ->
            {MetadataRelay.Cache.Redis, opts}

          {:error, reason} ->
            Logger.warning(
              "Failed to parse REDIS_URL: #{inspect(reason)}, falling back to in-memory cache"
            )

            {MetadataRelay.Cache.InMemory, []}
        end
    end
  end

  defp parse_redis_url(url) do
    uri = URI.parse(url)

    case uri do
      %URI{scheme: scheme, host: host, port: port} when scheme in ["redis", "rediss"] ->
        opts = [
          host: host || "localhost",
          port: port || 6379
        ]

        opts =
          if uri.userinfo do
            # Redis URLs can have format redis://[:password@]host:port
            case String.split(uri.userinfo, ":", parts: 2) do
              [password] -> Keyword.put(opts, :password, password)
              [_username, password] -> Keyword.put(opts, :password, password)
            end
          else
            opts
          end

        {:ok, opts}

      _ ->
        {:error, :invalid_redis_url}
    end
  end
end
