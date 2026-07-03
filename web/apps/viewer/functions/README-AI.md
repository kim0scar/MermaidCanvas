# AI-chatten (Pages Function-proxy)

`/api/chat` reläar chatten till Anthropic. Nyckeln bor som Cloudflare-secret — aldrig i koden, aldrig i webbläsaren. Åtkomstkoder gate:ar kostnaden (Kims vänner får varsin kod).

## Sätta secrets (produktion)

```bash
cd web/apps/viewer
npx wrangler pages secret put OPENROUTER_API_KEY --project-name visuali2e-viewer
npx wrangler pages secret put ACCESS_CODES --project-name visuali2e-viewer
```

- `ACCESS_CODES` = kommaseparerad lista, t.ex. `kim-hemlig1,bjorn-hemlig2`.
- Valfritt: `AI_MODEL` = OpenRouter-slug (annars `anthropic/claude-sonnet-5`; billigare: `anthropic/claude-haiku-4.5`, `google/gemini-2.5-flash`). Nyckeln skapas på openrouter.ai → Keys.

## Rotera åtkomstkoder

Kör `npx wrangler pages secret put ACCESS_CODES --project-name visuali2e-viewer` igen med en ny lista (ta bort/byt den kod som läckt). Gäller direkt — inga omdeployer behövs. Säg åt vännerna att skriva in sin nya kod (appen frågar igen vid 401).

## Köra lokalt

```bash
cd web/apps/viewer
cp .dev.vars.example .dev.vars   # fyll i värdena (filen är gitignorad)
npm run build -w @v2e/viewer      # från web/ — bygger dist/
npx wrangler pages dev dist       # serverar dist/ + functions/ på localhost
```

## Skydd i proxyn

- Fel/saknad åtkomstkod → 401.
- Max 40 meddelanden, max 100 000 tecken totalt → annars 400.
- Canvas-mermaid kapas vid 30 000 tecken.
- Endast `{role, content}` skickas vidare — allt annat i klientens meddelanden saneras bort.
