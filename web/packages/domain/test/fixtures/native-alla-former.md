---
title: Test v35.1 — alla former med pilar
spec_type: general
platform: blank
shape_packs: basic
last_updated: 2026-05-19
---
# Test v35.1 — alla former med pilar

Genererad 2026-05-19T17:12:38Z. Samma 9 former + 7 pilar. Edges styr layout — inga ~~~-hints.

```mermaid
flowchart TD
    ui_N0(("Start")):::ui
    %% ui_N0 pos: 1800,1750
    ui_N1["Process"]:::ui
    %% ui_N1 size: 1.5
    %% ui_N1 pos: 2000,1750
    ui_N2{"Beslut?"}:::ui
    %% ui_N2 pos: 2200,1750
    ui_N3(["Option A"]):::ui
    %% ui_N3 size: 0.8
    %% ui_N3 pos: 1800,1950
    ui_N4["Notering"]:::ui
    %% ui_N4 pos: 2000,1950
    ui_N5["Tabell"]:::ui
    %% ui_N5 size: 2.0
    %% ui_N5 pos: 2200,1950
    ui_N6["Se mer"]:::ui
    %% ui_N6 pos: 1800,2150
    ui_N7["Linje"]:::ui
    %% ui_N7 pos: 2000,2150
    ui_N8["Pil ut"]:::ui
    %% ui_N8 pos: 2200,2150
    ui_N0 --> ui_N1
    ui_N1 --> ui_N2
    ui_N2 -->|"Ja"| ui_N3
    ui_N2 -->|"Nej"| ui_N5
    ui_N3 --> ui_N6
    ui_N4 -->|"notis"| ui_N7
    ui_N4 -.-> ui_N7

    classDef ui fill:#1d4ed8,stroke:#1e293b,color:#f9fafb;
```

<!-- mermaidcanvas-state
{
  "platform": "blank",
  "shapePacks": [
    "basic"
  ],
  "specType": "general",
  "nodes": [
    {
      "id": "ui_N0",
      "type": "circle",
      "x": 1800,
      "y": 1750,
      "label": "Start",
      "category": "ui",
      "showLabel": true,
      "size": 1.0,
      "rotation": 0,
      "note": ""
    },
    {
      "id": "ui_N1",
      "type": "rectangle",
      "x": 2000,
      "y": 1750,
      "label": "Process",
      "category": "ui",
      "showLabel": true,
      "size": 1.5,
      "rotation": 0,
      "note": ""
    },
    {
      "id": "ui_N2",
      "type": "diamond",
      "x": 2200,
      "y": 1750,
      "label": "Beslut?",
      "category": "ui",
      "showLabel": true,
      "size": 1.0,
      "rotation": 0,
      "note": ""
    },
    {
      "id": "ui_N3",
      "type": "pill",
      "x": 1800,
      "y": 1950,
      "label": "Option A",
      "category": "ui",
      "showLabel": true,
      "size": 0.8,
      "rotation": 0,
      "note": ""
    },
    {
      "id": "ui_N4",
      "type": "text",
      "x": 2000,
      "y": 1950,
      "label": "Notering",
      "category": "ui",
      "showLabel": true,
      "size": 1.0,
      "rotation": 0,
      "note": ""
    },
    {
      "id": "ui_N5",
      "type": "table",
      "x": 2200,
      "y": 1950,
      "label": "Tabell",
      "category": "ui",
      "showLabel": true,
      "size": 2.0,
      "rotation": 0,
      "note": ""
    },
    {
      "id": "ui_N6",
      "type": "link",
      "x": 1800,
      "y": 2150,
      "label": "Se mer",
      "category": "ui",
      "showLabel": true,
      "size": 1.0,
      "rotation": 0,
      "note": ""
    },
    {
      "id": "ui_N7",
      "type": "line",
      "x": 2000,
      "y": 2150,
      "label": "Linje",
      "category": "ui",
      "showLabel": true,
      "size": 1.0,
      "rotation": 0,
      "note": ""
    },
    {
      "id": "ui_N8",
      "type": "arrow",
      "x": 2200,
      "y": 2150,
      "label": "Pil ut",
      "category": "ui",
      "showLabel": true,
      "size": 1.0,
      "rotation": 0,
      "note": ""
    }
  ],
  "edges": [
    {
      "from": "ui_N0",
      "to": "ui_N1",
      "label": "",
      "bidirectional": false,
      "style": "solid"
    },
    {
      "from": "ui_N1",
      "to": "ui_N2",
      "label": "",
      "bidirectional": false,
      "style": "solid"
    },
    {
      "from": "ui_N2",
      "to": "ui_N3",
      "label": "Ja",
      "bidirectional": false,
      "style": "solid"
    },
    {
      "from": "ui_N2",
      "to": "ui_N5",
      "label": "Nej",
      "bidirectional": false,
      "style": "solid"
    },
    {
      "from": "ui_N3",
      "to": "ui_N6",
      "label": "",
      "bidirectional": false,
      "style": "solid"
    },
    {
      "from": "ui_N4",
      "to": "ui_N7",
      "label": "notis",
      "bidirectional": false,
      "style": "solid"
    },
    {
      "from": "ui_N4",
      "to": "ui_N7",
      "label": "notis",
      "bidirectional": false,
      "style": "dashed"
    }
  ],
  "canvas": {
    "width": 4000,
    "height": 4000,
    "shapeBaseWidth": 120,
    "shapeBaseHeight": 80,
    "unit": "pt",
    "iphoneFrame": {
      "x": 1304,
      "y": 1074,
      "width": 393,
      "height": 852,
      "designWidth": 393,
      "designHeight": 852
    }
  }
}
-->
