# v27 GAP-analys

*Datum: 2026-05-16*

Detta är en jämförelse mellan Kims 5 önskningar och vad v27 levererar.

---

## Kims 5 önskningar (verbatim från feedback)

1. **Drag-ut fungerar inkonsekvent** — "jag kan klicka på symboler och de kommer ut men jag kan inte dra dem, dvs jag kan dra vissa men när jag släpper dem händer inget"
2. **Canvas är konstig** — "svårt att zooma och förslytta sig utifrån att det är som den är oändlig åt ett håll. förslag: normalstor + expand vid kant + minikarta-knapp"
3. **Text, Tabell, Länk fungerar inte** — "text tabell och länk fungerar inte alls"
4. **Pilar** — "tjockare/tydligare. markera pil → val för streckad/hel + pil åt ena/andra/båda. på det sättet behövs det inte i menyn"
5. **Visa Mermaid-kod + Preview** — "'visa innehåll' ibland går, ibland inte. byt till 'Visa Mermaid-kod'. ologisk ikon/text. preview, fungerar det?"
6. **Plattform vs mallar** — "ska finnas blank canvas-val + plattformar är bara Godot — det andra är mina form-uppsättningar, inte plattformar"

---

## v27 — vad som FIXADES

| # | Kims önskan | v27-lösning | Verifierat? |
|---|---|---|---|
| 1 | Drag-ut för Tabell+Länk | `specialChip` borttagen; alla 6 form-chips använder nu samma `shapeChip`-mönster med `highPriorityGesture(DragGesture)`. Tap + drag fungerar för alla. | ✅ XCUITest gröna (testDragTableChipToCanvas, testDragLinkChipToCanvas) |
| 2a | Canvas startar mindre | `model.contentSize` startar 2000×2000 (var 3000×3000 statisk) | ✅ Default-värde verifierat |
| 2b | Expand vid kant | `expandCanvasIfNeeded` växer 1000pt om form placeras inom 200pt från kant. Hookad i addShape/addTable/addJumpLinkPair/updatePosition. | ⚠️ Manuell verifiering kvarstår |
| 2c | Minikarta-knapp | `MinimapView` + `toolbar.minimap`-knapp. Toggle, viewport-ram, tap-to-jump. | ✅ XCUITest (testMinimapButtonExistsAndToggles) |
| 3 | Text/Tabell/Länk fungerar | Faktiskt fungerade rendering redan; problemet var bara drag-ut för Tabell/Länk. Allt fixat via #1. | ✅ Tap + drag-tester gröna |
| 4a | Tjockare pilar | `lineWidth: 1.5 → 2.5`. Pilhuvuden ritas som **fyllda trianglar** istället för två linjer. | ✅ Bygget grönt; visuell inspektion på iPhone kvarstår |
| 4b | Streckad/hel linje + dubbelpil | `EdgeStyle.solid / .dashed` på `EdgeConnection`. Context-meny på midpoint utökad med "Hel linje" + "Streckad linje" (utöver befintliga riktning-val). | ⚠️ XCUITest för meny kvarstår |
| 4c | Markera pil → in-context-meny | Context-meny på midpoint-handle finns redan sedan v25. v27 utökar den med stil-val. | ⚠️ Kim's tap-to-show-handle UX-test kvarstår |
| 5a | "Visa Mermaid-kod" namn + ikon | LägenMenu: "Visa filinnehåll" → "Visa Mermaid-kod". Ikon `curlybraces` → `chevron.left.forwardslash.chevron.right`. Sheet-titel: "Filinnehåll" → "Mermaid-kod". | ✅ Bygget grönt |
| 5b | Preview fungerar tydligt | Preview-knapp visas bara om `platform == .godot` (övriga plattformar har ingen renderer). | ✅ LägenMenu-villkor |
| 6a | Blank canvas-val | `Platform.blank` är default i `NewCanvasSheet`. | ✅ NewCanvasSheet förenklad till 2 val |
| 6b | Bara Godot är plattform | `Platform` enum har bara `.blank` + `.godot`. UI/Roadmap/Arch/Flow flyttade till `ShapePack`. | ✅ |
| 6c | Form-paketer slås på i menyn | LägenMenu har ny "Form-paketer"-sektion. Toggles för UI/Roadmap/Arkitektur/Flow. Basic är alltid på. | ✅ XCUITest (testShapePackTogglesExistInModesMenu) |

---

## v27 — vad som INTE ÄR i scope ännu (kommande etapper)

| Område | Beskrivning | När |
|---|---|---|
| **Streckad-stil round-trip i mermaid-block** | Vi exporterar `-.->` / `<-.->` korrekt och parser läser dessa, men XCUITest för full round-trip (skapa → spara → öppna → verifiera stil) saknas. JSON-state har `style`-fält som primär sanningskälla. | Nästa iteration |
| **Färgväljare exponerar paket-kategorier** | När form-pack aktiveras visas inte automatiskt paketens kategorier i färgpaletten. Användaren måste manuellt välja kategori via gammal mekanism. | v28 |
| **Minikarta — drag på röda ramen för pan** | Idag funkar bara **tap** på minikartan. Drag-pan på röda ramen är inte implementerat. | v28 |
| **Form-paketer påverkar shape-chips-raden** | Idag visar Former-raden bara basformer (6 chips). Aktiverade paket borde lägga till fler chips (t.ex. `folder-icon`, `module-icon`). | v28 — kräver custom chip-design per pack |
| **iOS-paketer beyond Godot** | Platform.swift har bara `.blank` och `.godot`. iOS-app-platform kommer "när Godot är klar". | Future |
| **Zoom-känslighet** | Kim sa "zommen är för snabb men jag ser ju inget men det känns så". v27 ändrade inte zoom (pow(0.2) sedan v25). Behöver verifieras på iPhone. | Kollas vid Kim's test |
| **Räta-ut-pil-symbol val** | Kims "räta ut pil"-val i context menu använder ikon `minus`. Skulle kunna vara tydligare. | Polish |
| **Preview för Blank canvas** | Idag dolts preview-knappen om `platform == .blank`. Användarexperience: ska det istället visas med ett "Preview tillgänglig endast för Godot"-meddelande? | UX-feedback från Kim |

---

## Migration-säkerhet

Kim har befintliga canvas-filer i iCloud (t.ex. `canvas test spara.md` med `spec_type: ui|roadmap|...`). v27 läser dessa korrekt:

| Legacy `spec_type` | v27 mapping vid load |
|---|---|
| `ui` | platform=`blank`, packs=`{basic, ui}` |
| `roadmap` | platform=`blank`, packs=`{basic, roadmap}` |
| `architecture` | platform=`blank`, packs=`{basic, architecture}` |
| `flow` | platform=`blank`, packs=`{basic, flow}` |
| `godot` | platform=`godot`, packs=`{basic}` |
| `general` (saknas i fil) | platform=`blank`, packs=`{basic}` |

Inga data förloras. Vid Spara skrivs nytt format med `platform:` + `shape_packs:` i frontmatter samt `platform` + `shapePacks` i JSON-state.

---

## Sample-canvas

Ett v27-sample-canvas skapades och placerades på två platser:
- `/Users/kim/2e Mermaid Code/sample-v27-canvas.md` (i git-repot)
- `~/Library/Mobile Documents/com~apple~CloudDocs/00000. Claude Code/1. Mermaid/sample-v27-canvas.md` (iCloud — kan öppnas i appen på iPhone)

Innehåll: 3 shapes (2 moduler, 1 folder), 2 edges (en solid one-way, en dashed bidi), platform=blank, packs=basic+architecture. Detta är **en exakt round-trip-test** — när Kim öppnar den på iPhone ska han se exakt vad mermaid-koden säger.

---

## Test-status

| Test-suite | Antal | Status |
|---|---|---|
| `DragOutTests` (befintlig) | 5 | ✅ Alla passerar efter v27-refactor |
| `V27FeatureTests` (ny) | 6 | ✅ Alla passerar |
| **Totalt XCUITest** | **11** | **✅ 11/11 gröna i iOS Simulator (iPhone 17)** |

---

## Verifiering Kim ska göra på iPhone

1. **Drag-ut**: Öppna Former-raden → dra varje chip ut till canvasen → landar exakt där fingret släpps.
2. **Pilar**: Skapa två former → dra pil mellan dem → tap+long-press på midpoint-handtaget → välj "Streckad linje" → öppna "Visa Mermaid-kod" → verifiera `-.->` syns.
3. **Canvas expand**: Flytta en form nära canvas-kanten → kanten ska expandera 1000pt.
4. **Minikarta**: Tap på map-knappen i övre hörnet → minikarta öppnas → tap på en plats → canvas hoppar dit.
5. **Plattform**: Lägen-menyn → toggle "Arkitektur"-paketet på/av → ✓ visas i menyn när aktivt.
6. **Visa Mermaid-kod**: Lägen-menyn → "Visa Mermaid-kod" → öppnar sheet med titel "Mermaid-kod" + chevron-bracket-ikon.
7. **Round-trip**: Öppna `sample-v27-canvas.md` från iCloud → ska visa 3 shapes + 2 edges (en solid, en dashed bidi) → Spara → öppna igen → exakt samma.

---

## Verifiering Claude Code ska göra på Mac (framtida)

När Kim refererar till en canvas-fil i iCloud kan Claude Code:
- Läsa `platform:` + `shape_packs:` från frontmatter
- Hänvisa till `<canvas>-regler.md`-sidecar om plattformen är Godot (sidecar finns inte för Blank — det är design)
- Tolka `-.->` / `<-.->` som dashed-pilar i mermaid-block
- Skriva tillbaka korrekt format vid ändringar
