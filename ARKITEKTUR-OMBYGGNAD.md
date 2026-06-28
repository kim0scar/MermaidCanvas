# ARKITEKTUR-OMBYGGNAD — Claude Codes uppdrag & roadmap (MA)

> **Detta är återupptagnings-dokumentet.** Efter `/clear`: läs CLAUDE.md → denna fil → PROJEKTPLAN.md (steg 17). Då har du hela uppdraget, allt som hittats, allt som är gjort, och exakt vad som är kvar — och kan fortsätta direkt.

## Uppdraget (Kims order)
Granska appens arkitektur + kod. Bygg om den STEGVIS (behåll fungerande kärna, ingen omskrivning) så delarna inte påverkar varandra och det går att bygga vidare — App Store-redo. Maskinellt tvingade regler. Ett sätt för Claude att SE och navigera UI:t själv (Kim ska slippa fota). Var intelligent, tänk tre gånger extra, upptäck förbättringar. Verifiera allt; varje steg grönt innan nästa.

## Vad som hittades (granskningen, 6 subagenter)
- Sund kärna: `Sources/Mermaid/` (parser/generator, importerar 0 SwiftUI), `Persistence/`, datamodellen `ShapeNode`/`EdgeConnection`. **Skrivs INTE om.**
- Monoliter: CanvasView 1781, ToolbarView 1069, CanvasModel 857, ContentView 691 rader. Allt hängde ihop runt dem.
- 3 återkommande buggklasser historiskt: **round-trip** (filen ≠ bilden), **fil/sandlåda**, **geometri/rendering**.

## Tre spår
- **Spår C — "se-appen" ✅ KLART.** Claude ser/styr appen i simulatorn. Skill `~/.claude/skills/se-appen/SKILL.md` + motor `scripts/see-app.sh`. Tre kanaler: skärmbild (pixlar), a11y-träd (tappbara element), state-dump (`-uitest-dump-state` → `uitest-state.json`, exakt data). Trigger: Kim säger "titta på appen".
- **Spår B — maskinellt tvingad arkitektur ✅ KLART.** `ARKITEKTUR-REGLER.md` (R1–R5 + version) + `scripts/arch-check.py` + `scripts/arch-baseline.json` (ratchet) + `scripts/hooks/pre-commit` (`git config core.hooksPath scripts/hooks`). CLAUDE.md regel 14. R1 Mermaid rör ej UI · R2 Model ritar ej · R4 inga fatalError/try!/as! i Model+Mermaid · R5 filer ≤300 / jättefiler bara krympa · version AppVersion↔project.yml↔Info.plist. `--appstore` = lanseringschecklista (kvar: PrivacyInfo.xcprivacy).
- **Spår A — skyddsnät + bryt monoliterna ✅ KLART (2026-06-17).** Alla fyra monoliter < 300 rader (CanvasView 1781→297, ToolbarView 1069→237, ContentView 691→225, CanvasModel 857→56), 171+ tester gröna, arch-check grön. Återstår bara valfri round-trip-hårdning (se nedan). Hela MA-uppdraget i praktiken avslutat.

## Skyddsnätet (Spår A, KLART — måste ALLTID vara grönt före refaktor)
36 tester i `app/MermaidCanvas/UnitTests/`:
- **A0** `ShapeNode`/`EdgeConnection: Equatable`.
- **A1** `RoundTripFidelityTests.swift` — djup round-trip (heltalskoord → exakt; Codable-baserad helhetsjämförelse, ignorerar bara id).
- **A2** `StateJSONSymmetryTests.swift` — 18 fält isolerat → fångar skriv/läs-glidning.
- **A3** `CanvasModelMutationTests.swift` — fryst beteendespec (kaskad, undo cap 30, collapse, container-barn, addEdge, duplicate/delete).

## Dekompositionen — GJORT
CanvasView **1781 → 1070** (alla steg: 171 tester gröna + visuell se-appen-koll, ratchet sänkt):
1. `ShapeGeometry` → `Models/ShapeGeometry.swift` (var i View-fil men Model använde den → fel lager).
2–4. `Views/Canvas/`: ConnectionOverlay, FreeLineView, ShapeBackgrounds (private→internal).
5. `ShapeRenderer.swift` (de tre stora form-switcharna) ut ur ShapeView; ShapeView → `Views/Canvas/ShapeView.swift` (279 rader).

## Dekompositionen — ✅ KLAR (2026-06-17). Alla fyra monoliter < 300:
CanvasView 1781→**297** · ToolbarView 1069→**237** · ContentView 691→**225** · CanvasModel 857→**56**.
171 tester gröna + arch-check grön efter varje steg; verifierat i sim (pil-rendering oförändrad, toolbar-rader, sheets, add-form + undo med rerender). Mönster för steg 7–18: dela typen över **extension-filer** (stored-props/@Published stannar i original-typen, metoder flyttas verbatim, `private`→`internal`) — kompilator-garanterad nollbeteendeändring. Detaljerna nedan = historik över vad som gjordes.

### Historik (det som var KVAR, nu gjort)
Ordning, WIP=1. Viktigt: stora vyer var SJÄLVA >300 → delades internt INNAN flytt (inte bara flyttades).

- **Steg 6 — EdgesView** (~730 rader i CanvasView.swift, börjar ~rad 341). Dela i ~4 filer:
  - `EdgeMidpointHandle.swift` — `midpointHandle` + `midpointGesture` (~170 rader, interaktiv vy + kontextmeny).
  - `EdgeDrawing.swift` — ritnings-matematiken under `// MARK: - Drawing`: `drawEdge`, `drawArrowHead`, `outwardNormal` (+ ev. dela i två om >300). Gör till `enum EdgeDrawing` med statiska funktioner; tråda `canvasScale` som parameter (kolla self-referenser: `shapes`/`edges`/`canvasScale`).
  - `EdgeGeometry.swift` — `edgePoint`, `sidePoint`, `edgeAnchors`, `rectSideCenter`, `diamondSideCenter`, `canvasRotatePoint` (rena, använder ShapeGeometry).
  - `EdgesView.swift` — kvarvarande vy (body, isVisible, stubGeometry, minusBadgePosition). Bör hamna <300 efter ovan.
- **Steg 6b — CanvasView-structen** (~322 rader, rad 12–333): `canvasContent` (rad ~130–333) är stor → bryt ut till egen vy/extension så CanvasView.swift hamnar <300.
- **Steg 7–11 — ToolbarView** (1069). REVIDERING 2026-06-17: rader bröts INTE till fristående `struct ...Row: View` (skulle kräva trådning av chip-drag-ut-state → regressrisk som ej syns i skärmbild). I stället: dela `ToolbarView` över **extension-filer** av SAMMA typ (`ToolbarView+ShapesRow/ColorsRow/TextStylesRow/PacksRow/MultiSelectRow/Chips.swift`). `@State`/stored-props stannar i huvud-structen; metod-kroppar flyttas verbatim; `private`→`internal`. Kompilator-garanterad nollbeteendeändring, samma modularitet (<300/fil).
- **Steg 12–13 — ContentView** (691). `ContentView+Files.swift` (open/save/reload/autosave — RÖR autosave/iCloud, extra simulator-verifiering: öppna/ändra/bakgrunda/öppna, ingen dubblettfil/dataförlust) + `ContentView+Sheets.swift` (alla .sheet/.alert).
- **Steg 14–18 — CanvasModel** (857). Behåll EN @Published-fasad (annars tappas rerender). Flytta REN logik till value-`enum`-services som metoderna delegerar till (`self.shapes = ...` triggar fortfarande): `CollapseOps` → `ContainerOps` → `SelectionOps` → `ShapeOps` → `UndoStack` (sist, känsligast). A3-sviten grön efter varje.
- **(Valfritt) round-trip-hårdning:** internt `CanvasState: Codable` så Codable-syntesen blir enda fältsanningen. Egen skyddad commit. Rör ALDRIG Mermaid-fallback-parsern.

## Per-steg-receptet (följ varje gång)
1. Flytta kod (ny fil + redigera monoliten). Verbatim om möjligt.
2. `cd app/MermaidCanvas && xcodegen generate` (registrerar nya filer).
3. `xcodebuild test ... -only-testing:MermaidCanvasUnitTests` → 171+ gröna.
4. View-ändring? `scripts/see-app.sh --scenario 08-arrow-each-shape-type` → `Read` bilden, bekräfta oförändrad.
5. `python3 scripts/arch-check.py --lower-baseline` (sänk taket när fil krympt).
6. Commit (pre-commit kör arch-check). Push. Vid milstolpe: bumpa version + deploy enligt VERSIONSHANTERING.md.

## Snabbfakta / kommandon
- Sim: iPhone 17 Pro `C09B8FE2-6FB9-4D5A-B5F5-BBB4BB1F4E69`. Bygg-derivat: `app/MermaidCanvas/DerivedData-sim`.
- Test: `xcodebuild test -project app/MermaidCanvas/MermaidCanvas.xcodeproj -scheme MermaidCanvas -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath app/MermaidCanvas/DerivedData-sim -only-testing:MermaidCanvasUnitTests`
- Arkitektur-grind: `python3 scripts/arch-check.py` (och `--lower-baseline`, `--appstore`).
- Se appen: `scripts/see-app.sh [--build] [--scenario <slug>] [--dump] [--shot-only]` + `~/.claude/skills/ux-personas-test/bin/ux-driver.sh <UDID> labels|tap|swipe`.
- iPhone-deploy: se VERSIONSHANTERING.md + "Start för ios appar Kim.md" (devicectl-ID `F271CF8E-4260-5501-9E86-1C765EA1A38E`, xcodebuild-ID `00008140-0009446C1EC0801C`, Team `SFXR8MV6MP`).
