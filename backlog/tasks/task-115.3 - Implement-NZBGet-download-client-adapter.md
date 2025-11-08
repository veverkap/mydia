---
id: task-115.3
title: Implement NZBGet download client adapter
status: Done
assignee:
  - Claude
created_date: '2025-11-08 01:39'
updated_date: '2025-11-08 02:16'
labels: []
dependencies:
  - task-115.1
parent_task_id: task-115
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create the NZBGet adapter module as an alternative Usenet client option. NZBGet is lighter weight and more performant than SABnzbd, making it popular for NAS and resource-constrained environments.

The adapter will handle:
- JSON-RPC or XML-RPC protocol communication
- HTTP Basic Auth authentication
- Adding NZB files via the `append` RPC method
- Querying download status via `listgroups` method
- Managing downloads (pause/resume/remove via RPC)
- State mapping from NZBGet states to internal states

**API Details:**
- Uses JSON-RPC protocol (POST requests)
- Authentication via HTTP Basic Auth (username:password)
- Single endpoint: `http://username:password@host:port/jsonrpc`
- Default port: 6789
- All methods use positional parameters (order matters)

**Implementation Note:**
NZBGet is implemented after SABnzbd to validate the adapter pattern works correctly and to reuse learnings from the SABnzbd implementation.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Adapter module created at lib/mydia/downloads/client/nzbget.ex
- [x] #2 test_connection/1 calls version RPC method and validates auth
- [x] #3 add_torrent/3 calls append RPC method with NZB URL
- [x] #4 get_status/2 calls listgroups and returns standardized status_map
- [x] #5 list_torrents/2 returns all active downloads from NZBGet
- [x] #6 remove_torrent/3 calls appropriate RPC method to delete downloads
- [x] #7 pause_torrent/2 and resume_torrent/2 use RPC pause/resume methods
- [x] #8 NZBGet states correctly mapped to internal states
- [x] #9 HTTP Basic Auth handled correctly in all requests
- [x] #10 save_path extracted from NZBGet response for media import
<!-- AC:END -->
