import { defineConfig } from '@playwright/test';

// Render- + visuell-regressions-grind (Fas 1): samma renderare skärmdumpas i iPhone- OCH Mac-bredd.
// iPhone↔Mac-gapet blir en maskin-grind, inte en bugg. Kräver `npx playwright install chromium`.
export default defineConfig({
  testDir: './e2e',
  timeout: 30_000,
  webServer: {
    command: 'npm run dev -- --port 5199 --strictPort',
    url: 'http://localhost:5199',
    reuseExistingServer: true,
    timeout: 60_000,
  },
  use: { baseURL: 'http://localhost:5199' },
  projects: [
    { name: 'iphone', use: { viewport: { width: 393, height: 852 } } },
    { name: 'mac', use: { viewport: { width: 1280, height: 800 } } },
  ],
});
