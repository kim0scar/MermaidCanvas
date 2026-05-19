---
title: v27 Sample — alla nya features
spec_type: general
platform: blank
shape_packs: basic,architecture
last_updated: 2026-05-16
---

# v27 Sample — alla nya features

Genererad 2026-05-16 av MermaidCanvas v27 för verifiering av round-trip.

Detta är ett exempel-canvas som visar v27:s nya features i mermaid-format:
- Plattform = `blank` (Blank canvas, inga regler)
- Form-paketer = `basic` + `architecture` (toggle:ade i Lägen-menyn)
- Pilar med olika stilar: en solid one-way (`-->`), en dashed bidi (`<-.->`)
- Edges har `style: solid|dashed` i JSON-state

```mermaid
flowchart TD
    module_N0["API"]:::module
    module_N1["Database"]:::module
    folder_N2["src/"]:::folder
    %% module_N0 pos: 400,300
    %% module_N1 pos: 700,300
    %% folder_N2 pos: 550,150
    module_N0 --> module_N1
    folder_N2 <-.-> module_N0

    classDef module fill:#0ea5e9,stroke:#0369a1,color:#f9fafb;
    classDef folder fill:#f3f4f6,stroke:#9ca3af,color:#111827;
```

<!-- mermaidcanvas-state
{
  "canvas": {
    "width": 2000,
    "height": 2000,
    "shapeBaseWidth": 120,
    "shapeBaseHeight": 80,
    "unit": "pt"
  },
  "specType": "general",
  "platform": "blank",
  "shapePacks": ["basic", "architecture"],
  "nodes": [
    {"id": "module_N0", "x": 400, "y": 300, "label": "API", "type": "rectangle", "category": "module", "showLabel": true, "size": 1.0, "rotation": 0, "note": ""},
    {"id": "module_N1", "x": 700, "y": 300, "label": "Database", "type": "rectangle", "category": "module", "showLabel": true, "size": 1.0, "rotation": 0, "note": ""},
    {"id": "folder_N2", "x": 550, "y": 150, "label": "src/", "type": "rectangle", "category": "folder", "showLabel": true, "size": 1.0, "rotation": 0, "note": ""}
  ],
  "edges": [
    {"from": "module_N0", "to": "module_N1", "label": "", "bidirectional": false, "style": "solid"},
    {"from": "folder_N2", "to": "module_N0", "label": "", "bidirectional": true, "style": "dashed"}
  ]
}
-->
