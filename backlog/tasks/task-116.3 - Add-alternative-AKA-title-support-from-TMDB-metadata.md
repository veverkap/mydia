---
id: task-116.3
title: Add alternative/AKA title support from TMDB metadata
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
**Goal**: Support matching releases that use alternative titles, localized names, or AKA titles from TMDB.

**Problem**: Movies often have different titles in different regions or multiple official names. Releases may use any of these variants.

**Examples**:
- "Edge of Tomorrow" / "Live Die Repeat"
- "The Matrix" / "黑客帝国" (Chinese title)
- "Leon: The Professional" / "The Professional" / "Leon"

**Implementation**:
1. Fetch alternative titles from TMDB when importing movies
2. Store alternative titles in movie metadata
3. Update TorrentMatcher to check against all title variants
4. Prioritize primary title matches over alternative titles

**Files to modify**:
- `lib/mydia/metadata/provider/tmdb.ex` - Fetch alternative titles
- Database migration to add alternative_titles field
- `lib/mydia/downloads/torrent_matcher.ex` - Check all title variants
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Alternative titles are fetched from TMDB during movie import
- [ ] #2 Database stores alternative titles as JSON array
- [ ] #3 Matcher checks both primary and alternative titles
- [ ] #4 Primary title matches score higher than alternative title matches
- [ ] #5 Tests include movies with known alternative titles
- [ ] #6 Migration handles existing movies without breaking data
<!-- AC:END -->
