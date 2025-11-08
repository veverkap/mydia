---
id: task-116.5
title: 'Add edition detection and matching (Director''s Cut, Extended, etc.)'
status: To Do
assignee: []
created_date: '2025-11-08 02:18'
labels: []
dependencies: []
parent_task_id: task-116
priority: low
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**Goal**: Properly detect and handle special editions of movies to ensure correct version matching.

**Edition types to support**:
- Director's Cut
- Extended Edition
- Theatrical Release
- Ultimate Edition
- Collector's Edition
- Unrated
- Remastered
- IMAX Edition

**Current problem**: Edition information is not extracted or considered during matching, potentially causing:
- Wrong edition downloads
- Duplicate downloads of different editions
- Confusion when both theatrical and extended versions exist

**Implementation**:
1. **Enhance TorrentParser**: Add edition regex patterns (similar to Radarr)
2. **Update SearchResult schema**: Add edition field
3. **Add edition preferences**: User configuration for preferred editions
4. **Update ReleaseRanker**: Apply bonuses/penalties based on edition preferences
5. **Matching logic**: Consider edition when comparing releases

**Files to modify**:
- `lib/mydia/downloads/torrent_parser.ex` - Extract edition info
- `lib/mydia/indexers/search_result.ex` - Store edition
- `lib/mydia/indexers/release_ranker.ex` - Score based on edition preferences
- `lib/mydia/settings.ex` - Add edition preference configuration
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Edition information is extracted from release names
- [ ] #2 All major edition types are detected correctly
- [ ] #3 Edition preferences can be configured per quality profile
- [ ] #4 Preferred editions receive scoring bonuses
- [ ] #5 Tests cover all supported edition types
- [ ] #6 UI displays edition information in search results
<!-- AC:END -->
