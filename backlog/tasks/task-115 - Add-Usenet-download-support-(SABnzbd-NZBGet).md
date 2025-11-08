---
id: task-115
title: Add Usenet download support (SABnzbd/NZBGet)
status: Done
assignee:
  - Claude
created_date: '2025-11-08 01:38'
updated_date: '2025-11-08 02:20'
labels: []
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Enable Usenet as a download protocol alongside existing torrent support. This will allow users to download media from Usenet indexers using SABnzbd or NZBGet clients.

The application already uses a protocol-agnostic adapter pattern for download clients, making Usenet integration clean. The architecture analysis shows that search jobs, download monitoring, media import, and configuration UI are all client-agnostic and will work automatically once the Usenet adapter is implemented.

**Key Benefits:**
- Faster download speeds (maxes out bandwidth unlike P2P)
- Better privacy (encrypted, no peer IP exposure)
- Long retention periods (6,200+ days)
- No seeding required
- Works with existing indexers (Prowlarr/Jackett already return NZB URLs)

**Architecture Overview:**
The system uses a behavior pattern (`Mydia.Downloads.Client`) with pluggable implementations. Adding Usenet requires creating a new adapter that implements the 7 required callbacks and registering it in the client registry.

**Documentation:**
Comprehensive architecture analysis and implementation guides have been created:
- `USENET_SUPPORT_README.md` - Navigation and overview
- `USENET_ARCHITECTURE_ANALYSIS.md` - Complete architectural deep-dive
- `USENET_QUICK_REFERENCE.md` - Implementation guide with code examples
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Users can configure SABnzbd or NZBGet clients in the download client settings
- [x] #2 Usenet downloads can be initiated from search results (NZB URLs)
- [x] #3 Download monitoring shows real-time status for Usenet downloads
- [x] #4 Completed Usenet downloads are automatically imported to the media library
- [x] #5 Files from Usenet downloads support hardlink/move/copy operations
- [x] #6 Usenet download state is properly mapped (downloading, paused, completed, failed)
- [x] #7 Multi-file NZB downloads (season packs, etc.) are handled correctly
- [x] #8 Download queue UI displays Usenet downloads with accurate progress
- [x] #9 Users can pause, resume, and cancel Usenet downloads
- [x] #10 Error handling provides clear feedback when Usenet client is unavailable
<!-- AC:END -->
