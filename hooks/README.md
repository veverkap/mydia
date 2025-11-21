# Hooks Directory

This directory contains user-defined hooks that execute at various application lifecycle events.

## Quick Start

Create a new hook by adding a Lua script to an event directory:

```bash
mkdir -p hooks/after_media_added
cat > hooks/after_media_added/01_my_hook.lua <<'EOF'
function execute(event_data)
  local media = event_data.data.media_item

  log.info("New media added: " .. media.title)

  return {
    modified = false,
    message = "Hook executed successfully"
  }
end

return execute(event)
EOF
```

## Available Events

Hooks are organized by event name in subdirectories:

- **`after_media_added/`** - After a movie or TV show is added to the library
- **`on_download_completed/`** - When a download finishes successfully
- **`on_download_failed/`** - When a download fails
- **`before_automatic_search/`** - Before automatic background search executes
- **`after_automatic_search/`** - After automatic search completes

More events will be added in future releases.

## Hook Priority

Hooks execute in alphabetical order. Use numeric prefixes to control execution order:

- `01_first.lua` - Executes first
- `02_second.lua` - Executes second
- `99_last.lua` - Executes last

## Hook Structure

Every hook must return a result table:

```lua
function execute(event_data)
  -- Access event data
  local media = event_data.data.media_item

  -- Your logic here

  -- Return result
  return {
    modified = false,  -- Set to true if you made changes
    changes = {},      -- Optional: changes to apply
    message = "Done"   -- Optional: log message
  }
end

return execute(event)
```

## Available Data

### `after_media_added` Event

```lua
event_data = {
  event = "after_media_added",
  timestamp = "2025-01-01T00:00:00Z",
  data = {
    media_item = {
      id = 123,
      type = "tv_show",  -- or "movie"
      title = "Attack on Titan",
      tmdb_id = 1429,
      year = 2013,
      monitored = true,
      metadata = { ... }
    }
  }
}
```

## Helper Functions

Hooks have access to built-in helper functions:

### Logging

```lua
log.info("Information message")
log.warn("Warning message")
log.error("Error message")
```

## Examples

See `after_media_added/01_example_anime_settings.lua` for a complete example.

## Reloading Hooks

Hooks are loaded when the application starts. To reload hooks:

```bash
# Development
./dev mix phx.server

# Production (Docker)
docker-compose restart mydia
```

## Troubleshooting

### Hooks Not Loading

1. Check hooks are enabled in `config.yaml`
2. Verify file has `.lua` extension
3. Check application logs for errors
4. Ensure hook syntax is valid Lua

### Hook Errors

If a hook fails:

- The error is logged but doesn't stop the application
- Other hooks continue to execute
- Check application logs for details

## Documentation

For complete documentation, see:

- `HOOKS_SYSTEM_DESIGN.md` - Architecture and technical details
- `HOOKS_DOCKER_CONFIG.md` - Docker deployment guide
- Module docs: `lib/mydia/hooks.ex`
