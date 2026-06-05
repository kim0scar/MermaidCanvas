# GAP-ANALYS v61 — vad saknas för "ren Mermaid-backend"

*Datum: 2026-06-05 (natt-session). Metod: 4 parallella granskar-agenter (round-trip,
Claude→app, n8n, 2e-UX) + adversarial verifiering av varje must-have-påstående mot koden
(23 agenter totalt). Kims mål: rita allt → bygga n8n-flöden som blir skills → kopiera
mermaid rakt av till Claude Code → Claude ritar tillbaka så Kim ser det visuellt.*

---

## Slutsats i en mening

Appen är stark på **Kim → Claude** (state-JSON round-trippar nästan allt), men svag på
**Claude → Kim**: rå mermaid utan state-JSON blir en cirkel av former utan layout, och
ändringar Claude gör i filen syns inte pålitligt i appen på iCloud.

---

## MUST-HAVE (byggs i v61)

| # | Gap | Varför det blockerar målet | Fix |
|---|---|---|---|
| 1 | **Rå mermaid → cirkel-layout.** Parsern struntar i `flowchart TD/LR` och lägger alla noder i en cirkel (`autoPosition`, MermaidParser.swift:439). | Claude skriver oftast vanlig mermaid utan state-JSON. Kim öppnar → ser en obegriplig cirkel = "Claude kan inte rita åt mig". | Lagrad auto-layout: följ kanternas riktning (BFS-nivåer), respektera TD/LR/BT/RL. |
| 2 | **`%% pos:`-kommentarer skrivs men läses aldrig.** Generatorn skriver `%% id pos: x,y` per nod — fallback-parsern läser bara `container-pos`. | Positioner finns i filen men ignoreras = onödig förlust. Mermaid-blocket ska vara självbärande ("ren mermaid i backend"). | Läs `%% pos:` + övriga metadata-kommentarer (size, rot, width, height, color, style, name, prompt, hidden-label, collapsed) i fallback-parsern. |
| 3 | **Live-reload opålitlig på iCloud.** CanvasFileManager pollar modification-date var 2s — känd kunskap: det missar iCloud-ändringar. | Tvåvägs-dialogen är appens hela syfte. Om Claudes ändringar inte dyker upp är dialogen död. | NSFilePresenter (filkoordinerad notifiering) + behåll polling som fallback. |
| 4 | **n8n-flöde är tolkningsbart men inte entydigt.** Kategorier+prompt+namn exporteras, men inget kontrakt säger Claude hur de blir n8n-noder. | "Kopiera rakt av" kräver att Claude aldrig gissar. | Nytt dokument `N8N-FLODE-KONTRAKT.md`: kategori→nodtyp, kantetikett→villkor, input-nodens prompt→trigger-config. Inga app-ändringar krävs. |
| 5 | **3 tryck för att kopiera mermaid-koden.** Meny → sheet → Kopiera. | Kims vanligaste handling. Friktion × varje gång. | "Kopiera Mermaid" direkt i Lägen-menyn (1 tryck). |
| 6 | **Pil-skapande osynligt för ny användare (UX-009).** Handles syns först när en form markeras — inget berättar det. | Pilar är halva språket. | EmptyCanvasHint får en rad om pilar. (Liten del av UX-009; resten kräver design.) |

## NICE-TO-HAVE (backlog, byggs ej inatt)

**Round-trip / mermaid-renhet**
- ProcessArrow/oktagon får generisk rektangel-syntax i mermaid (avsiktligt — state-JSON round-trippar; ev. `@{shape:...}` v11.3+ senare)
- Waypoints, tabell-celler, collapsed läses inte i fallback (skrivs som kommentarer/JSON)
- Stabila mermaid-ID:n (idag index-baserade — kan förskjutas när nod tas bort)

**Claude → app**
- Nästlade subgraphs stöds ej (yttersta vinner)
- classDef/style-rader från Claude ignoreras tyst (logga varning)
- Import-mallen i appen bör varna: utan state-JSON eller `%% pos:` → auto-layout

**n8n / skills**
- Frontmatter-fält: `trigger_type`, `description`, `skill_name`, `target_platform`
- Edge-typ-enum (sequence vs conditional success/error) i stället för fri etikett
- Router-utgångar med villkor + default-gren
- n8n-draft-JSON-export parallellt med mermaid (stor)

**2e-UX**
- UX-009 full lösning (pil-affordance, kräver design) + UX-011 (tabell-upptäckbarhet)
- MermaidImportSheet mindre text-tät (kort + ikoner)
- Fri textstorlek utöver R1/R2/R3/Body
- Kopiera former mellan canvas-filer
- iPad-tangentbordsgenvägar

**Avfärdat av verifierings-agenterna** (fungerar redan eller är by design):
oktagon-fallback, container-barn i JSON, canvas-meta i JSON, platform-frontmatter,
"3-stegs-friktion" (live-fil-flödet är 0 steg när det funkar), EditShapeSheet-textmängd,
node-credentials i appen (hör inte hemma i ritverktyget).

---

## Var fynden kom ifrån

- `MermaidParser.swift` / `MermaidGenerator.swift` — kodbevis rad-för-rad
- `METOD-VISUELL-DIALOG.md` — protokollkravet "förlustfri round-trip"
- `UX_PERSONA_AUDIT.md` — UX-009/UX-011 öppna sedan v50.7
- Memory: `feedback_icloud_polling` — datum-polling missar iCloud-ändringar
