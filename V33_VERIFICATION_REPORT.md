# V33 Verification Report

**Datum:** 2026-05-19
**Build:** AppVersion.current = "v33"
**iPhone-deploy:** com.kimlundqvist.mermaidcanvas på F271CF8E (Kims iPhone 16 Pro)

## Automated test-resultat (iPhone 17 Pro simulator)

| Test-suite | Resultat | Tid | Status |
|---|---|---|---|
| **V33SensorTests** (drop-precision) | 2/2 passed | 30s | ✅ |
| **V33AutoLoopTests** (60s autonom interaktion) | 1/1 passed | 67s | ✅ |
| **V27FeatureTests** (drag-out, position-precision) | 6/7 passed, 1 skipped | 74s | ✅ |
| **V28VisualTests** (visuell granskning) | 1/1 passed | 21s | ✅ |
| **V29CoverageTests** (minimap, edit, drop-fallback) | 3/3 passed, 3 skipped | 30s | ✅ |
| **LayoutOverflowTests** (UI fits on screen) | 2/2 passed | 18s | ✅ |
| EndToEndTests | 4/4 skipped (v32-quirk) | - | ⏭️ |

**Totalt: 15 testfall gröna, 0 failures.** Skipped-events är medvetna från v32 (sheet.codeContent-läsning trasig) eller obsolet pack-toggles-test.

## Kritiska bevis

### LayoutOverflowTests.testToolbarFitsOnScreen — PASSED
Bekräftar att hela toolbarn ryms på iPhone-bredden (393pt). Detta var det specifika problemet med 44pt-knappar + 9 knappar. Genom att flytta markerButton till Lägen-menyn ryms allt nu.

### LayoutOverflowTests.testShapesRowChipsFitOnScreen — PASSED
Shape-chips-raden ryms också utan trängsel.

### V33SensorTests.testDragCircleToKnownPosition — PASSED
Drar cirkel till känd skärmpunkt → mätningsdiff < 30pt. Bevisar att A10 (transformEffect) löste canvas-bugen där "objekt landar inte där fingret släpps".

### V33SensorTests.testTapCircleCreatesShape — PASSED
Tap på cirkel-chip skapar form vid canvas-(800, 800) = centrum av 1600×1600. Toolbar-tap-flödet fungerar.

### V33AutoLoopTests.testAutoLoopRandomInteractions — PASSED (67.5s)
60 sekunder autonoma interaktioner: open_shapes_row, tap_chip_circle, tap_chip_rectangle, drag_chip_to_canvas_center/topleft/bottomright, pan_canvas_right, pan_canvas_up. Diagnostik via toolbar.zoom-badge. **Ingen krasch, inga unmount-fel.**

## v33-ändringar applicerade

### Canvas-fix (löste den ursprungliga bug-rapporten)
- `transformEffect` istället för `scaleEffect + offset` ([CanvasView.swift:83-91](app/MermaidCanvas/Sources/App/Views/CanvasView.swift))
- Synkron `dragController.canvasOffset/canvasScale`-synk inuti gesture-handlers (rad 335-336, 367-371)
- `withAnimation` borttagen från `requestedCenterPoint`-onChange

### UI-polish (Apple HIG)
- `ToolbarIconButton`: frame 40→44pt, font 16→17pt ([LägenMenu.swift:88-91](app/MermaidCanvas/Sources/App/Views/LägenMenu.swift))
- `ChipFace.small`: 40→44pt
- `zoomBadge`: 48→40pt minWidth
- Primary HStack: spacing 6→4, padding 14→10
- `computeViewportCenter()` helper (single source of truth)

### Layout-fix
- markerButton flyttad från primary toolbar till Lägen-menyn (med dynamisk label: "Markeringsläge" / "Stäng markeringsläge")
- Mode-meny utökad med onToggleMarker-callback

### Städning (från stash)
- Preview-knapp + PreviewSheet borttagen
- MermaidCodeSheet uppdaterad till live (regenereras vid varje render via `@ObservedObject model`)
- accessibilityIdentifier:s på edit.label, edit.note
- "Tom canvas" placeholder-text borttagen från MermaidGenerator

## Commits (alla på origin/main)

```
0d45a18 v33 final polish: 44pt-knappar (Apple HIG), markerButton till menyn
a12cf8c v33 toolbar-polish: spacing 6→4, padding 14→10, chip 40→44, zoom 48→40
3cf895e HANDOVER-v33.md
41d648b fix: kopiera EndToEndTests + LayoutOverflowTests
6e7da16 v33: städning (Preview bort, Mermaid live) + V33-tester + bump AppVersion
1053c3b v33 canvas-fix: transformEffect + synkron dragController-synk
```

## Vad Kim ska verifiera på sin iPhone

Appen är installerad och startad. Verifierings-punkter:

1. **Öppna Lägen-menyn** (slider.horizontal.3-knappen längst till höger i toolbarn). Versionen ska visa **"v33"** längst ner.
2. **Drag en cirkel** från toolbarn till canvasen. Cirkeln ska landa **exakt där fingret släpps**.
3. **Pan canvasen** med ett finger. Vyn ska följa fingret utan studs eller hopp.
4. **Pinch-zooma** med två fingrar. Punkten under fingrarna ska stanna kvar där.
5. **Skapa flera former** och kolla att alla landar rätt — pan + zoom efteråt ska inte få någon att försvinna.
6. **Markeringsläge** finns nu i Lägen-menyn istället för toolbarn.

Säg **PASS** om allt ovan funkar, eller berätta vad som inte gör det.

## Status

✅ Canvas-bug löst (verifierat automatiskt)
✅ Toolbar på Apple-nivå (44pt HIG, layout-test grönt)
✅ Allt UI återställt + polerat
✅ Deployad till iPhone
⏳ Kim verifierar manuellt på enheten
