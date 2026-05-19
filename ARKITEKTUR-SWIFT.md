# MermaidCanvas — Swift-arkitektur

Filtabell + modul-roller. Uppdateras per release.

## Mappstruktur

```
app/MermaidCanvas/Sources/
├── App/                          # SwiftUI-appen
│   ├── MermaidCanvasApp.swift   # App-entry
│   ├── AppVersion.swift         # Single source of truth för version (v34)
│   ├── ContentView.swift        # Root-view + dropHandler
│   ├── Canvas/                  # v34: ny UIScrollView-baserad canvas
│   │   └── ZoomableCanvas.swift # UIViewRepresentable runt UIScrollView
│   ├── Views/                   # SwiftUI-vyer (toolbar, sheets, shape-rendering)
│   ├── Models/                  # CanvasModel + ShapeNode + EdgeConnection + co
│   └── Persistence/             # iCloud Drive read/write
├── Mermaid/                     # Mermaid-syntax parser + generator
│   ├── MermaidParser.swift
│   ├── MermaidGenerator.swift
│   └── SpecType.swift
└── ClaudeCode/                  # Form-paket + plattform-regler
    ├── ShapeCategory.swift
    ├── ShapePack.swift
    ├── Platform.swift
    └── PlatformRules.swift
```

## v34 modul-roller

| Fil | Roll | Rader |
|---|---|---|
| `Canvas/ZoomableCanvas.swift` | UIScrollView-wrap (pinch, pan, drop) | ~230 |
| `Views/CanvasView.swift` | Canvas-content (shapes/edges/selection) | ~570 |
| `ContentView.swift` | Root, drop-handler, sheets | ~290 |
| `Views/ToolbarView.swift` | Verktygshyllan | ~420 |
| `Models/CanvasModel.swift` | Data: shapes, edges, undo, selection | ~460 |

(Antal rader uppdateras vid varje större ändring.)

## Beroenden (vad använder vad)

```
ContentView
├── ToolbarView (toolbar-knappar + chips med .draggable)
├── CanvasView
│   ├── ZoomableCanvas (pan/zoom/drop)
│   ├── EdgesView (pilar)
│   ├── ShapeView (formerna)
│   ├── SelectionHandles + ConnectionHandles (för vald form)
│   └── MarkerOverlay (ritläge)
└── Sheets (Edit, Mermaid-kod, etc.)

CanvasModel (ObservableObject)
└── ShapeNode + EdgeConnection (Codable data-types)

MermaidParser/Generator
└── läser/skriver CanvasModel ↔ Markdown
```

## Drop-flöde (v34 — deterministisk)

```
ToolbarView shape-chip har .draggable(type)
   ↓ (system-drag startar)
användaren drar över canvas
   ↓
ZoomableCanvas's content har .dropDestination(for: ShapeType.self)
   ↓ (location i canvas-koordinater, redan transformerade av UIScrollView)
ContentView.handleDrop(type, canvasPoint)
   ↓
CanvasModel.addShape(type, at: canvasPoint)
```

Inget manuellt koordinat-transformerande — UIScrollView gör det åt oss.

## Pan/zoom-flöde (v34)

Allt sköts internt av UIScrollView (UIPinchGestureRecognizer + UIPanGestureRecognizer).
SwiftUI har INGA gestures för pan/zoom — de skulle bara konflikta med UIScrollViewens egna.

ZoomableCanvas's Coordinator rapporterar bara zoom uppåt via `@Binding zoomPercent` (för toolbar)
och `@Binding zoomScale` (för selection-handle-skalning).

## Filer rivna i v34

- `Models/ShapeDragController.swift` — ersatt av `.dropDestination`
- `Views/MinimapView.swift` — onödig med fit-zoom som minimum
