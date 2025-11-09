---
id: task-138
title: Fix Docker PUID/PGID startup error - groupmod GID already exists
status: Done
assignee: []
created_date: '2025-11-09 21:12'
updated_date: '2025-11-09 21:25'
labels:
  - bug
  - docker
  - devops
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Users cannot start the container with custom PUID/PGID environment variables. The entrypoint script fails with "groupmod: GID '100' already exists" error when trying to update the mydia user UID:GID.

The error occurs in the Docker entrypoint when attempting to set PUID=99 and PGID=100, indicating that GID 100 is already in use by another group in the container.

Related: https://github.com/getmydia/mydia/issues/5
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Container starts successfully with custom PUID/PGID environment variables
- [x] #2 No groupmod or usermod errors in container logs
- [x] #3 Entrypoint script handles existing GID/UID conflicts gracefully
- [x] #4 File permissions are correctly applied with custom UID/GID
- [x] #5 Documentation updated with PUID/PGID usage examples
<!-- AC:END -->
