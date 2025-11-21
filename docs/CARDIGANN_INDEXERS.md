# Cardigann Indexers

Mydia includes built-in support for Cardigann indexer definitions, allowing you to search hundreds of torrent indexers without setting up external services like Prowlarr or Jackett.

## What are Cardigann Indexers?

Cardigann is a YAML-based definition format that describes how to search torrent indexers. Each definition includes:

- Search endpoints and parameters
- HTML/JSON parsing rules for results
- Authentication methods for private indexers
- Rate limiting and retry policies

Mydia uses the same indexer definitions as Prowlarr, giving you access to 500+ indexers out of the box.

## Benefits

- **No External Dependencies**: Search indexers directly without running Prowlarr or Jackett
- **500+ Indexers**: Support for hundreds of public and private torrent sites
- **Automatic Updates**: Indexer definitions sync automatically from the Prowlarr repository
- **Works Alongside Prowlarr/Jackett**: You can use Cardigann indexers together with existing Prowlarr/Jackett instances
- **User Control**: Enable only the indexers you want to use

## Enabling Cardigann Support

Cardigann indexers are controlled by a feature flag. To enable:

**Via Environment Variable:**

```bash
CARDIGANN_ENABLED=true
```

**Via Application Configuration:**

```yaml
features:
  cardigann_enabled: true
```

Once enabled, you'll see a "Cardigann Library" link in the Indexers settings page.

## Using Cardigann Indexers

### Browsing Available Indexers

1. Navigate to **Settings → Indexers → Cardigann Library**
2. Browse the list of available indexer definitions
3. Use filters to narrow down:
   - **Type**: Public, Private, or Semi-Private
   - **Language**: Filter by indexer language
   - **Status**: Show only enabled or disabled indexers
4. Search by indexer name or description

### Enabling Public Indexers

Public indexers require no configuration - just toggle them on:

1. Find the indexer in the library
2. Click the toggle switch to enable it
3. The indexer will immediately be available for searches

### Configuring Private Indexers

Private indexers require authentication credentials:

1. Find the private indexer in the library
2. Click the **Configure** button
3. Enter your credentials:
   - **Username & Password**: For login-based authentication
   - **API Key**: For API-key based authentication
   - **Cookie**: For cookie-based authentication (advanced)
4. Click **Test Connection** to verify your credentials
5. Click **Save** to store your configuration
6. Enable the indexer using the toggle switch

**Note**: Credentials are stored securely in the database.

### Syncing Indexer Definitions

Indexer definitions are automatically synced daily from the [Prowlarr Indexers repository](https://github.com/Prowlarr/Indexers).

To manually trigger a sync:

1. Go to **Settings → Indexers → Cardigann Library**
2. Click the **Sync Definitions** button
3. Wait for the sync to complete

The sync process:

- Downloads the latest definitions from GitHub
- Updates existing definitions
- Adds new indexers
- Preserves your configuration and enabled status

## Searching with Cardigann Indexers

Once enabled, Cardigann indexers work exactly like Prowlarr or Jackett indexers:

1. Navigate to the **Search** page
2. Enter your search query
3. Results from all enabled indexers (Prowlarr, Jackett, and Cardigann) will appear together
4. Results are automatically deduplicated and ranked

### Search Performance

- Searches run concurrently across all enabled indexers
- Rate limits are respected per indexer
- Failed indexers don't block results from other indexers
- Each indexer's response time is tracked in the logs

## Mixing Cardigann with Prowlarr/Jackett

You can use Cardigann indexers alongside traditional Prowlarr or Jackett instances:

- All three types appear in the same search results
- Results are deduplicated based on info hash
- Each indexer type can be managed independently

This is useful when:

- You have a Prowlarr instance for some indexers but want direct access to others
- You're migrating from Prowlarr/Jackett to native Cardigann support
- Different indexers work better through different methods

## Rate Limiting

Each Cardigann indexer definition includes rate limiting rules to prevent overwhelming indexer sites:

- **Request Delay**: Minimum time between requests to the same indexer
- **Retry Logic**: Automatic retries with exponential backoff for failed requests
- **Concurrent Limits**: Maximum number of simultaneous searches

These limits are enforced automatically and cannot be overridden.

## Troubleshooting

### Indexer Not Appearing in Search Results

**Check if the indexer is enabled:**

1. Go to Cardigann Library
2. Verify the indexer toggle is ON
3. Check the status indicator (green = working, red = error)

**For private indexers, verify credentials:**

1. Click Configure on the indexer
2. Click Test Connection
3. Fix any authentication errors

### Search Results Missing from Specific Indexer

**Check the logs:**

```bash
docker-compose logs -f mydia
```

Look for messages like:

- `Cardigann search failed` - Authentication or parsing error
- `Rate limit exceeded` - Too many requests
- `HTTP 404/503` - Indexer temporarily down

**Common issues:**

- Private indexer credentials expired
- Indexer site is down or blocking requests
- Indexer definition needs updating (run Sync Definitions)

### Private Indexer Authentication Failing

**Login-based authentication:**

- Verify username and password are correct
- Check if the indexer requires captcha (not supported)
- Some indexers require you to log in via browser first

**API key authentication:**

- Copy the API key exactly from the indexer's settings page
- Check if the key has expired
- Verify the key has search permissions

**Cookie authentication:**

- Export cookies using a browser extension
- Cookie format varies by indexer (check definition for details)
- Cookies may expire frequently

### Definition Sync Failing

**Check GitHub connectivity:**

- Verify Mydia can reach github.com
- Check if you're behind a proxy or firewall
- Review logs for network errors

**Manual workaround:**

1. Download definitions from https://github.com/Prowlarr/Indexers
2. Contact Mydia administrator to import manually (future feature)

## Feature Flag

The Cardigann feature can be disabled at any time:

**When disabled:**

- Cardigann Library link is hidden from navigation
- Cardigann indexers are excluded from searches
- Existing definitions and configurations are preserved
- No automatic syncing occurs

**When re-enabled:**

- All previous settings are restored
- Syncing resumes
- Indexers become searchable again

This allows administrators to control whether users can access this feature.

## Privacy & Security

**Data Storage:**

- Indexer definitions: Stored in the local database
- Private indexer credentials: Encrypted in the database
- Search queries: Not logged by Mydia (may be logged by indexers)
- Cookies and sessions: Stored per-user, per-indexer

**Network Requests:**

- Mydia connects directly to indexer websites
- No data is sent to Mydia servers
- GitHub API is used only for definition syncing

**Credentials:**

- Private indexer credentials are your responsibility
- Use strong, unique passwords for private indexers
- Enable 2FA on indexer sites when possible
- Review which indexers you enable and share credentials with

## Best Practices

1. **Start with Public Indexers**: Test Cardigann with a few public indexers before configuring private ones
2. **Enable Selectively**: Don't enable all 500+ indexers - choose quality over quantity (10-20 good indexers is plenty)
3. **Monitor Performance**: Check search times and disable slow or unreliable indexers
4. **Keep Definitions Updated**: Run manual syncs occasionally to get bug fixes
5. **Respect Rate Limits**: Don't try to bypass rate limiting - it protects both you and the indexer
6. **Test Connections**: After configuring private indexers, always test the connection before enabling

## Comparison with Prowlarr/Jackett

| Feature            | Cardigann    | Prowlarr                  | Jackett                   |
| ------------------ | ------------ | ------------------------- | ------------------------- |
| External Service   | ❌ No        | ✅ Required               | ✅ Required               |
| Configuration      | In Mydia     | Separate UI               | Separate UI               |
| Indexers Available | 500+         | 500+                      | 500+                      |
| Auto-Updates       | ✅ Yes       | ✅ Yes                    | ✅ Yes                    |
| Private Indexers   | ✅ Yes       | ✅ Yes                    | ✅ Yes                    |
| Resource Usage     | Low (in-app) | Medium (separate service) | Medium (separate service) |
| Management         | Mydia UI     | Prowlarr UI               | Jackett UI                |

**When to use Cardigann:**

- You want fewer moving parts in your setup
- You're starting fresh with Mydia
- You prefer managing everything in one place

**When to use Prowlarr/Jackett:**

- You already have a working Prowlarr/Jackett setup
- You use Prowlarr/Jackett with other arr applications
- You need advanced Prowlarr-specific features (Flaresolverr, proxies, etc.)

**Best of both:**

- Use Prowlarr for indexers that need special handling
- Use Cardigann for simple public indexers
- Both types work together seamlessly in Mydia

## Further Reading

- [Prowlarr Indexers Repository](https://github.com/Prowlarr/Indexers) - Source of indexer definitions
- [Cardigann Definition Format](https://github.com/Prowlarr/Prowlarr/wiki/Cardigann-yml-Definition) - Technical specification
- Developer documentation: `docs/CARDIGANN_ARCHITECTURE.md` (for developers)

## Support

If you encounter issues with Cardigann indexers:

1. Check this documentation first
2. Review the application logs for error messages
3. Test the indexer in a web browser to rule out site issues
4. Report bugs on the Mydia GitHub repository with:
   - Indexer name and type (public/private)
   - Error messages from logs
   - Steps to reproduce

For indexer-specific issues (site down, definition broken), check the [Prowlarr Indexers repository](https://github.com/Prowlarr/Indexers/issues) for known issues.
