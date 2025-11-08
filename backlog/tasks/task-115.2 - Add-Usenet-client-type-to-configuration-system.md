---
id: task-115.2
title: Add Usenet client type to configuration system
status: Done
assignee:
  - Claude
created_date: '2025-11-08 01:39'
updated_date: '2025-11-08 02:14'
labels: []
dependencies: []
parent_task_id: task-115
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Update the download client configuration schema and UI to support Usenet clients (SABnzbd and NZBGet) as valid client types.

This involves:
- Adding `:sabnzbd` and `:nzbget` to the client type enum
- Ensuring the configuration form handles Usenet-specific fields (API key, URL base)
- Updating the client selection logic to work with Usenet clients
- Registering the Usenet adapters in the client registry

**Files to Modify:**
- `lib/mydia/settings/download_client_config.ex` - Add types to enum
- `lib/mydia/downloads.ex` - Register adapters in `register_clients/0`

The existing configuration schema already supports all needed fields (host, port, api_key, url_base, use_ssl), so no schema changes are required.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Client type enum includes :sabnzbd and :nzbget values
- [x] #2 Configuration form allows creating SABnzbd/NZBGet clients
- [x] #3 SABnzbd and NZBGet adapters registered in client registry
- [x] #4 Client selection logic includes Usenet clients when prioritizing
- [x] #5 Configuration test connection works for Usenet clients
- [x] #6 Existing torrent client configurations remain unaffected
<!-- AC:END -->
