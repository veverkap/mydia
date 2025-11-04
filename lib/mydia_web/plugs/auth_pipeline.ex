defmodule MydiaWeb.Plugs.AuthPipeline do
  @moduledoc """
  Guardian pipeline for JWT authentication.

  This pipeline verifies JWT tokens from either:
  1. Session (browser authentication)
  2. Authorization header (API authentication)
  """
  use Guardian.Plug.Pipeline,
    otp_app: :mydia,
    module: Mydia.Auth.Guardian,
    error_handler: Mydia.Auth.ErrorHandler

  plug Guardian.Plug.VerifySession, claims: %{"typ" => "access"}
  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}, scheme: "Bearer"
  plug Guardian.Plug.LoadResource, allow_blank: true
end
