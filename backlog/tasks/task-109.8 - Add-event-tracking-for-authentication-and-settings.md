---
id: task-109.8
title: Add event tracking for authentication and settings
status: To Do
assignee: []
created_date: '2025-11-06 18:46'
labels:
  - backend
  - integration
  - auth
  - settings
dependencies: []
parent_task_id: task-109
priority: low
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Add event tracking for user authentication actions and configuration changes.

## Integration Points

**Authentication (lib/mydia_web/auth/):**
- User login events (via Guardian or Ueberauth callbacks)
- User logout events
- Failed authentication attempts (optional)

**Settings Changes:**
- Quality profile changes
- Download client config changes
- Indexer config changes
- Library path changes

## Implementation Notes

- Add event tracking to auth plugs/controllers
- Track user.login with timestamp
- Track user.logout
- Track settings.changed with setting type and user
- Use :user actor_type for all auth/settings events
- Store relevant metadata without sensitive data (no passwords)
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 User login events tracked
- [ ] #2 User logout events tracked
- [ ] #3 Settings change events tracked for quality profiles
- [ ] #4 Settings change events tracked for client configs
- [ ] #5 Settings change events tracked for indexer configs
- [ ] #6 Events include actor (user_id) information
- [ ] #7 No sensitive data stored in event metadata
<!-- AC:END -->
