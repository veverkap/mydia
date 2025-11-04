---
id: task-5
title: Implement OIDC authentication with Ueberauth
status: In Progress
assignee:
  - assistant
created_date: '2025-11-04 01:52'
updated_date: '2025-11-04 03:15'
labels:
  - authentication
  - security
  - oidc
dependencies:
  - task-4
priority: high
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Set up OpenID Connect authentication using Ueberauth and Guardian for JWT tokens. Support OIDC providers like Authentik, Keycloak, Auth0. Include fallback local authentication for development.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Ueberauth and ueberauth_oidc dependencies configured
- [x] #2 Guardian set up for JWT token management
- [x] #3 OIDC callback routes implemented
- [x] #4 User session management working
- [x] #5 Role-based authorization (admin, user, readonly)
- [x] #6 Local auth fallback for development
- [x] #7 Authentication plugs created
<!-- AC:END -->

## Implementation Plan

<!-- SECTION:PLAN:BEGIN -->
## Implementation Plan for OIDC Authentication

### Stage 1: Add Dependencies
1. Uncomment and configure `ueberauth` and add `ueberauth_oidc` in mix.exs
2. Add `guardian` for JWT token management (~> 2.3)
3. Run `mix deps.get` to install dependencies

### Stage 2: Configure Guardian for JWT
1. Create `lib/mydia/auth/guardian.ex` - Guardian implementation module
2. Create `lib/mydia/auth/error_handler.ex` - Handle authentication errors
3. Configure Guardian in config files with secret key and token TTL

### Stage 3: Configure Ueberauth and OIDC Strategy
1. Configure Ueberauth providers in config/config.exs
2. Support configuration via environment variables for OIDC discovery URL, client ID/secret, scopes
3. Add environment-based config in config/runtime.exs

### Stage 4: Create Authentication Plugs
1. Create auth_pipeline.ex - Guardian pipeline for authenticated routes
2. Create ensure_authenticated.ex - Verify user is logged in
3. Create ensure_role.ex - Role-based authorization
4. Create api_auth.ex - API key authentication plug

### Stage 5: Implement OIDC Callback Routes and Controllers
1. Create auth_controller.ex with login, callback, logout actions
2. Add routes for OIDC authentication flow
3. Handle user creation/update from OIDC claims

### Stage 6: Session Management
1. Implement current_user assignment in LiveView on_mount hooks
2. Create user_auth.ex - LiveView authentication hooks

### Stage 7: Update Router Pipelines
1. Create :auth pipeline with Guardian verification
2. Create :require_authenticated and :require_admin pipelines
3. Protect routes appropriately

### Stage 8: Local Auth Fallback (Development)
1. Create session_controller.ex for local login
2. Add local login form view
3. Make it only available in development environment
<!-- SECTION:PLAN:END -->
