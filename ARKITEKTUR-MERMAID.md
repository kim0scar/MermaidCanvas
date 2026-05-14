# ARKITEKTUR-MERMAID — Version v2
*Datum: 2026-05-14*

Aktuell arkitektur för MermaidCanvas-appen. Uppdateras vid varje deploy enligt `VERSIONSHANTERING.md`.

## Diagram

```mermaid
flowchart TD
    User["👤 Kim<br/>trycker knapp / drar form"]

    subgraph App["📱 MermaidCanvas — iPhone"]
        ContentView["ContentView<br/>(huvudvy + status)"]
        ToolbarView["ToolbarView<br/>(Cirkel + Spara)"]
        CanvasView["CanvasView<br/>(rendering)"]
        CircleNodeView["CircleNodeView<br/>(en cirkel + drag-gest)"]
        CanvasModel["CanvasModel<br/>(@Published shapes)"]
        ShapeNode["ShapeNode<br/>(id, position, label, type)"]
        MermaidGenerator["MermaidGenerator<br/>(shapes → mermaid-kod)"]
        CanvasStore["CanvasStore<br/>(skriver canvas.md)"]
    end

    File["📄 canvas.md<br/>(appens Documents-mapp)"]

    User -->|tap| ToolbarView
    User -->|drag| CircleNodeView
    ToolbarView -->|addCircle| CanvasModel
    ToolbarView -->|onSave| ContentView
    CanvasModel -->|@Published| CanvasView
    CanvasView --> CircleNodeView
    CircleNodeView -->|uppdaterar position| CanvasModel
    ContentView -->|save\(\)| MermaidGenerator
    CanvasModel -->|shapes| MermaidGenerator
    MermaidGenerator -->|mermaid-string| CanvasStore
    CanvasStore -->|write| File
```

## Komponenter

| Komponent | Fil | Ansvar |
|---|---|---|
| App-entry | `Sources/MermaidCanvasApp.swift` | SwiftUI App-entry. Skapar root-fönstret med ContentView. |
| Huvudvy | `Sources/ContentView.swift` | Kombinerar toolbar, canvas, status-rad. Triggar save\(\). |
| Toolbar | `Sources/Views/ToolbarView.swift` | "Cirkel"-knapp och "Spara"-knapp. |
| Canvas | `Sources/Views/CanvasView.swift` | Bakgrund + renderar varje ShapeNode som CircleNodeView. |
| Cirkel-nod | `Sources/Views/CanvasView.swift` (CircleNodeView) | En cirkel + drag-gest som uppdaterar position i modellen. |
| Data-modell | `Sources/Models/CanvasModel.swift` | `@MainActor` ObservableObject. Lista med former. addCircle\(\), updatePosition\(\). |
| Form-data | `Sources/Models/ShapeNode.swift` | Identifiable + Codable struct: id, type, position, label. |
| Mermaid-generator | `Sources/Mermaid/MermaidGenerator.swift` | Konverterar shapes → flowchart-syntax enligt MERMAID-FAKTA.md. |
| Persistens | `Sources/Persistence/CanvasStore.swift` | Skriver `canvas.md` till appens Documents-mapp. |

## Anteckningar för v2

- Tre nya mappar under `Sources/`: `Models/`, `Views/`, `Mermaid/`, `Persistence/`
- iCloud-integration är INTE inkluderad i v2 — kräver iCloud Container i Apple Developer Portal som måste skapas manuellt. Tills dess sparas `canvas.md` i appens lokala Documents-mapp på iPhone (åtkomlig via Xcode → Devices and Simulators → Download Container).
- Bara *en* formtyp i v2: cirkel. Fyrkant och romb kommer i v3.
- Inga pilar mellan former i v2.
- Ingen läsning av `canvas.md` ännu — enbart skrivning. Re-rendering vid extern ändring kommer i v5.
- Status-rad visar antal sparade former samt eventuella fel.

## Planerat för v3

- iCloud-container — flytta `canvas.md` till `~/Library/Mobile Documents/iCloud~com~kimlundqvist~mermaidcanvas/Documents/`
- Tre formtyper: cirkel, fyrkant, romb
- Färgkodning per typ
- Status-rad visar filens fulla path så Kim kan kopiera och visa Claude Code

## Planerat för v4

- Pilar mellan former
- Namnge former (tap → text-input)

## Planerat för v5

- Läsa `canvas.md` → parsa mermaid → re-rendera canvas
- File-watcher (DispatchSource) som triggar re-render när Claude Code skrivit till filen
