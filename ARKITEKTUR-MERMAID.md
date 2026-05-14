# ARKITEKTUR-MERMAID — Version v6
*Datum: 2026-05-14*

Aktuell arkitektur för MermaidCanvas-appen. Uppdateras vid varje deploy enligt `VERSIONSHANTERING.md`.

## Diagram

```mermaid
flowchart TD
    Kim["👤 Kim"]
    Claude["🤖 Claude Code<br/>(skriver fil på Mac)"]

    subgraph App["📱 MermaidCanvas — iPhone"]
        ContentView["ContentView<br/>(orkestrerar Open/Save/Reload)"]
        ToolbarView["ToolbarView<br/>(Cirkel + Öppna + Spara)"]
        CanvasView["CanvasView<br/>(rendering)"]
        CircleNodeView["CircleNodeView<br/>(cirkel + drag)"]
        CanvasModel["CanvasModel<br/>(@Published shapes)"]
        ShapeNode["ShapeNode<br/>(id, position, label, type)"]
        MermaidGenerator["MermaidGenerator<br/>(shapes → mermaid + JSON state)"]
        MermaidParser["MermaidParser<br/>(MD → shapes via state-JSON eller mermaid)"]
        CanvasDocument["CanvasDocument<br/>(FileDocument: bygger MD)"]
        CanvasFileManager["CanvasFileManager<br/>(öppen fil + polling 2s)"]
    end

    Picker["📂 iOS Picker<br/>(Open/Save)"]
    File["📄 fil.md<br/>(iCloud Drive eller annan plats)"]

    Kim -->|tap / drag| ToolbarView
    Kim -->|tap / drag| CircleNodeView
    Kim -->|välj fil| Picker

    ToolbarView -->|addCircle| CanvasModel
    ToolbarView -->|onSave / onOpen| ContentView
    CanvasModel -->|@Published| CanvasView
    CanvasView --> CircleNodeView
    CircleNodeView -->|uppdatera position| CanvasModel

    ContentView -->|generera| MermaidGenerator
    CanvasModel -->|shapes| MermaidGenerator
    MermaidGenerator -->|mermaid + state| CanvasDocument
    ContentView -->|skriva| CanvasFileManager
    CanvasFileManager -->|write| File
    CanvasDocument -.->|fileExporter| Picker
    Picker -->|skapar ny fil| File

    Picker -->|välj öppna| CanvasFileManager
    CanvasFileManager -->|läs| File
    CanvasFileManager -->|content| ContentView
    ContentView -->|parsa| MermaidParser
    MermaidParser -->|shapes| CanvasModel

    Claude -.->|skriver| File
    CanvasFileManager -->|polling 2s upptäcker ändring| ContentView
```

## Komponenter

| Komponent | Fil | Ansvar |
|---|---|---|
| App-entry | `Sources/MermaidCanvasApp.swift` | SwiftUI App-entry. |
| Huvudvy | `Sources/ContentView.swift` | Orkestrerar open/save/reload. fileImporter + fileExporter. |
| Toolbar | `Sources/Views/ToolbarView.swift` | Cirkel + Öppna + Spara. |
| Canvas | `Sources/Views/CanvasView.swift` | Bakgrund + renderar shapes. |
| Cirkel-nod | `Sources/Views/CanvasView.swift` (CircleNodeView) | Cirkel + drag-gest. |
| Data-modell | `Sources/Models/CanvasModel.swift` | `addCircle`, `updatePosition`, `replaceAll`. |
| Form-data | `Sources/Models/ShapeNode.swift` | Identifiable + Codable. |
| Mermaid-generator | `Sources/Mermaid/MermaidGenerator.swift` | shapes → flowchart + canvasState-JSON. |
| Mermaid-parser | `Sources/Mermaid/MermaidParser.swift` | MD → shapes. Läser state-JSON för positioner, eller auto-positionerar i cirkel om JSON saknas. |
| Dokument-bygge | `Sources/Persistence/CanvasDocument.swift` | FileDocument: bygger MD (mermaid + state-JSON i HTML-kommentar). |
| Fil-hantering | `Sources/Persistence/CanvasFileManager.swift` | `@MainActor` ObservableObject. Håller öppen URL, skriver/läser, pollar var 2 sek för externa ändringar (reloadTick). |

## Ändringar från v5

- **Öppna-knapp** (orange) i ToolbarView. Visar fileImporter — Kim väljer en .md-fil från iCloud Drive eller var som helst.
- **MermaidParser**: parsar canvas-MD tillbaka till shapes. Letar först efter `<!-- mermaidcanvas-state ... -->` JSON-kommentar (autoritativ för positioner). Annars parsa mermaid-blocket med regex och auto-positionera noder i en cirkel.
- **CanvasFileManager**: håller `currentFileURL` med security-scoped åtkomst. Pollar filens modification date varje 2 sek; om ändrad → `reloadTick` ökar.
- **Smart Spara**: om en fil är öppen → skriv direkt tillbaka utan picker. Annars → öppna fileExporter (som tidigare). När exporter sparar en ny fil → den filen blir den öppna filen automatiskt.
- **Position-persistens**: CanvasDocument bygger MD med både mermaid-block och en HTML-kommentar med JSON `canvasState` som innehåller exakta positioner. Vid öppna återställs positioner exakt.
- **Tvåvägs aktivt**: Claude Code kan nu skriva till samma fil → CanvasFileManager:s polling upptäcker det → ContentView re-laddar → canvas re-renderar. Kim ser ändringen inom 2 sek.

## Hur Kim använder v6

Tre scenarier:

### A. Skapa nytt diagram
1. Tryck **Cirkel** några gånger → former dyker upp
2. Dra runt
3. Tryck **Spara** → välj plats (t.ex. iCloud Drive) → namnge filen → spara
4. Filen är nu *öppen*. Nästa Spara skriver direkt utan picker.

### B. Öppna befintligt diagram
1. Tryck **Öppna** → välj .md-fil → former dyker upp på canvasen
2. Dra runt, lägg till nya cirklar
3. Tryck **Spara** → skriver direkt tillbaka till samma fil

### C. Se Claude Codes ändringar (tvåvägs aktivt)
1. Öppna en fil enligt B
2. Claude Code skriver något i samma fil från Mac
3. Inom 2 sek upptäcker appen ändringen och re-renderar canvas
4. Status-raden visar "Uppdaterad från fil — N former"

## Planerat för v7+

- **Fler formtyper**: fyrkant, romb (beslutsruta)
- **Pilar** mellan former med riktning
- **Namnge former**: tap på cirkel → text-input för att byta label
- **Bookmark-persistens**: kom ihåg senast öppnade fil mellan app-starter
- **Konflikthantering**: om både appen och Claude Code skrivit till samma fil samtidigt → merge-dialog
