# End-to-End Testing with Playwright

Comprehensive guide for running, writing, and debugging E2E tests in Mydia.

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Prerequisites](#prerequisites)
- [Running Tests](#running-tests)
- [Writing Tests](#writing-tests)
- [Debugging](#debugging)
- [Mock Services](#mock-services)
- [CI Integration](#ci-integration)
- [Troubleshooting](#troubleshooting)

## Overview

### Testing Strategy

Mydia uses a three-layer testing approach:

1. **Unit/Integration Tests (ExUnit)** - Business logic, contexts, and data layer
2. **LiveView Tests (Phoenix.LiveViewTest)** - Component behavior, events, and server-side rendering
3. **E2E Tests (Playwright)** - Real browser, full workflows, JavaScript hooks, and complete user journeys

### When to Use E2E Tests

Write E2E tests for:

- ✅ Complete user workflows (login → search → add to library)
- ✅ JavaScript interactions (Alpine.js components, custom hooks)
- ✅ Real-time features (LiveView updates, WebSocket communication)
- ✅ Browser-specific behavior (media playback, file uploads)
- ✅ Cross-page navigation flows
- ✅ OIDC authentication flows

Use LiveView tests instead for:

- ❌ Testing individual LiveView events
- ❌ Form validation logic
- ❌ Server-side rendering
- ❌ Simple component behavior

### What's Covered

Current E2E test coverage includes:

- **Smoke Tests** - Basic page loads, meta tags, LiveView/Alpine.js initialization
- **Authentication** - Local login/logout, OIDC login, session persistence
- **Authorization** - Protected routes, role-based access control

## Quick Start

### Running Tests Locally

```bash
# Install dependencies
cd assets
npm install

# Run all E2E tests (only Chromium by default)
npm run test:e2e

# Run tests with UI for debugging
npm run test:e2e:ui

# Run tests in headed mode (see browser)
npm run test:e2e -- --headed

# Run specific test file
npm run test:e2e -- auth.spec.ts

# Run tests in specific browser
npm run test:e2e -- --project=firefox
```

### CI Environment

Tests run automatically in GitHub Actions on every PR and push to master.

View test results:

1. Go to the **Actions** tab in GitHub
2. Click on the latest workflow run
3. Check the **E2E Tests (Playwright)** job
4. Download artifacts to view screenshots/videos from failures

## Prerequisites

### Local Development

- **Node.js 18+** - For running Playwright tests
- **Docker & Docker Compose** - For running the test environment
- **Disk Space** - ~2GB for Docker images and browser binaries

### Installation

```bash
# Install Node dependencies (includes Playwright)
cd assets
npm install

# Install Playwright browsers (if not auto-installed)
npx playwright install chromium firefox webkit

# Verify installation
npx playwright --version
```

## Running Tests

### Test Environment Setup

The E2E tests run against a Docker Compose environment with:

- **Mydia app** - Fresh instance with test database
- **Mock OAuth2 server** - For OIDC authentication tests
- **Mock Prowlarr** - For indexer integration tests (future)
- **Mock qBittorrent** - For download client tests (future)

The `playwright.config.ts` automatically starts the environment using `./dev up` when running locally.

### Running All Tests

```bash
cd assets

# Run all tests (Chromium only by default)
npm run test:e2e

# Run all tests in all browsers (slower)
npm run test:e2e -- --project=chromium --project=firefox --project=webkit

# Run all tests including mobile viewports
npm run test:e2e -- --project=chromium --project='Mobile Chrome' --project='Mobile Safari'
```

### Running Specific Tests

```bash
# Run specific test file
npm run test:e2e -- auth.spec.ts

# Run tests matching pattern
npm run test:e2e -- --grep "login"

# Run specific test by line number
npm run test:e2e -- auth.spec.ts:25

# Run in specific browser
npm run test:e2e -- --project=firefox smoke.spec.ts
```

### Interactive UI Mode

The Playwright UI provides a visual interface for running and debugging tests:

```bash
npm run test:e2e:ui
```

Features:

- Click to run individual tests
- Watch mode - auto-runs tests on file changes
- Time travel debugging - step through each action
- Screenshot inspector - see page state at each step
- Network tab - inspect requests/responses
- Console logs - view browser console output

### Headed Mode

See the actual browser during test execution:

```bash
npm run test:e2e -- --headed
```

Useful for:

- Understanding test flow visually
- Debugging timing issues
- Verifying UI interactions
- Developing new tests

### Debug Mode

Run tests with full debugging capabilities:

```bash
npm run test:e2e -- --debug
```

This enables:

- Playwright Inspector with step-through debugging
- Browser DevTools access
- Automatic pause before each action
- Console output from the browser

## Writing Tests

### Project Structure

```
assets/e2e/
├── fixtures/          # Test data and user fixtures
│   └── users.ts       # testUsers.admin, testUsers.user
├── helpers/           # Reusable test utilities
│   ├── auth.ts        # loginAsAdmin(), logout(), mockOIDCLogin()
│   ├── liveview.ts    # waitForLiveViewUpdate(), assertFlashMessage()
│   └── index.ts       # Helper exports
├── pages/             # Page Object Models
│   ├── LoginPage.ts   # Login page actions and assertions
│   └── index.ts       # Page exports
└── tests/             # Test specs
    ├── smoke.spec.ts  # Basic smoke tests
    └── auth.spec.ts   # Authentication tests
```

### Basic Test Structure

```typescript
import { test, expect } from "@playwright/test";

test.describe("Feature Name", () => {
  test("should do something specific", async ({ page }) => {
    // Navigate to page
    await page.goto("/some-page");

    // Interact with elements
    await page.click('button[type="submit"]');

    // Assert expected behavior
    await expect(page.locator("h1")).toHaveText("Expected Text");
  });
});
```

### Using Helpers

```typescript
import { test, expect } from "@playwright/test";
import { loginAsAdmin, logout } from "../helpers/auth";
import { assertFlashMessage, waitForLiveViewUpdate } from "../helpers/liveview";

test("authenticated workflow", async ({ page }) => {
  // Login using helper
  await loginAsAdmin(page);

  // Navigate and perform action
  await page.goto("/admin/settings");
  await page.click('button[type="submit"]');

  // Wait for LiveView update
  await waitForLiveViewUpdate(page);

  // Assert flash message
  await assertFlashMessage(page, "success", "Settings saved");

  // Logout
  await logout(page);
});
```

### Using Page Objects

Page Objects encapsulate page-specific selectors and actions:

```typescript
import { test, expect } from "@playwright/test";
import { LoginPage } from "../pages/LoginPage";
import { testUsers } from "../fixtures/users";

test("login with page object", async ({ page }) => {
  const loginPage = new LoginPage(page);

  // Navigate to login page
  await loginPage.goto();

  // Assert form is visible
  await loginPage.assertLoginFormVisible();

  // Login
  await loginPage.login(testUsers.admin.username, testUsers.admin.password);

  // Assert successful redirect
  await expect(page).toHaveURL("/");
});
```

### Creating a New Page Object

```typescript
import { Page, expect } from "@playwright/test";

export class MyFeaturePage {
  constructor(private page: Page) {}

  // Selectors (private getters)
  private get submitButton() {
    return this.page.locator('button[type="submit"]');
  }

  private get titleInput() {
    return this.page.locator('input[name="title"]');
  }

  // Actions
  async goto() {
    await this.page.goto("/my-feature");
    await this.page.waitForLoadState("networkidle");
  }

  async fillTitle(title: string) {
    await this.titleInput.fill(title);
  }

  async submit() {
    await this.submitButton.click();
  }

  // Assertions
  async assertTitleVisible() {
    await expect(this.page.locator("h1")).toBeVisible();
  }

  async assertFormSubmitted() {
    await expect(this.submitButton).toBeDisabled();
  }
}
```

### Testing LiveView Updates

```typescript
import { test } from "@playwright/test";
import {
  waitForLiveViewUpdate,
  clickAndWaitForUpdate,
} from "../helpers/liveview";

test("LiveView real-time update", async ({ page }) => {
  await page.goto("/downloads");

  // Click button and wait for LiveView update
  await clickAndWaitForUpdate(page, 'button[phx-click="refresh"]');

  // Or manually wait after action
  await page.click('button[phx-click="delete"]');
  await waitForLiveViewUpdate(page);
});
```

### Testing Forms

```typescript
import { test, expect } from "@playwright/test";
import {
  fillAndWaitForValidation,
  submitFormAndWait,
} from "../helpers/liveview";

test("form submission with validation", async ({ page }) => {
  await page.goto("/admin/indexers/new");

  // Fill field and wait for validation
  await fillAndWaitForValidation(
    page,
    'input[name="indexer[name]"]',
    "Test Indexer",
  );

  // Submit form and wait for LiveView response
  await submitFormAndWait(page, "form#indexer-form");

  // Assert success
  await expect(page).toHaveURL("/admin/indexers");
});
```

### Test Naming Conventions

```typescript
// ✅ Good - Descriptive, behavior-focused
test('shows error message when login fails with invalid credentials', ...)
test('redirects to requested page after successful login', ...)
test('displays flash message when settings are saved', ...)

// ❌ Bad - Implementation-focused, vague
test('test login', ...)
test('form validation', ...)
test('button click', ...)
```

### Test Organization

- Group related tests in `test.describe()` blocks
- Use clear, descriptive test names that explain the expected behavior
- One assertion per test when possible (focused tests)
- Use `test.beforeEach()` for common setup (like login)
- Use `test.afterEach()` for cleanup (like logout)

Example:

```typescript
test.describe("Media Search", () => {
  test.beforeEach(async ({ page }) => {
    await loginAsAdmin(page);
    await page.goto("/search");
  });

  test("displays search results when query is entered", async ({ page }) => {
    // Test implementation
  });

  test("shows empty state when no results found", async ({ page }) => {
    // Test implementation
  });

  test.afterEach(async ({ page }) => {
    await logout(page);
  });
});
```

## Debugging

### Screenshots and Videos

Playwright automatically captures screenshots and videos on failure.

**Configuration** (in `playwright.config.ts`):

```typescript
use: {
  screenshot: 'only-on-failure',
  video: 'retain-on-failure',
}
```

**Locations:**

- Screenshots: `assets/test-results/<test-name>/screenshots/`
- Videos: `assets/test-results/<test-name>/videos/`
- HTML Report: `assets/e2e-results/html/`

**Viewing results:**

```bash
# Open HTML report with screenshots and videos
npx playwright show-report e2e-results/html
```

### Using the Playwright Inspector

The Inspector provides step-by-step debugging:

```bash
npm run test:e2e -- --debug
```

Features:

- Step through each test action
- Inspect page state at any point
- View selector suggestions
- Record new test interactions
- Copy selectors from the page

### Console Logs

View browser console output during tests:

```typescript
test("my test", async ({ page }) => {
  // Listen to console messages
  page.on("console", (msg) => console.log("Browser:", msg.text()));

  // Listen to page errors
  page.on("pageerror", (error) => console.error("Page error:", error));

  // Your test code
});
```

### Debugging Selectors

Test selectors in the browser console:

```typescript
test("debug selectors", async ({ page }) => {
  await page.goto("/");

  // Pause test and open browser DevTools
  await page.pause();

  // Test will pause here - use browser console to test selectors:
  // document.querySelector('button[type="submit"]')
});
```

### Analyzing Test Failures

When a test fails:

1. **Check the error message** - Often indicates the issue
2. **View the screenshot** - See page state at failure
3. **Watch the video** - Understand what happened leading to failure
4. **Check browser console** - Look for JavaScript errors
5. **Inspect network tab** - Verify API calls succeeded
6. **Run in headed mode** - Watch test execution
7. **Use debug mode** - Step through the test

### Common Debugging Patterns

```typescript
// Pause test at specific point
await page.pause();

// Add delay to observe behavior
await page.waitForTimeout(2000);

// Take manual screenshot
await page.screenshot({ path: "debug-screenshot.png" });

// Print element content
const text = await page.locator("h1").textContent();
console.log("H1 text:", text);

// Wait for specific condition
await page.waitForFunction(() => {
  return document.querySelector(".loading") === null;
});
```

## Mock Services

The E2E environment uses mock implementations of external services for fast, predictable testing.

### Architecture

```
┌─────────────────┐
│  Playwright     │
│  Browser Tests  │
└────────┬────────┘
         │ HTTP
         ▼
┌─────────────────┐
│  Mydia App      │
│  (Test Mode)    │
└────┬────────┬───┘
     │        │
     │        └──────────────┐
     ▼                       ▼
┌──────────────┐      ┌──────────────┐
│ Mock OAuth2  │      │ Mock Prowlarr│
│ Server       │      │ Server       │
└──────────────┘      └──────────────┘
```

### Available Mock Services

#### Mock OAuth2 Server

- **Purpose**: Test OIDC authentication without a real provider
- **Image**: `ghcr.io/navikt/mock-oauth2-server:2.1.10`
- **Endpoints**: Auto-discovery at `/.well-known/openid-configuration`
- **Default User**: `test@example.com` (auto-approved)

#### Mock Prowlarr

- **Purpose**: Test indexer search and integration
- **Implementation**: Node.js/Express server
- **API**: Prowlarr API v1 compatible
- **Test Data**: 2 indexers, 3 mock search results
- **API Key**: `test-api-key`

**Endpoints:**

- `GET /api/v1/indexer` - List indexers
- `GET /api/v1/search?query=...` - Search releases
- `GET /api/v1/system/status` - System status

#### Mock qBittorrent

- **Purpose**: Test download client integration
- **Implementation**: Node.js/Express server
- **API**: qBittorrent Web API v2 compatible
- **Credentials**: `admin` / `adminpass`
- **Features**: In-memory torrent storage, simulated progress

**Endpoints:**

- `POST /api/v2/auth/login` - Login (sets cookie)
- `GET /api/v2/torrents/info` - List torrents
- `POST /api/v2/torrents/add` - Add torrent
- `POST /api/v2/torrents/delete` - Delete torrents

### Service URLs

**From host machine:**

- Mydia: `http://localhost:4000`
- Mock OAuth2: `http://localhost:8080`
- Mock Prowlarr: `http://localhost:19696`
- Mock qBittorrent: `http://localhost:8082`

**From containers (internal network):**

- Mock OAuth2: `http://mock-oauth2:8080`
- Mock Prowlarr: `http://mock-prowlarr:9696`
- Mock qBittorrent: `http://mock-qbittorrent:8080`

### Starting Mock Services

```bash
# Start all services
docker compose -f compose.test.yml up -d

# View logs
docker compose -f compose.test.yml logs -f

# Stop all services
docker compose -f compose.test.yml down

# Rebuild mock services after changes
docker compose -f compose.test.yml build mock-prowlarr mock-qbittorrent
```

### Extending Mock Services

**Add new Prowlarr endpoints:**

Edit `test/mock_services/prowlarr/server.js`:

```javascript
app.get("/api/v1/my-endpoint", (req, res) => {
  res.json({ data: "response" });
});
```

**Add new test data:**

Edit `test/mock_services/prowlarr/server.js`:

```javascript
const mockSearchResults = [
  {
    title: "My Test Release",
    size: 1024000000,
    // ... other fields
  },
  // Add more results
];
```

**Add new qBittorrent endpoints:**

Edit `test/mock_services/qbittorrent/server.js`:

```javascript
app.post("/api/v2/torrents/my-action", requireAuth, (req, res) => {
  // Implementation
});
```

See `test/mock_services/README.md` for complete documentation.

## CI Integration

### GitHub Actions Workflow

E2E tests run automatically in CI as part of the main workflow.

**Workflow file:** `.github/workflows/ci.yml`

**Job:** `e2e-tests`

**Steps:**

1. Build Mydia Docker image
2. Start test environment (app + mock services)
3. Wait for app to be healthy
4. Seed test users into database
5. Run Playwright tests
6. Upload test results and artifacts
7. Tear down environment

**Triggers:**

- Every push to `master`
- Every pull request

### Viewing CI Results

1. Go to the **Actions** tab in GitHub
2. Click on the latest workflow run
3. Check the **E2E Tests (Playwright)** job
4. Expand steps to see logs
5. Download **playwright-results** artifact for screenshots/videos

### CI Configuration

**Browser:** Chromium only (for speed)

**Parallelization:** 2 workers

**Retries:** 2 retries on failure

**Artifacts:** Test results retained for 7 days

### Running Tests Locally Like CI

```bash
# Build Docker image
docker build -t mydia:test .

# Start test environment
docker compose -f compose.test.yml up -d app mock-oauth2

# Wait for app to be healthy
timeout 60 bash -c 'until docker compose -f compose.test.yml exec app curl -f http://localhost:4000/health > /dev/null 2>&1; do sleep 2; done'

# Seed test users
./scripts/seed_test_users.sh

# Run E2E tests
docker compose -f compose.test.yml run --rm playwright npm run test:e2e

# Cleanup
docker compose -f compose.test.yml down -v
```

## Troubleshooting

### Tests Failing Locally But Passing in CI

**Possible causes:**

- Different browser versions
- Timing issues (network latency)
- Environment-specific configuration

**Solutions:**

```bash
# Update Playwright browsers to match CI
npx playwright install --with-deps

# Run with same browser as CI
npm run test:e2e -- --project=chromium

# Increase timeouts if network is slow
# Edit playwright.config.ts: timeout: 60 * 1000
```

### Timeout Errors

**Error:** `Test timeout of 30000ms exceeded`

**Common causes:**

- Element not appearing
- LiveView not updating
- Network request hanging
- Selector not matching

**Debug steps:**

```bash
# Run in headed mode to see what's happening
npm run test:e2e -- --headed --timeout=60000

# Add debug logging
await page.locator('button').click();
console.log('Clicked button, waiting for response...');
await page.waitForSelector('.result', { timeout: 10000 });
```

**Solutions:**

```typescript
// Increase timeout for specific action
await page.waitForSelector(".slow-loading", { timeout: 60000 });

// Use waitForLoadState
await page.waitForLoadState("networkidle");

// Check element state before interacting
await page.waitForSelector("button", { state: "visible" });
await page.click("button");
```

### Docker Services Not Starting

**Check service health:**

```bash
docker compose -f compose.test.yml ps
```

**View service logs:**

```bash
docker compose -f compose.test.yml logs mock-prowlarr
docker compose -f compose.test.yml logs app
```

**Verify network connectivity:**

```bash
docker compose -f compose.test.yml exec app curl http://mock-prowlarr:9696/health
```

**Restart services:**

```bash
docker compose -f compose.test.yml down -v
docker compose -f compose.test.yml up -d
```

### Application Not Responding

**Symptoms:**

- Tests timeout waiting for app
- Health check fails
- Connection refused errors

**Check app logs:**

```bash
docker compose -f compose.test.yml logs app
```

**Check app health:**

```bash
curl http://localhost:4000/health
```

**Verify database:**

```bash
docker compose -f compose.test.yml exec app bin/mydia rpc "Mydia.Repo.query!(\"SELECT 1\")"
```

**Restart app:**

```bash
docker compose -f compose.test.yml restart app
```

### Selector Not Found

**Error:** `locator.click: Timeout exceeded waiting for locator`

**Common causes:**

- Incorrect selector
- Element not visible
- Element rendered differently than expected
- Dynamic content not loaded

**Debug steps:**

```typescript
// Print page HTML
console.log(await page.content());

// Check if element exists at all
const count = await page.locator("button").count();
console.log("Button count:", count);

// Wait for element with increased timeout
await page.waitForSelector("button", { state: "visible", timeout: 10000 });

// Use text content instead
await page.click("text=Submit");

// Use role-based selectors
await page.click('role=button[name="Submit"]');
```

### LiveView Not Updating

**Symptoms:**

- Flash messages not appearing
- Content not changing after click
- Form submission not working

**Check LiveView connection:**

```typescript
const connected = await page.evaluate(() => {
  const liveSocket = (window as any).liveSocket;
  return liveSocket && liveSocket.isConnected();
});
console.log("LiveView connected:", connected);
```

**Wait for updates:**

```typescript
import { waitForLiveViewUpdate } from "../helpers/liveview";

await page.click('button[phx-click="submit"]');
await waitForLiveViewUpdate(page);
```

**Check browser console:**

```typescript
page.on("console", (msg) => console.log("Browser:", msg.text()));
page.on("pageerror", (error) => console.error("Page error:", error));
```

### Authentication Issues

**Symptoms:**

- Cannot login
- Redirect loops
- Session not persisting

**Check test users exist:**

```bash
docker compose -f compose.test.yml exec app bin/mydia rpc "Mydia.Accounts.list_users()"
```

**Seed test users manually:**

```bash
./scripts/seed_test_users.sh
```

**Check session cookies:**

```typescript
const cookies = await page.context().cookies();
console.log("Session cookies:", cookies);
```

**Verify redirect:**

```typescript
await page.goto("/auth/local/login");
console.log("Current URL:", page.url());
```

### CI-Only Failures

**Symptoms:**

- Tests pass locally but fail in CI
- Intermittent failures in CI

**Common causes:**

- Race conditions
- Slower CI environment
- Browser version differences
- Missing dependencies

**Solutions:**

```typescript
// Use more reliable waits
await page.waitForLoadState("networkidle");
await page.waitForSelector(".element", { state: "visible" });

// Add retries for flaky tests
test("flaky test", async ({ page }) => {
  test.slow(); // Triple the timeout
  // Test code
});

// Use test fixtures for setup
test.beforeEach(async ({ page }) => {
  // Ensure clean state
});
```

**View CI artifacts:**

1. Download `playwright-results` artifact from failed workflow
2. Unzip and open `index.html` in browser
3. View screenshots and video to debug

### Performance Issues

**Symptoms:**

- Tests taking very long
- Timeouts in CI
- High resource usage

**Optimize tests:**

```typescript
// Run tests in parallel
test.describe.configure({ mode: "parallel" });

// Use fast selectors
await page.locator('[data-testid="submit"]').click(); // Fast
await page.locator("div > button.btn-primary").click(); // Slow

// Skip unnecessary waits
// Don't: await page.waitForTimeout(5000);
// Do: await page.waitForSelector('.loaded');

// Reuse authentication
test.use({ storageState: "auth.json" });
```

**Profile tests:**

```bash
# Run with trace
npm run test:e2e -- --trace on

# View trace
npx playwright show-trace trace.zip
```

### Environment Variables

**Check environment configuration:**

```bash
docker compose -f compose.test.yml exec app env | grep -E 'DATABASE|SECRET|OIDC'
```

**Override for debugging:**

```bash
# Edit compose.test.yml
environment:
  LOG_LEVEL: debug
  ECTO_LOG_LEVEL: debug
```

### Getting Help

1. **Check existing tests** - Look for similar test patterns
2. **Read Playwright docs** - https://playwright.dev
3. **Enable debug logging** - Run with `--debug` flag
4. **Ask for help** - Include error message, screenshot, and test code

## Contributing

### Adding New Test Coverage

When adding tests for new features:

1. **Identify the user journey** - What workflow are you testing?
2. **Check existing patterns** - Can you reuse helpers or page objects?
3. **Write focused tests** - One behavior per test
4. **Use descriptive names** - Explain what should happen
5. **Add to appropriate file** - Group related tests together

### Code Review Checklist

- [ ] Tests are focused and test one thing
- [ ] Test names clearly describe expected behavior
- [ ] Using helpers/page objects for common patterns
- [ ] Proper waits (no arbitrary timeouts)
- [ ] Assertions are specific and meaningful
- [ ] No commented-out code
- [ ] Tests pass locally in all browsers
- [ ] Tests pass in CI

### Best Practices

**DO:**

- ✅ Use semantic selectors (`data-testid`, `role`, `text`)
- ✅ Wait for specific conditions, not arbitrary timeouts
- ✅ Use page objects for repeated interactions
- ✅ Group related tests in `describe` blocks
- ✅ Clean up state in `afterEach`
- ✅ Make tests independent (can run in any order)

**DON'T:**

- ❌ Use brittle selectors (CSS classes, complex hierarchies)
- ❌ Use `waitForTimeout()` unless absolutely necessary
- ❌ Make tests depend on each other
- ❌ Test implementation details
- ❌ Duplicate code across tests (use helpers)
- ❌ Leave `test.only()` or `.skip()` in committed code

## Additional Resources

- [Playwright Documentation](https://playwright.dev)
- [Playwright Best Practices](https://playwright.dev/docs/best-practices)
- [Playwright Test API](https://playwright.dev/docs/api/class-test)
- [Mock Services README](../../test/mock_services/README.md)
- [LiveView Testing Guide](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveViewTest.html)
