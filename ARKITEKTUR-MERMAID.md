# ARKITEKTUR-MERMAID — Milstolpe v0.9 (build v88)
*Datum: 2026-06-20*

> **v87 (v0.9-forts.):** **OSX-app via Mac Catalyst** (Kims "lätt?" → ja; bygger+kör på Mac,
> nu universal iPhone+iPad+Mac). **"Fyra prickarna igen"** — 4 connection-handtag (ett per
> sida), pil går ut från vald sida (ej närmast). **Inline-redigering på canvasen** — namn +
> anteckning skrivs direkt i läs-lappen. (Mac: long-press → högerklick automatiskt via Catalyst.)
> KVAR (kräver Kims input): Fas 2 export-legend (gated) · Visio-drill "hoppa in" (scope) ·
> multi-fil-import (utforskande) · färg-UI-bygg (vagt).

> **v86 (v0.9-forts.) "V79-svep (byggbara delar)":** Facit-täckningsgrind
> (`AppCapabilitiesCoverageTests` — bijektion generator↔facit) + ärlig regel 15 (pekade
> förr på ett test som inte fanns). Facit-menyn "Hur funkar appen" redesignad (färg=
> överlevnad, riktiga glyfer, sök, sticky copy). **JPG-export** (PNG/JPG-val). **Import-
> mallen fixad** (lärde ut `<--` som kraschar mermaid → nu `frameworkText()`, alltid aktuell).
> **Snabb-mallar** (AI-Skill/UI/Arkitektur). **Snabb-navigeringsknapp** (centrera på innehåll).
> KVAR (kräver Kims input/scoping): Fas 2 export-legend (gated), edge-routing-ombyggnad,
> inline-canvas-text, + mega-projekt (OSX, Visio-drill, multi-fil-import). 197 tester gröna.

## Vad v0.9/v85 innehöll (föregående)

> **v0.9 "AI-ramverk som aldrig blir inaktuellt + Mermaid-vs-app-vy":** `AppCapabilities.swift`
> = SINGLE SOURCE OF TRUTH för "vad appen kan visa → vad en AI får använda i mermaid".
> Uttömmande `shape(_:)`-switch (ny ShapeType kompilerar inte utan rad) + `features`-lista
> driver BÅDE in-app-vyn **"Mermaid vs app-funktioner"** (LägenMenu, Kim ser native vs app-egna
> + bärare) OCH en copy-paste-bar **AI-ramvers-text** (`frameworkText()`, alltid genererad ur
> koden → kan aldrig bli stale). **CLAUDE.md regel 15** (icke förhandlingsbar): varje ändring
> måste hålla export↔import-round-trip + AppCapabilities aktuell; `AppCapabilitiesTests` +
> uttömmande switch tvingar currency. Milstolpe-etikett **v0.9** (bygg v85) visas i menyn.
> Verifierat: 193 unit-tester, arch-check, render-grind 3/3, round-trip stabil.

## Vad v84 innehöll (föregående — V79-feedback-svep, 7 features)

> **v84 "V79-feedback-svep (7 features)":** På Kims /goal byggdes 7 klara features ur
> V79-feedbacken (3 scoping-agenter kartlade först): **🔒 lås form** (hänglås — kan ej
> dras/storleksändras, round-trippar `%% locked`), **3 lager** (underst/mellan/överst —
> `ShapeNode.zLayer`, zIndex ±0,3, round-trippar `%% z`), **↪️ redo** (ångra åt båda håll),
> **"Spara Mermaid inom container"** (subset → ren mermaid-fil), **beroendepil-meny i
> kategorier** (Riktning/Stil-undermenyer), **container fri-resize nere höger**, **markera-
> flera ut ur huvudmenyn** (→ Lägen-menyn). Lås+lager round-trippar även på container (4 nya
> tester). Resten av V79-listan = idébank 💡#9–11 (OSX-app, Visio-drill, edge-routing, m.m.).
> Nya filer: `CanvasView+Selection.swift`, `Toolbar/ToolbarView+History.swift` (R5-utbrytningar).
> Verifierat: 191 unit-tester, arch-check, konformitet + render-grind 3/3, round-trip stabil.

## Vad v83 innehöll (föregående — pill-fix + fundament-verifiering)

> **v83 "pill-fix + fundament-verifiering":** Pill-formen rättad (140×60 var för platt →
> 138×74 proportionerlig kapsel; Kims fynd: ful oval-ikon). Fundamentet BEVISAT: scenario 39
> ritar alla basformer med text + kategori-färger, dumpar exakt mermaid (`-uitest-dump-doc`),
> renderar i RIKTIG mermaid (headless Chrome) och jämför mot app — native-former
> (cirkel/pill/rektangel/romb/cylinder) IDENTISKA (typ+text+färg); egna former visas som
> närmaste native men text+färg matchar exakt + identitet via `%%` → re-import exakt. Roten
> städad (stale fynd → arkiv/). 188 tester, render-grind 3/3, round-trip stabil.

## Vad v82 innehöll (föregående — fil-glyfer + UI-mall)

> **v82 "fil-glyfer + UI-mall (steg 8 del 2 + steg 9)":** Fil-former (MD/Excel) får
> igenkännings-glyf på canvasen (`ShapeCategory.fileGlyphSymbol` → `doc.text`/`tablecells`
> i ShapeRenderer). **UI-mall:** Mallar-menyn borttagen → iPhone 15/16 Pro som chips under
> UI-paketet; modellnamnet ritas UTANPÅ ramen (skärmytan fri); phoneFrame får bara
> proportionell resize. **phoneFrame-som-container:** ny `ShapeType.actsAsContainer`
> (container || phoneFrame) → former på skärmen blir barn (childOfContainerId), följer med
> vid flytt, round-trippar via state-JSON. **Byte-stabilitet:** state-JSON serialiseras med
> `.sortedKeys` (deterministisk ordning — tog bort flaky idempotens-test + onödig fil-diff).
> Verifierat: 188 unit-tester, arch-check, konformitet + render-grind 3/3, round-trip 3/3 stabil.

## Vad v81 innehöll (föregående — export-bild + render-grind)

> **v81 "Exportera som bild + render-trogen grind (steg G+H)":** Ny app-funktion
> **"Exportera som bild"** — PNG av enbart den ritade ytan (bbox, ej hela canvasen) via
> SAMMA vyer som canvasen (ShapeView/EdgesView i exportläge, ingen chrome) → kan aldrig
> avvika; sparas i Documents + delningsmeny. Export+render-jämförelsen avslöjade + tätade
> en **noll-avvikelse-bugg**: bakåtpil `<--` kraschade RIKTIG mermaid (mermaid.live) fast
> `mermaid.parse` släppte igenom — nu skrivs bakåtkant som omvänd framåtpil. Grinden är nu
> **render-trogen**: `mermaid-render-check.mjs` (headless Chrome) renderar fixturerna vid
> deploy + lint mot kända glapp i pre-commit. **G2**: basfigur-polish (triangel/romb-text,
> länk-färg, tabell-lager, Pill/Rektangel/Kvadrat åtskilda). **G1**: `EXTENDED-FORMAT.md`
> spikar app-only-lagret + `%% canvas-size` round-trippar nu i ren mermaid (sista tappade
> fältet). Verifierat: 187 unit-tester, arch-check, konformitet + render-grind 3/3, round-trip.
> Nya filer: `Views/Export/{ExportCanvasView,CanvasImageExporter,ActivityView}`,
> `ContentView+Canvas`, `ShapeView+Style`, `Toolbar/ToolbarView+Menu` (R5-utbrytningar).

## Vad v80 innehöll (föregående — STEG F)

> **v80 "noll-avvikelse-garantin (STEG F)":** Round-trip är nu bevisat förlustfritt och
> maskinellt tvingat. Det app-egna lagret ("Extended": `%%`-metadata + state-JSON) bär
> ALLT mermaid saknar (position, färg, storlek, rotation, kollaps, länk, waypoints,
> container-stil, form-typ) utan att skada ren mermaid → överlever om filen skickas till en
> vän. Parsern kapar inte längre tyst ("filen är sanningen"). Verifierat: 186 unit-tester
> gröna, 3/3 fixtures parsar i RIKTIG mermaid, round-trip-grind i pre-commit + deploy, två
> agent-par bekräftade noll avvikelse. MERMAID-FAKTA.md är skrivskyddad facit-bibel (444).

## Vad v80 innehåller (utöver v79)
- **Noll-avvikelse round-trip:** exakt Double-position; 5 former + textjust/listor/waypoints +
  container-stil överlever REN mermaid via `%%`; clamp borttaget (parsern bär exakt filens värden).
- **Extended-lagret formaliserat:** två bärare — `%%`-rader (mermaid ignorerar) + `<!-- state -->`
  (exakt kopia). CLAUDE.md regel 3 omskriven (a/b/c + Apple-robust + metodiskt-genom-former).
- **Maskinell round-trip-grind** i `scripts/hooks/pre-commit` (körs när `Sources/Mermaid/` ändras) + deploy.
- **Nya filer (R5-utbrytningar):** `MermaidGenerator+StateJSON.swift`, `MermaidParser+TextHelpers.swift`,
  `UITestScenarios+FormReview.swift`, `Color+Hex.swift`. Skill-flöde-meny (steg 8 del 1): `.mcp/.plugin/
  .fileMarkdown/.fileExcel` + `ShapePack.skillFlow`.
- **Version-sync:** bundle härleds från `AppVersion.swift` (v80 → 1.80.0 / 80).

## Vad v79 innehöll (milstolpe MA — föregående)
> **v79 "arkitektur-ombyggnad KLAR (milstolpe MA)":** Funktionellt identisk med v77/v78 —
> men nu är ALLA fyra monoliter nedbrutna under 300 rader, koden lagerindelad och
> maskinellt grindad, och Claude kan se/styra appen i simulatorn. Verifierat: 171 unit-
> tester gröna + arch-check grön efter varje steg, samt sim-koll (pil-rendering, toolbar,
> sheets, lägg-form + ångra med rerender).

## Vad v79 innehåller (slutförd MA-milstolpe, utöver v78)
- **Alla fyra monoliter < 300 rader** (mönster: dela typen över extension-filer, @Published-/stored-fasaden kvar i original-typen → rerender oförändrad):
  - **CanvasView** 1781 → **297** (EdgeGeometry/EdgeDrawing/EdgeMidpointHandle/EdgesView i `Views/Canvas/` + CanvasView+Helpers).
  - **ToolbarView** 1069 → **237** (6 extension-rader i `Views/Toolbar/`).
  - **ContentView** 691 → **225** (`ContentView+Files` fil/autosave/drop/scenario + `ContentView+Sheets` attachSheets-kedjan).
  - **CanvasModel** 857 → **56** (7 ansvars-extensions: Shapes/Selection/Containers/Collapse/Edges/Undo/Platform; `@Published`-fasaden kvar i klassen).
- **Lagerindelning** (View → Model → Mermaid/Persistence) med tvingad beroenderiktning.
- **Maskinell grind** (`scripts/arch-check.py` + pre-commit): filstorlek-ratchet, lager-regler, version-sync, inga kraschpunkter i Model/Mermaid.
- **Skyddsnät**: 36 unit-tester (djup round-trip, per-fält-symmetri, CanvasModel-beteendespec).
- **`se-appen`**-loopen: Claude bygger/startar sim, tar egen skärmbild, läser UI + state-dump, trycker/drar.
- **Version-sync**: bundle-version härleds från `AppVersion.swift` (v79 → 1.79.0 / 79).

## Lager + flöden

```mermaid
graph TD
    subgraph View["VIEW-lager (Sources/App/Views, ContentView)"]
        CV[CanvasView]
        SV[ShapeView → ShapeRenderer]
        EV[EdgesView]
        TV[ToolbarView]
        CW[ContentView: root + fil + sheets]
    end
    subgraph Model["MODEL-lager (Sources/App/Models)"]
        CM[CanvasModel: state + mutationer]
        SN[ShapeNode / EdgeConnection]
        SG[ShapeGeometry]
    end
    subgraph MermaidL["MERMAID + PERSISTENCE (rena, 0 SwiftUI)"]
        MP[MermaidParser]
        MG[MermaidGenerator]
        FM[CanvasFileManager]
    end
    CW --> CM
    CV --> CM
    TV --> CM
    SV --> CM
    EV --> CM
    CM --> SN
    CM --> SG
    CW --> MP
    CW --> MG
    CW --> FM
    MP --> SN
    MG --> SN
```

arch-check.py (pre-commit) tvingar pilarnas riktning + filstorlek + version-sync.

## Komponenter

| Komponent | Fil | Ansvar |
|---|---|---|
| Root-vy | `Sources/App/ContentView.swift` (+`ContentView+Files`/`+Sheets`) | App-root + filhantering/autosave + sheet-kedja (225 / 248 / 250) |
| Canvas-vy | `Sources/App/Views/CanvasView.swift` (+`CanvasView+Helpers`) | Canvas-content + interaktion (297 / 54) |
| Kant-lager | `Sources/App/Views/Canvas/{EdgesView,EdgeMidpointHandle,EdgeDrawing,EdgeGeometry}.swift` | Pilar + handtag + bezier-ritning/geometri (178 / 191 / 198 / 220) |
| Form-vy | `Sources/App/Views/Canvas/ShapeView.swift` | En forms vy + gester (279) |
| Form-rendering | `Sources/App/Views/Canvas/ShapeRenderer.swift` | Bakgrund/ram/highlight per ShapeType |
| Canvas-hjälpvyer | `Sources/App/Views/Canvas/{ConnectionOverlay,FreeLineView,ShapeBackgrounds}.swift` | Rubber band/handtag, lösa linjer, tabell/länk-bakgrund |
| Verktygsrad | `Sources/App/Views/ToolbarView.swift` (+`Views/Toolbar/ToolbarView+*Row`/`+Chips`) | Form/färg/textstil/paket/multi-select (237 + 6 extensions, alla <300) |
| Modell | `Sources/App/Models/CanvasModel.swift` (+7 `CanvasModel+*` extensions) | All state (@Published-fasad) + mutationer (56 + Shapes/Selection/Containers/Collapse/Edges/Undo/Platform) |
| Datatyper | `Sources/App/Models/{ShapeNode,EdgeConnection}.swift` | Former + kanter (Equatable + Codable) |
| Geometri | `Sources/App/Models/ShapeGeometry.swift` | Bredd/höjd/hit-test (ren domänlogik) |
| Mermaid | `Sources/Mermaid/{MermaidParser,MermaidGenerator}.swift` | Text ↔ modell (round-trip, 0 SwiftUI) |
| Persistens | `Sources/App/Persistence/*.swift` | iCloud-fil-IO + dokument |
| Testläge | `Sources/App/{UITestScenarios,StateDump}.swift` | Känt canvas-innehåll + state-dump för se-appen |
| Version | `Sources/App/AppVersion.swift` | Single source of truth (v79) |

## Kärninvarianter (icke förhandlingsbara)
- **Förlustfri round-trip + korrekt semantik:** canvas → mermaid/state-JSON → canvas ger IDENTISK bild. Bevisas av `RoundTripFidelityTests` + `StateJSONSymmetryTests` (måste vara gröna före deploy).
- **Mermaid-blocket självbärande** (v61): state-JSON är sanningskällan; mermaid-fallback finns kvar för AI-ritade filer utan JSON.
- **Lagerregler** (ARKITEKTUR-REGLER.md): Mermaid rör aldrig UI; Model ritar aldrig; jättefiler får bara krympa.

## Att verifiera på iPhone (Kims ögon)
- Appen startar och visar **v78** i status-baren.
- Öppna en befintlig canvas-fil, flytta former, dra en pil, spara — inget tappas (round-trip).
