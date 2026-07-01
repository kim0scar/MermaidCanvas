import { defineConfig } from 'vitest/config';

// Vitest kör enhets-/round-trip-tester. Playwright-e2e (apps/**/e2e) körs separat med `playwright test`
// och får INTE plockas upp här (deras test() är Playwrights, inte Vitests).
export default defineConfig({
  test: {
    exclude: ['**/node_modules/**', '**/dist/**', '**/e2e/**'],
  },
});
