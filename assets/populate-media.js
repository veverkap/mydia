const { chromium } = require("@playwright/test");

/**
 * Configuration
 */
const config = {
  baseUrl: process.env.BASE_URL || "http://localhost:4000",
  credentials: {
    username: process.env.USERNAME || "admin",
    password: process.env.PASSWORD || "admin",
  },
};

/**
 * Media to add
 */
const tvSeries = [
  "The Last of Us",
  "House of the Dragon",
  "Severance",
  "The Bear",
  "Succession",
  "Yellowstone",
  "Wednesday",
  "Stranger Things",
];

const movies = [
  "Oppenheimer",
  "Barbie",
  "Poor Things",
  "The Holdovers",
  "Past Lives",
  "Killers of the Flower Moon",
  "The Zone of Interest",
];

/**
 * Add a TV series
 */
async function addSeries(page, seriesName) {
  console.log(`📺 Adding series: ${seriesName}`);

  try {
    await page.goto(`${config.baseUrl}/add/series`);
    await page.waitForLoadState("networkidle");
    await page.waitForTimeout(1000);

    // Check if the search input exists
    const searchInput = page.locator('input[name="search"]');
    const inputExists = (await searchInput.count()) > 0;

    if (!inputExists) {
      console.log(
        `  ⚠ Search input not found - may need authentication or configuration`,
      );
      // Save a screenshot for debugging
      await page.screenshot({ path: "../tmp/debug-series.png" });
      console.log(`  📸 Screenshot saved to tmp/debug-series.png`);
      return;
    }

    // Enter search query
    await searchInput.fill(seriesName);
    await page.click('button[type="submit"]:has-text("Search")');

    // Wait for search results
    await page.waitForTimeout(3000);

    // Click the first "Add" button (quick_add) - excluding "Added" buttons
    const addButton = page
      .locator(
        'button:has-text("Add"):not(:has-text("Added")):not(:has-text("Adding"))',
      )
      .first();
    if (await addButton.isVisible({ timeout: 5000 })) {
      await addButton.click();
      console.log(`  ✓ Added ${seriesName}`);
      await page.waitForTimeout(2000);
    } else {
      console.log(`  ⚠ No results found for ${seriesName}`);
    }
  } catch (error) {
    console.log(`  ✗ Error adding ${seriesName}: ${error.message}`);
  }
}

/**
 * Add a movie
 */
async function addMovie(page, movieName) {
  console.log(`🎬 Adding movie: ${movieName}`);

  try {
    await page.goto(`${config.baseUrl}/add/movie`);
    await page.waitForLoadState("networkidle");
    await page.waitForTimeout(1000);

    // Check if the search input exists
    const searchInput = page.locator('input[name="search"]');
    const inputExists = (await searchInput.count()) > 0;

    if (!inputExists) {
      console.log(
        `  ⚠ Search input not found - may need authentication or configuration`,
      );
      return;
    }

    // Enter search query
    await searchInput.fill(movieName);
    await page.click('button[type="submit"]:has-text("Search")');

    // Wait for search results
    await page.waitForTimeout(3000);

    // Click the first "Add" button (quick_add) - excluding "Added" buttons
    const addButton = page
      .locator(
        'button:has-text("Add"):not(:has-text("Added")):not(:has-text("Adding"))',
      )
      .first();
    if (await addButton.isVisible({ timeout: 5000 })) {
      await addButton.click();
      console.log(`  ✓ Added ${movieName}`);
      await page.waitForTimeout(2000);
    } else {
      console.log(`  ⚠ No results found for ${movieName}`);
    }
  } catch (error) {
    console.log(`  ✗ Error adding ${movieName}: ${error.message}`);
  }
}

/**
 * Main function
 */
async function populateMedia() {
  console.log("🎬 Starting media population...\n");

  const browser = await chromium.launch({
    headless: true,
  });

  const context = await browser.newContext({
    viewport: { width: 1920, height: 1080 },
    deviceScaleFactor: 1,
  });

  const page = await context.newPage();

  try {
    // Login first
    console.log("🔐 Logging in...");
    await page.goto(`${config.baseUrl}/auth/local/login`);
    await page.waitForLoadState("networkidle");

    const loginForm = await page.locator("form").first();
    const formVisible = await loginForm.isVisible().catch(() => false);

    if (formVisible) {
      await page.fill(
        'input[name="user[username]"]',
        config.credentials.username,
      );
      await page.fill(
        'input[name="user[password]"]',
        config.credentials.password,
      );
      await page.click('button[type="submit"]');

      // Wait for navigation to complete
      await page.waitForURL(/\/$/, { timeout: 10000 }).catch(() => {});
      await page.waitForLoadState("networkidle");
      await page.waitForTimeout(2000);
      console.log("✓ Logged in successfully\n");
    } else {
      console.log("ℹ Already logged in\n");
    }

    // Add TV series (skip - already added)
    // console.log('📺 Adding TV Series...\n');
    // for (const series of tvSeries) {
    //   await addSeries(page, series);
    // }

    console.log("🎬 Adding Movies...\n");
    // Add movies
    for (const movie of movies) {
      await addMovie(page, movie);
    }

    console.log("\n✅ Media population complete!");
  } catch (error) {
    console.error("❌ Error populating media:", error.message);
    throw error;
  } finally {
    await browser.close();
  }
}

// Run if called directly
if (require.main === module) {
  populateMedia()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

module.exports = { populateMedia };
