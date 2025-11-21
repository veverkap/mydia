/**
 * Media fixtures for E2E tests
 *
 * Provides predefined TV shows, movies, and episodes for testing media-related
 * functionality. These fixtures include realistic metadata to simulate real-world
 * scenarios.
 *
 * @module e2e/fixtures/media
 * @example
 * import { tvShows, movies } from '../fixtures/media';
 *
 * test('search for TV show', async ({ page }) => {
 *   await page.fill('input[name="search"]', tvShows.breakingBad.title);
 *   // ... assert search results
 * });
 */

/**
 * Test fixture for a TV show
 *
 * @typedef {Object} TVShowFixture
 * @property {number} tvdbId - TVDB identifier
 * @property {number} tmdbId - TMDB identifier
 * @property {string} title - Show title
 * @property {number} year - Release year
 * @property {string} overview - Show description
 * @property {string[]} genres - List of genres
 * @property {string} network - Broadcasting network
 * @property {number} seasons - Number of seasons
 */

/**
 * Test fixture for a movie
 *
 * @typedef {Object} MovieFixture
 * @property {number} tmdbId - TMDB identifier
 * @property {string} title - Movie title
 * @property {number} year - Release year
 * @property {string} overview - Movie description
 * @property {string[]} genres - List of genres
 * @property {number} runtime - Runtime in minutes
 */

/**
 * Test fixture for a TV episode
 *
 * @typedef {Object} EpisodeFixture
 * @property {number} season - Season number
 * @property {number} episode - Episode number
 * @property {string} title - Episode title
 * @property {string} airDate - Air date (YYYY-MM-DD)
 * @property {string} overview - Episode description
 */

/**
 * Sample TV shows for testing
 *
 * @constant
 * @example
 * // Use in search tests
 * const show = tvShows.breakingBad;
 * await page.fill('input[name="search"]', show.title);
 * await expect(page.locator('.search-result')).toContainText(show.title);
 */
export const tvShows = {
  /**
   * Breaking Bad - Complete series with 5 seasons
   */
  breakingBad: {
    tvdbId: 81189,
    tmdbId: 1396,
    title: "Breaking Bad",
    year: 2008,
    overview:
      "A high school chemistry teacher diagnosed with inoperable lung cancer turns to manufacturing and selling methamphetamine in order to secure his family's future.",
    genres: ["Crime", "Drama", "Thriller"],
    network: "AMC",
    seasons: 5,
    episodes: [
      {
        season: 1,
        episode: 1,
        title: "Pilot",
        airDate: "2008-01-20",
        overview:
          "When an unassuming high school chemistry teacher discovers he has a rare form of lung cancer, he decides to team up with a former student and create a top of the line crystal meth.",
      },
      {
        season: 1,
        episode: 2,
        title: "Cat's in the Bag...",
        airDate: "2008-01-27",
        overview:
          "Walt and Jesse attempt to tie up loose ends. The desperate situation gets more complicated with the flip of a coin. Walt's wife, Skyler, becomes suspicious of Walt's strange behavior.",
      },
    ],
  },
  /**
   * The Office - Popular sitcom with 9 seasons
   */
  theOffice: {
    tvdbId: 73244,
    tmdbId: 2316,
    title: "The Office",
    year: 2005,
    overview:
      "The everyday lives of office employees in the Scranton, Pennsylvania branch of the fictional Dunder Mifflin Paper Company.",
    genres: ["Comedy"],
    network: "NBC",
    seasons: 9,
    episodes: [
      {
        season: 1,
        episode: 1,
        title: "Pilot",
        airDate: "2005-03-24",
        overview:
          "The premiere episode introduces the boss and staff of the Dunder-Mifflin Paper Company in Scranton, Pennsylvania.",
      },
    ],
  },
  /**
   * Stranger Things - Recent Netflix series with 4 seasons
   */
  strangerThings: {
    tvdbId: 305288,
    tmdbId: 66732,
    title: "Stranger Things",
    year: 2016,
    overview:
      "When a young boy vanishes, a small town uncovers a mystery involving secret experiments, terrifying supernatural forces, and one strange little girl.",
    genres: ["Drama", "Fantasy", "Horror"],
    network: "Netflix",
    seasons: 4,
    episodes: [
      {
        season: 1,
        episode: 1,
        title: "Chapter One: The Vanishing of Will Byers",
        airDate: "2016-07-15",
        overview:
          "On his way home from a friend's house, young Will sees something terrifying. Nearby, a sinister secret lurks in the depths of a government lab.",
      },
    ],
  },
} as const;

/**
 * Sample movies for testing
 *
 * @constant
 * @example
 * // Use in library tests
 * const movie = movies.inception;
 * await page.goto(`/movies/${movie.tmdbId}`);
 * await expect(page.locator('h1')).toContainText(movie.title);
 */
export const movies = {
  /**
   * Inception - Sci-fi thriller
   */
  inception: {
    tmdbId: 27205,
    title: "Inception",
    year: 2010,
    overview:
      "Cobb, a skilled thief who commits corporate espionage by infiltrating the subconscious of his targets is offered a chance to regain his old life as payment for a task considered to be impossible: \"inception\", the implantation of another person's idea into a target's subconscious.",
    genres: ["Action", "Science Fiction", "Mystery"],
    runtime: 148,
  },
  /**
   * The Matrix - Classic sci-fi
   */
  theMatrix: {
    tmdbId: 603,
    title: "The Matrix",
    year: 1999,
    overview:
      "Set in the 22nd century, The Matrix tells the story of a computer hacker who joins a group of underground insurgents fighting the vast and powerful computers who now rule the earth.",
    genres: ["Action", "Science Fiction"],
    runtime: 136,
  },
  /**
   * The Shawshank Redemption - Drama
   */
  shawshankRedemption: {
    tmdbId: 278,
    title: "The Shawshank Redemption",
    year: 1994,
    overview:
      "Framed in the 1940s for the double murder of his wife and her lover, upstanding banker Andy Dufresne begins a new life at the Shawshank prison, where he puts his accounting skills to work for an amoral warden.",
    genres: ["Drama", "Crime"],
    runtime: 142,
  },
} as const;

/**
 * Export type definitions for TypeScript type checking
 */
export type TVShowFixture = typeof tvShows.breakingBad;
export type MovieFixture = typeof movies.inception;
export type EpisodeFixture = (typeof tvShows.breakingBad.episodes)[0];
