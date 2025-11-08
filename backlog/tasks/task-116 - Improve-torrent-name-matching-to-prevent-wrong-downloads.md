---
id: task-116
title: Improve torrent name matching to prevent wrong downloads
status: In Progress
assignee:
  - Claude
created_date: '2025-11-08 02:17'
updated_date: '2025-11-08 02:27'
labels: []
dependencies: []
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**Problem**: Current torrent matching can incorrectly match similar titles, causing wrong downloads (e.g., "The Matrix Reloaded" being downloaded for "The Matrix", sequels matching originals, etc.).

**Current State**:
- Uses Jaro-Winkler distance (0.8 threshold) with basic normalization
- Movie matching: 70% title + 30% year weighting
- Title normalization removes articles and special chars
- No ID-based matching from indexers
- No alternative/AKA title support
- Limited validation of release quality

**Research Findings** (Radarr/Sonarr approach):
1. **ID-based matching**: Primary method using TMDB/IMDB IDs from indexer responses
2. **Sophisticated parsing**: Multiple regex patterns for different formats, editions, anime
3. **Alternative titles**: Support for AKA/localized titles from TMDB
4. **Custom formats**: Negative scoring to filter unwanted patterns
5. **Release validation**: Reject hashed/invalid releases
6. **Edition handling**: Detect and match "Director's Cut", "Extended", etc.
7. **Year validation**: Stricter matching to prevent sequel/prequel confusion

**Goal**: Implement a robust multi-layered matching system that significantly reduces false positives while maintaining high recall for valid matches.

**Impact**: Users will no longer experience wrong downloads, saving bandwidth and improving automation reliability.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Test case: Searching for 'The Matrix' (1999) does not match 'The Matrix Reloaded' (2003)
- [ ] #2 Test case: Searching for 'Alien' (1979) does not match 'Aliens' (1986) or other sequels
- [ ] #3 Test case: Alternative/AKA titles from TMDB are matched correctly
- [ ] #4 Test case: Hashed/invalid release names are rejected
- [ ] #5 Test case: Edition variants (Director's Cut, Extended) are detected and matched appropriately
- [ ] #6 Test case: Indexer responses with TMDB/IMDB IDs are prioritized over title-only matching
- [ ] #7 All existing torrent matcher tests continue to pass
- [ ] #8 Documentation updated with new matching algorithm details
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Implementation Approach

### Phase-Based Implementation

**Phase 1: Foundation (High Priority)**
1. Task 116.4 - ID-based matching (most reliable method, highest impact)
2. Task 116.1 - Release validation (pre-filtering to reduce noise)

**Phase 2: Core Improvements (High Priority)**
3. Task 116.2 - Enhanced title normalization and year matching

**Phase 3: Extended Matching (Medium Priority)**
4. Task 116.3 - Alternative/AKA title support
5. Task 116.6 - Negative scoring/filtering

**Phase 4: Advanced Features (Low Priority)**
6. Task 116.5 - Edition detection and matching

### Key Architecture Decisions

1. **ID-based matching is primary**: When TMDB/IMDB IDs are available, they override title matching
2. **Layered validation**: Release validation → ID matching → Title matching → Scoring
3. **Backward compatible**: All changes are additive, existing functionality preserved
4. **Independent subtasks**: Each can be deployed separately

### Testing Strategy

- Dedicated test files per subtask
- Integration tests for parent task acceptance criteria
- Ensure all existing tests continue passing
- Test with real-world torrent names (Matrix/Matrix Reloaded, Alien/Aliens, etc.)
<!-- SECTION:PLAN:END -->
