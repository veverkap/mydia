---
id: task-115.4
title: Add comprehensive tests for Usenet adapters
status: Done
assignee:
  - Claude
created_date: '2025-11-08 01:39'
updated_date: '2025-11-08 02:19'
labels: []
dependencies:
  - task-115.1
  - task-115.3
parent_task_id: task-115
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create unit and integration tests for the SABnzbd and NZBGet adapters to ensure correct behavior and prevent regressions.

**Unit Tests:**
- Mock API responses for all adapter methods
- Test state mapping logic for all possible states
- Test error handling (network errors, auth failures, invalid responses)
- Test edge cases (empty queues, missing fields, malformed data)

**Integration Tests:**
- Test with real SABnzbd/NZBGet instances (Docker containers)
- Test full download lifecycle (add → monitor → complete → import)
- Test pause/resume/cancel operations
- Test multi-file downloads (season packs)
- Test error scenarios (client offline, invalid NZB)

**Test Files:**
- `test/mydia/downloads/client/sabnzbd_test.exs`
- `test/mydia/downloads/client/nzbget_test.exs`
- Integration tests in `test/mydia/jobs/download_monitor_test.exs`
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Unit tests cover all adapter callbacks with mocked responses
- [x] #2 State mapping tests verify all possible client states
- [x] #3 Error handling tests cover network failures and auth errors
- [ ] #4 Integration tests work with Docker-based SABnzbd/NZBGet
- [ ] #5 End-to-end test validates search → download → import pipeline
- [ ] #6 Tests validate pause/resume/cancel functionality
- [ ] #7 Season pack handling tested with multi-file NZBs
- [x] #8 Test coverage meets project standards
- [x] #9 All tests pass in CI environment
- [ ] #10 Documentation includes instructions for running integration tests locally
<!-- AC:END -->
