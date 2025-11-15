# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Automatic Database Backups**: Database backups are now automatically created before running migrations on container startup
  - Timestamped backup files stored alongside the database (e.g., `mydia_prod_backup_20251115_143022.db`)
  - Automatic cleanup keeps the 10 most recent backups
  - Backup integrity verification before proceeding with migrations
  - Can be disabled with `SKIP_BACKUPS=true` environment variable (not recommended)

- **Library Path Update Validation**: Added validation when updating library paths via the Admin UI
  - Samples up to 10 media files to verify accessibility at new location
  - Prevents path updates that would break file references
  - User-friendly error messages with file counts and guidance
  - Audit logging for path update operations

### Changed

- **Relative Path Storage for Media Files** (Breaking Change - Automatic Migration):
  - Media files now store paths relative to their library root instead of absolute paths
  - Enables flexible library relocation without breaking file references
  - Database becomes portable across different mount points
  - **Migration is automatic and transparent** on first startup after upgrade
  - All existing media files are migrated from absolute to relative paths during first boot
  - Stream playback and import functionality automatically resolve relative paths to absolute paths on-demand

  **What this means for users:**
  - ✅ **No action required** - migration happens automatically
  - ✅ Can now change library paths (e.g., `/mnt/old/movies` → `/mnt/new/movies`) without re-importing files
  - ✅ Database backups are portable across different systems
  - ✅ Zero downtime - existing functionality continues to work
  - ⚠️ **Important**: Ensure you have sufficient disk space for database backup before upgrading

### Technical Details

#### Migration Process

The relative path migration follows this process:

1. **Pre-Migration Backup**: Automatic database backup created before any changes
2. **Library Path Sync**: Runtime library paths (from environment variables) are synced to database
3. **Path Calculation**: For each media file, calculate relative path from its library root
4. **Foreign Key Assignment**: Link each file to its corresponding library path record
5. **Validation**: Verify all files have valid relative paths and library references
6. **Cleanup**: Remove old automatic backups (keep last 10)

#### Affected Components

- **Schema Changes** (Phase 1):
  - Added `library_path_id` foreign key to `media_files` table
  - Added `relative_path` column to `media_files` table
  - Migration: `20251115001234_add_relative_path_to_media_files.exs`

- **Data Migration** (Phase 2):
  - Migration: `20251115002345_populate_media_file_relative_paths.exs`
  - Syncs runtime library paths to database
  - Populates relative paths for all existing files

- **Code Changes** (Phases 3-6):
  - `MediaFile` schema updated with path resolution functions
  - Import job stores relative paths for new files
  - Stream controller resolves paths at playback time
  - Library scanner uses relative paths

- **Safety Features** (Phases 7-8):
  - Path update validation prevents broken references
  - Comprehensive test coverage (31 tests)
  - Migration validation scripts
  - Performance benchmarks (within 10% of baseline)

- **Backup System** (Phase 10):
  - Automatic backups on container startup if migrations pending
  - Mix task: `mix mydia.backup_before_migrate`
  - Integrated into `docker-entrypoint.sh`

#### Rollback Procedure

If issues occur after upgrade, you can roll back:

1. Stop the container: `docker compose down`
2. Restore from backup: `cp /config/mydia_*_backup_*.db /config/mydia.db`
3. Downgrade image: Update `docker-compose.yml` to previous version tag
4. Restart: `docker compose up -d`

See [docs/deployment/DEPLOYMENT.md](docs/deployment/DEPLOYMENT.md) for detailed rollback instructions.

### Fixed

- Improved error handling during library path updates
- Enhanced validation for media file imports

### Security

- Database backups are created with secure permissions matching the database file

## Previous Releases

_(Release history to be documented as versions are published)_
