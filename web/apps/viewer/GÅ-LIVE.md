# Gå live — visaren (Fas 1)

Visaren är en statisk webbapp. Den behöver **ingen server** — bara en gratis statisk host.
Kim gör engångs-kontot; Claude bygger och kör kommandot.

## Se den lokalt (nu, utan konto)
```
cd web
npm install
npm run dev        # → http://localhost:5173
```

## Lägg den live (gratis, delbar URL)
1. **Kim:** skapa gratis konto på https://dash.cloudflare.com (Pages ingår gratis, funkar med privat repo).
2. Bygg: `cd web && npm run build:viewer`  → skapar `apps/viewer/dist/`.
3. Logga in engångs: `npx wrangler login` (öppnar webbläsaren — **Kim godkänner**).
4. Deploy: `cd apps/viewer && npx wrangler pages deploy dist`
   → ger en publik URL (t.ex. `https://visuali2e-viewer.pages.dev`).
5. Öppna URL:en på iPhone, klistra in en canvas eller tryck **Dela** → skicka länken till en vän.

Alternativ utan CLI: Cloudflare-dashboard → Pages → "Upload assets" → dra in `dist/`-mappen.

> GitHub Pages är INTE ett alternativ här: privat repo kräver betald plan.
