# METOD-VISUELL-DIALOG — Delat visuellt språk mellan Kim och Claude Code

Detta är en **portabel metodfil**. Den hör inte till en specifik app — den beskriver hur Kim och Claude Code kan kommunicera visuellt via en delad fil, oavsett projekt. Lägg in den i varje projekt där visuell dialog är en del av arbetssättet.

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

## Vad protokollet MÅSTE innehålla för att fungera

För att Claude ska kunna **återskapa** det Kim ritat — med rätt proportioner, placering och storlek — krävs:

### Per form (node)
| Fält | Varför |
|---|---|
| `id` | Stabil referens för pilar att peka på |
| `type` | Cirkel, rektangel, romb, etc. — formens semantik |
| `x`, `y` | Exakt position i canvas-koordinatsystem |
| `size` | Relativ storlek (multiplikator av bastypen) |
| `label` | Text i formen |
| `showLabel` | Om texten ska visas eller döljas |
| `note` | Anteckning som inte syns på canvasen men följer formen |

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

## Filformat (konvention)

Markdown med tre lager:

```markdown
# Rubrik

Beskrivande text (valfri, för människor).

​```mermaid
flowchart TD
    A(("Start"))
    A --> B["Slut"]
​```

<!-- visual-state
{
  "canvas": { "width": 393, "height": 600, "shapeBaseWidth": 120, "shapeBaseHeight": 80, "unit": "pt" },
  "nodes": [
    { "id": "A", "type": "circle", "x": 200, "y": 100, "size": 1.0, "label": "Start", "showLabel": true, "note": "" },
    { "id": "B", "type": "rectangle", "x": 200, "y": 300, "size": 1.0, "label": "Slut", "showLabel": true, "note": "" }
  ],
  "edges": [
    { "from": "A", "to": "B", "bidirectional": false, "label": "" }
  ]
}
-->
```

**Tre lager med olika syfte:**
1. **Rubrik + brödtext**: för människor (Kim, Claude, github-läsare)
2. **Mermaid-block**: human-readable struktur + renderas av GitHub/IDE
3. **HTML-comment JSON**: autoritativ visuell state — full round-trip

JSON i HTML-comment är **autoritativ för positioner och visuella attribut**. Mermaid är fallback om JSON saknas.

---

## Regler för att hålla protokollet förlustfritt

1. **Skriv alltid alla tre lagren.** Saknas JSON är round-trip förlorad.
2. **Stega aldrig över canvas-meta.** Utan referensram är x/y obegripligt för en ny läsare.
3. **Lägg till fält bakåtkompatibelt.** Nya attribut ska ha default-värden i parsern så gamla filer fortfarande laddas.
4. **Klampa orimliga värden i parsern.** Storlek 100x, position utanför rimligt intervall: klampa eller varna, krascha aldrig.
5. **id är opakt.** Inga regler om format — bara att det är unikt inom filen.
6. **Glömt fält = default, inte fel.** Parser ska aldrig krascha på saknad data.
7. **Versionera inte.** Ingen `"version": 2` — använd alltid bakåtkompatibel utvidgning. Om brytande ändring krävs: nytt protokoll-namn.

---

## Hur du som Claude ska arbeta med filen

**När du läser:**
1. Läs canvas-meta först. Förstå referensramen.
2. Tolka x/y i den ramen, inte din egen.
3. Tolka size relativt shapeBase-värdena.
4. Behandla noteringar som mer-kontext — de följer formen.

**När du skriver:**
1. Använd samma canvas-storlek som Kim senast skrev (läs från filen om den finns).
2. Om filen är tom — använd defaults för Kims aktuella enhet (iPhone-canvas: 393×600 pt).
3. Skriv ALLA fält Kim använder, även med defaults — gör round-trip trygg.
4. Skriv alla tre lagren (rubrik + mermaid + JSON).
5. Validera mot reglerna ovan innan du sparar.

---

## Konkret referensimplementation

**MermaidCanvas** (iOS-app i detta projekt) är första implementationen av detta protokoll. Se:
- `app/MermaidCanvas/Sources/Mermaid/MermaidGenerator.swift` — skriver
- `app/MermaidCanvas/Sources/Mermaid/MermaidParser.swift` — läser
- `app/MermaidCanvas/Sources/Persistence/CanvasDocument.swift` — fil-lager

Använd MermaidCanvas-filen `canvas.md` (i Kims iCloud) som live-exempel.

---

## När ska den här filen användas?

- **I varje nytt projekt där Kim vill kunna visa visuellt istället för att beskriva i text.**
- Lägg in den så fort projektet har en visuell yta (UI, arkitektur-canvas, flöde, layout).
- Hänvisa till den från projektets `CLAUDE.md` så den blir oavvislig.

---

## Hur protokollet utvecklas

När en ny visuell egenskap behövs (färg, rotation, z-order, etc.):

1. Lägg till fältet med en default som matchar nuvarande beteende
2. Uppdatera generator + parser i samma commit
3. Lägg till fältet i tabellen i denna fil
4. Skriv inga "version: 2"-flaggor — bakåtkompatibilitet via defaults

Den här filen är den enda specifikationen. Håll den aktuell.
