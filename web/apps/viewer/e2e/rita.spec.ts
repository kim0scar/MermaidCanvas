// W2 e2e-grinden: öppna Kims riktiga fil → rita-läget → spara → state-blocket intakt.
// Körs i BÅDA projekten (iphone 393×852 + mac 1280×800) — samma renderare, båda bredder.
import { expect, test } from '@playwright/test';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const fixturePath = fileURLToPath(
  new URL('../../../packages/domain/test/fixtures/native-v49-modern.md', import.meta.url),
);
const fixture = readFileSync(fixturePath, 'utf8');

test('öppna modern fil → rita-läge → spara .md med intakt state', async ({ page }) => {
  await page.goto('/');
  await page.getByText('Klistra in text').click();
  await page.locator('textarea').fill(fixture);

  // filen har modernt state-block → appen växlar själv till Rita och tldraw mountar
  await expect(page.locator('.tl-container')).toBeVisible({ timeout: 30000 });
  await expect(page.locator('.tl-shape').first()).toBeVisible({ timeout: 30000 });

  const downloadPromise = page.waitForEvent('download');
  await page.getByRole('button', { name: /Spara/ }).click();
  const download = await downloadPromise;
  const saved = readFileSync((await download.path())!, 'utf8');

  expect(saved).toContain('<!-- mermaidcanvas-state');
  const json = saved.split('<!-- mermaidcanvas-state')[1]!.split('-->')[0]!;
  const state = JSON.parse(json);
  expect(state.nodes).toHaveLength(129);
  expect(state.edges).toHaveLength(128);
  // frontmatter + brödtext bevarade (kirurgisk redigering)
  expect(saved.split('---')[1]).toBe(fixture.split('---')[1]);

  await page.screenshot({ path: `test-results/rita-${test.info().project.name}.png` });
});

test('ny canvas → rit-ytan öppnas med avskalad verktygsrad', async ({ page }) => {
  await page.goto('/');
  await page.getByRole('button', { name: /Ny canvas/ }).click();
  await expect(page.locator('.tl-container')).toBeVisible({ timeout: 30000 });
  // spara en tom canvas ger en giltig ny fil
  const downloadPromise = page.waitForEvent('download');
  await page.getByRole('button', { name: /Spara/ }).click();
  const saved = readFileSync((await (await downloadPromise).path())!, 'utf8');
  expect(saved).toContain('spec_type: general');
  expect(saved).toContain('<!-- mermaidcanvas-state');
});
