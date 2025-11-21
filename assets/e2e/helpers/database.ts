/**
 * Database helpers for E2E tests
 *
 * Provides utilities for database setup, cleanup, and test isolation.
 * These helpers ensure tests run in a clean environment and don't interfere
 * with each other.
 *
 * @module e2e/helpers/database
 * @example
 * import { resetDatabase, seedTestUsers } from '../helpers/database';
 *
 * test.beforeEach(async () => {
 *   await resetDatabase();
 *   await seedTestUsers();
 * });
 */

import { APIRequestContext, request } from "@playwright/test";

/**
 * Base URL for the application API
 * Uses environment variable or defaults to localhost
 */
const BASE_URL = process.env.BASE_URL || "http://localhost:4000";

/**
 * Reset the database to a clean state
 *
 * This function truncates all test data from the database, providing a clean
 * slate for each test. It's typically called in beforeEach hooks to ensure
 * test isolation.
 *
 * **Important**: This only works in test environments. The endpoint will
 * return an error in development or production.
 *
 * @returns Promise that resolves when database is reset
 * @throws {Error} If database reset fails or endpoint is not available
 * @example
 * test.beforeEach(async () => {
 *   await resetDatabase();
 *   // Database is now clean
 * });
 *
 * @example
 * // Use in a test that needs isolation
 * test('user registration', async ({ page }) => {
 *   await resetDatabase();
 *   await page.goto('/auth/register');
 *   // ... test with clean database
 * });
 */
export async function resetDatabase(): Promise<void> {
  const context = await request.newContext();

  try {
    const response = await context.post(`${BASE_URL}/api/test/reset-db`, {
      headers: {
        "Content-Type": "application/json",
      },
    });

    if (!response.ok()) {
      throw new Error(
        `Database reset failed: ${response.status()} ${response.statusText()}`,
      );
    }
  } finally {
    await context.dispose();
  }
}

/**
 * Seed test users into the database
 *
 * Creates the standard test users (admin and regular user) needed for
 * authentication tests. This should be called after resetDatabase() to
 * ensure users exist for login tests.
 *
 * @returns Promise that resolves when users are seeded
 * @throws {Error} If user seeding fails
 * @example
 * test.beforeEach(async () => {
 *   await resetDatabase();
 *   await seedTestUsers();
 *   // Admin and user accounts now exist
 * });
 */
export async function seedTestUsers(): Promise<void> {
  const context = await request.newContext();

  try {
    const response = await context.post(`${BASE_URL}/api/test/seed-users`, {
      headers: {
        "Content-Type": "application/json",
      },
    });

    if (!response.ok()) {
      throw new Error(
        `User seeding failed: ${response.status()} ${response.statusText()}`,
      );
    }
  } finally {
    await context.dispose();
  }
}

/**
 * Seed sample media into the database
 *
 * Creates test TV shows, movies, and episodes for testing media-related
 * functionality. Use this when testing library, search, or metadata features.
 *
 * @param options - Seeding options
 * @param options.tvShows - Number of TV shows to create (default: 3)
 * @param options.movies - Number of movies to create (default: 3)
 * @param options.episodes - Number of episodes per show (default: 5)
 * @returns Promise that resolves when media is seeded
 * @throws {Error} If media seeding fails
 * @example
 * test('library browsing', async ({ page }) => {
 *   await resetDatabase();
 *   await seedTestUsers();
 *   await seedTestMedia({ tvShows: 5, movies: 10 });
 *   // Library now contains test media
 * });
 */
export async function seedTestMedia(options?: {
  tvShows?: number;
  movies?: number;
  episodes?: number;
}): Promise<void> {
  const context = await request.newContext();

  try {
    const response = await context.post(`${BASE_URL}/api/test/seed-media`, {
      headers: {
        "Content-Type": "application/json",
      },
      data: {
        tv_shows: options?.tvShows ?? 3,
        movies: options?.movies ?? 3,
        episodes_per_show: options?.episodes ?? 5,
      },
    });

    if (!response.ok()) {
      throw new Error(
        `Media seeding failed: ${response.status()} ${response.statusText()}`,
      );
    }
  } finally {
    await context.dispose();
  }
}

/**
 * Execute raw SQL against the test database
 *
 * **Warning**: Use with caution! This allows arbitrary SQL execution.
 * Only use for test setup that can't be done through the API.
 *
 * @param sql - SQL query to execute
 * @returns Promise that resolves when query completes
 * @throws {Error} If SQL execution fails or is not allowed
 * @example
 * // Create specific test data
 * await executeSQL(`
 *   INSERT INTO users (username, email, role)
 *   VALUES ('testuser', 'test@example.com', 'user')
 * `);
 */
export async function executeSQL(sql: string): Promise<void> {
  const context = await request.newContext();

  try {
    const response = await context.post(`${BASE_URL}/api/test/execute-sql`, {
      headers: {
        "Content-Type": "application/json",
      },
      data: { sql },
    });

    if (!response.ok()) {
      throw new Error(
        `SQL execution failed: ${response.status()} ${response.statusText()}`,
      );
    }
  } finally {
    await context.dispose();
  }
}

/**
 * Clean up test files and directories
 *
 * Removes test media files, uploads, and temporary directories created
 * during tests. Use this in afterEach or afterAll hooks to clean up
 * file system state.
 *
 * @returns Promise that resolves when cleanup completes
 * @throws {Error} If cleanup fails
 * @example
 * test.afterEach(async () => {
 *   await cleanupTestFiles();
 *   // All test files removed
 * });
 */
export async function cleanupTestFiles(): Promise<void> {
  const context = await request.newContext();

  try {
    const response = await context.post(`${BASE_URL}/api/test/cleanup-files`, {
      headers: {
        "Content-Type": "application/json",
      },
    });

    if (!response.ok()) {
      throw new Error(
        `File cleanup failed: ${response.status()} ${response.statusText()}`,
      );
    }
  } finally {
    await context.dispose();
  }
}

/**
 * Full test environment setup
 *
 * Convenience function that performs complete test environment setup:
 * 1. Resets database to clean state
 * 2. Seeds test users
 * 3. Optionally seeds media
 *
 * This is ideal for beforeEach hooks in test suites that need a complete
 * test environment.
 *
 * @param options - Setup options
 * @param options.seedMedia - Whether to seed media (default: false)
 * @param options.tvShows - Number of TV shows if seeding media
 * @param options.movies - Number of movies if seeding media
 * @returns Promise that resolves when setup completes
 * @throws {Error} If any setup step fails
 * @example
 * // Minimal setup (just users)
 * test.beforeEach(async () => {
 *   await setupTestEnvironment();
 * });
 *
 * @example
 * // Full setup with media
 * test.beforeEach(async () => {
 *   await setupTestEnvironment({
 *     seedMedia: true,
 *     tvShows: 5,
 *     movies: 10
 *   });
 * });
 */
export async function setupTestEnvironment(options?: {
  seedMedia?: boolean;
  tvShows?: number;
  movies?: number;
}): Promise<void> {
  await resetDatabase();
  await seedTestUsers();

  if (options?.seedMedia) {
    await seedTestMedia({
      tvShows: options.tvShows,
      movies: options.movies,
    });
  }
}

/**
 * Full test environment teardown
 *
 * Convenience function that performs complete test environment cleanup:
 * 1. Cleans up test files
 * 2. Resets database (optional)
 *
 * Use this in afterEach or afterAll hooks to ensure clean state.
 *
 * @param options - Teardown options
 * @param options.resetDatabase - Whether to reset database (default: false)
 * @returns Promise that resolves when teardown completes
 * @throws {Error} If any cleanup step fails
 * @example
 * test.afterEach(async () => {
 *   await teardownTestEnvironment({ resetDatabase: true });
 * });
 */
export async function teardownTestEnvironment(options?: {
  resetDatabase?: boolean;
}): Promise<void> {
  await cleanupTestFiles();

  if (options?.resetDatabase) {
    await resetDatabase();
  }
}
