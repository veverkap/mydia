# Production Deployment Guide

This guide covers advanced deployment topics for Mydia. For basic deployment instructions, see the [Production Deployment](../../README.md#-production-deployment) section in the main README.

## Quick Reference

**Basic deployment steps:**
1. See [README.md](../../README.md#-production-deployment) for quick start with Docker Compose or Docker Run
2. Review the [Environment Variables Reference](../../README.md#-environment-variables-reference) for all configuration options
3. Return to this guide for advanced topics below

## Installation Options

### Option 1: Pre-built Images (Recommended)

Pull the latest pre-built image from GitHub Container Registry:

```bash
docker pull ghcr.io/getmydia/mydia:latest
```

Or pull a specific version:

```bash
docker pull ghcr.io/getmydia/mydia:v1.0.0
```

### Option 2: Build from Source

Build the image locally from the repository:

```bash
docker build -t mydia:latest -f Dockerfile .
```

## Configuration Options

### Using Environment Files (Optional)

While the README shows inline configuration, you can optionally use a `.env` file:

1. Create a `.env.prod` file with your configuration:

```bash
# Container configuration (LinuxServer.io standards)
PUID=1000
PGID=1000
TZ=America/New_York

# Required secrets (generate with: openssl rand -base64 48)
SECRET_KEY_BASE=your-secret-key-base-here
GUARDIAN_SECRET_KEY=your-guardian-secret-key-here

# Server configuration
PHX_HOST=mydia.example.com
PORT=4000
DATABASE_PATH=/config/mydia.db

# Media paths
MOVIES_PATH=/media/movies
TV_PATH=/media/tv

# Optional: OIDC authentication
OIDC_DISCOVERY_DOCUMENT_URI=https://auth.example.com/.well-known/openid-configuration
OIDC_CLIENT_ID=your-client-id
OIDC_CLIENT_SECRET=your-client-secret
```

2. Reference it in your docker-compose.yml:

```yaml
services:
  mydia:
    image: ghcr.io/getmydia/mydia:latest
    env_file: .env.prod
    # ... rest of configuration
```

Or with Docker Run:

```bash
docker run -d \
  --name mydia \
  --env-file .env.prod \
  -v /path/to/mydia/config:/config \
  -v /path/to/movies:/media/movies \
  -v /path/to/tv:/media/tv \
  ghcr.io/getmydia/mydia:latest
```

See the [Environment Variables Reference](../../README.md#-environment-variables-reference) for all available options.

## Health Check

The application includes a health check endpoint at `/health` that returns JSON:

```bash
curl http://localhost:4000/health
```

Response:
```json
{
  "status": "ok",
  "service": "mydia",
  "timestamp": "2025-11-05T00:00:00Z"
}
```

## Advanced Configuration

For a complete list of all configuration options, see the [Environment Variables Reference](../../README.md#-environment-variables-reference) in the README.

Advanced topics include:
- Download client integration (qBittorrent, Transmission)
- Indexer configuration (Prowlarr, Jackett)
- Database performance tuning
- Background job configuration
- Custom logging levels

## Volumes

The production setup uses the following volumes:

- `mydia_data` - Application data and SQLite database
- Media directories - Mount your existing media library directories

### Network Mounts (NFS/SMB)

Mydia supports NFS and SMB network mounts. Ensure your mount has proper permissions for the container's UID/GID (default 1000, configurable via `PUID`/`PGID`).

**NFS Export Example** (`/etc/exports` on NFS server):
```bash
/path/to/media  192.168.1.0/24(rw,all_squash,anonuid=1000,anongid=1000)
```

**Docker Compose with Host Mount**:
```yaml
services:
  mydia:
    volumes:
      - /mnt/nfs/movies:/media/movies
      - /mnt/smb/tv:/media/tv
```

**Troubleshooting**: If you get permission errors, verify the mount's UID/GID matches your `PUID`/`PGID` settings.

## Ports

- `4000` - HTTP port for the web interface

## First Run

On first startup, the application will:
1. Run database migrations
2. Create default quality profiles
3. Start the web server on port 4000

## Troubleshooting

### Container won't start

Check the logs:
```bash
docker logs mydia
```

### Health check failing

Ensure the application is listening on the correct port:
```bash
docker exec mydia curl -f http://localhost:4000/health
```

### Database permission issues

Ensure the data volume has correct permissions:
```bash
docker exec mydia ls -la /data
```

## Database Backups

Mydia automatically creates database backups before running migrations to protect your data:

### Automatic Backups

- **When**: Automatically created before applying any pending migrations
- **Location**: Stored alongside the database file (e.g., `/config/mydia_dev_backup_YYYYMMDD_HHMMSS.db`)
- **Format**: Timestamped filename `mydia_<env>_backup_YYYYMMDD_HHMMSS.db`
- **Retention**: Last 10 backups are kept, older backups are automatically cleaned up
- **Validation**: Backup integrity is verified before proceeding with migrations

### Manual Backups

Create a manual backup before major changes:

```bash
# Stop the container
docker compose down

# Copy the database file
cp /path/to/config/mydia.db /path/to/backups/mydia_manual_backup_$(date +%Y%m%d_%H%M%S).db

# Restart the container
docker compose up -d
```

### Disabling Automatic Backups

While not recommended, you can disable automatic backups:

```yaml
environment:
  - SKIP_BACKUPS=true
```

**Warning**: Only disable backups if you have your own backup strategy in place.

## Upgrading

To upgrade to a new version:

1. Pull the new image
2. Stop the current container
3. Start a new container with the new image
4. Automatic database backup is created (if migrations are pending)
5. Migrations run automatically on startup

### With Docker Compose

```bash
docker compose pull
docker compose down
docker compose up -d
```

### With Docker Run

```bash
docker pull ghcr.io/getmydia/mydia:latest
docker stop mydia && docker rm mydia
# Re-run your docker run command
```

To upgrade to a specific version, specify the version tag:

```bash
docker pull ghcr.io/getmydia/mydia:v1.0.0
# Update your docker-compose.yml or docker run command to use the specific version
```

### Upgrade Safety

- **Automatic Backups**: A timestamped backup is created before migrations run
- **Backup Location**: Check `/config/mydia_*_backup_*.db` for backup files
- **Verification**: The system verifies backup integrity before proceeding
- **Logging**: Watch startup logs to see backup creation and migration progress

Example startup logs:
```
[info] Checking for pending migrations...
[info] Found 2 pending migrations, creating database backup...
[info] Created backup: /config/mydia_prod_backup_20251115_143022.db
[info] Backup verification successful
[info] Running migrations...
[info] Migration completed successfully
```

### Rollback Procedure

If an upgrade causes issues, you can roll back to the previous version:

**Option 1: Roll back to previous image (recommended)**

```bash
# Stop the container
docker compose down

# Restore from automatic backup
cp /path/to/config/mydia_prod_backup_20251115_143022.db /path/to/config/mydia.db

# Update docker-compose.yml to use previous version
# image: ghcr.io/getmydia/mydia:v1.0.0  # previous version

# Start the container
docker compose up -d
```

**Option 2: Use a specific backup**

If you need to restore from a specific backup:

```bash
# Stop the container
docker compose down

# List available backups
ls -lh /path/to/config/mydia_*_backup_*.db

# Restore chosen backup
cp /path/to/config/mydia_prod_backup_20251114_120000.db /path/to/config/mydia.db

# Start the container with the appropriate image version
docker compose up -d
```

**Important Notes:**
- Always restore a backup that matches the version you're rolling back to
- Automatic backups are timestamped - use the most recent one before the upgrade
- Keep at least 2-3 manual backups before major version upgrades
- Test the rollback procedure in a non-production environment first

## Release Process

Mydia uses automated CI/CD to build and publish Docker images.

### For Maintainers: Creating a Release

To create a new release:

1. Update version numbers if needed (in mix.exs, etc.)
2. Commit all changes
3. Create and push a version tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

4. GitHub Actions will automatically:
   - Build multi-platform Docker images (amd64, arm64)
   - Tag the image with the version number and 'latest'
   - Publish to GitHub Container Registry
   - Generate build attestation for supply chain security

5. Monitor the workflow at: https://github.com/getmydia/mydia/actions

### Available Image Tags

Images are published to `ghcr.io/getmydia/mydia` with the following tags:

- `latest` - Most recent stable release
- `v1.0.0` - Specific version (full semver)
- `v1.0` - Minor version (receives patch updates)
- `v1` - Major version (receives minor and patch updates)

### Image Platforms

All images support multiple platforms:
- `linux/amd64` - Standard x86_64 systems
- `linux/arm64` - ARM64 systems (e.g., Apple Silicon, Raspberry Pi 4+)
