---
id: task-12
title: Set up testing infrastructure and write initial tests
status: In Progress
assignee: []
created_date: '2025-11-04 01:52'
updated_date: '2025-11-05 00:00'
labels:
  - testing
  - quality
dependencies:
  - task-4
  - task-7
  - task-11
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Configure test environment with SQLite in-memory database. Write tests for contexts, controllers, and LiveViews. Set up test helpers and factories.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Test database configured (SQLite in-memory)
- [x] #2 ExMachina or similar factory library set up
- [x] #3 Test helpers for common operations
- [ ] #4 Context tests for Media, Accounts, Downloads
- [ ] #5 Controller tests for API endpoints
- [ ] #6 LiveView tests for main pages
- [ ] #7 Test coverage > 70%
- [ ] #8 All tests passing with `mix test`
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Investigation Results

### Current Test Infrastructure
- 608 tests total
- 67 failures (mostly authentication and config-related)
- 11 skipped
- Test infrastructure exists:
  - DataCase for context tests
  - ConnCase for controller tests
  - Media and Downloads fixtures
  - No factory library (ExMachina or similar)

### Main Test Failures
1. **Authentication issues**: LiveView tests failing due to missing authentication setup
2. **Download client health tests**: Configuration/setup issues with client IDs
3. **Compiler warnings**: Several unused variables and inefficient patterns

### Next Steps
1. Add ExMachina for better test data generation
2. Create authentication helpers for LiveView tests
3. Fix download client health test setup
4. Address compiler warnings
5. Measure and improve test coverage
<!-- SECTION:PLAN:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Current Status

**Infrastructure fixes completed:**
- ✅ task-20: Fixed Oban/SQL Sandbox configuration issues
- ✅ Test database appears to be working (SQLite)

**Unclear/Needs verification:**
- Test helpers and factories setup?
- Current test coverage level?
- Which contexts/LiveViews have test coverage?

**Likely remaining work:**
- Set up ExMachina or similar factory library (AC #2)
- Create comprehensive test helpers (AC #3)
- Expand context test coverage (AC #4)
- Add controller/API tests (AC #5)
- Add LiveView tests beyond basics (AC #6)
- Achieve 70%+ coverage (AC #7)

This task needs investigation to determine actual current state vs. desired state.

## Progress Summary (2025-11-04)

### Completed
1. ✅ Added ExMachina 2.8 for better test data generation
2. ✅ Created comprehensive Factory module with factories for:
   - MediaItem (movie and tv_show variants)
   - Episode
   - MediaFile
   - Download
3. ✅ Created AuthHelpers for authentication in tests:
   - create_test_user/1
   - create_admin_user/1
   - log_in_user/2
   - create_user_and_token/1
   - Works with actual Guardian/Accounts modules
4. ✅ Created ConfigHelpers for download client/indexer configuration
5. ✅ Updated DataCase and ConnCase to auto-import helpers
6. ✅ Reduced test failures from 67 to 63

### Remaining Issues

#### Authentication Test Failures (~60 failures)
- LiveView tests using `guardian_default_token` session key
- Should use `guardian_token` to match UserAuth hook expectations
- Tests in: test/mydia_web/live/search_live/add_to_library_test.exs

#### Download Client Health Tests (6 failures)
- Settings.get_download_client_config!/2 doesn't handle binary_id properly
- Function expects integer IDs but schema uses :binary_id (UUIDs)
- Needs fix in lib/mydia/settings.ex:257-285
- ETS table :download_client_health not initialized in test env

#### Test Database Configuration
- `mix precommit` fails with DBConnection.ConnectionPool error
- Test config has correct Sandbox pool setting
- Issue with ./dev test wrapper vs native mix test

### Next Steps
1. Fix Settings module to handle binary IDs
2. Update failing LiveView tests to use correct session key
3. Ensure ETS tables are initialized for tests
4. Add more comprehensive tests for uncovered contexts
5. Measure test coverage with mix test --cover
<!-- SECTION:NOTES:END -->
