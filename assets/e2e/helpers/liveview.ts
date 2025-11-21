/**
 * LiveView-specific helpers and assertions for E2E tests
 *
 * Provides utilities for working with Phoenix LiveView features including
 * waiting for updates, checking flash messages, testing streams, and handling
 * real-time updates.
 *
 * @module e2e/helpers/liveview
 * @example
 * import { waitForLiveViewUpdate, assertFlashMessage } from '../helpers/liveview';
 *
 * test('LiveView form submission', async ({ page }) => {
 *   await page.click('button[phx-click="save"]');
 *   await waitForLiveViewUpdate(page);
 *   await assertFlashMessage(page, 'success', 'Saved successfully');
 * });
 */
import { Page, expect } from "@playwright/test";

/**
 * Wait for LiveView to finish updating after an action
 *
 * Waits for any LiveView loading indicators to disappear and for the network
 * to be idle. This ensures that LiveView has finished processing server events
 * and rendering updates to the DOM.
 *
 * Use this after clicking buttons with phx-click, submitting forms, or any
 * action that triggers a LiveView server event.
 *
 * @param page - Playwright page object
 * @param timeout - Maximum time to wait in milliseconds (default: 5000)
 * @returns Promise that resolves when LiveView update is complete
 * @throws {Error} If timeout is exceeded waiting for update
 * @example
 * // Click button and wait for LiveView update
 * await page.click('button[phx-click="refresh"]');
 * await waitForLiveViewUpdate(page);
 *
 * // With custom timeout
 * await page.click('button[phx-click="slow-action"]');
 * await waitForLiveViewUpdate(page, 10000);
 */
export async function waitForLiveViewUpdate(
  page: Page,
  timeout: number = 5000,
): Promise<void> {
  // Wait for any loading indicators to disappear
  await page.waitForFunction(
    () => {
      const loadingElements = document.querySelectorAll(
        "[phx-loading], .phx-loading",
      );
      return (
        loadingElements.length === 0 ||
        Array.from(loadingElements).every(
          (el) => !el.classList.contains("phx-loading"),
        )
      );
    },
    { timeout },
  );

  // Also wait for network to be idle
  await page.waitForLoadState("networkidle", { timeout });
}

/**
 * Assert that a flash message is displayed
 * @param page - Playwright page object
 * @param type - Flash message type ('info', 'error', 'success', 'warning')
 * @param message - Expected message text (can be substring)
 */
export async function assertFlashMessage(
  page: Page,
  type: "info" | "error" | "success" | "warning",
  message?: string,
): Promise<void> {
  // Wait for flash message to appear
  const flashSelector = `[role="alert"], .alert, .flash-${type}, [data-test="flash-${type}"]`;
  await page.waitForSelector(flashSelector, {
    state: "visible",
    timeout: 3000,
  });

  if (message) {
    // Check that the flash contains the expected message
    const flashElement = page.locator(flashSelector).first();
    await expect(flashElement).toContainText(message, { timeout: 2000 });
  }
}

/**
 * Assert that a LiveView stream has been updated
 * This checks for the presence of new items in a phx-update="stream" container
 *
 * @param page - Playwright page object
 * @param streamId - The ID of the stream container
 * @param expectedItemCount - Optional: expected number of items in the stream
 */
export async function assertStreamUpdated(
  page: Page,
  streamId: string,
  expectedItemCount?: number,
): Promise<void> {
  // Wait for the stream container to exist
  const streamSelector = `#${streamId}[phx-update="stream"]`;
  await page.waitForSelector(streamSelector, {
    state: "attached",
    timeout: 3000,
  });

  if (expectedItemCount !== undefined) {
    // Count direct children (stream items)
    await page.waitForFunction(
      ({ selector, count }) => {
        const container = document.querySelector(selector);
        if (!container) return false;
        return container.children.length === count;
      },
      { selector: streamSelector, count: expectedItemCount },
      { timeout: 5000 },
    );
  }
}

/**
 * Click an element and wait for LiveView to update
 *
 * Convenience function that combines clicking an element with waiting for
 * the LiveView update to complete. Equivalent to calling page.click()
 * followed by waitForLiveViewUpdate().
 *
 * @param page - Playwright page object
 * @param selector - CSS selector for the element to click
 * @returns Promise that resolves when click and update are complete
 * @throws {Error} If element is not found or timeout is exceeded
 * @example
 * // Instead of:
 * // await page.click('button#refresh');
 * // await waitForLiveViewUpdate(page);
 *
 * // Use:
 * await clickAndWaitForUpdate(page, 'button#refresh');
 */
export async function clickAndWaitForUpdate(
  page: Page,
  selector: string,
): Promise<void> {
  await page.click(selector);
  await waitForLiveViewUpdate(page);
}

/**
 * Fill a form field and wait for LiveView validation
 *
 * Fills an input field, triggers a blur event to initiate validation,
 * and waits for validation to complete. Useful for testing real-time
 * form validation in LiveView forms.
 *
 * @param page - Playwright page object
 * @param selector - CSS selector for the form field
 * @param value - Value to fill into the field
 * @returns Promise that resolves when field is filled and validation completes
 * @throws {Error} If field is not found
 * @example
 * await fillAndWaitForValidation(page, 'input[name="email"]', 'test@example.com');
 * // Check for validation error
 * await expect(page.locator('.error')).not.toBeVisible();
 */
export async function fillAndWaitForValidation(
  page: Page,
  selector: string,
  value: string,
): Promise<void> {
  await page.fill(selector, value);
  // Trigger blur event to run validations
  await page.locator(selector).blur();
  // Wait a bit for validation to complete
  await page.waitForTimeout(500);
}

/**
 * Submit a LiveView form and wait for response
 *
 * Finds the submit button within the form, clicks it, and waits for the
 * LiveView update to complete. This is the proper way to submit LiveView
 * forms in tests.
 *
 * @param page - Playwright page object
 * @param formSelector - CSS selector for the form element
 * @returns Promise that resolves when form is submitted and update completes
 * @throws {Error} If form or submit button is not found
 * @example
 * await page.fill('input[name="title"]', 'My Title');
 * await submitFormAndWait(page, 'form#media-form');
 * await assertFlashMessage(page, 'success', 'Media added');
 */
export async function submitFormAndWait(
  page: Page,
  formSelector: string,
): Promise<void> {
  await page.locator(formSelector).locator('button[type="submit"]').click();
  await waitForLiveViewUpdate(page);
}

/**
 * Wait for a specific Phoenix/LiveView event to be triggered
 *
 * Listens for custom Phoenix events (dispatched via push_event/3 in LiveView).
 * This is useful for testing custom JavaScript hooks and event handling.
 *
 * Note: The event name should not include the 'phx:' prefix - it will be
 * added automatically.
 *
 * @param page - Playwright page object
 * @param eventName - Name of the Phoenix event (without 'phx:' prefix)
 * @param timeout - Maximum time to wait in milliseconds (default: 5000)
 * @returns Promise that resolves when the event is triggered
 * @throws {Error} If timeout is exceeded waiting for event
 * @example
 * // In LiveView: push_event(socket, "media-added", %{id: 123})
 * // In test:
 * await page.click('button[phx-click="add-media"]');
 * await waitForPhoenixEvent(page, 'media-added');
 */
export async function waitForPhoenixEvent(
  page: Page,
  eventName: string,
  timeout: number = 5000,
): Promise<void> {
  await page.waitForFunction(
    (event) => {
      return new Promise((resolve) => {
        window.addEventListener(`phx:${event}`, () => resolve(true), {
          once: true,
        });
        // Also resolve if the event was already triggered
        setTimeout(() => resolve(false), 100);
      });
    },
    eventName,
    { timeout },
  );
}

/**
 * Check if LiveView is connected to the server
 *
 * Checks the LiveView socket connection state. Useful for debugging
 * connection issues or ensuring LiveView is ready before performing actions.
 *
 * @param page - Playwright page object
 * @returns Promise resolving to true if LiveView is connected, false otherwise
 * @example
 * const connected = await isLiveViewConnected(page);
 * if (!connected) {
 *   console.log('LiveView not connected, retrying...');
 *   await page.reload();
 * }
 */
export async function isLiveViewConnected(page: Page): Promise<boolean> {
  return await page.evaluate(() => {
    const liveSocket = (window as any).liveSocket;
    if (!liveSocket) return false;

    // Check if there are any connected views
    const views = liveSocket.main ? [liveSocket.main] : [];
    return views.some((view: any) => view.isConnected && view.isConnected());
  });
}

/**
 * Wait for LiveView to be fully connected and ready
 *
 * Waits for the LiveView socket to establish a connection with the server.
 * Use this after page navigation to ensure LiveView is ready before
 * interacting with the page.
 *
 * @param page - Playwright page object
 * @param timeout - Maximum time to wait in milliseconds (default: 5000)
 * @returns Promise that resolves when LiveView is connected
 * @throws {Error} If timeout is exceeded waiting for connection
 * @example
 * await page.goto('/media');
 * await waitForLiveViewReady(page);
 * // Now safe to interact with LiveView elements
 * await page.click('button[phx-click="refresh"]');
 */
export async function waitForLiveViewReady(
  page: Page,
  timeout: number = 5000,
): Promise<void> {
  await page.waitForFunction(
    () => {
      const liveSocket = (window as any).liveSocket;
      return liveSocket && liveSocket.isConnected && liveSocket.isConnected();
    },
    { timeout },
  );
}
