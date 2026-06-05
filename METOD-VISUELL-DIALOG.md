# METOD-VISUELL-DIALOG — Delat visuellt språk mellan Kim och Claude Code

Detta är en **portabel metodfil**. Den hör inte till en specifik app — den beskriver hur Kim och Claude Code kan kommunicera visuellt via en delad fil, oavsett projekt. Lägg in den i varje projekt där visuell dialog är en del av arbetssättet.

> **Engelskt alias:** Visual Spec Protocol. Använd vilket namn som passar projektet, men en fil per projekt.

---

## Varför

Kim har 2e-profil (dyslexi/ADHD/gifted). Tänker rumsligt och visuellt — saknar vokabulär för att beskriva visuell design i ord. Lösningen: **rita** i stället för att beskriva. Claude Code läser samma fil och ser **exakt** det Kim ser.

Omvänt: när Claude visar hur den tänker — UI-skiss, arkitektur, flöde — skriver Claude till samma fil. Kim öppnar och **ser** Claudes tanke i samma rumsliga koordinatsystem.

Det här ersätter natural-språk-beskrivning av visuell information. Förutsättning: protokollet måste vara **förlustfritt** i båda riktningar.

---

## Grundprincip

En enda fil är sanningen. Båda parter läser och skriver i den.

```
┌──────────┐     fil.md (markdown)      ┌──────────────┐
│   Kim    │ ──── skriver / läser ────► │ Claude Code  │
│  (app)   │ ◄──── läser / skriver ──── │  (terminal)  │
└──────────┘                             └──────────────┘
```

Filen är läsbar för båda — Kim kan se den i appen, Claude kan se den som text. Ingen part äger filen.

---

## Två lager (icke förhandlingsbara)

Protokollet och appen är **två separata saker** som aldrig får blandas:

| Lager | Vad det är | Var det bor |
|---|---|---|
| **App-lager** | Canvas-interaktion: zoom, pan, multiselect, undo, dra/släpp, rotera, snap, jump-links, kollaps | Bara i app-koden (t.ex. Swift) — inte i filen |
| **Protokoll-lager** | Det filen innehåller: fidelity (positioner, storlekar) **och** semantik (vad noder *betyder*) | I `METOD-VISUELL-DIALOG.md` + state-JSON i filen |

App-lagret får växa hur som helst utan att röra protokollet. Protokollet växer bakåtkompatibelt och påtvingar inga app-ändringar.

Inom protokoll-lagret finns två sub-lager:

- **Lager 1 — Fidelity**: var, hur stor, vilken form. Garanterar att Claude ser exakt det Kim ritat.
- **Lager 2 — Semantik**: vad noden *betyder*. Är det en UI-knapp? En zon? En kommentar? Detta gör att Claude kan agera på filen, inte bara visa den.

---

## Lager 1: Fidelity (visuell trogenhet)

För att Claude ska kunna **återskapa** det Kim ritat — med rätt proportioner, placering och storlek — krävs:

### Per form (node)
| Fält | Varför |
|---|---|
| `id` | Stabil referens för pilar att peka på |
| `type` | Cirkel, rektangel, romb, etc. — formens grafiska semantik |
| `x`, `y` | Exakt position i canvas-koordinatsystem |
| `size` | Relativ storlek (multiplikator av bastypen) |
| `label` | Text i formen |
| `showLabel` | Om texten ska visas eller döljas |
| `note` | Anteckning som inte syns på canvasen men följer formen |
| `category` | Semantisk kategori (se Lager 2). Default: `"ui"`. |

### Per pil (edge)
| Fält | Varför |
|---|---|
| `from`, `to` | Vilka former pilen kopplar |
| `bidirectional` | Enkel- eller dubbelriktad |
| `label` | Text på pilen |

### Canvas-meta (referensram) — **kritisk**
| Fält | Varför |
|---|---|
| `width`, `height` | Definierar koordinatsystemet. Utan detta är x/y meningslösa för en annan läsare. |
| `shapeBaseWidth`, `shapeBaseHeight` | Bas-storlek av en form med `size=1.0`. Avgör absolut storlek. |
| `unit` | Pixlar, pt, eller normaliserat (0–1). Default: "pt". |

**Utan canvas-meta vet Claude inte vilken referensram positionerna är i** — det gör Claudes "vy" av filen ofullständig.

---

## Lager 2: Semantik (vad noder betyder)

Fidelity säger var en form ligger. Semantik säger vad den **är**. Båda behövs för att Claude ska kunna förvandla filen till kod, arkitektur eller flöde.

### 2.1 Kategorier (klasser)

Varje nod har en `category` som styr hur Claude tolkar den:

| Kategori | Betydelse | Renderas av Claude som |
|---|---|---|
| `ui` | Riktigt UI-element (knapp, mätare, panel, ikon, text) | SwiftUI/komponent som ska byggas |
| `zone` | Layoutzon eller region (top HUD, sidopanel, bottom controls) | Stack/region där `ui`-element placeras |
| `note` | Kommentar eller UX-regel — **inte** UI-text | Implementationstips. Ska aldrig synas på skärm. |
| `overlay` | Element som ligger ovanpå andra (modal, tooltip, HUD-överlägg) | ZStack-overlay eller motsvarande |
| `link` | Canvas-länk (jump mellan platser på canvasen) | Bara metadata. Claude implementerar inte canvas-navigering. |
| `dev` | Teknisk note (kod-constraint, refaktorerings-tips) | Implementationsstöd, ej UI |

Default-kategori om inget anges: `ui`.

För andra fil-typer (se nedan) kan listan utökas — t.ex. `feat`, `milestone`, `module`, `agent`. Reglerna är desamma: bakåtkompatibel utvidgning, defaults i parser, aldrig brytande ändringar.

### 2.2 Prefix i Mermaid-blocket

I det human-readable Mermaid-blocket ska node-ID:n få **prefix** som matchar kategorin:

```
ui_energy["Energy Meter"]
zone_top["Top HUD"]
note_boost["Boost ska nås med höger tumme"]
```

Det gör att en människa som läser mermaid-blocket direkt ser semantiken. State-JSON är fortfarande autoritativ; prefixet är för läsbarhet.

Konvention: `<kategori>_<kort_namn>` eller `<kategori>_<index>`.

### 2.3 classDef-färger

Mermaid-blocket ska innehålla `classDef` per kategori så att GitHub-rendering visar färg:

```
classDef ui fill:#1d4ed8,stroke:#1e293b,color:#f9fafb;
classDef zone fill:#e5e7eb,stroke:#9ca3af,color:#111827;
classDef note fill:#ecfdf3,stroke:#16a34a,color:#166534;
classDef overlay fill:#0f172a,stroke:#38bdf8,color:#e0f2fe;
```

Hex-färgerna är estetik — kan justeras i appen. **Klassnamnet bär semantiken**, inte hexen. Claude tolkar `:::ui`, inte `#1d4ed8`.

### 2.4 Textregler (kritiska)

Det finns **två** typer av text i filen. Att blanda dem är det vanligaste sättet protokollet kan bryta.

| Texttyp | Var | Tolkning |
|---|---|---|
| **Displaytext** | Inne i en `ui`-nod (`label`-fältet) | Text som ska *synas* på skärmen i den byggda appen |
| **Kommentartext** | Inne i `note`-nod, eller Markdown-paragraf utanför ```` ```mermaid ```` -block | Text som *förklarar* — ska aldrig hamna i UI |

Regel för Claude: läs aldrig `note_*`-text som UI-text. Använd den gärna som implementationsråd, men sätt den aldrig på skärmen.

Regel för Kim (genom appen): när du skriver i en form vars kategori är `note`, är texten kommentar. När kategori är `ui` är texten displaytext.

---

## Fil-typer (samma protokoll, olika tankelägen)

Samma fil-format kan användas för olika syften. Skillnaden anges i frontmatter:

```yaml
---
title: Echowake HUD
spec_type: ui
last_updated: 2026-05-14
---
```

| `spec_type` | Filnamnskonvention | Vad den beskriver | Typiska kategorier |
|---|---|---|---|
| `ui` | `ui-spec.md` eller `*-ui.md` | Skärmar, HUD, layout-zoner | `ui`, `zone`, `note`, `overlay` |
| `roadmap` | `roadmap.md` | MVP-steg, features, beroenden, status | `feat`, `milestone`, `blocker`, `future`, `note` |
| `architecture` | `architecture.md` | Mappar, moduler, tjänster, scener | `folder`, `file`, `module`, `service`, `note` |
| `flow` | `flow-main.md` | Agentflöden, input/output, routing | `input`, `agent`, `tool`, `router`, `memory`, `output`, `note` |
| `general` | `canvas.md` eller fritt | När typen är odefinierad eller blandad | valfritt |

`spec_type` är hint för Claude — den bestämmer t.ex. om Claude ska generera SwiftUI-kod (`ui`), planeringsförslag (`roadmap`), refaktoreringsförslag (`architecture`) eller exekverbara agentkedjor (`flow`).

Om frontmatter saknas: anta `spec_type: general`.

---

## Filformat (konvention)

Markdown med fyra lager — frontmatter, mermaid, brödtext och state-JSON:

```markdown
---
title: Echowake HUD
spec_type: ui
last_updated: 2026-05-14
---

# Echowake HUD

Beskrivande text (valfri, för människor).

​```mermaid
flowchart TD
    ui_energy["Energy Meter"]:::ui
    zone_top["Top HUD"]:::zone
    note_boost["Boost ska nås med höger tumme"]:::note
    zone_top --> ui_energy
    ui_energy --> note_boost

    classDef ui fill:#1d4ed8,stroke:#1e293b,color:#f9fafb;
    classDef zone fill:#e5e7eb,stroke:#9ca3af,color:#111827;
    classDef note fill:#ecfdf3,stroke:#16a34a,color:#166534;
​```

<!-- mermaidcanvas-state
{
  "canvas": { "width": 393, "height": 600, "shapeBaseWidth": 120, "shapeBaseHeight": 80, "unit": "pt" },
  "nodes": [
    { "id": "ui_energy", "type": "rectangle", "category": "ui", "x": 200, "y": 100, "size": 1.0, "label": "Energy Meter", "showLabel": true, "note": "" },
    { "id": "zone_top",  "type": "rectangle", "category": "zone", "x": 200, "y": 40,  "size": 2.0, "label": "Top HUD", "showLabel": true, "note": "" },
    { "id": "note_boost","type": "rectangle", "category": "note", "x": 200, "y": 300, "size": 1.5, "label": "Boost ska nås med höger tumme", "showLabel": true, "note": "" }
  ],
  "edges": [
    { "from": "zone_top",  "to": "ui_energy",   "bidirectional": false, "label": "" },
    { "from": "ui_energy", "to": "note_boost",  "bidirectional": false, "label": "" }
  ]
}
-->
```

**Fyra lager med olika syfte:**
1. **Frontmatter (YAML)**: metadata, `spec_type`
2. **Rubrik + brödtext**: för människor (Kim, Claude, github-läsare). Räknas alltid som kommentar.
3. **Mermaid-block**: human-readable struktur + renderas av GitHub/IDE. Innehåller prefix + classDef.
4. **HTML-comment JSON**: autoritativ visuell + semantisk state — full round-trip.

JSON i HTML-comment är **autoritativ för positioner, kategorier och visuella attribut**. Mermaid är fallback om JSON saknas.

---

## Regler för att hålla protokollet förlustfritt

1. **Skriv alltid alla lager.** Saknas JSON är round-trip förlorad.
2. **Stega aldrig över canvas-meta.** Utan referensram är x/y obegripligt för en ny läsare.
3. **Lägg till fält bakåtkompatibelt.** Nya attribut ska ha default-värden i parsern så gamla filer fortfarande laddas.
4. **Klampa orimliga värden i parsern.** Storlek 100x, position utanför rimligt intervall: klampa eller varna, krascha aldrig.
5. **id är opakt men följer prefix-konventionen.** Inom mermaid: använd `<kategori>_<...>`. State-JSON spelar ingen roll på id-format, bara att det är unikt.
6. **Glömt fält = default, inte fel.** Parser ska aldrig krascha på saknad data. Saknad kategori → `ui`. Saknat `spec_type` → `general`.
7. **Versionera inte.** Ingen `"version": 2` — använd alltid bakåtkompatibel utvidgning. Om brytande ändring krävs: nytt protokoll-namn.
8. **Aldrig blanda displaytext och kommentartext.** Text i `note`-kategori syns aldrig som UI. Text i `ui`-kategori är alltid synlig i den byggda appen.

---

## Hur du som Claude ska arbeta med filen

**När du läser:**
1. Läs frontmatter först. `spec_type` säger vad filen handlar om.
2. Läs canvas-meta. Förstå referensramen.
3. Läs nodernas `category` för att veta vad varje form är (UI, zon, note, etc.).
4. Tolka x/y i canvas-referensramen, inte din egen.
5. Tolka size relativt shapeBase-värdena.
6. Behandla `note`-nodernas text som implementationsstöd, aldrig som UI-text.
7. Markdown utanför ```` ```mermaid ````-block är förklaringar för människor — använd som kontext, inte som protokoll-data.

**När du skriver:**
1. Använd samma canvas-storlek som Kim senast skrev (läs från filen om den finns).
2. Om filen är tom — använd defaults för Kims aktuella enhet (iPhone-canvas: 393×600 pt).
3. Skriv ALLA fält Kim använder, även med defaults — gör round-trip trygg.
4. Sätt rätt `category` per nod. Default `ui` om du är osäker.
5. Använd prefix i Mermaid-block (`ui_`, `zone_`, etc.) konsekvent.
6. Skriv `classDef`-rader för alla kategorier du använder.
7. Skriv alla fyra lagren (frontmatter + rubrik + mermaid + JSON).
8. Validera mot reglerna ovan innan du sparar.

---

## Konkret referensimplementation

**MermaidCanvas** (iOS-app i detta projekt) är första implementationen av detta protokoll. Se:
- `app/MermaidCanvas/Sources/Mermaid/MermaidGenerator.swift` — skriver
- `app/MermaidCanvas/Sources/Mermaid/MermaidParser.swift` — läser
- `app/MermaidCanvas/Sources/Persistence/CanvasDocument.swift` — fil-lager

Använd MermaidCanvas-filen `canvas.md` (i Kims iCloud) som live-exempel.

**Status:** Lager 1 (fidelity) + Lager 2 (semantik) stöds fullt ut. Sedan **v61** är
mermaid-blocket dessutom **självbärande**: `%%`-kommentarerna nedan round-trippar all
fidelity även om state-JSON saknas. State-JSON förblir autoritativ när den finns.

### %%-metadata-kommentarer (självbärande mermaid, v61)

Format: `%% <nod-id> <nyckel>: <värde>` (en rad per egenskap, skrivs av generatorn,
läses av parsern). Radbrytning i text skrivs som ` ⏎ `, `%%` i text som `%-%`.

| Nyckel | Exempel | Betyder |
|---|---|---|
| `pos` | `%% ui_N0 pos: 200,320` | Exakt position (canvas-pt) |
| `size` | `%% ui_N0 size: 1.5` | Storleks-multiplikator |
| `width` / `height` | `%% ui_N0 width: 2.00` | Fri-resize-multiplikatorer |
| `rot` | `%% ui_N0 rot: 45°` | Rotation i grader |
| `color` | `%% ui_N0 color: #ff0000` | Färg-override (hex) |
| `pack` | `%% ui_N0 pack: rosa` | Färgpaket-id |
| `style` | `%% ui_N0 style: r1` | Textstil (r1/r2/r3/body) |
| `note` | `%% ui_N0 note: text` | Anteckning (syns ej på canvas) |
| `name` | `%% ui_N0 name: text` | Nodens label (återställer dold etikett) |
| `prompt` | `%% ui_N0 prompt: text` | n8n-prompt — se `N8N-FLODE-KONTRAKT.md` |
| `hidden-label` | `%% ui_N0 hidden-label` | Etiketten är dold (flagga) |
| `collapsed` | `%% ui_N0 collapsed` | Sub-trädet är kollapsat (flagga) |
| `link` | `%% ui_N0 link: 1` | Hopplänk-parnummer |
| `table` | `%% ui_N0 table: 3×4` | Tabell rader×kolumner |
| `line-end` | `%% ui_N0 line-end: 280,140` | Lös linjes slutpunkt (absolut) |
| `container-pos` | `%% cont_N1 container-pos: 400,300` | Containerns position |

**När du som Claude skriver RÅ mermaid utan state-JSON:** lägg gärna `%% id pos: x,y`
per nod om layouten spelar roll. Utan pos-kommentarer får noderna automatisk lagrad
layout som följer `flowchart TD/LR/BT/RL` (v61) — strukturen blir rätt, exakta
positioner väljer appen.

---

## När ska den här filen användas?

- **I varje nytt projekt där Kim vill kunna visa visuellt istället för att beskriva i text.**
- Lägg in den så fort projektet har en visuell yta (UI, arkitektur-canvas, flöde, layout).
- Hänvisa till den från projektets `CLAUDE.md` så den blir oavvislig.

---

## Hur protokollet utvecklas

När en ny visuell egenskap behövs (färg, rotation, z-order, etc.) eller en ny kategori:

1. Lägg till fältet/kategorin med en default som matchar nuvarande beteende
2. Uppdatera generator + parser i samma commit
3. Lägg till fältet/kategorin i tabellen i denna fil
4. Skriv inga "version: 2"-flaggor — bakåtkompatibilitet via defaults

Den här filen är den enda specifikationen. Håll den aktuell.
