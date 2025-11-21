/**
 * Page Object Model for the Login page
 *
 * Encapsulates all interactions with the login page including filling forms,
 * clicking buttons, and making assertions. This provides a clean, reusable
 * interface for login-related test operations.
 *
 * @class LoginPage
 * @example
 * import { LoginPage } from '../pages/LoginPage';
 *
 * test('user can login', async ({ page }) => {
 *   const loginPage = new LoginPage(page);
 *   await loginPage.goto();
 *   await loginPage.assertLoginFormVisible();
 *   await loginPage.login('admin', 'adminpass');
 * });
 */
import { Page, expect } from "@playwright/test";

export class LoginPage {
  /**
   * Creates a new LoginPage instance
   * @param page - Playwright page object
   */
  constructor(private page: Page) {}

  // Selectors
  private get usernameInput() {
    return this.page.locator('input[name="user[username]"]');
  }

  private get passwordInput() {
    return this.page.locator('input[name="user[password]"]');
  }

  private get submitButton() {
    return this.page.locator('button[type="submit"]');
  }

  private get oidcButton() {
    return this.page.locator(
      'a:has-text("Sign in with OIDC"), button:has-text("Sign in with OIDC")',
    );
  }

  private get errorMessage() {
    return this.page.locator('[role="alert"], .alert-error, .flash-error');
  }

  // Actions

  /**
   * Navigate to the local login page
   * Waits for the page to be fully loaded before returning
   * @example
   * const loginPage = new LoginPage(page);
   * await loginPage.goto();
   */
  async goto() {
    await this.page.goto("/auth/local/login");
    await this.page.waitForLoadState("networkidle");
  }

  /**
   * Fill in the username field
   * @param username - Username to enter
   * @example
   * await loginPage.fillUsername('admin');
   */
  async fillUsername(username: string) {
    await this.usernameInput.fill(username);
  }

  /**
   * Fill in the password field
   * @param password - Password to enter
   * @example
   * await loginPage.fillPassword('adminpass');
   */
  async fillPassword(password: string) {
    await this.passwordInput.fill(password);
  }

  /**
   * Click the submit button
   * @example
   * await loginPage.clickSubmit();
   */
  async clickSubmit() {
    await this.submitButton.click();
  }

  /**
   * Perform complete login flow
   * Fills username, password, submits form, and waits for redirect
   * @param username - Username to login with
   * @param password - Password to login with
   * @throws {Error} If login fails or redirect times out
   * @example
   * await loginPage.login('admin', 'adminpass');
   */
  async login(username: string, password: string) {
    await this.fillUsername(username);
    await this.fillPassword(password);
    await this.clickSubmit();
    // Wait for navigation
    await this.page.waitForURL("/", { timeout: 5000 });
  }

  /**
   * Click the OIDC/OAuth login button
   * @example
   * await loginPage.clickOIDCLogin();
   */
  async clickOIDCLogin() {
    await this.oidcButton.click();
  }

  // Assertions

  /**
   * Assert that the login form is visible
   * Checks for username field, password field, and submit button
   * @throws {Error} If any form element is not visible
   * @example
   * await loginPage.goto();
   * await loginPage.assertLoginFormVisible();
   */
  async assertLoginFormVisible() {
    await expect(this.usernameInput).toBeVisible();
    await expect(this.passwordInput).toBeVisible();
    await expect(this.submitButton).toBeVisible();
  }

  /**
   * Assert that an error message is displayed with specific text
   * @param message - Expected error message text (can be substring)
   * @throws {Error} If error message is not visible or doesn't contain text
   * @example
   * await loginPage.login('invalid', 'credentials');
   * await loginPage.assertErrorMessage('Invalid username or password');
   */
  async assertErrorMessage(message: string) {
    await expect(this.errorMessage).toBeVisible();
    await expect(this.errorMessage).toContainText(message);
  }

  /**
   * Assert that the current page is the login page
   * @throws {Error} If URL does not match login page pattern
   * @example
   * await page.goto('/admin'); // Requires auth
   * await loginPage.assertOnLoginPage(); // Should redirect
   */
  async assertOnLoginPage() {
    await expect(this.page).toHaveURL(/\/auth\/(local\/)?login/);
  }
}
