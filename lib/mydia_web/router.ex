defmodule MydiaWeb.Router do
  use MydiaWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {MydiaWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Authentication pipeline - verifies JWT tokens from session or header
  pipeline :auth do
    plug MydiaWeb.Plugs.AuthPipeline
  end

  # Require authenticated user
  pipeline :require_authenticated do
    plug MydiaWeb.Plugs.EnsureAuthenticated
  end

  # Require admin role
  pipeline :require_admin do
    plug MydiaWeb.Plugs.EnsureRole, :admin
  end

  # API authentication pipeline - supports both JWT and API keys
  pipeline :api_auth do
    plug MydiaWeb.Plugs.AuthPipeline
    plug MydiaWeb.Plugs.ApiAuth
  end

  # Authentication routes
  scope "/auth", MydiaWeb do
    pipe_through :browser

    # Local authentication (development only)
    get "/login", SessionController, :new
    get "/local/login", SessionController, :new
    post "/local/login", SessionController, :create

    # OIDC authentication
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
    post "/:provider/callback", AuthController, :callback

    # Logout
    get "/logout", AuthController, :logout
  end

  scope "/", MydiaWeb do
    pipe_through [:browser, :auth]

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", MydiaWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard in development
  if Application.compile_env(:mydia, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: MydiaWeb.Telemetry
    end
  end
end
