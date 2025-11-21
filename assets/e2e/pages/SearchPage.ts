/**
 * Page Object Model for the Media Search page
 *
 * Encapsulates all interactions with the search functionality including
 * searching for TV shows/movies, viewing results, and adding media to library.
 *
 * @class SearchPage
 * @example
 * import { SearchPage } from '../pages/SearchPage';
 *
 * test('search for TV show', async ({ page }) => {
 *   const searchPage = new SearchPage(page);
 *   await searchPage.goto();
 *   await searchPage.search('Breaking Bad');
 *   await searchPage.assertResultsVisible();
 * });
 */
import { Page, expect, Locator } from "@playwright/test";

export class SearchPage {
  /**
   * Creates a new SearchPage instance
   * @param page - Playwright page object
   */
  constructor(private page: Page) {}

  // Selectors

  private get searchInput() {
    return this.page.locator(
      'input[type="search"], input[name="search"], input[placeholder*="search" i]',
    );
  }

  private get searchButton() {
    return this.page
      .locator('button:has-text("Search"), button[type="submit"]')
      .first();
  }

  private get resultsContainer() {
    return this.page.locator(
      '[data-test="search-results"], .search-results, #search-results',
    );
  }

  private get emptyState() {
    return this.page.locator(
      '[data-test="empty-state"], .empty-state, :has-text("No results found")',
    );
  }

  /**
   * Get a search result by index
   * @param index - Zero-based index of result
   */
  private resultItem(index: number) {
    return this.resultsContainer
      .locator('[data-test="search-result"], .search-result')
      .nth(index);
  }

  /**
   * Get add button for a specific result
   * @param index - Zero-based index of result
   */
  private addButton(index: number) {
    return this.resultItem(index).locator(
      'button:has-text("Add"), button[data-test="add-button"]',
    );
  }

  /**
   * Get result title element
   * @param index - Zero-based index of result
   */
  private resultTitle(index: number) {
    return this.resultItem(index)
      .locator('[data-test="title"], h2, h3, .title')
      .first();
  }

  /**
   * Get quality badge for a result
   * @param index - Zero-based index of result
   */
  private qualityBadge(index: number) {
    return this.resultItem(index).locator(
      '[data-test="quality"], .quality, .badge',
    );
  }

  // Actions

  /**
   * Navigate to the search page
   * @example
   * await searchPage.goto();
   */
  async goto() {
    await this.page.goto("/search");
    await this.page.waitForLoadState("networkidle");
  }

  /**
   * Search for media by query string
   * @param query - Search query (TV show or movie title)
   * @example
   * await searchPage.search('Breaking Bad');
   */
  async search(query: string) {
    await this.searchInput.fill(query);
    await this.searchButton.click();
    // Wait for search results to load
    await this.page.waitForLoadState("networkidle");
  }

  /**
   * Click on a search result to view details
   * @param index - Zero-based index of result to click
   * @example
   * await searchPage.clickResult(0); // Click first result
   */
  async clickResult(index: number) {
    await this.resultItem(index).click();
  }

  /**
   * Click the add button for a specific search result
   * @param index - Zero-based index of result
   * @example
   * await searchPage.clickAddButton(0);
   */
  async clickAddButton(index: number) {
    await this.addButton(index).click();
  }

  /**
   * Get the title text of a search result
   * @param index - Zero-based index of result
   * @returns Promise resolving to the title text
   * @example
   * const title = await searchPage.getResultTitle(0);
   */
  async getResultTitle(index: number): Promise<string | null> {
    return await this.resultTitle(index).textContent();
  }

  /**
   * Check if a result has a quality badge
   * @param index - Zero-based index of result
   * @returns Promise resolving to true if quality badge exists
   * @example
   * const hasQuality = await searchPage.hasQualityBadge(0);
   */
  async hasQualityBadge(index: number): Promise<boolean> {
    return (await this.qualityBadge(index).count()) > 0;
  }

  // Assertions

  /**
   * Assert that search results are visible
   * @throws {Error} If results container is not visible
   * @example
   * await searchPage.search('Breaking Bad');
   * await searchPage.assertResultsVisible();
   */
  async assertResultsVisible() {
    await expect(this.resultsContainer).toBeVisible({ timeout: 10000 });
  }

  /**
   * Assert that empty state is shown (no results)
   * @throws {Error} If empty state is not visible
   * @example
   * await searchPage.search('NonexistentShow123456');
   * await searchPage.assertEmptyState();
   */
  async assertEmptyState() {
    await expect(this.emptyState).toBeVisible({ timeout: 5000 });
  }

  /**
   * Assert that a specific number of results are shown
   * @param count - Expected number of results
   * @throws {Error} If actual count doesn't match expected
   * @example
   * await searchPage.assertResultCount(5);
   */
  async assertResultCount(count: number) {
    const results = this.resultsContainer.locator(
      '[data-test="search-result"], .search-result',
    );
    await expect(results).toHaveCount(count, { timeout: 5000 });
  }

  /**
   * Assert that a result contains specific text in its title
   * @param index - Zero-based index of result
   * @param text - Text that should be in the title
   * @throws {Error} If result doesn't contain the text
   * @example
   * await searchPage.assertResultContains(0, 'Breaking Bad');
   */
  async assertResultContains(index: number, text: string) {
    await expect(this.resultTitle(index)).toContainText(text);
  }

  /**
   * Assert that quality badge is displayed for a result
   * @param index - Zero-based index of result
   * @throws {Error} If quality badge is not visible
   * @example
   * await searchPage.assertQualityBadgeVisible(0);
   */
  async assertQualityBadgeVisible(index: number) {
    await expect(this.qualityBadge(index)).toBeVisible();
  }
}
