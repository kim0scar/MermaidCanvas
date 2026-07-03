import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { VitePWA } from 'vite-plugin-pwa';

// Fas 1 läs-visare. base: './' → relativa asset-URL:er, funkar på valfri host/subpath (Cloudflare Pages).
// @v2e/domain är en ren-TS workspace-dep (Vite följer symlänken och transpilerar källan) → exkludera
// från esbuild-prebundling. server.fs.allow → låt dev-servern läsa domän-källan utanför app-mappen.
// PWA: installerbar (hemskärm) + offline. SW + manifest genereras vid build; registrering injiceras
// automatiskt (injectRegister: 'auto') — ingen src-ändring behövs.
export default defineConfig({
  plugins: [
    react(),
    VitePWA({
      registerType: 'autoUpdate',
      injectRegister: 'auto',
      includeAssets: ['apple-touch-icon.png'],
      manifest: {
        name: 'Visuali2e',
        short_name: 'Visuali2e',
        lang: 'sv',
        description: 'Rita flödesscheman — sparas som mermaid',
        display: 'standalone',
        start_url: './',
        scope: './',
        theme_color: '#f6f7f9',
        background_color: '#ffffff',
        icons: [
          { src: 'pwa-192.png', sizes: '192x192', type: 'image/png' },
          { src: 'pwa-512.png', sizes: '512x512', type: 'image/png' },
          { src: 'pwa-maskable-512.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' },
        ],
      },
      workbox: {
        // tldraw-chunken (~1,6 MB) MÅSTE precachas så ritläget funkar offline
        maximumFileSizeToCacheInBytes: 4_000_000,
        navigateFallback: 'index.html',
        // /api/** ska aldrig caches — varken som navigering eller runtime
        navigateFallbackDenylist: [/^\/api\//],
      },
    }),
  ],
  base: './',
  optimizeDeps: { exclude: ['@v2e/domain'] },
  build: { outDir: 'dist', sourcemap: false },
  server: { fs: { allow: ['..', '../..'] } },
});
