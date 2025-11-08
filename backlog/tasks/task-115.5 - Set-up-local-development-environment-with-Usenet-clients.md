---
id: task-115.5
title: Set up local development environment with Usenet clients
status: Done
assignee:
  - Claude
created_date: '2025-11-08 01:39'
updated_date: '2025-11-08 02:18'
labels: []
dependencies: []
parent_task_id: task-115
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Configure Docker Compose development environment to include SABnzbd and NZBGet containers for local testing and development.

This will allow developers to:
- Test Usenet adapters without needing separate installations
- Validate the full download pipeline locally
- Develop and debug with real client responses
- Run integration tests in CI/CD

**Implementation:**
Add service definitions to `docker-compose.override.yml` (or create example file) with:
- SABnzbd container (LinuxServer.io image recommended)
- NZBGet container (LinuxServer.io image recommended)
- Proper volume mounts for downloads and config
- Pre-configured API keys for testing
- Port mappings (8080 for SABnzbd, 6789 for NZBGet)

**Documentation:**
Update development docs with:
- How to start Usenet clients via `./dev up`
- Default credentials and API keys
- How to access web UIs
- Configuration for testing (test NZB files, mock indexers)
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Docker Compose includes SABnzbd service definition
- [x] #2 Docker Compose includes NZBGet service definition
- [x] #3 Services start successfully with ./dev up
- [x] #4 Web UIs accessible on expected ports
- [x] #5 API authentication configured with test credentials
- [x] #6 Volume mounts preserve config and downloads between restarts
- [x] #7 Documentation explains how to use local Usenet clients
- [x] #8 Example download client configs provided for local testing
- [x] #9 Integration with existing ./dev command wrapper works smoothly
<!-- AC:END -->
