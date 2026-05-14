# PRODUKT.md — vad MermaidCanvas är och varför

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

## Hör hemma i appen — JA

- Drag-och-släpp av former (cirkel, fyrkant, triangel, rektangel, romb-beslut)
- Text *i* formerna
- Pilar med riktning mellan former
- Pan/zoom på canvas (Lucidchart-känsla)
- Flera projekt (varje projekt = en fil)
- Autospar till iCloud Drive
- Live-läsning av filen när Claude Code skrivit i den
- Re-rendering av canvas från Mermaid-koden
- Färgkodning av nod-typer
- Subgrafer (gruppera relaterat)
- Export-format som Claude Code kan använda direkt i andra projekt

## Hör INTE hemma i appen — NEJ

- Fritextredigering utöver text i former
- Komplexa textfält, formulär, dialoger
- Flera fönster, tabs, splitscreen
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

## Vad nästa version (v2) bör innehålla

Enligt Kims MVP-definition är detta naturlig första leverans:
1. Projektskapande (lista med projekt i appen)
2. Pan/zoom-canvas
3. Tre formtyper minimum: rektangel (för skärmar/processer), cirkel (för start/slut/markörer), romb (för beslut)
4. Drag-ut från verktygsmeny → släpp på canvas
5. Namnge former (text i form)
6. Pilar mellan former, med riktning + möjlig etikett
7. Spara → genererar Mermaid-kod till `projects/<namn>.md` i iCloud
8. Öppna projekt → läsa Mermaid → re-rendera canvas

Allt detta står Mermaid-tekniskt i `MERMAID-FAKTA.md`.
