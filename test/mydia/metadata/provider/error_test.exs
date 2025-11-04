defmodule Mydia.Metadata.Provider.ErrorTest do
  use ExUnit.Case, async: true

  alias Mydia.Metadata.Provider.Error

  describe "new/3" do
    test "creates error with type and message" do
      error = Error.new(:connection_failed, "Connection refused")

      assert error.type == :connection_failed
      assert error.message == "Connection refused"
      assert error.details == nil
    end

    test "creates error with details" do
      error = Error.new(:api_error, "Bad request", %{status: 400, body: "Invalid query"})

      assert error.type == :api_error
      assert error.message == "Bad request"
      assert error.details == %{status: 400, body: "Invalid query"}
    end
  end

  describe "convenience constructors" do
    test "connection_failed/2" do
      error = Error.connection_failed("Connection refused")

      assert error.type == :connection_failed
      assert error.message == "Connection refused"
    end

    test "authentication_failed/2" do
      error = Error.authentication_failed("Invalid API key")

      assert error.type == :authentication_failed
      assert error.message == "Invalid API key"
    end

    test "timeout/2" do
      error = Error.timeout("Request timed out after 30s")

      assert error.type == :timeout
      assert error.message == "Request timed out after 30s"
    end

    test "not_found/2" do
      error = Error.not_found("Media not found")

      assert error.type == :not_found
      assert error.message == "Media not found"
    end

    test "rate_limited/2" do
      error = Error.rate_limited("Rate limit exceeded", %{retry_after: 60})

      assert error.type == :rate_limited
      assert error.message == "Rate limit exceeded"
      assert error.details == %{retry_after: 60}
    end

    test "invalid_request/2" do
      error = Error.invalid_request("Missing required parameter")

      assert error.type == :invalid_request
      assert error.message == "Missing required parameter"
    end

    test "invalid_config/2" do
      error = Error.invalid_config("Missing API key")

      assert error.type == :invalid_config
      assert error.message == "Missing API key"
    end

    test "api_error/2" do
      error = Error.api_error("Bad request", %{status: 400})

      assert error.type == :api_error
      assert error.message == "Bad request"
      assert error.details == %{status: 400}
    end

    test "network_error/2" do
      error = Error.network_error("DNS resolution failed")

      assert error.type == :network_error
      assert error.message == "DNS resolution failed"
    end

    test "parse_error/2" do
      error = Error.parse_error("Invalid JSON")

      assert error.type == :parse_error
      assert error.message == "Invalid JSON"
    end

    test "unknown/2" do
      error = Error.unknown("Unexpected error")

      assert error.type == :unknown
      assert error.message == "Unexpected error"
    end
  end

  describe "from_req_error/1" do
    test "converts connection refused transport error" do
      req_error = %Req.TransportError{reason: :econnrefused}
      error = Error.from_req_error(req_error)

      assert error.type == :connection_failed
      assert error.message == "Connection refused"
    end

    test "converts timeout transport error" do
      req_error = %Req.TransportError{reason: :timeout}
      error = Error.from_req_error(req_error)

      assert error.type == :timeout
      assert error.message == "Request timed out"
    end

    test "converts DNS resolution error" do
      req_error = %Req.TransportError{reason: :nxdomain}
      error = Error.from_req_error(req_error)

      assert error.type == :network_error
      assert error.message == "DNS resolution failed"
    end

    test "converts 401 response to authentication failed" do
      response = %Req.Response{status: 401, body: %{"error" => "Unauthorized"}}
      error = Error.from_req_error(response)

      assert error.type == :authentication_failed
      assert error.message =~ "401"
      assert error.details.status == 401
    end

    test "converts 403 response to authentication failed" do
      response = %Req.Response{status: 403, body: %{"error" => "Forbidden"}}
      error = Error.from_req_error(response)

      assert error.type == :authentication_failed
      assert error.message =~ "403"
      assert error.details.status == 403
    end

    test "converts 404 response to not found" do
      response = %Req.Response{status: 404, body: %{}}
      error = Error.from_req_error(response)

      assert error.type == :not_found
      assert error.message =~ "404"
      assert error.details.status == 404
    end

    test "converts 429 response to rate limited" do
      response = %Req.Response{status: 429, body: %{}, headers: [{"retry-after", ["60"]}]}
      error = Error.from_req_error(response)

      assert error.type == :rate_limited
      assert error.message =~ "429"
      assert error.details.status == 429
      assert error.details.retry_after == 60
    end

    test "extracts error message from response body" do
      response = %Req.Response{
        status: 401,
        body: %{"status_message" => "Invalid API key"}
      }

      error = Error.from_req_error(response)

      assert error.message =~ "Invalid API key"
    end

    test "converts other 4xx/5xx responses to api_error" do
      response = %Req.Response{status: 500, body: %{"error" => "Internal Server Error"}}
      error = Error.from_req_error(response)

      assert error.type == :api_error
      assert error.message =~ "500"
      assert error.details.status == 500
    end

    test "converts unknown errors to unknown type" do
      error = Error.from_req_error(:some_random_error)

      assert error.type == :unknown
      assert error.message =~ "Unexpected error"
    end
  end

  describe "message/1" do
    test "formats error message with type label" do
      error = Error.connection_failed("Connection refused")
      message = Error.message(error)

      assert message == "Connection failed: Connection refused"
    end

    test "formats multi-word error types" do
      error = Error.rate_limited("Too many requests")
      message = Error.message(error)

      assert message == "Rate limited: Too many requests"
    end
  end

  describe "exception behaviour" do
    test "can be raised as an exception" do
      assert_raise Error, "Connection failed: Connection refused", fn ->
        raise Error.connection_failed("Connection refused")
      end
    end

    test "exception/1 with keyword list" do
      error =
        Error.exception(
          type: :api_error,
          message: "Bad request",
          details: %{status: 400}
        )

      assert error.type == :api_error
      assert error.message == "Bad request"
      assert error.details == %{status: 400}
    end

    test "exception/1 with string" do
      error = Error.exception("Something went wrong")

      assert error.type == :unknown
      assert error.message == "Something went wrong"
    end
  end
end
