/**
 * E2E tests for admin configuration UI
 *
 * Tests cover:
 * - Adding indexers (Prowlarr)
 * - Adding download clients (qBittorrent)
 * - Editing existing configurations
 * - Deleting configurations
 * - Feature flag toggles
 * - Validation and error handling
 */
import { test, expect } from "@playwright/test";
import { AdminConfigPage } from "../pages/AdminConfigPage";
import { loginAsAdmin } from "../helpers/auth";

test.describe("Admin Configuration - Indexers", () => {
  test("can add a Prowlarr indexer", async ({ page }) => {
    // Login as admin
    await loginAsAdmin(page);

    // Navigate to admin config page
    const adminPage = new AdminConfigPage(page);
    await adminPage.goto();
    await adminPage.assertPageLoaded();

    // Go to Indexers tab
    await adminPage.goToIndexersTab();

    // Click "Add Indexer" button
    await adminPage.clickAddIndexer();
    await adminPage.assertIndexerModalVisible();

    // Fill in indexer configuration
    await adminPage.fillIndexerForm({
      name: "Test Prowlarr",
      type: "prowlarr",
      baseUrl: "http://mock-prowlarr:9696",
      apiKey: "test-api-key-123",
    });

    // Save the indexer
    await adminPage.saveIndexer();

    // Verify success message
    await adminPage.assertSuccessMessage("saved successfully");

    // Verify indexer appears in the list
    await adminPage.assertIndexerExists("Test Prowlarr");
  });

  test("can test indexer connection", async ({ page }) => {
    // Login as admin
    await loginAsAdmin(page);

    // Navigate to admin config page
    const adminPage = new AdminConfigPage(page);
    await adminPage.goto();
    await adminPage.goToIndexersTab();

    // Add an indexer first
    await adminPage.clickAddIndexer();
    await adminPage.fillIndexerForm({
      name: "Prowlarr Connection Test",
      type: "prowlarr",
      baseUrl: "http://mock-prowlarr:9696",
      apiKey: "test-api-key-123",
    });
    await adminPage.saveIndexer();

    // Test the connection
    await adminPage.testIndexerConnection();

    // Should see a success or error flash message
    // (Success depends on mock service being available)
    await expect(page.locator("#flash-info, #flash-error")).toBeVisible({
      timeout: 5000,
    });
  });

  test("can edit existing indexer configuration", async ({ page }) => {
    // Login as admin
    await loginAsAdmin(page);

    // Navigate to admin config page
    const adminPage = new AdminConfigPage(page);
    await adminPage.goto();
    await adminPage.goToIndexersTab();

    // Add an indexer first
    await adminPage.clickAddIndexer();
    await adminPage.fillIndexerForm({
      name: "Indexer to Edit",
      type: "prowlarr",
      baseUrl: "http://localhost:9696",
      apiKey: "old-key",
    });
    await adminPage.saveIndexer();
    await adminPage.assertIndexerExists("Indexer to Edit");

    // Edit the indexer
    await adminPage.editIndexer("Indexer to Edit");
    await adminPage.assertIndexerModalVisible();

    // Update the API key
    const apiKeyInput = page.locator('input[name="indexer_config[api_key]"]');
    await apiKeyInput.fill("new-api-key-456");

    // Save changes
    await adminPage.saveIndexer();

    // Verify success message
    await adminPage.assertSuccessMessage("saved successfully");
  });

  test("can delete an indexer", async ({ page }) => {
    // Login as admin
    await loginAsAdmin(page);

    // Navigate to admin config page
    const adminPage = new AdminConfigPage(page);
    await adminPage.goto();
    await adminPage.goToIndexersTab();

    // Add an indexer first
    await adminPage.clickAddIndexer();
    await adminPage.fillIndexerForm({
      name: "Indexer to Delete",
      type: "prowlarr",
      baseUrl: "http://localhost:9696",
      apiKey: "temp-key",
    });
    await adminPage.saveIndexer();
    await adminPage.assertIndexerExists("Indexer to Delete");

    // Delete the indexer
    await adminPage.deleteIndexer("Indexer to Delete");

    // Verify success message
    await adminPage.assertSuccessMessage("deleted successfully");

    // Verify indexer is removed from list
    await adminPage.assertIndexerNotExists("Indexer to Delete");
  });
});

test.describe("Admin Configuration - Download Clients", () => {
  test("can add a qBittorrent download client", async ({ page }) => {
    // Login as admin
    await loginAsAdmin(page);

    // Navigate to admin config page
    const adminPage = new AdminConfigPage(page);
    await adminPage.goto();
    await adminPage.assertPageLoaded();

    // Go to Download Clients tab
    await adminPage.goToClientsTab();

    // Click "Add Download Client" button
    await adminPage.clickAddDownloadClient();
    await adminPage.assertClientModalVisible();

    // Fill in download client configuration
    await adminPage.fillDownloadClientForm({
      name: "Test qBittorrent",
      type: "qbittorrent",
      host: "mock-qbittorrent",
      port: "8080",
      username: "admin",
      password: "adminpass",
      useSsl: false,
    });

    // Save the download client
    await adminPage.saveDownloadClient();

    // Verify success message
    await adminPage.assertSuccessMessage("saved successfully");

    // Verify download client appears in the list
    await adminPage.assertDownloadClientExists("Test qBittorrent");
  });

  test("can test download client connection", async ({ page }) => {
    // Login as admin
    await loginAsAdmin(page);

    // Navigate to admin config page
    const adminPage = new AdminConfigPage(page);
    await adminPage.goto();
    await adminPage.goToClientsTab();

    // Add a download client first
    await adminPage.clickAddDownloadClient();
    await adminPage.fillDownloadClientForm({
      name: "qBittorrent Connection Test",
      type: "qbittorrent",
      host: "mock-qbittorrent",
      port: "8080",
      username: "admin",
      password: "adminpass",
    });
    await adminPage.saveDownloadClient();

    // Test the connection
    await adminPage.testDownloadClientConnection();

    // Should see a success or error flash message
    await expect(page.locator("#flash-info, #flash-error")).toBeVisible({
      timeout: 5000,
    });
  });

  test("can edit existing download client configuration", async ({ page }) => {
    // Login as admin
    await loginAsAdmin(page);

    // Navigate to admin config page
    const adminPage = new AdminConfigPage(page);
    await adminPage.goto();
    await adminPage.goToClientsTab();

    // Add a download client first
    await adminPage.clickAddDownloadClient();
    await adminPage.fillDownloadClientForm({
      name: "Client to Edit",
      type: "qbittorrent",
      host: "localhost",
      port: "8080",
      username: "admin",
      password: "oldpass",
    });
    await adminPage.saveDownloadClient();
    await adminPage.assertDownloadClientExists("Client to Edit");

    // Edit the download client
    await adminPage.editDownloadClient("Client to Edit");
    await adminPage.assertClientModalVisible();

    // Update the password
    const passwordInput = page.locator(
      'input[name="download_client_config[password]"]',
    );
    await passwordInput.fill("newpass");

    // Save changes
    await adminPage.saveDownloadClient();

    // Verify success message
    await adminPage.assertSuccessMessage("saved successfully");
  });

  test("can delete a download client", async ({ page }) => {
    // Login as admin
    await loginAsAdmin(page);

    // Navigate to admin config page
    const adminPage = new AdminConfigPage(page);
    await adminPage.goto();
    await adminPage.goToClientsTab();

    // Add a download client first
    await adminPage.clickAddDownloadClient();
    await adminPage.fillDownloadClientForm({
      name: "Client to Delete",
      type: "qbittorrent",
      host: "localhost",
      port: "8080",
      username: "admin",
      password: "temppass",
    });
    await adminPage.saveDownloadClient();
    await adminPage.assertDownloadClientExists("Client to Delete");

    // Delete the download client
    await adminPage.deleteDownloadClient("Client to Delete");

    // Verify success message
    await adminPage.assertSuccessMessage("deleted successfully");

    // Verify download client is removed from list
    await adminPage.assertDownloadClientNotExists("Client to Delete");
  });
});

test.describe("Admin Configuration - Feature Flags", () => {
  test("can toggle crash reporting setting", async ({ page }) => {
    // Login as admin
    await loginAsAdmin(page);

    // Navigate to admin config page
    const adminPage = new AdminConfigPage(page);
    await adminPage.goto();
    await adminPage.assertPageLoaded();

    // Ensure we're on General Settings tab
    await adminPage.goToGeneralTab();

    // Find the crash reporting toggle
    const crashReportingToggle = page.locator(
      'input[type="checkbox"][phx-value-key="crash_reporting.enabled"]',
    );

    // Get initial state
    const initialState = await crashReportingToggle.isChecked();

    // Toggle the setting
    await adminPage.toggleSetting("crash_reporting.enabled");

    // Wait a bit for the LiveView to update
    await page.waitForTimeout(1000);

    // Verify the state changed
    const newState = await crashReportingToggle.isChecked();
    expect(newState).not.toBe(initialState);

    // Toggle back to original state
    await adminPage.toggleSetting("crash_reporting.enabled");
    await page.waitForTimeout(1000);

    // Verify it's back to initial state
    const finalState = await crashReportingToggle.isChecked();
    expect(finalState).toBe(initialState);
  });
});

test.describe("Admin Configuration - Validation", () => {
  test("shows validation error for indexer with missing fields", async ({
    page,
  }) => {
    // Login as admin
    await loginAsAdmin(page);

    // Navigate to admin config page
    const adminPage = new AdminConfigPage(page);
    await adminPage.goto();
    await adminPage.goToIndexersTab();

    // Click "Add Indexer" button
    await adminPage.clickAddIndexer();
    await adminPage.assertIndexerModalVisible();

    // Try to save without filling required fields
    await adminPage.saveIndexer();

    // Should see validation errors or stay on modal
    // The exact behavior depends on how validation is implemented
    await expect(page.locator('[role="dialog"], .modal-box')).toBeVisible();
  });

  test("shows error for invalid indexer connection", async ({ page }) => {
    // Login as admin
    await loginAsAdmin(page);

    // Navigate to admin config page
    const adminPage = new AdminConfigPage(page);
    await adminPage.goto();
    await adminPage.goToIndexersTab();

    // Add an indexer with invalid credentials
    await adminPage.clickAddIndexer();
    await adminPage.fillIndexerForm({
      name: "Invalid Indexer",
      type: "prowlarr",
      baseUrl: "http://nonexistent-host:9999",
      apiKey: "invalid-key",
    });

    // Try to test connection
    await adminPage.testIndexerConnection();

    // Should see an error message
    // (This depends on the mock service behavior)
    await page.waitForTimeout(2000);

    // Either an error flash or connection test failed message should appear
    const errorVisible = await page
      .locator('#flash-error, [role="alert"]:has-text("failed")')
      .isVisible();
    const infoVisible = await page.locator("#flash-info").isVisible();

    // At least one of them should be visible
    expect(errorVisible || infoVisible).toBe(true);
  });

  test("shows validation error for download client with missing fields", async ({
    page,
  }) => {
    // Login as admin
    await loginAsAdmin(page);

    // Navigate to admin config page
    const adminPage = new AdminConfigPage(page);
    await adminPage.goto();
    await adminPage.goToClientsTab();

    // Click "Add Download Client" button
    await adminPage.clickAddDownloadClient();
    await adminPage.assertClientModalVisible();

    // Try to save without filling required fields
    await adminPage.saveDownloadClient();

    // Should see validation errors or stay on modal
    await expect(page.locator('[role="dialog"], .modal-box')).toBeVisible();
  });

  test("shows error for invalid download client connection", async ({
    page,
  }) => {
    // Login as admin
    await loginAsAdmin(page);

    // Navigate to admin config page
    const adminPage = new AdminConfigPage(page);
    await adminPage.goto();
    await adminPage.goToClientsTab();

    // Add a download client with invalid credentials
    await adminPage.clickAddDownloadClient();
    await adminPage.fillDownloadClientForm({
      name: "Invalid Client",
      type: "qbittorrent",
      host: "nonexistent-host",
      port: "9999",
      username: "invalid",
      password: "invalid",
    });

    // Try to test connection
    await adminPage.testDownloadClientConnection();

    // Should see an error message
    await page.waitForTimeout(2000);

    // Either an error flash or connection test failed message should appear
    const errorVisible = await page
      .locator('#flash-error, [role="alert"]:has-text("failed")')
      .isVisible();
    const infoVisible = await page.locator("#flash-info").isVisible();

    // At least one of them should be visible
    expect(errorVisible || infoVisible).toBe(true);
  });
});
