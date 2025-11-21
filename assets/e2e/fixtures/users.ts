/**
 * User fixtures for E2E tests
 *
 * Provides predefined test user accounts with different roles and permissions.
 * These users should be seeded into the database before running tests.
 *
 * @module e2e/fixtures/users
 * @example
 * import { testUsers } from '../fixtures/users';
 *
 * test('login as admin', async ({ page }) => {
 *   const { username, password } = testUsers.admin;
 *   await login(page, username, password);
 * });
 */

/**
 * Predefined test users for E2E testing
 *
 * Contains user accounts with different roles:
 * - admin: Full administrative access to all features
 * - user: Regular user with standard permissions
 *
 * These users must be seeded into the test database before running tests.
 * See scripts/seed_test_users.sh for the seeding script.
 *
 * @constant
 * @example
 * // Use in authentication helpers
 * import { testUsers } from '../fixtures/users';
 * await login(page, testUsers.admin.username, testUsers.admin.password);
 *
 * @example
 * // Check user properties
 * const adminEmail = testUsers.admin.email; // 'admin@localhost'
 * const userRole = testUsers.user.role;     // 'user'
 */
export const testUsers = {
  /**
   * Administrator user account with full system access
   */
  admin: {
    /** Admin username for login */
    username: "admin",
    /** Admin password for login */
    password: "adminpass",
    /** Admin email address */
    email: "admin@localhost",
    /** User role (admin has full access) */
    role: "admin",
  },
  /**
   * Regular user account with standard permissions
   */
  user: {
    /** Regular user username for login */
    username: "testuser",
    /** Regular user password for login */
    password: "testpass",
    /** Regular user email address */
    email: "testuser@example.com",
    /** User role (user has standard access) */
    role: "user",
  },
} as const;

/**
 * Type representing a test user object
 *
 * @typedef {Object} TestUser
 * @property {string} username - Username for authentication
 * @property {string} password - Password for authentication
 * @property {string} email - User email address
 * @property {string} role - User role ('admin' | 'user')
 */
export type TestUser = typeof testUsers.admin | typeof testUsers.user;
