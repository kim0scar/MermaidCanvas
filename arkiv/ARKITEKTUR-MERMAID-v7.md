# ARKITEKTUR-MERMAID — Version v7
*Datum: 2026-05-14*

Aktuell arkitektur för MermaidCanvas-appen. Uppdateras vid varje deploy enligt `VERSIONSHANTERING.md`.

## Diagram

```mermaid
flowchart TD
    Kim["👤 Kim"]
    Claude["🤖 Claude Code<br/>(Mac)"]

    subgraph App["📱 MermaidCanvas — iPhone"]
        ContentView["ContentView<br/>(orkestrerar allt)"]
        ToolbarView["ToolbarView<br/>(Cirkel/Box/Romb + Pil + Öppna/Spara)"]
        CanvasView["CanvasView<br/>(rendering-yta)"]
        ShapeView["ShapeView<br/>(cirkel/box/romb + drag eller tap)"]
        EdgesView["EdgesView<br/>(pilar mellan former)"]
        DiamondShape["DiamondShape<br/>(custom Shape-path)"]
        CanvasModel["CanvasModel<br/>(shapes + edges + edge-mode)"]
        ShapeNode["ShapeNode<br/>(circle/rectangle/diamond)"]
        EdgeConnection["EdgeConnection<br/>(from/to/label)"]
        MermaidGenerator["MermaidGenerator<br/>(shapes+edges → mermaid + JSON state)"]
        MermaidParser["MermaidParser<br/>(MD → shapes+edges)"]
        CanvasDocument["CanvasDocument<br/>(FileDocument)"]
        CanvasFileManager["CanvasFileManager<br/>(öppen fil + polling 2s)"]
    end

    Picker["📂 iOS Picker"]
    File["📄 fil.md"]

    Kim -->|tap form-knapp| ToolbarView
    Kim -->|tap Pil + tap form 1 + tap form 2| ToolbarView
    Kim -->|drag| ShapeView
    Kim -->|välj fil| Picker

    ToolbarView -->|addShape / cancelEdgeMode| CanvasModel
    ToolbarView -->|onOpen / onSave / onToggleEdgeMode| ContentView
    CanvasModel -->|@Published| CanvasView
    CanvasView --> ShapeView
    CanvasView --> EdgesView
    ShapeView -->|drag uppdaterar position| CanvasModel
    ShapeView -->|tap i pil-mode| ContentView
    ContentView -->|handleEdgeTap| CanvasModel

    ContentView -->|generera| MermaidGenerator
    CanvasModel -->|shapes+edges| MermaidGenerator
    MermaidGenerator -->|mermaid+state| CanvasDocument
    ContentView -->|skriv| CanvasFileManager
    CanvasFileManager -->|write| File
    CanvasDocument -.->|fileExporter| Picker
    Picker -->|skapar ny fil| File

    Picker -->|välj öppna| CanvasFileManager
    CanvasFileManager -->|läs| File
    CanvasFileManager -->|content| ContentView
    ContentView -->|parsa| MermaidParser
    MermaidParser -->|shapes+edges| CanvasModel

    Claude -.->|skriver| File
    CanvasFileManager -->|polling 2s| ContentView
```

## Komponenter

| Komponent | Fil | Ansvar |
|---|---|---|
| App-entry | `Sources/MermaidCanvasApp.swift` | SwiftUI App-entry. |
| Huvudvy | `Sources/ContentView.swift` | Orkestrerar open/save/reload, edge-mode, shape-tap. |
| Toolbar | `Sources/Views/ToolbarView.swift` | 3 form-knappar (Cirkel/Box/Romb), Pil-toggle, Öppna, Spara. |
| Canvas | `Sources/Views/CanvasView.swift` | Bakgrund + EdgesView + ShapeView per form. |
| Form-vy | `Sources/Views/CanvasView.swift` (ShapeView) | Renderar valfri ShapeType. Drag (utanför pil-mode) eller tap (i pil-mode). |
| Diamond-path | `Sources/Views/CanvasView.swift` (DiamondShape) | Custom Shape-path för romb. |
| Pil-rendering | `Sources/Views/CanvasView.swift` (EdgesView) | Canvas-baserad rendering av pilar mellan former. |
| Data-modell | `Sources/Models/CanvasModel.swift` | shapes, edges, pendingEdgeFrom. `handleEdgeTap`. |
| Form-data | `Sources/Models/ShapeNode.swift` | circle/rectangle/diamond. |
| Pil-data | `Sources/Models/EdgeConnection.swift` | from-UUID, to-UUID, label. |
| Mermaid-generator | `Sources/Mermaid/MermaidGenerator.swift` | shapes+edges → flowchart + canvasState-JSON. |
| Mermaid-parser | `Sources/Mermaid/MermaidParser.swift` | MD → shapes+edges. State-JSON eller mermaid-fallback. |
| Dokument | `Sources/Persistence/CanvasDocument.swift` | FileDocument: bygger MD. |
| Fil-hantering | `Sources/Persistence/CanvasFileManager.swift` | Öppen URL, läs/skriv, polling 2s. |

## Ändringar från v6

- **3 formtyper**: cirkel (blå), fyrkant (grön), romb (orange). Toolbar har en knapp per typ.
- **Pilar mellan former**: ny `EdgeConnection`-modell + EdgesView som renderar pilar med pilhuvuden. Pilar bevaras i Mermaid-koden och i canvasState-JSON.
- **Pil-mode**: lila "Pil"-knapp i toolbar togglar mode. När mode är aktivt: tap startform (röd ring) → tap målform → pil skapas och mode stängs av. Drag är avstängd i pil-mode.
- **Generator + parser uppdaterade** för alla 3 shape-typer (`((...))`, `[...]`, `{...}`) och pilsyntax (`A --> B`, `A -->|label| B`).

## Hur Kim använder v7

- **Lägg till form**: tap en av Cirkel/Box/Romb → form dyker upp i canvas-mitten.
- **Flytta form**: drag den till önskad plats.
- **Rita pil**: tap **Pil** (lila) → tap startform (får röd ring) → tap målform → pil skapas.
- **Avbryt pil-mode**: tap **Avbryt pil** (röd) eller tap samma form två gånger.
- **Spara**: tap **Spara**. Om en fil är öppen → skriver direkt. Annars → välj plats i picker.
- **Öppna**: tap **Öppna** → välj en .md-fil → canvas återställs.

## Planerat för v8+

- **Namnge former**: tap på form → text-input för att byta label.
- **Ta bort former / pilar**: långtryck-gest eller "papperskorg"-mode.
- **Bookmark**: kom ihåg senast öppnade fil mellan app-starter.
- **NSFilePresenter**: ersätt polling för live-reload utan re-öppna.
- **Pan/zoom på canvas**: när diagram blir större än skärmen.
