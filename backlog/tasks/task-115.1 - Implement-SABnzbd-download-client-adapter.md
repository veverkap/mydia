---
id: task-115.1
title: Implement SABnzbd download client adapter
status: Done
assignee:
  - Claude
created_date: '2025-11-08 01:39'
updated_date: '2025-11-08 02:15'
labels: []
dependencies: []
parent_task_id: task-115
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create the SABnzbd adapter module that implements the `Mydia.Downloads.Client` behavior. SABnzbd is prioritized first as it's the most common Usenet client in media automation stacks and has a simpler REST API compared to NZBGet's RPC protocol.

The adapter will handle:
- Connection testing and authentication via API key
- Adding NZB files from URLs
- Querying download status and progress
- Managing downloads (pause/resume/remove)
- State mapping from SABnzbd states to internal states
- Returning standardized status maps with save_path for media import

**API Details:**
- REST API over HTTP(S)
- Authentication via API key (query parameter)
- Supports JSON response format
- Default port: 8080 (or 9090 for SSL)

**Reference Implementation:**
Study `lib/mydia/downloads/client/qbittorrent.ex` for the adapter pattern and use the shared `Mydia.Downloads.Client.HTTP` module for API calls.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Adapter module created at lib/mydia/downloads/client/sabnzbd.ex
- [x] #2 test_connection/1 validates API key and returns version info
- [x] #3 add_torrent/3 accepts NZB URLs and returns SABnzbd job ID
- [x] #4 get_status/2 returns standardized status_map with all required fields
- [x] #5 list_torrents/2 returns all active downloads from SABnzbd queue
- [x] #6 remove_torrent/3 removes downloads from SABnzbd with optional file deletion
- [x] #7 pause_torrent/2 and resume_torrent/2 control download state
- [x] #8 SABnzbd states correctly mapped to internal states (downloading, paused, completed, error)
- [x] #9 save_path field points to correct download location for media import
- [x] #10 Error handling provides descriptive messages for API failures
<!-- AC:END -->
