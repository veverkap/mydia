/**
 * Authentication helpers for E2E tests
 *
 * Provides utilities for logging in/out users with different authentication methods.
 * These helpers abstract away the details of form filling and navigation, making
 * tests more readable and maintainable.
 *
 * @module e2e/helpers/auth
 * @example
 * import { loginAsAdmin, logout } from '../helpers/auth';
 *
 * test('admin workflow', async ({ page }) => {
 *   await loginAsAdmin(page);
 *   // ... test admin functionality
 *   await logout(page);
 * });
 */
import { Page, expect } from "@playwright/test";
import { testUsers } from "../fixtures/users";

/**
 * Login as admin user using local authentication
 *
 * Uses the predefined admin test user from fixtures. This is a convenience
 * wrapper around the login() function for the most common use case.
 *
 * @param page - Playwright page object
 * @returns Promise that resolves when login is complete and user is redirected
 * @throws {Error} If login fails or timeout occurs
 * @example
 * test('admin can access settings', async ({ page }) => {
 *   await loginAsAdmin(page);
 *   await page.goto('/admin/settings');
 *   // ... rest of test
 * });
 */
export async function loginAsAdmin(page: Page): Promise<void> {
  await login(page, testUsers.admin.username, testUsers.admin.password);
}

/**
 * Login as regular user using local authentication
 *
 * Uses the predefined regular user from fixtures. Useful for testing
 * non-admin workflows and permission boundaries.
 *
 * @param page - Playwright page object
 * @returns Promise that resolves when login is complete and user is redirected
 * @throws {Error} If login fails or timeout occurs
 * @example
 * test('user cannot access admin panel', async ({ page }) => {
 *   await loginAsUser(page);
 *   await page.goto('/admin');
 *   await expect(page).toHaveURL('/'); // Should redirect
 * });
 */
export async function loginAsUser(page: Page): Promise<void> {
  await login(page, testUsers.user.username, testUsers.user.password);
}

/**
 * Login with custom credentials using local authentication
 *
 * Navigate to the local login page, fill in credentials, submit the form,
 * and wait for successful redirect to the homepage. This is the base login
 * function that other helpers build upon.
 *
 * @param page - Playwright page object
 * @param username - Username to login with
 * @param password - Password to login with
 * @returns Promise that resolves when login is complete and user is redirected to homepage
 * @throws {Error} If form is not found, credentials are invalid, or redirect times out
 * @example
 * test('custom user login', async ({ page }) => {
 *   await login(page, 'myuser', 'mypassword');
 *   await expect(page).toHaveURL('/');
 * });
 */
export async function login(
  page: Page,
  username: string,
  password: string,
): Promise<void> {
  // Navigate to local login page
  await page.goto("/auth/local/login");

  // Wait for login form to be visible
  await page.waitForSelector("form", { state: "visible" });

  // Fill in credentials
  await page.fill('input[name="user[username]"]', username);
  await page.fill('input[name="user[password]"]', password);

  // Submit the form
  await page.click('button[type="submit"]');

  // Wait for redirect to homepage or successful login
  // The redirect to "/" is sufficient proof that login succeeded
  await page.waitForURL("/", { timeout: 5000 });
}

/**
 * Mock OIDC login flow for testing OAuth2/OpenID Connect authentication
 *
 * This function simulates OIDC authentication using the mock-oauth2-server
 * running in the test environment. It navigates through the OAuth flow and
 * completes the authentication process.
 *
 * Note: This assumes mock-oauth2-server is running in the Docker Compose
 * test environment (compose.test.yml).
 *
 * @param page - Playwright page object
 * @param email - Email address for the mock user (default: 'test@example.com')
 * @param name - Display name for the mock user (default: 'Test User')
 * @returns Promise that resolves when OIDC login is complete and user is redirected
 * @throws {Error} If OAuth flow fails or redirect times out
 * @example
 * test('OIDC login creates user account', async ({ page }) => {
 *   await mockOIDCLogin(page, 'newuser@example.com', 'New User');
 *   await expect(page).toHaveURL('/');
 * });
 */
export async function mockOIDCLogin(
  page: Page,
  email: string = "test@example.com",
  name: string = "Test User",
): Promise<void> {
  // Navigate to OIDC login
  await page.goto("/auth/oidc");

  // The mock OAuth2 server should redirect us to an interactive login page
  // Fill in the mock login form if it appears
  const loginButton = page.locator('button:has-text("Sign in")').first();
  if (await loginButton.isVisible({ timeout: 2000 })) {
    await loginButton.click();
  }

  // Wait for redirect back to the app
  await page.waitForURL("/", { timeout: 5000 });
}

/**
 * Logout the currently authenticated user
 *
 * Navigates to the logout endpoint and waits for redirect to the login page
 * or homepage. This clears the user's session.
 *
 * @param page - Playwright page object
 * @returns Promise that resolves when logout is complete and redirect occurs
 * @throws {Error} If logout endpoint fails or redirect times out
 * @example
 * test('user can logout', async ({ page }) => {
 *   await loginAsAdmin(page);
 *   await logout(page);
 *   await expect(page).toHaveURL(/\/auth.*login/);
 * });
 */
export async function logout(page: Page): Promise<void> {
  // Navigate to logout endpoint
  await page.goto("/auth/logout");

  // Wait for redirect to login page or homepage
  await page.waitForURL(
    (url) => {
      return (
        url.pathname === "/auth/local/login" ||
        url.pathname === "/" ||
        url.pathname === "/auth/login"
      );
    },
    { timeout: 5000 },
  );
}

/**
 * Check if a user is currently authenticated
 *
 * Checks for the presence of authenticated UI elements (user menu, navbar)
 * to determine if a user session exists.
 *
 * @param page - Playwright page object
 * @returns Promise resolving to true if user is logged in, false otherwise
 * @example
 * test('protected route requires auth', async ({ page }) => {
 *   await page.goto('/admin');
 *   const loggedIn = await isLoggedIn(page);
 *   expect(loggedIn).toBe(false);
 * });
 */
export async function isLoggedIn(page: Page): Promise<boolean> {
  // Check for presence of user menu or other logged-in indicators
  const userMenu = await page
    .locator('[data-test="user-menu"], .navbar')
    .count();
  return userMenu > 0;
}

/**
 * Ensure a user is logged in, logging in if necessary
 *
 * Checks if user is already authenticated. If not, performs login using
 * provided credentials or defaults to admin user.
 *
 * This is useful for test setup when you need authentication but don't
 * care about the login flow itself.
 *
 * @param page - Playwright page object
 * @param username - Optional username (defaults to admin)
 * @param password - Optional password (defaults to admin password)
 * @returns Promise that resolves when user is guaranteed to be logged in
 * @throws {Error} If login is required but fails
 * @example
 * test.beforeEach(async ({ page }) => {
 *   await ensureLoggedIn(page);
 *   // Test will run with admin user logged in
 * });
 */
export async function ensureLoggedIn(
  page: Page,
  username?: string,
  password?: string,
): Promise<void> {
  if (!(await isLoggedIn(page))) {
    if (username && password) {
      await login(page, username, password);
    } else {
      await loginAsAdmin(page);
    }
  }
}
