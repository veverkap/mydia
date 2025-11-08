---
id: task-116.2
title: Enhance title normalization and implement stricter year matching
status: To Do
assignee: []
created_date: '2025-11-08 02:18'
labels: []
dependencies: []
parent_task_id: task-116
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
**Goal**: Improve title comparison to prevent sequel/prequel/spinoff confusion while maintaining flexibility for legitimate matches.

**Enhancements needed**:
1. **Better normalization**: Handle accents, umlauts (ä→ae, ö→oe, ü→ue), punctuation consistently
2. **Stricter year validation**: 
   - Exact year match: high confidence boost
   - ±1 year: medium confidence
   - >1 year difference: significant penalty (prevent sequels)
   - No year in release: apply cautious threshold
3. **Title suffix detection**: Identify sequel markers (II, 2, Part 2, Reloaded, etc.) and penalize if base title matches but suffix differs
4. **Word boundary matching**: Prevent "Alien" matching "Aliens" by checking word boundaries

**Current state**:
- Jaro-Winkler with basic article removal
- Year matching: +0.3 exact, +0.15 ±1, -0.2 mismatch
- 0.8 confidence threshold

**Improvement targets**:
- Reduce false positives for sequels/prequels
- Maintain high recall for legitimate matches
- Configurable thresholds per use case
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Title normalization handles accents and umlauts correctly
- [ ] #2 Year difference >1 results in match rejection for similar titles
- [ ] #3 Sequel markers (II, 2, Part 2, etc.) are detected and penalized appropriately
- [ ] #4 Word boundary checks prevent 'Alien' matching 'Aliens'
- [ ] #5 Legitimate variations (e.g., 'The Movie' vs 'Movie, The') still match
- [ ] #6 Tests cover edge cases: sequels, prequels, spin-offs, anthology series
<!-- AC:END -->
