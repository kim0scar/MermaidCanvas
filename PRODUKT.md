# PRODUKT.md — vad MermaidCanvas är och varför

*Senast scope-revidering: 2026-06-28 (Kims governance-reset — se "Kärnprincip" + "Hör hemma/Hör INTE hemma" nedan).*

Den här filen är **VARFÖR och VAD**. När Claude Code är osäker på om en feature hör hemma i appen, läs det här först. När scope-tvivel uppstår — kom hit.

## TL;DR

- **Vad**: iPhone-app där Kim ritar former → Mermaid-kod genereras → sparas i `.md`-fil i iCloud Drive
- **För vem**: Kim själv (2e-profil, inte utvecklare) som ett personligt arbetsgränssnitt för människa↔AI-samarbete
- **Varför**: ett gemensamt visuellt språk mellan Kim och Claude Code där diagrammet *är* specen — slipper långa textbeskrivningar

---

## Produktbeskrivning (Kims egna ord)

Det jag vill bygga är en iPhone-first iOS-app för visuell planering och kommunikation med Claude Code. Appen ska låta mig snabbt rita upp skärmlayouter, boxar, flöden, knappar, HUD-element och relationer direkt på iPhone, och sedan spara detta i en gemensam textbaserad projektfil, helst Markdown med Mermaid eller ett liknande strukturerat format som Claude Code kan läsa och arbeta vidare med via `CLAUDE.md`.

Syftet är att skapa ett gemensamt språk mellan människa och AI där det visuella blir styrdokumentet för hur appar, spel, automationer och program ska byggas, i stället för att jag behöver beskriva allt i lång, abstrakt text.

---

## MVP (Kims definition)

MVP:n bör vara medvetet enkel. Första versionen ska låta mig:

1. Skapa ett projekt
2. Rita ett fåtal typer av boxar och pilar på en mobil canvas
3. Namnge dem
4. Koppla ihop skärmar
5. Exportera allt till en gemensam `.md`-fil (t.ex. `ui-spec.md`) som Claude Code kan läsa som projektets UI/UX-kontrakt via `CLAUDE.md`

Nästa steg i MVP: kunna återöppna samma fil, se tidigare struktur visuellt och iterera vidare → samma fil tvåvägs.

---

## Användningsområden

1. **App-UI**: planera och iterera UI för iPhone-appar (inventory, settings, onboarding, dashboard, menyer)
2. **Spel-HUD och touch-kontroller**: layout, placering, navigering på iPhone-spel
3. **Flöden och automationer**: n8n-stil triggers → noder → actions, som styrfil
4. **Systemstruktur**: arkitektur, komponenter, dataflöden

Det sista — automationer och systemstruktur — gör att verktyget inte bara är ett ritblock, utan ett **personligt visuellt gränssnitt för att tänka, planera och kommunicera med AI om hela projekt**.

---

## Målbild: fyra ingångar (tankelägen)

Samma canvas, samma protokoll — fyra olika tankelägen som motsvarar de fyra användningsområdena ovan. Varje läge har sina egna kategorier (`category`-fältet i protokollet), men allt sparas i samma fil-format enligt `METOD-VISUELL-DIALOG.md`.

| Ingång | Tankefråga | Exempel-fil | Typiska kategorier |
|---|---|---|---|
| **UI** | Hur ska detta se ut på skärmen? | `ui-spec.md` | `ui`, `zone`, `note`, `overlay` |
| **Roadmap** | Vad bygger vi nu och senare? | `roadmap.md` | `feat`, `milestone`, `blocker`, `future` |
| **Arkitektur** | Hur är projektet uppbyggt? | `architecture.md` | `folder`, `file`, `module`, `service` |
| **Flow** | Hur rör sig data/agentlogik? | `flow-main.md` | `input`, `agent`, `tool`, `router`, `memory`, `output` |

Byggordning enligt MVP-planen: **UI först** (mest konkret), sedan roadmap, sedan arkitektur, sedan flow. Att hålla dem separata sänker kognitiv belastning — varje läge blir tydligare, mindre överbelastande.

---

## Vad som gör det unikt

Excalidraw och Obsidian är kraftfulla för skissande. MermaidCanvas är smalare och mer riktad:

> Ett iPhone-verktyg som producerar en gemensam arbetsfil för Claude Code, snarare än bara en fristående ritning.

Värdet ligger i att appen är en **bro mellan visuell tanke och AI-driven implementation**, inte en diagramapp som råkar exportera till Mermaid.

Det är särskilt värdefullt för en 2e-person utan traditionell utvecklarbakgrund — kombinationen ADHD, dyslexi, hög begåvning och stark associativitet gör det svårt att hålla röd tråd i enbart textbaserat arbete. Visuellt, konkret, återanvändbart styrspråk → mindre friktion, mindre arbetsminnesbelastning, lättare att fånga idéer i stunden och omvandla dem till byggbara projekt.

---

## Projektmål

Inte att bygga ännu en diagramapp — utan att skapa ett **personligt arbetsgränssnitt för människa–AI-samarbete**. Appen ska hjälpa Kim att:
- Tänka tydligare
- Kommunicera bättre med Claude Code
- Snabbare gå från idé till fungerande app, spel eller automation
- Slippa fastna i abstrakt språk eller kontextförlust

---

## Kärnprincip (2026-06-28, Kims governance-reset)

**Allt ska synas på EN canvas** och struktureras med **expandera/kollapsa + länk + containers**. En "process i en process" hör hemma som en *container* (native mermaid `subgraph`, syns i ren mermaid, kan kollapsas) — INTE som en gömd separat nivå. Allt app-eget ska kunna exporteras till mermaid, och även rena app-funktioner ska en AI kunna förstå ur filen (CLAUDE.md regel 3 + 15). Detta är linsen vid scope-tvivel.

## Hör hemma i appen — JA

- Drag-och-släpp av former (cirkel, fyrkant, triangel, rektangel, romb-beslut + appens egna: kvadrat, oktagon, processpil, phoneFrame, tabell, länk, lös linje, emoji)
- Text *i* formerna — inkl. **rik text** (storlek, fet/kursiv/understruken, justering, listor; per-ord = framtida)
- Pilar med riktning mellan former (färg, sidor, etikett, waypoints, linjeform)
- Pan/zoom på canvas (Lucidchart-känsla)
- **Expandera/kollapsa** grenar + **containers** (gruppera relaterat = native `subgraph`)
- **Länkfunktion** (hoppa mellan kopplade former)
- **Lås form + lager (z: underst/mellan/överst)**
- Flera projekt (varje projekt = en fil)
- Autospar till iCloud Drive + live-läsning när Claude Code skrivit i filen
- Re-rendering av canvas från Mermaid-koden
- Färgkodning av nod-typer + egen färg/fyllning
- Export-format som Claude Code kan använda direkt i andra projekt (inkl. skill-export)
- **macOS-variant** (Catalyst + menyrad) — EN delad kodbas med iPhone (en port, inte en andra app)
- **Multi-fil-import** (flera filer → en container med flikar/länkar) — i scope, byggs som framtida roadmap-steg

## Hör INTE hemma i appen — NEJ

- Fritextredigering utöver text i former
- Komplexa textfält, formulär, dialoger
- Flera **fönster/tabs/splitscreen inom iOS-appen** (en canvas i taget; macOS-porten räknas inte hit)
- **Gömda separata nivåer** (innehåll som inte syns på canvasen + inte i ren mermaid) — t.ex. det gamla underflöde/Visio-drill-bygget. Använd container + kollaps istället (PARKERAT 2026-06-28; se ROADMAP.md för ev. ombyggnad på native subgraphs)
- App-funktioner som **inte kan exporteras till mermaid** eller som en AI inte kan förstå ur filen
- Inbyggd AI-chatt (det är vad Claude Code-sessionen är till för)
- Diagramtyper bortom Kims use cases (t.ex. Gantt, ER, pie chart) — om det behövs senare, lägg till då
- Multi-user / collaboration realtid med andra människor
- Cloud-konton bortom iCloud
- Reklam, in-app-köp, telemetri

---

## Filkonventioner

| Fil | Var | Syfte |
|---|---|---|
| `canvas.md` | `~/Library/Mobile Documents/com~apple~CloudDocs/ClaudeCanvas/canvas.md` | **Live-dialog** mellan iPhone-appen och Claude Code för MermaidCanvas själv |
| `projects/<namn>.md` | `~/Library/Mobile Documents/com~apple~CloudDocs/ClaudeCanvas/projects/` | **Projektfiler** Kim skapar för varje sak han planerar (login-flow, spel-hud, automation, etc.) |
| `ui-spec.md` | I respektive Claude Code-projekt | **Exporterad spec** när Kim använder MermaidCanvas för att styra ett *annat* projekt. Inte i den här appens repo — produceras av appen och placeras där Kim väljer. |

---

## Status & framtid (2026-06-28)

MVP:n ovan är sedan länge levererad och passerad — appen är nu på **v1.5** (universal iPhone/iPad/Mac). Vad varje version innehållit står i `ROADMAP.md`; vad som byggs härnäst styrs av `PROJEKTPLAN.md` (lagen, regel 13). **Kommande funktioner och idéer** (post-bas) bor i `ROADMAP.md` — men inget byggs ur roadmappen utan att först bli ett steg i `PROJEKTPLAN.md` (vi håller oss till metod + plan).

Allt Mermaid-tekniskt står i `MERMAID-FAKTA.md`; det app-egna lagrets exakta bärare i `EXTENDED-FORMAT.md`.
