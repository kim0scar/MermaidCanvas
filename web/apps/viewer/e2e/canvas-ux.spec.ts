// Canvas-paritet mot iOS: begränsat papper, drag-ut från chips, zoom-knappar.
// Läser editor-state via test-kroken window.__v2eEditor (sätts i onEditorMount).
import { test, expect, type Page } from '@playwright/test';

type Ed = {
  setCamera: (c: { x: number; y: number; z: number }, o?: object) => void;
  getViewportPageBounds: () => { x: number; y: number; w: number; h: number };
  getZoomLevel: () => number;
  zoomIn: () => void;
  getCurrentPageShapes: () => Array<{ type: string; x: number; y: number }>;
};

async function openRita(page: Page) {
  await page.goto('/');
  await page.getByRole('button', { name: 'Ny canvas' }).click();
  await page.waitForFunction(() => Boolean((window as unknown as { __v2eEditor?: unknown }).__v2eEditor));
}

test('kameran kan inte panoreras bort från pappret och zoom stannar på max 4', async ({ page }) => {
  await openRita(page);
  const vp = await page.evaluate(() => {
    const ed = (window as unknown as { __v2eEditor: Ed }).__v2eEditor;
    ed.setCamera({ x: -50_000, y: -50_000, z: 1 }, { immediate: true });
    const b = ed.getViewportPageBounds();
    return { x: b.x, y: b.y, w: b.w, h: b.h };
  });
  // Vyn ska fortfarande överlappa pappret 0–4000
  expect(vp.x).toBeLessThan(4000);
  expect(vp.x + vp.w).toBeGreaterThan(0);
  expect(vp.y).toBeLessThan(4000);
  expect(vp.y + vp.h).toBeGreaterThan(0);

  const zoom = await page.evaluate(() => {
    const ed = (window as unknown as { __v2eEditor: Ed }).__v2eEditor;
    for (let i = 0; i < 12; i += 1) ed.zoomIn();
    return ed.getZoomLevel();
  });
  expect(zoom).toBeLessThanOrEqual(4.01);
});

test('drag-ut från chip lägger formen på släpp-punkten', async ({ page }) => {
  await openRita(page);
  const chip = page.getByRole('button', { name: 'Cirkel', exact: true });
  const box = (await chip.boundingBox())!;
  const canvas = (await page.locator('.canvas-wrap').boundingBox())!;
  const drop = { x: canvas.x + canvas.width * 0.3, y: canvas.y + canvas.height * 0.6 };

  await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
  await page.mouse.down();
  await page.mouse.move(drop.x, drop.y, { steps: 8 });
  await page.mouse.up();

  await expect(page.locator('.tl-shape')).toHaveCount(1);
  // Formen ska ligga nära släpp-punkten i page-koordinater
  const ok = await page.evaluate((pt) => {
    const ed = (window as unknown as { __v2eEditor: Ed & { screenToPage: (p: { x: number; y: number }) => { x: number; y: number } } }).__v2eEditor;
    const s = ed.getCurrentPageShapes().find((sh) => sh.type === 'v2e-shape')!;
    const page_ = ed.screenToPage(pt);
    return Math.hypot(s.x - page_.x, s.y - page_.y) < 150;
  }, drop);
  expect(ok).toBe(true);
});

test('litet wobbel (<8px) räknas som vanligt tryck och lägger form i mitten', async ({ page }) => {
  await openRita(page);
  const chip = page.getByRole('button', { name: 'Cirkel', exact: true });
  const box = (await chip.boundingBox())!;
  await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2);
  await page.mouse.down();
  await page.mouse.move(box.x + box.width / 2 + 3, box.y + box.height / 2 + 3);
  await page.mouse.up();
  await expect(page.locator('.tl-shape')).toHaveCount(1);
});

test('zoom-knapparna ändrar zoom och pappret läcker aldrig in i dokumentet', async ({ page }) => {
  await openRita(page);
  const before = await page.evaluate(() =>
    (window as unknown as { __v2eEditor: Ed }).__v2eEditor.getZoomLevel(),
  );
  await page.getByRole('button', { name: 'Zooma in' }).click();
  await expect
    .poll(() =>
      page.evaluate(() => (window as unknown as { __v2eEditor: Ed }).__v2eEditor.getZoomLevel()),
    )
    .toBeGreaterThan(before);
  await page.getByRole('button', { name: 'Passa in allt' }).click();

  // Export-renhet: bara v2e-former/pilar finns i store:n — inget papper
  await page.getByRole('button', { name: 'Cirkel', exact: true }).click();
  const types = await page.evaluate(() =>
    (window as unknown as { __v2eEditor: Ed }).__v2eEditor.getCurrentPageShapes().map((s) => s.type),
  );
  expect(types.every((t) => t === 'v2e-shape' || t === 'arrow')).toBe(true);
});
