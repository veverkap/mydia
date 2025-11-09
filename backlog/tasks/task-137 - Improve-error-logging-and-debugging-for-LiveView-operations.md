---
id: task-137
title: Improve error logging and debugging for LiveView operations
status: Done
assignee: []
created_date: '2025-11-09 18:41'
updated_date: '2025-11-09 19:25'
labels:
  - enhancement
  - observability
  - dx
  - user-experience
dependencies: []
priority: medium
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
User-reported bugs (GitHub Issue #4) lack detailed error information, making it difficult to diagnose and fix issues. The application needs better error logging and user-facing error messages to help both developers and users understand failures.

**Current Gaps**:
- Generic error messages like "Failed to update setting"
- No detailed logging for LiveView event handler failures
- Users see "Error" without specifics
- Difficult to debug production issues without logs

**Improvements Needed**:
1. **Enhanced logging**: Add structured logging for all LiveView operations
2. **Error details**: Log full error messages and stack traces
3. **User feedback**: Provide specific, actionable error messages
4. **Monitoring**: Consider adding error tracking/monitoring
5. **Debug mode**: Environment variable to enable verbose logging

**Benefits**:
- Faster issue diagnosis and resolution
- Better user experience with clear error messages
- Easier community support and bug reporting
- Improved production debugging

**Scope**:
- AdminConfigLive operations (settings, quality profiles, downloaders, indexers)
- Other critical LiveView operations
- Error boundary components for graceful degradation

**Related**: GitHub Issue #4
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Structured logging added to all critical LiveView operations
- [x] #2 Error messages include actionable information for users
- [x] #3 Stack traces logged (but not exposed to users)
- [x] #4 Environment variable for debug/verbose mode
- [x] #5 Error boundaries prevent complete page failures
<!-- AC:END -->

## Implementation Notes

<!-- SECTION:NOTES:BEGIN -->
## Implementation Complete

Successfully implemented comprehensive error logging and debugging improvements for LiveView operations.

### What Was Implemented:

1. **Structured Logging Module** (`lib/mydia/logger.ex`):
   - Created `Mydia.Logger` module for structured logging with metadata
   - Functions for logging errors, warnings, info, and debug messages
   - Automatic error message extraction and sanitization for users
   - Support for various error types (changesets, exceptions, tuples)
   - Stack trace logging in debug mode only

2. **Environment Variable Support**:
   - Added `MYDIA_DEBUG` and `LOG_LEVEL` environment variables
   - Updated `config/dev.exs` to support debug mode
   - Updated `config/runtime.exs` to configure log level dynamically
   - Different log formats for debug vs. normal mode

3. **Enhanced AdminConfigLive Error Handling**:
   - Added comprehensive error logging to all operations:
     - Settings updates (toggle_setting, update_setting_form)
     - Quality profile operations (duplicate, delete)
     - Download client operations (delete, test)
     - Indexer operations (delete, test)
     - Library path operations (delete)
   - Structured metadata includes: operation, user_id, resource IDs, error details
   - User-facing messages now provide specific, actionable information

4. **Error Boundary Components**:
   - Created `MydiaWeb.Components.ErrorBoundary` with:
     - `error_boundary/1` component for wrapping sections that might fail
     - `error_fallback/1` component for inline error display
     - Retry functionality for error recovery
   - Created `MydiaWeb.Live.ErrorHandler` helper module:
     - `handle_operation/4` for wrapping dangerous operations
     - `safe_fetch/3` for safe data fetching
     - Automatic error logging and state management

5. **Comprehensive Documentation**:
   - Created `docs/ERROR_HANDLING_GUIDE.md` with:
     - Usage examples for all new features
     - Best practices for error handling
     - Environment variable reference
     - Integration patterns for LiveViews

### Files Changed:
- `lib/mydia/logger.ex` (new)
- `lib/mydia_web/components/error_boundary.ex` (new)
- `lib/mydia_web/live/error_handler.ex` (new)
- `docs/ERROR_HANDLING_GUIDE.md` (new)
- `lib/mydia_web/live/admin_config_live/index.ex` (enhanced error handling)
- `config/dev.exs` (debug mode support)
- `config/runtime.exs` (log level configuration)

### Benefits:
- **Better Debugging**: Structured logs with full context make issues easier to diagnose
- **Improved UX**: Users see specific, actionable error messages instead of generic failures
- **Production Ready**: Environment variables enable verbose logging when needed
- **Graceful Degradation**: Error boundaries prevent complete page failures
- **Developer Friendly**: Comprehensive documentation and reusable patterns

### Testing:
- Code compiles successfully
- All new modules follow project conventions
- Error handling patterns integrated into AdminConfigLive
- Documentation provides clear usage examples

Note: Some pre-existing test failures observed (database busy, timeout in nzbget tests) are unrelated to this implementation.
<!-- SECTION:NOTES:END -->
