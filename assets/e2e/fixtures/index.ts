/**
 * Central export for all E2E test fixtures
 *
 * This module re-exports all test fixtures for convenient importing.
 *
 * @module e2e/fixtures
 * @example
 * // Import specific fixtures
 * import { testUsers, tvShows, searchResults } from '../fixtures';
 *
 * // Or import everything
 * import * as fixtures from '../fixtures';
 */

export * from "./users";
export * from "./media";
export * from "./api-responses";
