---
id: task-116.1
title: Add release validation to reject invalid/hashed torrents
status: To Do
assignee: []
created_date: '2025-11-08 02:18'
labels: []
dependencies: []
parent_task_id: task-116
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**Goal**: Implement pre-filtering to reject invalid releases before attempting matching, similar to Radarr's Parser validation.

**Invalid patterns to detect**:
- Hashed releases (32/24-char hex strings in brackets)
- Titles with only numbers (no alphanumeric content)
- Password-protected yenc releases
- Reversed title formats (p027, p0801 patterns)
- Releases with zero meaningful content

**Implementation approach**:
- Add `ReleaseValidator` module with rejection rules
- Integrate into TorrentParser before parsing logic
- Add validation to search result processing pipeline

**Files to modify**:
- `lib/mydia/downloads/torrent_parser.ex` - Add validation step
- Create `lib/mydia/downloads/release_validator.ex` - New validation module
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Hashed release names like '[A1B2C3D4E5F6...]' are rejected
- [ ] #2 Releases with only numeric titles are rejected
- [ ] #3 Password-protected releases are rejected
- [ ] #4 Reversed title patterns are detected and rejected
- [ ] #5 Valid releases continue to pass validation
- [ ] #6 Tests cover all rejection patterns
<!-- AC:END -->
