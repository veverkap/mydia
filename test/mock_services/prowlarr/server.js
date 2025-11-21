const express = require("express");
const bodyParser = require("body-parser");

const app = express();
const PORT = process.env.PORT || 9696;
const API_KEY = process.env.API_KEY || "test-api-key";

app.use(bodyParser.json());

// Middleware to validate API key
const validateApiKey = (req, res, next) => {
  const apiKey = req.headers["x-api-key"] || req.query.apikey;
  if (apiKey !== API_KEY) {
    return res.status(401).json({ error: "Unauthorized" });
  }
  next();
};

// Mock indexers
const mockIndexers = [
  {
    id: 1,
    name: "Mock Indexer 1",
    protocol: "torrent",
    privacy: "public",
    enable: true,
    priority: 25,
    added: "2025-01-01T00:00:00Z",
    capabilities: {
      categories: [
        { id: 2000, name: "Movies" },
        { id: 5000, name: "TV" },
      ],
      supportsRawSearch: true,
    },
  },
  {
    id: 2,
    name: "Mock Indexer 2",
    protocol: "usenet",
    privacy: "private",
    enable: true,
    priority: 50,
    added: "2025-01-01T00:00:00Z",
    capabilities: {
      categories: [
        { id: 2000, name: "Movies" },
        { id: 5000, name: "TV" },
      ],
      supportsRawSearch: true,
    },
  },
];

// Mock search results
const mockSearchResults = [
  {
    guid: "mock-result-1",
    indexerId: 1,
    indexer: "Mock Indexer 1",
    title: "Test Movie 2025 1080p BluRay x264",
    size: 2147483648,
    seeders: 150,
    leechers: 10,
    protocol: "torrent",
    downloadUrl: "magnet:?xt=urn:btih:1234567890abcdef",
    infoUrl: "http://example.com/details/1",
    publishDate: "2025-11-16T12:00:00Z",
    categories: [2000],
  },
  {
    guid: "mock-result-2",
    indexerId: 1,
    indexer: "Mock Indexer 1",
    title: "Test TV Show S01E01 720p WEB-DL",
    size: 1073741824,
    seeders: 80,
    leechers: 5,
    protocol: "torrent",
    downloadUrl: "magnet:?xt=urn:btih:abcdef1234567890",
    infoUrl: "http://example.com/details/2",
    publishDate: "2025-11-16T11:00:00Z",
    categories: [5000],
  },
  {
    guid: "mock-result-3",
    indexerId: 2,
    indexer: "Mock Indexer 2",
    title: "Another Test Movie 2025 2160p UHD BluRay x265",
    size: 5368709120,
    protocol: "usenet",
    downloadUrl: "https://usenet.example.com/nzb/12345",
    infoUrl: "http://example.com/details/3",
    publishDate: "2025-11-16T10:00:00Z",
    categories: [2000],
  },
];

// Health check endpoint
app.get("/health", (req, res) => {
  res.json({ status: "ok" });
});

// Get all indexers
app.get("/api/v1/indexer", validateApiKey, (req, res) => {
  res.json(mockIndexers);
});

// Get specific indexer
app.get("/api/v1/indexer/:id", validateApiKey, (req, res) => {
  const indexer = mockIndexers.find((i) => i.id === parseInt(req.params.id));
  if (!indexer) {
    return res.status(404).json({ error: "Indexer not found" });
  }
  res.json(indexer);
});

// Search endpoint
app.get("/api/v1/search", validateApiKey, (req, res) => {
  const { query, categories, type } = req.query;

  let results = [...mockSearchResults];

  // Filter by query if provided
  if (query) {
    results = results.filter((r) =>
      r.title.toLowerCase().includes(query.toLowerCase()),
    );
  }

  // Filter by categories if provided
  if (categories) {
    const catList = categories.split(",").map((c) => parseInt(c));
    results = results.filter((r) =>
      r.categories.some((cat) => catList.includes(cat)),
    );
  }

  res.json(results);
});

// Test connection endpoint
app.get("/api/v1/test", validateApiKey, (req, res) => {
  res.json({ status: "success", message: "Connection successful" });
});

// System status endpoint
app.get("/api/v1/system/status", validateApiKey, (req, res) => {
  res.json({
    appName: "Prowlarr",
    version: "1.0.0-mock",
    startTime: "2025-11-16T00:00:00Z",
    isDebug: false,
    isProduction: true,
  });
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Mock Prowlarr server listening on port ${PORT}`);
  console.log(`API Key: ${API_KEY}`);
});
