import { test, expect } from '@playwright/test';

test.describe('Chat Flow', () => {
  test('complete user journey', async ({ page }) => {
    // Start from the home page
    await page.goto('/');

    // Verify initial state
    await expect(page.getByPlaceholder(/ask about our menu/i)).toBeVisible();
    await expect(page.getByText(/namaste/i)).toBeVisible();

    // Send a message
    await page.getByPlaceholder(/ask about our menu/i).fill('I want a dosa');
    await page.getByRole('button').click();

    // Wait for response
    await expect(page.getByText(/dosa/i)).toBeVisible();
    
    // Verify menu card appears
    await expect(page.getByText(/masala dosa/i)).toBeVisible();
    
    // Test customization
    await page.getByText(/customize/i).click();
    await expect(page.getByText(/spice level/i)).toBeVisible();
    
    // Complete order
    await page.getByText(/order now/i).click();
    
    // Verify order confirmation
    await expect(page.getByText(/thank you/i)).toBeVisible();
  });

  test('handles error states', async ({ page }) => {
    await page.goto('/');
    
    // Simulate network error
    await page.route('**/rest/v1/**', route => route.abort());
    
    await page.getByPlaceholder(/ask about our menu/i).fill('Show me the menu');
    await page.getByRole('button').click();
    
    // Verify error handling
    await expect(page.getByText(/trouble connecting/i)).toBeVisible();
  });
});