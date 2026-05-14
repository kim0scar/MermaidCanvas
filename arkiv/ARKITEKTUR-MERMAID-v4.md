# ARKITEKTUR-MERMAID — Version v4
*Datum: 2026-05-14*

Aktuell arkitektur för MermaidCanvas-appen. Uppdateras vid varje deploy enligt `VERSIONSHANTERING.md`.

## Diagram

```mermaid
flowchart TD
    User["👤 Kim<br/>trycker knapp / drar form"]

    subgraph App["📱 MermaidCanvas — iPhone"]
        ContentView["ContentView<br/>(huvudvy + status)"]
        ToolbarView["ToolbarView<br/>(Cirkel + Spara)"]
        CanvasView["CanvasView<br/>(rendering-yta)"]
        CircleNodeView["CircleNodeView<br/>(cirkel + drag-gest)"]
        CanvasModel["CanvasModel<br/>(@Published shapes)"]
        ShapeNode["ShapeNode<br/>(id, position, label, type)"]
        MermaidGenerator["MermaidGenerator<br/>(shapes → mermaid-kod)"]
        CanvasStore["CanvasStore<br/>(skriver canvas.md)"]
    end

    File["📄 canvas.md<br/>(Documents — synlig i Files-appen)"]
    Files["📂 Files-appen<br/>På min iPhone → MermaidCanvas"]

    User -->|tap| ToolbarView
    User -->|drag| CircleNodeView
    User -.->|öppnar| Files
    Files -->|visar| File
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
| App-entry | `Sources/MermaidCanvasApp.swift` | SwiftUI App-entry. |
| Huvudvy | `Sources/ContentView.swift` | Toolbar + canvas + status. |
| Toolbar | `Sources/Views/ToolbarView.swift` | Cirkel + Spara, båda borderedProminent. |
| Canvas | `Sources/Views/CanvasView.swift` | Bakgrund + renderar shapes. |
| Cirkel-nod | `Sources/Views/CanvasView.swift` (CircleNodeView) | Cirkel + drag-gest. |
| Data-modell | `Sources/Models/CanvasModel.swift` | `@MainActor` ObservableObject. |
| Form-data | `Sources/Models/ShapeNode.swift` | Identifiable + Codable. |
| Mermaid-generator | `Sources/Mermaid/MermaidGenerator.swift` | shapes → flowchart-syntax. |
| Persistens | `Sources/Persistence/CanvasStore.swift` | Skriver `canvas.md` till Documents. |
| Project config | `project.yml` | xcodegen-spec. Nu med UIFileSharingEnabled + LSSupportsOpeningDocumentsInPlace. |

## Ändringar från v3

- **Files-app-access**: `UIFileSharingEnabled = YES` + `LSSupportsOpeningDocumentsInPlace = YES` i Info.plist (via xcodegen INFOPLIST_KEY_*). `canvas.md` är nu synlig i Files-appen.

## Hur Kim hittar canvas.md

På iPhone:
1. Öppna **Files**-appen
2. **På min iPhone** → **MermaidCanvas**
3. `canvas.md` ligger där

Kim kan öppna filen direkt, kopiera till iCloud Drive manuellt, eller dela till Mac via AirDrop / Mail.

## Planerat för v5+

- Fler formtyper: fyrkant, romb (beslutsruta)
- Pilar mellan former med riktning
- Namnge former (tap → text-input)
- iCloud-container (kräver Apple Developer Portal-setup)
- Läsa Mermaid → re-rendera canvas (tvåvägs)
