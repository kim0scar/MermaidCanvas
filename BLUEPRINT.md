# BLUEPRINT.md — 2e-Think App Arkitektur

> Levande dokument. Uppdateras vid varje version. Refereras i CLAUDE.md.
> **Regel:** Innan du ändrar en fil — läs dess sektion här. Motivera avvikelse för Kim.
> **Mätbara gränser + maskinell kontroll (filstorlek, lager, version): se `ARKITEKTUR-REGLER.md`** (blockerar brott via `scripts/arch-check.py`). Den här filen säger *var* saker bor; ARKITEKTUR-REGLER.md *mäter och stoppar*.

---

## Modul-karta

```
Sources/
├── App/
│   ├── AppVersion.swift              ← versionsnummer (single source of truth)
│   ├── MermaidCanvasApp.swift        ← app-entry + scene-setup
│   ├── ContentView.swift             ← root-layout: toolbar + canvas + sheets
│   │
│   ├── Canvas/
│   │   ├── ZoomableCanvas.swift      ← UIScrollView-wrap (pan/zoom/inertia)
│   │   ├── CanvasViewportState.swift ← synkad spegel av scroll-state
│   │   └── FloatingChipPreview.swift ← flytande form-preview vid drag-to-canvas
│   │
│   ├── Models/
│   │   ├── CanvasModel.swift         ← all canvas-logik, undo, collapse, multi-select
│   │   ├── ShapeNode.swift           ← en form: typ, position, text, stil, metadata
│   │   ├── EdgeConnection.swift      ← en kant: from/to, riktning, stil, waypoints, label
│   │   ├── ColorPack.swift           ← färgpaket (fill/stroke/text-trio)
│   │   ├── TextStyle.swift           ← textstorlek + vikt enum (Rubrik1/2/3/Body)
│   │   └── iPhoneFrameMath.swift     ← hjälp för iPhone-frame-overlay-beräkningar
│   │
│   ├── Views/
│   │   ├── CanvasView.swift          ← HUVUD-CANVAS: ShapeView, EdgesView,
│   │   │                                ConnectionHandles, ConnectionRubberBand,
│   │   │                                ShapeGeometry, alle form-shapes (DiamondShape etc.)
│   │   ├── ToolbarView.swift         ← primär + sekundär toolbar, shape-chips, chip-drag
│   │   ├── EditShapeSheet.swift      ← redigera text/stil/bullets/justering per form
│   │   ├── LägenMenu.swift           ← hamburger-meny (spara/öppna/lägen/importera)
│   │   ├── MarkerOverlay.swift       ← multi-select lasso-drag overlay
│   │   ├── ColorPackPopover.swift    ← välja färgpaket-popover
│   │   ├── ColorPickerPopover.swift  ← välja enstaka färg
│   │   ├── MermaidCodeSheet.swift    ← visa + kopiera Mermaid-kod
│   │   ├── MermaidImportSheet.swift  ← importera Mermaid från AI (2 steg)
│   │   ├── NewCanvasSheet.swift      ← nytt canvas-dialog
│   │   ├── NotePopupSheet.swift      ← visa alla anteckningar
│   │   ├── NoteMiniSheet.swift       ← mini-anteckning per form
│   │   ├── NoteBadge.swift           ← liten antecknings-ikon på form
│   │   ├── CollapseBadge.swift       ← +/- ikon för collapse/expand av sub-träd
│   │   ├── PlatformRulesSheet.swift  ← plattform-regler-info
│   │   ├── PreviewSheet.swift        ← förhandsgranskning (Godot/UI/Flow)
│   │   ├── DotGridBackground.swift   ← canvas-bakgrunds-rutnät
│   │   └── iPhoneFrameOverlay.swift  ← iPhone-ram-overlay för UI-spec-läge
│   │
│   ├── Handles/
│   │   └── SelectionHandles.swift    ← resize (proportional + fri) + rotation-handtag
│   │
│   ├── Persistence/
│   │   ├── CanvasDocument.swift      ← UIDocument-subclass (läs/skriv .md-fil)
│   │   ├── CanvasFileManager.swift   ← iCloud-fil-hantering, öppna/spara/lista
│   │   └── SkillFileComposer.swift   ← v74: portabel skill-export (frontmatter + kontrakt + mermaid)
│   │
│   └── Preview/
│       ├── FlowRenderer.swift        ← flowchart-preview-rendering
│       ├── ArchitectureRenderer.swift← arkitektur-preview
│       ├── UIRenderer.swift          ← UI-spec-preview
│       ├── UIScreenRenderer.swift    ← skärm-rendering
│       ├── GodotPreviewRenderer.swift← Godot-preview
│       └── RoadmapRenderer.swift     ← roadmap-preview
│
├── Mermaid/
│   ├── MermaidGenerator.swift        ← canvas → Mermaid-kod
│   ├── MermaidParser.swift           ← Mermaid-kod → canvas
│   └── SpecType.swift                ← diagram-typ (general/ui/flow/arch)
│
└── ClaudeCode/
    ├── Platform.swift                ← plattform-enum (Blank/Godot)
    ├── PlatformRules.swift           ← regler per plattform
    ├── ShapeCategory.swift           ← form-kategorier + färger
    ├── ShapePack.swift               ← form-paket-enum
    └── SkillExportContract.swift     ← v74: fryst exekverings-kontrakt (master: EXPORT-KONTRAKT.md)
```

---

## Ansvarsfördelning per modul

| Modul | Ansvar | Får INTE göra |
|---|---|---|
| `CanvasModel` | All state-mutation, undo, collapse-logik | UI-rendering, geometry |
| `ShapeNode` | Data-struct för en form. Inga metoder. | Business-logik |
| `EdgeConnection` | Data-struct för en kant. Migration i Decodable. | Business-logik |
| `CanvasView` | Rita alla former + kanter på canvas | State-mutation direkt |
| `ShapeGeometry` (i CanvasView) | Beräkna storlekar + hit-test | Rendering |
| `EdgesView` (i CanvasView) | Rita alla kanter, midpoint-handles, labels | State-mutation direkt |
| `SelectionHandles` | Resize + rotation-handtag per form | All annan UI |
| `ToolbarView` | Primär + sekundär toolbar, chip-drag | Canvas-rendering |
| `ZoomableCanvas` | UIScrollView-wrap: pan/zoom/inertia | Business-logik |
| `MermaidGenerator` | Canvas-state → Mermaid-sträng | State-mutation |
| `MermaidParser` | Mermaid-sträng → canvas-state | Rendering |
| `ContentView` | Koordinator: kopplar Model ↔ View ↔ Sheets | Business-logik |

---

## v39 — Feature-kluster (genomförandeordning)

### Kluster A — App Identity
*Filer: project.pbxproj, AppIcon assets*

| # | Feature | Komplexitet |
|---|---------|------------|
| A1 | Byt namn "Flöde" → "2e" | Trivial |
| A2 | Ny ikon: rosa/lila pastell | Enkel |

---

### Kluster B — Selection Handles (handles bor i SelectionHandles.swift)
*Filer: SelectionHandles.swift, CollapseBadge.swift, CanvasView.swift*

| # | Feature | Komplexitet |
|---|---------|------------|
| B1 | Rotation-handtag: flytta till övre vänster, transparent bakgrund | Enkel |
| B2 | Fri-resize: flytta till nedre vänster, diagonal ikon (`arrow.down.left.and.arrow.up.right`) | Enkel |
| B3 | Collapse/expand badge: flytta från form-hörn till kant-start (nära mittpunktsikonen) | Medium |

---

### Kluster C — Edge Rendering & Routing
*Filer: CanvasView.swift (EdgesView, drawEdge, outwardNormal, edgePoint)*

| # | Feature | Komplexitet |
|---|---------|------------|
| C1 | Kanter utgår från närmaste sidans mitt (inte hörn) | Enkel — `edgePoint()` justeras |
| C2 | Bezier-kurvor behåller nuvarande S-kurva-form (v38) | Klar |
| C3 | Smart routing runt former (obstacle avoidance) | Stor — implementeras som waypoint-algoritm |

> **C3 Mermaid-notering:** Mermaid (Dagre) har inget obstacle-avoidance. Routing visas bara i appen — Mermaid-export ser oförändrad ut. OK per Kim's beslut.

---

### Kluster D — Multi-select Mode
*Filer: ToolbarView.swift, LägenMenu.swift, CanvasModel.swift, CanvasView.swift, MarkerOverlay.swift*

| # | Feature | Komplexitet |
|---|---------|------------|
| D1 | Flytta multi-select-knapp från meny till primär toolbar | Enkel |
| D2 | Multi-select: duplicera alla markerade | Enkel |
| D3 | Multi-select: proportionell resize för alla | Medium |
| D4 | Multi-select: align horisontellt / vertikalt | Medium |

---

### Kluster E — Text & Formatting
*Filer: ToolbarView.swift, ShapeNode.swift, CanvasView.swift, EditShapeSheet.swift*

| # | Feature | Komplexitet |
|---|---------|------------|
| E1 | Textstorlek: picker med 3 nivåer (liten/mellan/stor) i toolbar | Enkel |
| E2 | Fetstil-toggle i toolbar | Enkel |
| E3 | Punktlista / numrerad lista i toolbar | Enkel |
| E4 | Indrag höger/vänster för underlistor | Medium |

---

### Kluster F — Link Pairs
*Filer: CanvasModel.swift, ToolbarView.swift*

| # | Feature | Komplexitet |
|---|---------|------------|
| F1 | Länk-par dras alltid ut i par (redan: addJumpLinkPair) — verifiera UX | Enkel |
| F2 | Tap på länk → hoppar till partner (redan implementerat) — verifiera | Trivial |

> **Mermaid:** Jump-links exporteras som kommentarer + osynliga `~~~`-links. Klickbara pair-jumps är app-only.

---

### Kluster G — Canvas Interaction
*Filer: ZoomableCanvas.swift, CanvasView.swift (ShapeView.dragGesture)*

| # | Feature | Komplexitet |
|---|---------|------------|
| G1 | Auto-scroll när form dras mot canvas-kant | Medium |

---

## Prioritetsordning v39

```
Kluster A (Identity) → B (Handles) → C1 (Edge exits) → D (Multi-select) → E (Text) → F (Links) → G (Auto-scroll) → C3 (Smart routing, sist — störst)
```

---

## Skalbarhetsprinciper

1. **En fil = en ansvarsenhet.** CanvasView.swift är nu 1026 rader — acceptabelt men bör inte växa mer. Nästa stora modul ska brytas ut (t.ex. `EdgesView` → egen fil).
2. **Modellen muteras aldrig direkt från View.** Alltid via `CanvasModel`-metoder.
3. **Ny data i ShapeNode/EdgeConnection** → alltid Codable med bakåtkompatibelt default.
4. **Mermaid export/import** → MermaidGenerator/Parser är isolerade. Inga SwiftUI-imports där.
5. **Handles** bor i `Sources/App/Views/Handles/` — lägg fler filer där vid behov.
6. **Varje ny View-fil** ska vara under 300 rader. Bryt ut om det blir mer.

---

## Filer att INTE röra utan god anledning

| Fil | Varför känslig |
|---|---|
| `ZoomableCanvas.swift` | UIScrollView-wrap — känslig för iOS-specifika race-conditions |
| `CanvasDocument.swift` | iCloud-sync — fel här tappar Kims data |
| `MermaidParser.swift` | Parsning är fragil — testa noga vid ändring |
| `CanvasModel.swift (undo-stack)` | Ändringar kan bryta undo-kedjan |

---

*Senast uppdaterad: v38 → v39. Nästa update vid v40.*
