import { test, expect } from '@playwright/test';

test.describe('Authentication and Authorization', () => {
  test('prevents accessing other users conversations', async ({ page, browser }) => {
    // Create and login as first user
    await page.goto('/');
    await page.getByText(/sign in/i).click();
    await page.getByLabel(/email/i).fill('alice@test.com');
    await page.getByLabel(/password/i).fill('test-password');
    await page.getByRole('button', { name: /sign in/i }).click();

    // Create a conversation
    await page.getByPlaceholder(/ask about our menu/i).fill('Show me the menu');
    await page.getByRole('button').click();
    
    // Get conversation URL
    const conversationUrl = page.url();

    // Create new browser context for second user
    const context2 = await browser.newContext();
    const page2 = await context2.newPage();
    
    // Try to access first user's conversation
    await page2.goto(conversationUrl);
    await page2.getByText(/sign in/i).click();
    await page2.getByLabel(/email/i).fill('bob@test.com');
    await page2.getByLabel(/password/i).fill('test-password');
    await page2.getByRole('button', { name: /sign in/i }).click();

    // Verify access is denied
    await expect(page2.getByText(/access denied/i)).toBeVisible();
  });

  test('complete conversation flow with authentication', async ({ page }) => {
    // Sign in
    await page.goto('/');
    await page.getByText(/sign in/i).click();
    await page.getByLabel(/email/i).fill('test@example.com');
    await page.getByLabel(/password/i).fill('test-password');
    await page.getByRole('button', { name: /sign in/i }).click();

    // Start conversation
    await page.getByPlaceholder(/ask about our menu/i).fill('I want a dosa');
    await page.getByRole('button').click();

    // Wait for response and verify
    await expect(page.getByText(/masala dosa/i)).toBeVisible();

    // Send follow-up message
    await page.getByPlaceholder(/ask about our menu/i).fill('Make it spicy');
    await page.getByRole('button').click();

    // Verify customization options
    await expect(page.getByText(/spice level/i)).toBeVisible();

    // Complete order
    await page.getByText(/order now/i).click();

    // Verify order confirmation
    await expect(page.getByText(/thank you/i)).toBeVisible();

    // Verify conversation persistence
    await page.reload();
    await expect(page.getByText(/dosa/i)).toBeVisible();
  });
});