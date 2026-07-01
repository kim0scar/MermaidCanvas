import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// Fas 1 läs-visare. base: './' → relativa asset-URL:er, funkar på valfri host/subpath (Cloudflare Pages).
// @v2e/domain är en ren-TS workspace-dep (Vite följer symlänken och transpilerar källan) → exkludera
// från esbuild-prebundling. server.fs.allow → låt dev-servern läsa domän-källan utanför app-mappen.
export default defineConfig({
  plugins: [react()],
  base: './',
  optimizeDeps: { exclude: ['@v2e/domain'] },
  build: { outDir: 'dist', sourcemap: false },
  server: { fs: { allow: ['..', '../..'] } },
});
