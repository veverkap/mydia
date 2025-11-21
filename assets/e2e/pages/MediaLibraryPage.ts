/**
 * Page Object Model for the Media Library page
 *
 * Encapsulates all interactions with the media library including browsing
 * TV shows, movies, and verifying media has been added successfully.
 *
 * @class MediaLibraryPage
 * @example
 * import { MediaLibraryPage } from '../pages/MediaLibraryPage';
 *
 * test('verify media in library', async ({ page }) => {
 *   const libraryPage = new MediaLibraryPage(page);
 *   await libraryPage.goto();
 *   await libraryPage.assertMediaExists('Breaking Bad');
 * });
 */
import { Page, expect } from "@playwright/test";

export class MediaLibraryPage {
  /**
   * Creates a new MediaLibraryPage instance
   * @param page - Playwright page object
   */
  constructor(private page: Page) {}

  // Selectors

  private get mediaGrid() {
    return this.page.locator(
      '[data-test="media-grid"], .media-grid, .library-grid',
    );
  }

  private get emptyState() {
    return this.page.locator(
      '[data-test="empty-library"], .empty-state, :has-text("No media in library")',
    );
  }

  /**
   * Get a media item by title text
   * @param title - Media title to find
   */
  private mediaItem(title: string) {
    return this.page
      .locator(
        `[data-test="media-item"]:has-text("${title}"), .media-item:has-text("${title}")`,
      )
      .first();
  }

  /**
   * Get filter/tab buttons
   */
  private get tvShowsTab() {
    return this.page
      .locator('button:has-text("TV Shows"), a:has-text("TV Shows")')
      .first();
  }

  private get moviesTab() {
    return this.page
      .locator('button:has-text("Movies"), a:has-text("Movies")')
      .first();
  }

  // Actions

  /**
   * Navigate to the media library page
   * @example
   * await libraryPage.goto();
   */
  async goto() {
    await this.page.goto("/media");
    await this.page.waitForLoadState("networkidle");
  }

  /**
   * Filter library to show only TV shows
   * @example
   * await libraryPage.filterByTVShows();
   */
  async filterByTVShows() {
    if (await this.tvShowsTab.isVisible()) {
      await this.tvShowsTab.click();
      await this.page.waitForLoadState("networkidle");
    }
  }

  /**
   * Filter library to show only movies
   * @example
   * await libraryPage.filterByMovies();
   */
  async filterByMovies() {
    if (await this.moviesTab.isVisible()) {
      await this.moviesTab.click();
      await this.page.waitForLoadState("networkidle");
    }
  }

  /**
   * Click on a media item to view details
   * @param title - Title of media to click
   * @example
   * await libraryPage.clickMedia('Breaking Bad');
   */
  async clickMedia(title: string) {
    await this.mediaItem(title).click();
  }

  /**
   * Check if media exists in library
   * @param title - Title of media to check
   * @returns Promise resolving to true if media exists
   * @example
   * const exists = await libraryPage.hasMedia('Breaking Bad');
   */
  async hasMedia(title: string): Promise<boolean> {
    return (await this.mediaItem(title).count()) > 0;
  }

  // Assertions

  /**
   * Assert that the library page is loaded
   * @throws {Error} If page is not loaded
   * @example
   * await libraryPage.goto();
   * await libraryPage.assertPageLoaded();
   */
  async assertPageLoaded() {
    await expect(this.page).toHaveURL(/\/media/);
  }

  /**
   * Assert that specific media exists in the library
   * @param title - Title of media that should exist
   * @throws {Error} If media is not found
   * @example
   * await libraryPage.assertMediaExists('Breaking Bad');
   */
  async assertMediaExists(title: string) {
    await expect(this.mediaItem(title)).toBeVisible({ timeout: 10000 });
  }

  /**
   * Assert that specific media does not exist in the library
   * @param title - Title of media that should not exist
   * @throws {Error} If media is found
   * @example
   * await libraryPage.assertMediaNotExists('Nonexistent Show');
   */
  async assertMediaNotExists(title: string) {
    await expect(this.mediaItem(title)).not.toBeVisible();
  }

  /**
   * Assert that the library is empty
   * @throws {Error} If library is not empty
   * @example
   * await libraryPage.assertEmpty();
   */
  async assertEmpty() {
    await expect(this.emptyState).toBeVisible();
  }

  /**
   * Assert that library contains at least one media item
   * @throws {Error} If library is empty
   * @example
   * await libraryPage.assertNotEmpty();
   */
  async assertNotEmpty() {
    const items = this.page.locator('[data-test="media-item"], .media-item');
    await expect(items).not.toHaveCount(0);
  }
}
