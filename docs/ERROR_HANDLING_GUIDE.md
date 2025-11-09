# Error Handling and Logging Guide

This guide covers the error handling and logging patterns implemented in Mydia to improve debugging, user experience, and system observability.

## Table of Contents

1. [Overview](#overview)
2. [Structured Logging](#structured-logging)
3. [Error Boundaries](#error-boundaries)
4. [LiveView Error Handling](#liveview-error-handling)
5. [Debug Mode](#debug-mode)
6. [Best Practices](#best-practices)

## Overview

Mydia implements comprehensive error handling and logging to:

- **Improve debugging**: Structured logs with metadata make it easier to diagnose issues
- **Enhance user experience**: Clear, actionable error messages instead of generic failures
- **Enable monitoring**: Structured data for error tracking and alerting
- **Graceful degradation**: Error boundaries prevent complete page failures

## Structured Logging

### Using Mydia.Logger

The `Mydia.Logger` module provides structured logging with metadata:

```elixir
require Logger
alias Mydia.Logger, as: MydiaLogger

# Log an error with context
MydiaLogger.log_error(:liveview, "Failed to save quality profile",
  error: changeset,
  operation: :save_quality_profile,
  user_id: socket.assigns.current_user.id,
  profile_name: params["name"]
)

# Log a warning
MydiaLogger.log_warning(:liveview, "Attempted to delete profile in use",
  operation: :delete_quality_profile,
  profile_id: id
)

# Debug logging (only when debug mode is enabled)
MydiaLogger.debug("Processing search results", count: length(results))
```

### Log Categories

Use appropriate categories for different types of operations:

- `:liveview` - LiveView operations and user interactions
- `:download` - Download client operations
- `:metadata` - Metadata fetching and processing
- `:indexer` - Indexer operations
- `:job` - Background job execution
- `:auth` - Authentication and authorization

### Metadata Keys

Include relevant metadata to aid debugging:

- `operation`: The operation being performed (e.g., `:save_quality_profile`)
- `user_id`: The user performing the action
- `error`: The error object (changeset, exception, etc.)
- `stacktrace`: Stack trace for exceptions (logged separately in debug mode)
- Context-specific keys: IDs, names, types, etc.

### User-Friendly Error Messages

Use `user_error_message/2` to create actionable error messages for users:

```elixir
error_msg = MydiaLogger.user_error_message(:save_quality_profile, changeset)
put_flash(socket, :error, error_msg)
```

This sanitizes technical errors and provides specific guidance to users.

## Error Boundaries

### Using Error Boundary Components

Wrap potentially failing sections of your LiveView with error boundaries:

```heex
<.error_boundary
  id="quality-profiles-section"
  error={@quality_profiles_error}
  title="Failed to load quality profiles"
  show_retry={true}
  retry_event="retry_load_profiles"
>
  <div :for={profile <- @quality_profiles}>
    <%= profile.name %>
  </div>
</.error_boundary>
```

### Initialize Error State

In your LiveView `mount/3`:

```elixir
def mount(_params, _session, socket) do
  {:ok,
   socket
   |> assign(:quality_profiles_error, nil)
   |> assign(:quality_profiles, [])}
end
```

### Handle Errors

Update the error state when operations fail:

```elixir
def handle_event("load_profiles", _, socket) do
  try do
    profiles = Settings.list_quality_profiles()
    {:noreply, assign(socket, quality_profiles: profiles, quality_profiles_error: nil)}
  rescue
    error ->
      MydiaLogger.log_error(:liveview, "Failed to load quality profiles",
        error: error,
        stacktrace: __STACKTRACE__
      )
      {:noreply, assign(socket, quality_profiles_error: Exception.message(error))}
  end
end
```

### Inline Error Fallback

For smaller sections, use `error_fallback`:

```heex
<.error_fallback error={@form_error}>
  <.form for={@form} phx-submit="save">
    <%!-- form fields --%>
  </.form>
</.error_fallback>
```

## LiveView Error Handling

### Using ErrorHandler Helper

The `MydiaWeb.Live.ErrorHandler` module simplifies error handling:

```elixir
alias MydiaWeb.Live.ErrorHandler

# Simple operation
socket = ErrorHandler.handle_operation(socket, :load_profiles, fn ->
  Settings.list_quality_profiles()
end)

# With success/error handlers
socket = ErrorHandler.handle_operation(
  socket,
  :save_profile,
  fn -> Settings.create_quality_profile(params) end,
  success: fn socket, profile ->
    socket
    |> put_flash(:info, "Profile saved successfully")
    |> assign(:quality_profile, profile)
  end,
  error: fn socket, error ->
    socket
    |> put_flash(:error, "Failed to save profile")
    |> assign(:quality_profile_error, error)
  end
)

# With error boundary assign
socket = ErrorHandler.handle_operation(
  socket,
  :load_data,
  fn -> fetch_data() end,
  error_assign: :data_error
)
```

### Safe Data Fetching

For operations that might fail during mount or async loading:

```elixir
case ErrorHandler.safe_fetch(:load_profiles, fn ->
  Settings.list_quality_profiles()
end, user_id: current_user.id) do
  {:ok, profiles} ->
    assign(socket, :quality_profiles, profiles)

  {:error, reason} ->
    assign(socket, quality_profiles_error: reason, quality_profiles: [])
end
```

## Debug Mode

### Enabling Debug Mode

Set environment variables to enable verbose logging:

```bash
# Enable debug mode
export MYDIA_DEBUG=true

# Or set log level
export LOG_LEVEL=debug
```

### In Development

The development environment automatically uses these environment variables. In `dev.exs`:

```elixir
log_level =
  cond do
    System.get_env("MYDIA_DEBUG") == "true" -> :debug
    System.get_env("LOG_LEVEL") == "debug" -> :debug
    true -> :info
  end

config :logger, level: log_level
```

### In Production

Set `LOG_LEVEL` in your production environment:

```bash
# In production
export LOG_LEVEL=info  # or debug for troubleshooting
```

### Debug Logging

Debug logs only appear when debug mode is enabled:

```elixir
MydiaLogger.debug("Processing batch", size: batch_size, user_id: user_id)
```

### Stack Traces

Stack traces are automatically logged in debug mode:

```elixir
MydiaLogger.log_error(:liveview, "Operation failed",
  error: error,
  stacktrace: __STACKTRACE__,  # Only logged in debug mode
  operation: :save_item
)
```

## Best Practices

### 1. Always Log Errors

Every error case should have a corresponding log entry:

```elixir
case Settings.delete_profile(profile) do
  {:ok, _} ->
    # Success path
    {:noreply, put_flash(socket, :info, "Deleted successfully")}

  {:error, error} ->
    # Log the error
    MydiaLogger.log_error(:liveview, "Failed to delete profile",
      error: error,
      profile_id: profile.id,
      user_id: socket.assigns.current_user.id
    )

    # Show user-friendly message
    error_msg = MydiaLogger.user_error_message(:delete_quality_profile, error)
    {:noreply, put_flash(socket, :error, error_msg)}
end
```

### 2. Include Context in Logs

Always include relevant context to make debugging easier:

```elixir
# Bad: No context
MydiaLogger.log_error(:liveview, "Save failed", error: error)

# Good: Rich context
MydiaLogger.log_error(:liveview, "Failed to save quality profile",
  error: error,
  operation: :save_quality_profile,
  user_id: user_id,
  profile_name: params["name"],
  qualities: params["qualities"]
)
```

### 3. Use Specific Error Messages

Provide actionable guidance to users:

```elixir
# Bad: Generic message
put_flash(socket, :error, "Failed to update")

# Good: Specific and actionable
put_flash(socket, :error, "Failed to update setting: Name must be at least 3 characters")

# Best: Use the helper
error_msg = MydiaLogger.user_error_message(:update_setting, changeset)
put_flash(socket, :error, error_msg)
```

### 4. Wrap Dangerous Operations

Use error boundaries or error handlers for operations that might fail:

```elixir
# In mount for async data loading
socket = ErrorHandler.handle_operation(
  socket,
  :load_initial_data,
  fn -> load_data() end,
  error_assign: :data_error
)
```

### 5. Never Expose Sensitive Information

Don't include sensitive data in logs or user-facing errors:

```elixir
# Bad: Exposes credentials
MydiaLogger.log_error(:download, "Connection failed",
  password: client.password  # DON'T DO THIS
)

# Good: Only non-sensitive info
MydiaLogger.log_error(:download, "Connection failed",
  client_type: client.type,
  host: client.host,
  use_ssl: client.use_ssl
)
```

### 6. Test Error Paths

Write tests for error handling:

```elixir
test "shows user-friendly error when profile name is invalid", %{conn: conn} do
  {:ok, view, _html} = live(conn, ~p"/admin/config?tab=quality_profiles")

  view
  |> element("button", "New Profile")
  |> render_click()

  result =
    view
    |> form("#quality-profile-form", quality_profile: %{name: ""})
    |> render_submit()

  assert result =~ "Name can&#39;t be blank"
end
```

### 7. Monitor Logs in Production

Use structured logging for monitoring and alerting:

- Set up log aggregation (e.g., Elasticsearch, CloudWatch)
- Create alerts for error patterns
- Monitor error rates and trends
- Use the metadata for filtering and searching

## Examples from the Codebase

See these files for implementation examples:

- `lib/mydia_web/live/admin_config_live/index.ex` - Comprehensive error handling in LiveView
- `lib/mydia/logger.ex` - Structured logging utilities
- `lib/mydia_web/components/error_boundary.ex` - Error boundary component
- `lib/mydia_web/live/error_handler.ex` - LiveView error handling helpers

## Environment Variables Reference

| Variable | Values | Default | Description |
|----------|--------|---------|-------------|
| `MYDIA_DEBUG` | `true`, `false` | `false` | Enable debug mode with verbose logging |
| `LOG_LEVEL` | `debug`, `info`, `warning`, `error` | `info` | Set logger level |

## Related

- [Phoenix LiveView Error Handling](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#module-error-handling)
- [Elixir Logger Documentation](https://hexdocs.pm/logger/Logger.html)
- [CLAUDE.md Development Guidelines](../CLAUDE.md) - Project development standards
