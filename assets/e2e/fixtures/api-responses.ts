/**
 * API response fixtures for E2E tests
 *
 * Provides sample API responses from external services (Prowlarr, indexers, etc.)
 * for testing search, download, and integration functionality. These fixtures allow
 * tests to run without depending on external services.
 *
 * @module e2e/fixtures/api-responses
 * @example
 * import { searchResults, torrentInfo } from '../fixtures/api-responses';
 *
 * // Use fixtures to mock API responses in tests
 * const mockData = searchResults.tvShow;
 */

/**
 * Search result fixture
 *
 * @typedef {Object} SearchResultFixture
 * @property {string} guid - Unique identifier for the result
 * @property {string} title - Release title
 * @property {number} size - Size in bytes
 * @property {string} publishDate - Publication date (ISO 8601)
 * @property {string} indexer - Indexer name
 * @property {string} downloadUrl - Download link
 * @property {number} seeders - Number of seeders
 * @property {number} leechers - Number of leechers
 */

/**
 * Torrent info fixture
 *
 * @typedef {Object} TorrentInfoFixture
 * @property {string} hash - Torrent info hash
 * @property {string} name - Torrent name
 * @property {number} size - Total size in bytes
 * @property {number} progress - Download progress (0-100)
 * @property {string} state - Torrent state
 * @property {number} downloadSpeed - Download speed in bytes/sec
 * @property {number} uploadSpeed - Upload speed in bytes/sec
 */

/**
 * Sample search results for TV shows
 *
 * These represent typical responses from indexer searches via Prowlarr
 * or Cardigann indexers.
 *
 * @constant
 * @example
 * // Use in tests to mock search API responses
 * const results = searchResults.tvShow;
 */
export const searchResults = {
  /**
   * TV show search results for Breaking Bad S01E01
   */
  tvShow: [
    {
      guid: "https://example.com/torrent/12345",
      title: "Breaking.Bad.S01E01.Pilot.1080p.BluRay.x264-DEMAND",
      size: 2147483648, // 2 GB
      publishDate: "2024-01-15T10:30:00Z",
      indexer: "Mock Indexer",
      indexerId: 1,
      downloadUrl: "https://example.com/download/12345",
      magnetUrl: "magnet:?xt=urn:btih:ABCDEF1234567890",
      seeders: 150,
      leechers: 25,
      protocol: "torrent",
      categories: ["TV", "TV/HD"],
    },
    {
      guid: "https://example.com/torrent/12346",
      title: "Breaking.Bad.S01E01.720p.WEB-DL.DD5.1.H.264-GROUP",
      size: 1073741824, // 1 GB
      publishDate: "2024-01-15T09:15:00Z",
      indexer: "Mock Indexer",
      indexerId: 1,
      downloadUrl: "https://example.com/download/12346",
      magnetUrl: "magnet:?xt=urn:btih:1234567890ABCDEF",
      seeders: 200,
      leechers: 30,
      protocol: "torrent",
      categories: ["TV", "TV/HD"],
    },
    {
      guid: "https://usenet-indexer.com/nzb/78901",
      title: "Breaking.Bad.S01E01.1080p.BluRay.x264-NTb",
      size: 3221225472, // 3 GB
      publishDate: "2024-01-16T14:20:00Z",
      indexer: "Mock Usenet Indexer",
      indexerId: 2,
      downloadUrl: "https://usenet-indexer.com/api/nzb/78901",
      seeders: 0, // N/A for usenet
      leechers: 0,
      protocol: "usenet",
      categories: ["TV", "TV/HD"],
    },
  ],

  /**
   * Movie search results for Inception
   */
  movie: [
    {
      guid: "https://example.com/torrent/99001",
      title: "Inception.2010.1080p.BluRay.x264-SPARKS",
      size: 8589934592, // 8 GB
      publishDate: "2024-02-01T12:00:00Z",
      indexer: "Mock Indexer",
      indexerId: 1,
      downloadUrl: "https://example.com/download/99001",
      magnetUrl: "magnet:?xt=urn:btih:MOVIE123456789",
      seeders: 500,
      leechers: 50,
      protocol: "torrent",
      categories: ["Movies", "Movies/HD"],
    },
    {
      guid: "https://example.com/torrent/99002",
      title: "Inception.2010.2160p.UHD.BluRay.x265-TERMINAL",
      size: 17179869184, // 16 GB
      publishDate: "2024-02-02T08:30:00Z",
      indexer: "Mock Indexer",
      indexerId: 1,
      downloadUrl: "https://example.com/download/99002",
      magnetUrl: "magnet:?xt=urn:btih:MOVIE4K123456",
      seeders: 250,
      leechers: 35,
      protocol: "torrent",
      categories: ["Movies", "Movies/UHD"],
    },
  ],

  /**
   * Empty search results (no matches found)
   */
  empty: [],
} as const;

/**
 * Sample torrent information from download clients
 *
 * These represent responses from qBittorrent, Transmission, or other
 * download clients when querying torrent status.
 *
 * @constant
 * @example
 * // Use in tests to mock download client API responses
 * const torrents = [torrentInfo.downloading, torrentInfo.seeding];
 */
export const torrentInfo = {
  /**
   * Torrent currently downloading
   */
  downloading: {
    hash: "ABCDEF1234567890ABCDEF1234567890ABCDEF12",
    name: "Breaking.Bad.S01E01.Pilot.1080p.BluRay.x264-DEMAND",
    size: 2147483648,
    progress: 0.45, // 45%
    state: "downloading",
    dlspeed: 5242880, // 5 MB/s
    upspeed: 1048576, // 1 MB/s
    eta: 3600, // 1 hour
    num_seeds: 150,
    num_leechs: 25,
    ratio: 0.5,
    added_on: 1705320000,
    completion_on: 0,
    save_path: "/downloads/tv/Breaking Bad/Season 01/",
    category: "tv",
  },

  /**
   * Torrent that finished downloading and is seeding
   */
  seeding: {
    hash: "1234567890ABCDEF1234567890ABCDEF12345678",
    name: "Inception.2010.1080p.BluRay.x264-SPARKS",
    size: 8589934592,
    progress: 1.0, // 100%
    state: "seeding",
    dlspeed: 0,
    upspeed: 2097152, // 2 MB/s
    eta: 8640000, // Infinite (seeding)
    num_seeds: 500,
    num_leechs: 50,
    ratio: 2.5,
    added_on: 1705233600,
    completion_on: 1705320000,
    save_path: "/downloads/movies/Inception (2010)/",
    category: "movies",
  },

  /**
   * Torrent that is paused
   */
  paused: {
    hash: "FEDCBA0987654321FEDCBA0987654321FEDCBA09",
    name: "The.Matrix.1999.1080p.BluRay.x264",
    size: 4294967296,
    progress: 0.75, // 75%
    state: "pausedDL",
    dlspeed: 0,
    upspeed: 0,
    eta: 8640000, // Infinite (paused)
    num_seeds: 200,
    num_leechs: 20,
    ratio: 0.25,
    added_on: 1705147200,
    completion_on: 0,
    save_path: "/downloads/movies/The Matrix (1999)/",
    category: "movies",
  },

  /**
   * Torrent with error state
   */
  error: {
    hash: "ERROR123456789ERROR123456789ERROR12345678",
    name: "Failed.Download.Example",
    size: 1073741824,
    progress: 0.1, // 10%
    state: "error",
    dlspeed: 0,
    upspeed: 0,
    eta: 8640000,
    num_seeds: 0,
    num_leechs: 0,
    ratio: 0,
    added_on: 1705060800,
    completion_on: 0,
    save_path: "/downloads/failed/",
    category: "tv",
  },
} as const;

/**
 * Sample Prowlarr indexer definitions
 *
 * @constant
 */
export const indexerDefinitions = {
  /**
   * Sample Cardigann indexer definition
   */
  cardigann: {
    id: "mock-indexer",
    name: "Mock Indexer",
    description: "A mock indexer for testing",
    language: "en-US",
    type: "public",
    encoding: "UTF-8",
    links: ["https://mock-indexer.example.com/"],
    caps: {
      categorymappings: [
        { id: "1", cat: "TV", desc: "TV" },
        { id: "2", cat: "Movies", desc: "Movies" },
      ],
      modes: {
        search: ["q"],
        "tv-search": ["q", "season", "ep"],
        "movie-search": ["q"],
      },
    },
    search: {
      paths: [{ path: "/search" }],
      inputs: {
        $raw: "{{ .Keywords }}",
      },
      rows: {
        selector: "table.results tr",
      },
      fields: {
        title: {
          selector: "td.title",
        },
        download: {
          selector: "td.download a",
          attribute: "href",
        },
        size: {
          selector: "td.size",
        },
        seeders: {
          selector: "td.seeders",
        },
        leechers: {
          selector: "td.leechers",
        },
      },
    },
  },
} as const;

/**
 * Export type definitions for TypeScript type checking
 */
export type SearchResultFixture = (typeof searchResults.tvShow)[0];
export type TorrentInfoFixture = typeof torrentInfo.downloading;
export type IndexerDefinitionFixture = typeof indexerDefinitions.cardigann;
