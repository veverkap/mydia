---
id: task-116.4
title: Implement ID-based matching from indexer responses
status: In Progress
assignee:
  - Claude
created_date: '2025-11-08 02:18'
updated_date: '2025-11-08 02:27'
labels: []
dependencies: []
parent_task_id: task-116
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**Goal**: Use TMDB/IMDB IDs from indexer responses as the primary matching method, falling back to title matching only when IDs are unavailable.

**Radarr approach**: Indexers report TMDB/IMDB IDs with search results. If the ID matches, download is approved regardless of title variations. This is the most reliable matching method.

**Implementation**:
1. **Update SearchResult schema**: Add optional tmdb_id and imdb_id fields
2. **Modify indexer adapters**: Extract IDs from Torznab responses (newznab:attr[@name="tmdbid"], newznab:attr[@name="imdbid"])
3. **Update TorrentMatcher logic**:
   - If result has TMDB/IMDB ID matching library item: Immediate match (high confidence)
   - If no ID or ID mismatch: Fall back to title-based matching
   - Log ID mismatches for debugging
4. **Add configuration**: Option to require ID matching (strict mode) or allow fallback

**Files to modify**:
- `lib/mydia/indexers/search_result.ex` - Add ID fields
- `lib/mydia/indexers/torznab_adapter.ex` - Parse ID attributes
- `lib/mydia/downloads/torrent_matcher.ex` - Implement ID matching logic
- Database migration for search_results table
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 SearchResult schema includes tmdb_id and imdb_id fields
- [ ] #2 Torznab adapter extracts IDs from newznab:attr elements
- [ ] #3 ID-based matches have 0.98+ confidence score
- [ ] #4 ID mismatches are logged with details for debugging
- [ ] #5 Fallback to title matching works when IDs unavailable
- [ ] #6 Strict mode configuration prevents downloads without ID match
- [ ] #7 Tests cover ID match, ID mismatch, and no-ID scenarios
<!-- AC:END -->
