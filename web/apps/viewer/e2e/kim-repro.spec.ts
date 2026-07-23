// Repro av Kims rapport 2026-07-23: tryck direkt efter "Ny canvas" (innan rit-motorn
// laddat) slängdes tyst — nu köas de. Testet trycker SNABBT, som en riktig användare.
import { test, expect } from '@playwright/test';

test.use({ viewport: { width: 393, height: 852 }, hasTouch: true, isMobile: true });

test('mobil: snabbt tryck på Cirkel direkt efter Ny canvas ger en form', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('button', { name: 'Ny canvas' }).click();
  // INGEN väntan — trycket ska överleva att motorn inte laddat än
  await page.getByRole('button', { name: 'Cirkel', exact: true }).click();
  const shape = page.locator('.tl-shape');
  await expect(shape).toHaveCount(1, { timeout: 10_000 });
  const box = await shape.boundingBox();
  expect(box).toBeTruthy();
  // Formen ska ligga synligt i vyn
  expect(box!.y).toBeGreaterThan(0);
  expect(box!.y).toBeLessThan(852);

  // Markera formen med tryck → markerings-raden visas
  await page.touchscreen.tap(box!.x + box!.width / 2, box!.y + box!.height / 2);
  await expect(page.locator('.sel-bar')).toBeVisible({ timeout: 3000 });
});
