# Cardigann Architecture

This document describes the technical implementation of Cardigann indexer support in Mydia.

## Overview

Cardigann support allows Mydia to directly search torrent indexers using YAML-based definitions, eliminating the need for external Prowlarr or Jackett instances. The implementation integrates with the existing Indexers module architecture.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Interface                           │
│  ┌──────────────────────┐    ┌────────────────────────────────┐ │
│  │  SearchLive          │    │  IndexerLibrary LiveView       │ │
│  │  (Search Page)       │    │  (Cardigann Management UI)     │ │
│  └──────────┬───────────┘    └───────────┬────────────────────┘ │
└─────────────┼──────────────────────────────┼───────────────────┘
              │                               │
              ▼                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Indexers Module                             │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Indexers.search_all(query, opts)                          │ │
│  │    • Searches all enabled indexers in parallel             │ │
│  │    • Deduplicates and ranks results                        │ │
│  │    • Returns combined SearchResult list                    │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │  Prowlarr    │  │  Jackett     │  │  Cardigann Adapter   │  │
│  │  Adapter     │  │  Adapter     │  │  (New)               │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                                 │
                                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Cardigann Components                           │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  CardigannSearchEngine                                    │  │
│  │    • Builds search URLs from definition                   │  │
│  │    • Executes HTTP requests                               │  │
│  │    • Handles authentication                               │  │
│  │    • Respects rate limits                                 │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  CardigannResultParser                                    │  │
│  │    • Parses HTML/JSON responses                           │  │
│  │    • Extracts torrent metadata                            │  │
│  │    • Normalizes to SearchResult structs                   │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  CardigannParser                                          │  │
│  │    • Parses YAML definitions                              │  │
│  │    • Validates definition structure                       │  │
│  │    • Caches parsed definitions                            │  │
│  └──────────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  CardigannAuth                                            │  │
│  │    • Handles login flows                                  │  │
│  │    • Manages cookies                                      │  │
│  │    • Session persistence                                  │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Data Layer                               │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  cardigann_definitions table                              │  │
│  │    • Stores YAML definitions                              │  │
│  │    • User configurations (credentials)                    │  │
│  │    • Enabled/disabled status                              │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Database Schema (`CardigannDefinition`)

**Module**: `Mydia.Indexers.CardigannDefinition`

Stores indexer definitions and user configuration:

```elixir
schema "cardigann_definitions" do
  field :indexer_id, :string        # Unique identifier (e.g., "rarbg", "1337x")
  field :name, :string              # Display name
  field :description, :string       # Indexer description
  field :language, :string          # Primary language
  field :type, :string              # "public", "private", "semi-private"
  field :encoding, :string          # Character encoding
  field :links, {:array, :string}   # Indexer URLs
  field :yaml_content, :string      # Full YAML definition
  field :enabled, :boolean          # User toggle
  field :config, :map               # User credentials (username, password, api_key)
  field :last_used_at, :utc_datetime
  field :synced_at, :utc_datetime   # Last definition update

  timestamps()
end
```

**Key Functions**:
- `toggle_changeset/2` - Enable/disable indexer
- `config_changeset/2` - Update user credentials
- `sync_changeset/2` - Update definition from GitHub

### 2. YAML Parser (`CardigannParser`)

**Module**: `Mydia.Indexers.CardigannParser`

Parses Cardigann YAML definitions into Elixir structs.

**Input**: Raw YAML string
**Output**: `Mydia.Indexers.CardigannDefinition.Parsed` struct

**Key Functions**:
- `parse_definition/1` - Parse YAML to struct
- `validate_definition/1` - Validate required fields
- `extract_capabilities/1` - Extract supported search modes

**Parsed Structure**:
```elixir
%Parsed{
  id: "rarbg",
  name: "RARBG",
  type: "public",
  links: ["https://rarbg.to"],
  capabilities: %{modes: %{"search" => ["q"]}},
  search: %{
    paths: [%{path: "/search", method: "get"}],
    fields: %{
      title: %{selector: "td.title"},
      download: %{selector: "a.download", attribute: "href"},
      size: %{selector: "td.size"},
      seeders: %{selector: "td.seeders"},
      leechers: %{selector: "td.leechers"}
    }
  },
  login: nil | %{path: "/login", method: "post", ...}
}
```

### 3. Search Engine (`CardigannSearchEngine`)

**Module**: `Mydia.Indexers.CardigannSearchEngine`

Executes searches using parsed definitions.

**Key Functions**:
- `execute_search/3` - Perform search and return raw HTTP response
- `build_search_url/3` - Construct search URL from template
- `apply_rate_limiting/1` - Enforce request delays

**Flow**:
1. Build search URL from definition template
2. Apply query parameters (interpolate `{{ .Query }}`)
3. Check rate limit (using `request_delay` from definition)
4. Execute HTTP request with Req
5. Handle redirects and retries
6. Return response body for parsing

**Rate Limiting**:
- Stored in ETS table per indexer_id
- Minimum delay between requests (from definition)
- Automatic retries with exponential backoff

### 4. Result Parser (`CardigannResultParser`)

**Module**: `Mydia.Indexers.CardigannResultParser`

Parses HTML/JSON responses into `SearchResult` structs.

**Key Functions**:
- `parse_results/3` - Main entry point
- `parse_html_results/3` - Parse HTML using selectors
- `parse_json_results/3` - Parse JSON using JSONPath
- `extract_field/3` - Extract field using selector
- `normalize_size/1` - Convert size strings to bytes

**Selector Types**:
- **Element selector**: CSS selector for target element
- **Attribute selector**: Extract attribute value (`attribute: "href"`)
- **Text selector**: Extract text content
- **Regex selector**: Apply regex to extracted value

**Result Transformation**:
```
HTML/JSON Response
  ↓ (selectors from definition)
Raw field values
  ↓ (normalization)
SearchResult struct {
  title: String,
  download_url: String,
  info_hash: String (optional),
  size: Integer (bytes),
  seeders: Integer,
  leechers: Integer,
  quality: Map,
  indexer: String
}
```

### 5. Authentication (`CardigannAuth`)

**Module**: `Mydia.Indexers.CardigannAuth`

Handles authentication for private indexers.

**Supported Methods**:
1. **Login Form**: POST credentials to login endpoint, store cookies
2. **API Key**: Include key in query params or headers
3. **Cookie**: Use pre-provided cookie string

**Key Functions**:
- `perform_login/3` - Execute login flow
- `build_authenticated_request/3` - Add auth to request
- `extract_cookies/1` - Extract cookies from response
- `validate_session/2` - Check if session is still valid

**Cookie Management**:
- Stored per-user, per-indexer
- Automatically refreshed on expiration
- Cached in memory for performance

### 6. Adapter (`Mydia.Indexers.Adapter.Cardigann`)

**Module**: `Mydia.Indexers.Adapter.Cardigann`

Implements the `Mydia.Indexers.Adapter` behaviour to integrate with existing search infrastructure.

**Behaviour Implementation**:
```elixir
@behaviour Mydia.Indexers.Adapter

@impl true
def test_connection(config)  # Validate indexer config

@impl true
def search(config, query, opts)  # Execute search

@impl true
def get_capabilities(config)  # Return categories/modes
```

**Search Pipeline**:
1. Fetch definition from database (by `indexer_id`)
2. Parse YAML definition (cached)
3. Authenticate if needed (private indexer)
4. Execute search via `CardigannSearchEngine`
5. Parse results via `CardigannResultParser`
6. Transform to `SearchResult` structs
7. Apply filters (min_seeders, size limits)
8. Return `{:ok, [%SearchResult{}, ...]}`

**Config Structure**:
```elixir
%{
  type: :cardigann,
  name: "RARBG",
  indexer_id: "rarbg",  # References CardigannDefinition
  enabled: true,
  user_settings: %{
    username: "...",  # For private indexers
    password: "...",
    api_key: "..."
  }
}
```

### 7. GitHub Sync (`Mydia.Indexers.CardigannSync`)

**Module**: `Mydia.Indexers.CardigannSync`

Syncs indexer definitions from Prowlarr's GitHub repository.

**Key Functions**:
- `sync_definitions/0` - Download and import all definitions
- `fetch_definition_list/0` - Get list of available definitions
- `import_definition/1` - Parse and store single definition
- `cleanup_stale_definitions/0` - Remove definitions no longer in repo

**Sync Process**:
1. Fetch index of available definitions from GitHub API
2. Download each YAML file
3. Parse and validate definition
4. Upsert to database (preserving user config and enabled status)
5. Log sync statistics

**Scheduled Sync**:
- Runs daily via Oban background job
- Can be triggered manually from UI
- Only runs if feature flag is enabled

### 8. Feature Flag (`CardigannFeatureFlags`)

**Module**: `Mydia.Indexers.CardigannFeatureFlags`

Controls whether Cardigann features are available.

**Key Functions**:
- `enabled?/0` - Check if Cardigann is enabled

**Configuration**:
```elixir
# config/runtime.exs
config :mydia, :features,
  cardigann_enabled: System.get_env("CARDIGANN_ENABLED", "false") == "true"
```

**Integration Points**:
- Adapter skips search if disabled
- UI components hidden when disabled
- Background sync job skips if disabled
- Redirects users trying to access Cardigann Library

## Integration with Indexers Module

### Search Flow

When `Indexers.search_all/2` is called:

1. **Fetch Enabled Indexers**:
   ```elixir
   # From Settings.list_indexer_configs/0
   # Returns Prowlarr, Jackett, and Cardigann configs
   ```

2. **Parallel Search**:
   ```elixir
   Task.async_stream(indexers, fn config ->
     Indexers.search(config, query, opts)
   end)
   ```

3. **Adapter Dispatch**:
   - Prowlarr config → `Adapter.Prowlarr.search/3`
   - Jackett config → `Adapter.Jackett.search/3`
   - Cardigann config → `Adapter.Cardigann.search/3`

4. **Result Aggregation**:
   ```elixir
   results
   |> Enum.flat_map(fn {:ok, results} -> results end)
   |> deduplicate_by_info_hash()
   |> rank_by_quality_and_seeders()
   |> Enum.take(max_results)
   ```

### How Cardigann Definitions Become Searchable

**Option 1: Direct Adapter Call** (Currently Used):
- Each enabled `CardigannDefinition` is accessed directly by the adapter
- Adapter builds config map on-the-fly during search
- No `IndexerConfig` records created

**Option 2: IndexerConfig Integration** (Future Enhancement):
- Create `IndexerConfig` records for enabled Cardigann definitions
- `type: :cardigann`, `settings: %{indexer_id: "rarbg"}`
- Allows unified management in settings UI
- Enables same health checks and statistics as other indexers

Currently, Cardigann indexers integrate at the adapter level rather than through `IndexerConfig` creation.

## Error Handling

### Search Errors

**Types**:
1. **Definition Errors**: Missing definition, invalid YAML
2. **Network Errors**: Connection refused, timeout
3. **Auth Errors**: Login failed, session expired
4. **Parse Errors**: Invalid HTML/JSON, selector mismatch

**Strategy**:
- All errors return `{:error, %Adapter.Error{}}`
- Errors logged with context (indexer name, query, error type)
- Individual failures don't block other indexers
- UI shows error badges on failed indexers

**Example Error Flow**:
```elixir
{:error, %Adapter.Error{
  type: :auth_failed,
  message: "Login failed: Invalid credentials",
  details: %{indexer_id: "private-tracker"}
}}
```

### Rate Limiting

**Implementation**:
- ETS table stores last request time per indexer
- Before each request, check if enough time has elapsed
- Return ` {:error, :rate_limited}` if too soon
- Retry logic with exponential backoff

**Configuration**:
```yaml
# In definition
settings:
  - name: requestdelay
    type: info
    label: Request Delay (ms)
    default: 2000
```

## Performance Considerations

### Caching

**Parsed Definitions**:
- YAML parsing is expensive
- Cache parsed definitions in memory (future enhancement)
- Invalidate on definition update

**Authentication Sessions**:
- Cookie sessions cached per-user, per-indexer
- Reduces login requests
- Automatic refresh on expiration

### Concurrent Searches

- Searches run in parallel using `Task.async_stream`
- Max concurrency: `System.schedulers_online() * 2`
- Timeout: `:infinity` (individual indexer timeouts via Req)
- Failed tasks don't block other results

### Database Queries

**Indexer Fetching**:
```elixir
# Efficient query for enabled definitions
from d in CardigannDefinition,
  where: d.enabled == true,
  select: d
```

**Avoiding N+1**:
- All enabled definitions fetched in single query
- Preload associations when needed

## Testing Strategy

### Unit Tests

**Modules Tested**:
- `CardigannParserTest` - YAML parsing
- `CardigannSearchEngineTest` - URL building, rate limiting
- `CardigannResultParserTest` - HTML/JSON parsing
- `CardigannAuthTest` - Authentication flows
- `Adapter.CardigannTest` - Adapter interface

**Test Approach**:
- Mock HTTP requests using mocks or fixtures
- Test with real definition samples
- Edge case handling (missing fields, malformed data)

### Integration Tests

**Cardigann Parser Integration Test**:
- Tagged `:external`
- Fetches real definitions from GitHub
- Validates parsing of production definitions
- Runs manually, not in CI

**LiveView Tests**:
- Indexer library UI (`IndexerLibraryTest`)
- Enable/disable functionality
- Configuration modal
- Feature flag behavior

### Real-World Testing

**Test with Popular Indexers**:
- 3-5 public indexers (1337x, RARBG, etc.)
- 1-2 private indexers (if available)
- Verify results match expectations
- Check performance metrics

## Security Considerations

### Credential Storage

**Database Encryption**:
- Private indexer credentials stored in `config` JSONB field
- Should be encrypted at rest (database-level encryption)
- Access controlled by application permissions

**In-Memory Handling**:
- Credentials never logged
- Sensitive fields redacted in error messages
- Cookies stored in secure HTTP-only format

### Network Security

**HTTPS Enforcement**:
- All indexer requests use HTTPS when available
- Certificate validation enabled
- Configurable SSL options per definition

**Request Headers**:
- Custom User-Agent to identify Mydia
- Respect robots.txt (future consideration)
- Rate limiting to prevent abuse

### Input Validation

**User Input**:
- Query strings sanitized before URL interpolation
- SQL injection prevented via Ecto parameterization
- XSS prevented by Phoenix HTML escaping

**Definition Validation**:
- YAML parsing validates structure
- Required fields enforced
- Selector syntax validated

## Future Enhancements

### Performance Optimizations

1. **Definition Caching**: Cache parsed definitions in ETS
2. **Result Streaming**: Stream results as indexers respond
3. **Smart Indexer Selection**: Prefer fast/reliable indexers
4. **Connection Pooling**: Reuse HTTP connections

### Feature Additions

1. **Flaresolverr Support**: Bypass Cloudflare protection
2. **Proxy Support**: Route requests through proxies
3. **Custom Definitions**: Allow users to create/edit definitions
4. **Statistics Dashboard**: Track indexer performance
5. **Health Checks**: Periodic connectivity tests
6. **Indexer Recommendations**: Suggest popular indexers

### Code Quality

1. **Telemetry Events**: Emit events for monitoring
2. **Type Specs**: Add @spec annotations
3. **Documentation**: Expand module docs
4. **Refactoring**: Extract common patterns

## Debugging

### Enable Debug Logging

```elixir
# config/runtime.exs
config :logger, level: :debug
```

### Useful Log Messages

**Search Flow**:
```
[info] Cardigann search started: indexer=rarbg, query="ubuntu"
[debug] Built search URL: https://rarbg.to/search?q=ubuntu
[debug] Cardigann search completed: results=25, time=1234ms
```

**Authentication**:
```
[debug] Performing login for indexer: private-tracker
[info] Login successful, cookies stored
[warning] Session expired, re-authenticating
```

**Errors**:
```
[error] Cardigann search failed: indexer=rarbg, error=connection_refused
[warning] Rate limit exceeded, retry after 2000ms
```

### Interactive Testing

```elixir
# Start IEx
iex -S mix

# Fetch and parse a definition
definition = Mydia.Indexers.get_cardigann_definition!("rarbg")
{:ok, parsed} = Mydia.Indexers.CardigannParser.parse_definition(definition.yaml_content)

# Execute a search
config = %{type: :cardigann, indexer_id: "rarbg", name: "RARBG"}
{:ok, results} = Mydia.Indexers.Adapter.Cardigann.search(config, "ubuntu", [])

# Inspect results
IO.inspect(results, limit: :infinity)
```

## References

- [Prowlarr Indexers Repository](https://github.com/Prowlarr/Indexers) - Source definitions
- [Cardigann Definition Spec](https://github.com/Prowlarr/Prowlarr/wiki/Cardigann-yml-Definition)
- [Mydia Indexers Module](lib/mydia/indexers.ex)
- [User Documentation](CARDIGANN_INDEXERS.md)

## Contributing

When adding Cardigann features:

1. **Update Tests**: Add unit tests for new functionality
2. **Update Docs**: Keep this document in sync with code
3. **Feature Flags**: Use feature flag for experimental features
4. **Error Handling**: Proper error types and logging
5. **Performance**: Consider caching and concurrent execution
6. **Security**: Validate all input, encrypt sensitive data

---

**Last Updated**: 2025-11-16
**Version**: 1.0.0
