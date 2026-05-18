# claude-canvas-protocol.md — Hur Claude Code läser MermaidCanvas-filer

Detta är **kontraktet** mellan MermaidCanvas-appen (på Kim's iPhone) och Claude Code (på Kim's Mac). När Kim sparar en canvas → Claude Code öppnar canvas-filen för att läsa och kan svara genom att skriva tillbaka i samma fil.

> Princip: filen är "språket". Mermaid-blocket är människo-läsbart. State-JSON är auktoritativt för positions/storlek/färg. Plattform-regelfilen säger vad som är tillåtet.

---

## Filstruktur

Varje canvas är en `.md`-fil som ligger i Kim's iCloud Drive:

```
~/Library/Mobile Documents/com~apple~CloudDocs/00000. Claude Code/1. Mermaid/<namn>.md
~/Library/Mobile Documents/com~apple~CloudDocs/00000. Claude Code/1. Mermaid/<namn>-regler.md
```

Två filer per canvas:
- **`<namn>.md`** — själva canvasen
- **`<namn>-regler.md`** — kopia av plattform-regelfilen (automatiskt skriven av appen vid Spara)

Båda filerna ska Claude Code öppna när Kim refererar till canvasen.

---

## Filens fem delar

### 1. YAML-frontmatter
```yaml
---
title: <användarens canvas-titel>
spec_type: ui | roadmap | architecture | flow | godot | general
last_updated: 2026-05-16
---
```

`spec_type` säger vilken plattform canvasen tillhör. Det styr vilka regler som gäller (se `<namn>-regler.md`).

### 2. Människoläsbar titel
```markdown
# <användarens canvas-titel>
```

### 3. Mermaid-blocket (`flowchart TD`)
Människoläsbar översikt. Innehåller noder och pilar med klass-suffix.

Form-syntax:
- `id(("label"))` — cirkel
- `id["label"]` — rektangel (eller text/table)
- `id{"label"}` — romb
- `:::categoryName` — klass-suffix som matchar `ShapeCategory`-rawValue

Pil-syntax:
- `A --> B` — riktad pil
- `A <--> B` — dubbelpil
- `A -->|"label"| B` — pil med label

Bredvid noder finns `%% ID metadata: value`-kommentarer för:
- `pos: x,y` — kanvas-position i pt
- `size: 1.2` — sizeMultiplier (om != 1.0)
- `rot: 45°` — rotation (om != 0)
- `note: <text>` — anteckning på formen
- `color: #rrggbb` — färg-override
- `style: r1|r2|r3` — textstil (default = body)
- `pack: persika|rosa|blå|grön|gul|lila` — färg-paket
- `link: 3` — jump-link-par-nummer
- `table: 4×5` — tabell-storlek
- `hidden-label` — text döljs i formen
- `collapsed` — formen är kollapsad (descendants döljs i appen)

Edge-waypoints:
- `%% eN waypoint: x,y` — där `N` är edge-index

### 4. Auktoritativ state (HTML-kommentar med JSON)
```html
<!-- mermaidcanvas-state
{
  "canvas": {
    "width": 3000, "height": 3000, "unit": "pt",
    "shapeBaseWidth": 120, "shapeBaseHeight": 80,
    "iphoneFrame": { "x": ..., "y": ..., "width": 393, "height": 852,
                     "designWidth": 393, "designHeight": 852 }
  },
  "specType": "godot",
  "nodes": [
    { "id": "godot_scene_N0", "x": 1500, "y": 1200,
      "label": "MainMenu", "type": "rectangle",
      "category": "godot_scene", "showLabel": true,
      "size": 1.0, "rotation": 0.0, "note": "",
      "textStyle": "r1", "colorPackId": "blå" },
    ...
  ],
  "edges": [
    { "from": "godot_scene_N0", "to": "godot_container_N1",
      "label": "", "bidirectional": false, "waypoints": [...] }
  ],
  "collapsed": ["..."]
}
-->
```

**Detta är sanningen.** Om du skriver tillbaka — uppdatera både mermaid-blocket OCH state-JSON så att de matchar. Mermaid-id:t är formatet `<category>_N<index>` (t.ex. `ui_N0`, `godot_button_N3`).

### 5. (auto-genererad) regler-fil

`<namn>-regler.md` ligger bredvid och innehåller den fulla regelfilen för canvas-ens `spec_type`. Det är samma innehåll som appen visar via "Visa regler" — så du som Claude Code direkt vet vilka former och pilar som är tillåtna i just den här canvasen.

---

## Plattformer (spec_type) i korthet

| spec_type | Vad det är | Form-katalog (raw category) |
|---|---|---|
| `ui` | iPhone-skärm-design (393×852 iPhone-ram syns i canvas) | ui, zone, overlay, note |
| `roadmap` | Feature-roadmap | feat, milestone, blocker, future, note |
| `architecture` | Kodbas-arkitektur | folder, file, module, service, data, note |
| `flow` | AI-agent-pipeline | input, agent, tool, router, memory, output, note |
| `godot` | Godot scene-blueprint | godot_scene, godot_control, godot_container, godot_panel, godot_button, godot_label, godot_signal, godot_script, note |
| `general` | Allt | alla ovan |

Reglerna per plattform finns i `<namn>-regler.md`. Läs den först innan du skriver något.

---

## Att skriva tillbaka — round-trip-regler

1. **Behåll alla `id`** som finns i state-JSON. Om du behöver lägga till nya former: använd nästa lediga `<category>_N<idx>` där `idx` är `max(existing) + 1`.
2. **Behåll kanvas-positioner** (`x`, `y`) om du bara ändrar label/note. Flytta inte runt former utan goda skäl.
3. **Mermaid-blocket och state-JSON måste matcha.** Skriv båda. Appen läser primärt state-JSON.
4. **Använd kategorierna som matchar `spec_type`** — annars valideras filen inte korrekt.
5. **Lägg till noter via `note`-fältet**, inte som extra mermaid-noder. Anteckningen syns som gul prick på formen.
6. **Bevara `iphoneFrame`-blocket** för `spec_type: ui` — appen behöver det för att rita iPhone-ramen.

---

## Form-positioner

- Canvas är 3000×3000 pt.
- iPhone-ramen i UI-läget är 393×852, placerad cirka (1303, 1074) i canvas-koordinater (se `iphoneFrame` i state).
- För Godot finns ingen ram — använd hela canvasen.
- Default form-storlek: 120 × 80 pt. `size: 1.5` betyder 180 × 120.

---

## Anteckning vs label

- `label` = synlig text i formen (visas på canvas).
- `note` = dold text (visas via gul prick → öppnar mini-sheet).

För Godot specifikt:
- `godot_script` → `label` är filnamnet (`main_menu.gd`), `note` är beskrivning av scriptet.
- `godot_signal` → `label` är signal-namnet (`pressed`, `value_changed`).

---

## När du svarar Kim

Kim har en 2e-profil (dyslexi/ADHD/2e). Tänker visuellt. Inte utvecklare.
- Svara på svenska.
- Korta meningar.
- Visa hellre än förklara — modifiera canvasen istället för att beskriva ändringar i ord.
- Spara filen efter ändring så syns det direkt på Kim's iPhone.
