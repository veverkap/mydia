# Mydia - Modern Media Management Platform

## Vision

Mydia is a unified, self-hosted media management platform that replaces the fragmented \*arr stack (Radarr, Sonarr, Bazarr) with a single, cohesive application. Built with modern technology and designed for the self-hosting community, Mydia provides flexible media organization, automated acquisition, and seamless integration with existing media infrastructure.

## Quick Start

Get Mydia running in under 5 minutes:

```bash
docker run -d \
  --name mydia \
  -p 4000:4000 \
  -e SECRET_KEY_BASE=$(openssl rand -base64 48) \
  -v mydia_data:/data \
  -v /path/to/movies:/media/movies \
  mydia:latest
```

That's it! No database to configure, no multi-container setup. Access at http://localhost:4000

## Problem Statement

Current media management solutions have several limitations:

- **Fragmentation**: Separate applications for movies, TV shows, and subtitles create complexity
- **Rigid Storage**: Limited support for multiple versions/qualities of the same media
- **Configuration Overhead**: Each service requires separate configuration and maintenance
- **Authentication Gaps**: Inconsistent or missing SSO/OIDC support across services
- **Resource Usage**: Multiple services consume more resources than necessary

## Key Features

### Unified Media Management

- **Single Platform**: Manage movies, TV shows, and subtitles from one application
- **Unified Search**: Search across all indexers and trackers simultaneously
- **Consistent UX**: One interface, one authentication system, one configuration

### Flexible Media Storage

- **Multi-Version Support**: Store multiple versions of the same media (4K, 1080p, HDR variants)
- **Quality Profiles**: Define preferred qualities with fallback options
- **Custom Organization**: Flexible file naming and folder structure
- **Version Metadata**: Track codec, resolution, bitrate, HDR type, audio tracks per version

### Modern Self-Hosting

- **Zero-Config Database**: SQLite embedded - no separate database container needed
- **OIDC/SSO Integration**: Native support for Authentik, Keycloak, Auth0, etc.
- **Docker-First**: Single container deployment with persistent volumes
- **Simple Configuration**: Single YAML file or environment variables only
- **Multi-User**: Role-based access control (admin, user, read-only)
- **Reverse Proxy Friendly**: Works behind Traefik, Caddy, nginx
- **Easy Backups**: Database is a single file - copy to backup

### Automation & Intelligence

- **Smart Upgrading**: Automatically replace media when better versions are available
- **Custom Rules**: Complex logic for what to download/keep (e.g., "keep 1080p until 4K HDR10+ available")
- **Indexer Aggregation**: Support for Jackett, Prowlarr, or direct indexer integration
- **Webhook Support**: Notify other services on media events

### Developer Experience

- **REST API**: Complete API for automation and integrations
- **GraphQL Support**: Efficient querying for complex data relationships
- **Real-time Updates**: WebSocket support for live status updates
- **Extensibility**: Plugin system for custom downloaders and post-processors

## Target Users

### Primary

- Self-hosting enthusiasts managing personal media libraries
- Users of the existing \*arr stack seeking consolidation
- Privacy-conscious users wanting full control over their media

### Secondary

- Small communities sharing media libraries
- Content creators managing their own productions
- Digital archivists preserving media collections

## Comparison to Existing Solutions

| Feature               | Radarr/Sonarr      | Bazarr             | Mydia                 |
| --------------------- | ------------------ | ------------------ | --------------------- |
| Unified Platform      | ❌ Separate apps   | ❌ Separate        | ✅ Single app         |
| Multi-Version Storage | ⚠️ Limited         | N/A                | ✅ Full support       |
| Database Setup        | ⚠️ Requires config | ⚠️ Requires config | ✅ Zero-config SQLite |
| Container Count       | ⚠️ 3+ containers   | ⚠️ Separate        | ✅ Single container   |
| OIDC Support          | ❌ No              | ❌ No              | ✅ Native             |
| Config Method         | UI + files         | UI + files         | ✅ Code-as-config     |
| Backup Simplicity     | ⚠️ Complex         | ⚠️ Complex         | ✅ Single file copy   |
| Modern Tech Stack     | ❌ .NET old        | ❌ Python          | ✅ Phoenix/Elixir     |
| Resource Usage        | ⚠️ 3+ processes    | ⚠️ Separate        | ✅ Single process     |
| Real-time Updates     | ⚠️ Polling         | ⚠️ Polling         | ✅ WebSockets         |

## Use Cases

### Personal Media Server

"I want to automatically download and organize my movie and TV show collection, storing both 1080p versions for streaming and 4K versions for local playback."

### Multi-User Household

"My family uses different authentication for all our services. I want everyone to log in with our Authentik server and have different permission levels."

### Quality Enthusiast

"I want to keep multiple versions: theatrical and extended cuts, different HDR formats (HDR10, HDR10+, Dolby Vision), and different audio tracks (Atmos, DTS-HD)."

### Upgrader

"I started with 720p content years ago. I want to automatically replace with 1080p when available, then with 4K HDR, but keep the old versions until the new ones are verified."

### Automation Power User

"I want to define complex rules like 'download 1080p immediately, but only download 4K if it has Dolby Vision AND Atmos audio AND is under 40GB'."

## Success Metrics

- Time to set up first media download < 15 minutes
- Single application replaces 3+ existing services
- Memory usage < combined \*arr stack
- User satisfaction score > 8/10
- Active community contributions

## Roadmap

### Phase 1: MVP (v0.1)

- Basic movie and TV show management
- Manual search and download
- OIDC authentication
- Docker deployment
- File-based configuration

### Phase 2: Automation (v0.5)

- Automatic searching and downloading
- Indexer integration (Jackett/Prowlarr)
- Quality profiles and upgrading
- Webhook notifications

### Phase 3: Advanced Features (v1.0)

- Multi-version support
- Subtitle management
- Custom rules engine
- GraphQL API
- Plugin system

### Phase 4: Enhanced UX (v1.5+)

- Mobile app
- Streaming preview
- Collection management
- Advanced statistics and insights
- Community feature requests
