# ARKITEKTUR-MERMAID — Version v3
*Datum: 2026-05-14*

Aktuell arkitektur för MermaidCanvas-appen. Uppdateras vid varje deploy enligt `VERSIONSHANTERING.md`.

## Diagram

```mermaid
flowchart TD
    User["👤 Kim<br/>trycker knapp / drar form"]

    subgraph App["📱 MermaidCanvas — iPhone"]
        ContentView["ContentView<br/>(huvudvy + status)"]
        ToolbarView["ToolbarView<br/>(Cirkel blå + Spara grön)"]
        CanvasView["CanvasView<br/>(rendering-yta)"]
        CircleNodeView["CircleNodeView<br/>(en cirkel + drag-gest)"]
        CanvasModel["CanvasModel<br/>(@Published shapes)"]
        ShapeNode["ShapeNode<br/>(id, position, label, type)"]
        MermaidGenerator["MermaidGenerator<br/>(shapes → mermaid-kod)"]
        CanvasStore["CanvasStore<br/>(skriver canvas.md)"]
    end

    File["📄 canvas.md<br/>(appens lokala Documents-mapp)"]

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
| App-entry | `Sources/MermaidCanvasApp.swift` | SwiftUI App-entry. |
| Huvudvy | `Sources/ContentView.swift` | Toolbar + canvas + status-rad. Triggar save\(\), visar omedelbar feedback. |
| Toolbar | `Sources/Views/ToolbarView.swift` | Blå Cirkel + grön Spara, båda borderedProminent + contentShape. |
| Canvas | `Sources/Views/CanvasView.swift` | Bakgrund + renderar varje ShapeNode. |
| Cirkel-nod | `Sources/Views/CanvasView.swift` (CircleNodeView) | En cirkel + drag-gest. |
| Data-modell | `Sources/Models/CanvasModel.swift` | `@MainActor` ObservableObject. addCircle\(\), updatePosition\(\). |
| Form-data | `Sources/Models/ShapeNode.swift` | Identifiable + Codable: id, type, position, label. |
| Mermaid-generator | `Sources/Mermaid/MermaidGenerator.swift` | shapes → flowchart-syntax enligt MERMAID-FAKTA.md. |
| Persistens | `Sources/Persistence/CanvasStore.swift` | Skriver `canvas.md` till appens Documents. |

## Ändringar från v2

- **Tappable Spara-knapp**: båda knappar nu `borderedProminent` med olika tint (blå/grön) + `contentShape(Rectangle())` för säker tap-area.
- **Omedelbar feedback**: status-raden visar "Sparar…" direkt när Spara trycks, sedan resultatet — så Kim ser att tappet registrerats.
- **Layout-fix**: GeometryReader flyttad från root till runt CanvasView. Toolbar och status sitter naturligt i safe area.
- **Status-rad bakgrund**: bytt till `secondarySystemBackground` för bättre kontrast.

## Anteckningar för v3

- `canvas.md` ligger fortfarande i appens lokala Documents-mapp — inte iCloud, inte synlig i Files-appen.
- Det är planerat för v4 (Files-app-access) eller v5 (iCloud-container).

## Planerat för v4

Två alternativ — Kim väljer:
- **Quick win**: lägg till `UIFileSharingEnabled` + `LSSupportsOpeningDocumentsInPlace` i Info.plist → `canvas.md` syns i Files-appen → På min iPhone → MermaidCanvas. Tar minuter.
- **Riktig lösning**: iCloud Container via Apple Developer Portal → `canvas.md` syns automatiskt i iCloud Drive både på iPhone och Mac. Kräver manuellt steg i Portal.

Eller båda i samma version.

## Planerat för v5+

- Fyrkant + romb-former
- Pilar mellan former
- Namnge former (tap → text-input)
- Läsa Mermaid → re-rendera canvas
