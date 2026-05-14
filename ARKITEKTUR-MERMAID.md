# ARKITEKTUR-MERMAID — Version v11
*Datum: 2026-05-14*

Aktuell arkitektur för MermaidCanvas-appen. Uppdateras vid varje deploy enligt `VERSIONSHANTERING.md`.

## Diagram

```mermaid
flowchart TD
    Kim["👤 Kim"]
    Claude["🤖 Claude Code"]

    subgraph App["📱 MermaidCanvas v11"]
        ToolbarView["ToolbarView<br/>(rena ikoner, Pil-meny)"]
        TitleField["TextField<br/>(rubrik)"]
        CanvasView["CanvasView"]
        ShapeView["ShapeView<br/>(tap = redigera, drag = flytta)"]
        EditShapeSheet["EditShapeSheet (NY)<br/>(sheet med text-input)"]
        EdgesView["EdgesView"]
        CanvasModel["CanvasModel<br/>(+ canvasTitle, updateLabel)"]
        ShapeNode["ShapeNode"]
        EdgeConnection["EdgeConnection"]
        MermaidGenerator["MermaidGenerator"]
        MermaidParser["MermaidParser<br/>(+ parseTitle)"]
        CanvasDocument["CanvasDocument<br/>(title som # H1)"]
        CanvasFileManager["CanvasFileManager"]
    end

    File["📄 fil.md"]

    Kim -->|skriv rubrik| TitleField
    Kim -->|tap form| ShapeView
    ShapeView -->|onEdit| EditShapeSheet
    EditShapeSheet -->|spara label| CanvasModel

    Kim -->|tap Pil-ikon| ToolbarView
    ToolbarView -->|Menu: Enkel / Dubbel| CanvasModel

    TitleField -.->|@Binding| CanvasModel
    CanvasModel --> CanvasView
    CanvasModel --> CanvasDocument
    CanvasDocument --> File
    File --> CanvasFileManager
    CanvasFileManager --> MermaidParser
    MermaidParser -->|title + shapes + edges| CanvasModel

    Claude -.->|skriver| File
```

## Komponenter — ändringar i v11

| Komponent | Fil | Ändring |
|---|---|---|
| ToolbarView | `Sources/Views/ToolbarView.swift` | **Komplett redesign**: form-knappar är nu rena SF Symbol-ikoner utan text/färg (`circle`, `rectangle`, `diamond`). Pil är en **Menu** som kombinerar Enkel + Dubbel-pil — ersätter de två separata knapparna från v9. Öppna/Spara är ikoner; Spara är accent-färgad. Cleaner spacing och Divider-overlay. |
| EditShapeSheet (NY) | `Sources/Views/EditShapeSheet.swift` | Sheet med TextField för att byta namn på en form. Auto-fokus på text-fältet. Avbryt/Klar-knappar. |
| ShapeView | `Sources/Views/CanvasView.swift` | Tap utanför pil-mode öppnar nu `EditShapeSheet` via `onEdit`-closure. DragGesture har nu `minimumDistance: 10` så tap kan matcha utan att drag tar över. Större formdimensioner (120×80), rounded-design-font, minimumScaleFactor för lång text. |
| CanvasView | `Sources/Views/CanvasView.swift` | Tar emot `onShapeEdit` callback från ContentView. |
| Rubrik | `Sources/ContentView.swift` | `TextField` mellan toolbar och canvas, bunden till `model.canvasTitle`. Stor rounded font. |
| CanvasModel | `Sources/Models/CanvasModel.swift` | `canvasTitle: String`, `updateLabel(id:to:)`, `replaceAll(...)` tar nu `title`-parameter. |
| MermaidParser | `Sources/Mermaid/MermaidParser.swift` | Ny `parseTitle(...)` läser första `# H1`-rad innan mermaid-blocket. `ParsedCanvas.title` lagrar rubriken. Default-rubrik "Canvas — MermaidCanvas" filtreras bort. |
| CanvasDocument | `Sources/Persistence/CanvasDocument.swift` | `init(title:shapes:edges:)` — title används som `# H1` överst i MD. |
| ContentView | `Sources/ContentView.swift` | Sheet-presentation för EditShapeSheet via `editingShapeId`-state. Default-filnamn vid Spara använder rubriken (`"<rubrik>.md"`). |

## Ändringar från v10

1. **Toolbar redesign**: rena form-ikoner (cirkel/rektangel/romb) utan text och utan färg. Pil-knapp blev en Menu som kombinerar Enkel + Dubbel. Spara-knapp accent-färgad.
2. **Tap på form → byt namn**: tap (utanför pil-mode) öppnar en sheet med TextField. Drag-gesten kräver nu 10pt minimum-rörelse så tap kan registreras separat.
3. **Rubrik på canvasen**: TextField direkt under toolbar. Rubriken sparas som `# H1` överst i MD-filen och läses tillbaka vid Öppna.
4. **Default-filnamn använder rubrik**: vid Spara av ny fil föreslås `<rubrik>.md`.
5. **Färgfri estetik**: formerna fortsatt neutrala (vit fyll, svart stroke). Toolbar fortsatt neutral förutom Spara som behåller accent-färg.

## Planerat för v12 och v13

- v12: regnbåge-knapp + färgväljare (per form)
- v13: Apple-snygg app-ikon (1024×1024 + AppIcon.appiconset)
