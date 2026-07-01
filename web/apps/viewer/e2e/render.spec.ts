import { test, expect } from '@playwright/test';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

// En riktig MermaidCanvas .md → visaren renderar en SVG utan fel, i denna bredd (iPhone/Mac).
const sample = readFileSync(
  fileURLToPath(new URL('../../../../arkiv/sample-v27-canvas.md', import.meta.url)),
  'utf8',
);

test('renderar en MermaidCanvas .md → SVG (ingen fel-ruta)', async ({ page }, testInfo) => {
  await page.goto('/');
  await page.getByText('Klistra in text').click(); // öppna <details>
  await page.locator('textarea').fill(sample);
  await expect(page.locator('.diagram svg')).toBeVisible({ timeout: 15_000 });
  await expect(page.locator('.error')).toHaveCount(0);
  await page.screenshot({
    path: testInfo.outputPath(`render-${testInfo.project.name}.png`),
    fullPage: true,
  });
});
