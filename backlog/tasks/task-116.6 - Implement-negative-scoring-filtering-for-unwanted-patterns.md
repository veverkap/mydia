---
id: task-116.6
title: Implement negative scoring/filtering for unwanted patterns
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
**Goal**: Add a flexible filtering system to reject or deprioritize releases matching unwanted patterns, similar to Radarr's Custom Formats.

**Use cases**:
- Block known bad release groups
- Avoid specific codecs (e.g., xvid)
- Filter out CAM/TS/HDCAM qualities
- Reject releases with ads/watermarks
- Block releases with specific keywords

**Implementation approach**:
1. **Define filter patterns**: Create configurable filter rules with:
   - Pattern (regex or keyword)
   - Score adjustment (negative for unwanted)
   - Action (reject completely vs penalize)
2. **Add to configuration**: Allow users to define custom filters
3. **Apply during ranking**: ReleaseRanker evaluates filters before scoring
4. **Preset filters**: Include common patterns (CAM, TS, hardcoded subs, etc.)

**Scoring logic**:
- Cumulative score must exceed minimum threshold
- Negative scores can outweigh positive qualities
- Rejection score (e.g., -10000) immediately disqualifies release

**Files to modify**:
- Create `lib/mydia/indexers/release_filter.ex` - New filtering module
- `lib/mydia/indexers/release_ranker.ex` - Integrate filtering
- `lib/mydia/settings.ex` - Add filter configuration
- Database migration for storing filter rules
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Custom filter rules can be defined with regex patterns and scores
- [ ] #2 Filters are applied during release ranking
- [ ] #3 Releases below minimum score threshold are rejected
- [ ] #4 Preset filters block common unwanted patterns (CAM, TS, ads)
- [ ] #5 Filter matches are logged for debugging
- [ ] #6 Tests verify filter logic and score calculations
- [ ] #7 UI allows managing filter rules
<!-- AC:END -->
