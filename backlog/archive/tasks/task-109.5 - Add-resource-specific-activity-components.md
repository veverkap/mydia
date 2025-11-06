---
id: task-109.5
title: Add resource-specific activity components
status: To Do
assignee: []
created_date: '2025-11-06 18:46'
labels:
  - ui
  - liveview
  - component
dependencies: []
parent_task_id: task-109
priority: low
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Create reusable components to display event history for specific resources (media items, episodes, downloads).

## Components

**ActivityFeedComponent (LiveComponent):**
- Display events for a specific resource
- Props: resource_type, resource_id, limit (default 20)
- Compact display suitable for detail pages
- Real-time updates via PubSub

**Integration Points:**
- Media item detail page - show activity for that item
- Episode detail page (future) - show episode activity
- Download detail/list - show download events

## UI Design

- Compact timeline suitable for sidebars/sections
- Show most recent N events
- "View all activity" link to main feed filtered by resource
- Icons and minimal metadata
- Optional title prop for section header
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 ActivityFeedComponent created as reusable LiveComponent
- [ ] #2 Component filters events by resource_type and resource_id
- [ ] #3 Component displays up to N most recent events
- [ ] #4 Integrated into at least one detail page (media item recommended)
- [ ] #5 Real-time updates work when viewing resource activity
- [ ] #6 Compact design suitable for embedding in pages
<!-- AC:END -->
