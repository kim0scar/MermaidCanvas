# ARKITEKTUR-MERMAID — Version v5
*Datum: 2026-05-14*

Aktuell arkitektur för MermaidCanvas-appen. Uppdateras vid varje deploy enligt `VERSIONSHANTERING.md`.

## Diagram

```mermaid
flowchart TD
    User["👤 Kim<br/>trycker / drar / väljer plats"]

    subgraph App["📱 MermaidCanvas — iPhone"]
        ContentView["ContentView<br/>(huvudvy + fileExporter)"]
        ToolbarView["ToolbarView<br/>(Cirkel + Spara)"]
        CanvasView["CanvasView<br/>(rendering)"]
        CircleNodeView["CircleNodeView<br/>(cirkel + drag)"]
        CanvasModel["CanvasModel<br/>(@Published shapes)"]
        ShapeNode["ShapeNode<br/>(id, position, label, type)"]
        MermaidGenerator["MermaidGenerator<br/>(shapes → mermaid)"]
        CanvasDocument["CanvasDocument<br/>(FileDocument: bygger MD)"]
    end

    Picker["📂 iOS Save Picker<br/>(välj iCloud Drive eller annan plats)"]
    File["📄 canvas.md<br/>(vald plats)"]

    User -->|tap| ToolbarView
    User -->|drag| CircleNodeView
    User -->|väljer plats| Picker
    ToolbarView -->|addCircle| CanvasModel
    ToolbarView -->|onSave| ContentView
    CanvasModel -->|@Published| CanvasView
    CanvasView --> CircleNodeView
    CircleNodeView -->|uppdaterar position| CanvasModel
    ContentView -->|save\(\)| MermaidGenerator
    CanvasModel -->|shapes| MermaidGenerator
    MermaidGenerator -->|mermaid-string| CanvasDocument
    CanvasDocument -.->|presenteras via fileExporter| Picker
    Picker -->|skriver| File
```

## Komponenter

| Komponent | Fil | Ansvar |
|---|---|---|
| App-entry | `Sources/MermaidCanvasApp.swift` | SwiftUI App-entry. |
| Huvudvy | `Sources/ContentView.swift` | Toolbar + canvas + status + fileExporter. |
| Toolbar | `Sources/Views/ToolbarView.swift` | Cirkel + Spara, borderedProminent. |
| Canvas | `Sources/Views/CanvasView.swift` | Bakgrund + renderar shapes. |
| Cirkel-nod | `Sources/Views/CanvasView.swift` (CircleNodeView) | Cirkel + drag-gest. |
| Data-modell | `Sources/Models/CanvasModel.swift` | `@MainActor` ObservableObject. |
| Form-data | `Sources/Models/ShapeNode.swift` | Identifiable + Codable. |
| Mermaid-generator | `Sources/Mermaid/MermaidGenerator.swift` | shapes → flowchart-syntax. |
| Persistens | `Sources/Persistence/CanvasDocument.swift` | FileDocument: bygger MD-innehåll + skriver via fileExporter. |

## Ändringar från v4

- **Användaren väljer plats**: Spara öppnar nu iOS Save Picker (`.fileExporter`). Kim navigerar dit han vill — iCloud Drive, On My iPhone, eller var som helst — och sparar `canvas.md` där. Ingen iCloud-container behövs.
- **Borttagen**: `Sources/Persistence/CanvasStore.swift` (lokal auto-spar i appens Documents). Ersatt av `CanvasDocument.swift` som är en `FileDocument` integrerad med systemets save picker.
- **Status-rad**: visar nu filnamnet efter sparet ("Sparad: canvas.md") så Kim ser att det funkade.

## Hur Kim sparar nu

1. Tryck **Spara** (grön knapp i toolbar)
2. iOS Save Picker dyker upp
3. Navigera till önskad plats (rekommenderat första gången: **iCloud Drive** → skapa mapp `ClaudeCanvas` → spara där)
4. Tryck **Spara**
5. Status visar: "Sparad: canvas.md"

Nästa gång kan Kim öppna samma plats och välja **Ersätt** för att överskriva.

## Planerat för v6+

- Fler formtyper: fyrkant, romb
- Pilar mellan former med riktning
- Namnge former (tap → text-input)
- Komma ihåg senaste plats (security-scoped bookmark) så Kim slipper navigera varje gång
- Läsa Mermaid → re-rendera canvas (tvåvägs)
