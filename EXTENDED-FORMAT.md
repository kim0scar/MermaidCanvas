# EXTENDED-FORMAT.md — "MermaidCanvas Extended"

*Spikat 2026-06-20 (steg G1). Speglar koden i `Sources/Mermaid/`. Uppdatera i samma commit som format-ändringar.*

Det här är **det app-egna lagret** som MermaidCanvas bär *inuti* mermaid-filen utan att skada den rena mermaiden. Syftet: en fil kan skickas till en vän → öppnas i mermaid.live (visar diagrammet) ELLER återimporteras i appen (exakt samma bild). Se CLAUDE.md regel 3 (noll-avvikelse) + `MERMAID-FAKTA.md` sektion K/L (två-lager-modellen).

## Två-lager-modellen

Mermaid är **transporten** (portabel, AI-läsbar kropp). Appen är **renderaren** med ett eget tilläggslager. Filen har därför flera bärare:

| Bärare | Vad | Vem läser | Förlustfri? |
|---|---|---|---|
| **Mermaid-kroppen** | noder, kanter, subgraphs, classDefs | mermaid.live + appen | strukturen (mermaids gräns) |
| **`%%`-rader** | app-only-fält som inline-kommentarer | appens fallback-parser + människa/Claude | ren-mermaid-trogen |
| **`<!-- mermaidcanvas-state … -->`** | hela modellen som JSON | appens state-parser | **bokstavligt noll avvikelse** |
| **`---` frontmatter** | title, spec_type, platform, shape_packs | appens frontmatter-parser | exakt |
| **Inbäddat AI-ramverk (1.0)** | förklaring av de två lagren + varje bärare, genererat ur `AppCapabilities` | en främmande AI som tar emot filen | n/a (ren spec-text, ej data) |

**Vid import vinner state-JSON** om blocket finns (Tier 1 = exakt). Saknas det (vän strippade det, eller en AI ritade för hand) faller appen tillbaka på `%%` + mermaid-strukturen (Tier 2 = troget, men egna former visas som närmaste native-form och `%%`-only-fält bärs av kommentarerna).

**Inbäddat AI-ramverk (1.0):** sist i varje exportfil ligger `AppCapabilities.frameworkText()` som **synlig markdown** (efter state-blocket, inte i en HTML-kommentar — ramverket innehåller `-->` och strängen `<!-- mermaidcanvas-state -->`). Så filen är *själv-förklarande*: en främmande AI ser direkt vad som är ren mermaid och vad som är app-lagret, och kan bygga vidare utan att förstöra något. mermaid.live/markdown-preview påverkas inte (de bryr sig bara om ```mermaid-blocket). Genereras ur samma single source som menyn → kan aldrig bli inaktuellt; `AppCapabilitiesCoverageTests.test_exportEmbedsFrameworkAndStillRoundTrips` tvingar att det följer med OCH att inbäddningen inte bryter round-trippen.

**Egna former** (phoneFrame, tabell, oktagon, kvadrat, processpil, lös linje/pil) renderas i ren mermaid som närmaste native-form; identiteten bärs av `%% <id> shape-type:` så den round-trippar. Det är mermaids gräns, inte en bugg.

---

## Nod-fält (ShapeNode)

`<id>` = mermaid-id (t.ex. `ui_N3`). Alla `%%`-rader är osynliga i mermaid.live.

| Fält | `%%`-nyckel | state-JSON | Överlever REN mermaid? |
|---|---|---|---|
| position | `%% <id> pos: x,y` (heltal) | `x`,`y` (Double, exakt) | ja |
| label | nodens kropp + `%% <id> name:` | `label` | ja |
| type | `%% <id> shape-type:` (för icke-native former) | `type` | ja (annars härledd ur kroppen) |
| category | mermaid-id-prefix + `:::klass` | `category` | ja |
| showLabel | `%% <id> hidden-label` | `showLabel` | ja |
| sizeMultiplier | `%% <id> size:` (om ≠1) | `size` | ja |
| widthMultiplier | `%% <id> width:` | `widthMultiplier` | ja |
| heightMultiplier | `%% <id> height:` | `heightMultiplier` | ja |
| note | `%% <id> note:` | `note` | ja |
| prompt | `%% <id> prompt:` | `prompt` | ja |
| rotation | `%% <id> rot: N°` (om |v|>0,5) | `rotation` | ja (exakt, ingen kapning) |
| colorOverride | `%% <id> color:` | `color` | ja |
| strokeColorOverride | `%% <id> stroke:` | `strokeColor` | ja |
| linkNumber | `%% <id> link:` | `linkNumber` | ja |
| skillNumber | `%% <cid> skill-nr:` (bara container) | `skillNumber` | ja |
| tableRows/Cols | `%% <id> table: R×C` | `tableRows`,`tableCols` | ja |
| tableCells | `%% <id> table-cells: <JSON>` | `tableCells` | ja |
| textStyle | `%% <id> style:` (om ≠body) | `textStyle` | ja |
| colorPackId | `%% <id> pack:` | `colorPackId` | ja |
| lineEnd | `%% <id> line-end: absX,absY` | `lineEnd` (relativ) | ja |
| textAlignment | `%% <id> align:` (om ≠center) | `textAlignment` | ja |
| hasBullets | `%% <id> bullets` | `hasBullets` | ja |
| hasNumberedList | `%% <id> numbered` | `hasNumberedList` | ja |
| indentLevel | `%% <id> indent:` (om >0) | `indentLevel` | ja (exakt, ingen kapning) |
| bold | — (inget %%-spår) | `bold` | **nej** (state-JSON-only; mermaid saknar nod-text-fetstil) |
| italic | — (inget %%-spår) | `italic` | **nej** (state-JSON-only) |
| underline | — (inget %%-spår) | `underline` | **nej** (state-JSON-only) |
| childOfContainerId | `subgraph`+`end`-medlemskap | `childOfContainerId` | ja (positionellt) |
| id (UUID) | — (mermaid-id är nyckeln) | — | ny UUID vid import (kanter följer med) |

Containrar emitteras som `subgraph`-block och re-emitterar samma nycklar, men position som `%% <cid> container-pos: x,y`.

## Kant-fält (EdgeConnection)

`e<i>` = kantens emit-ordning.

| Fält | `%%`-nyckel | state-JSON | Överlever REN mermaid? |
|---|---|---|---|
| from/to | pil-raden `src pil dst` | `from`,`to` | ja |
| direction | pil-glyfen (`-->`/`<-->`/`---`) | `direction` | delvis* |
| style | pil-glyfen (`-.->` = streckad) | `style` | ja |
| label | inline `\|"label"\|` | `label` | ja |
| waypoints | `%% e<i> waypoint: x,y` | `waypoints` | ja |
| labelPlacement | `%% e<i> labelPlacement:` (om ≠below) | `labelPlacement` | ja |
| colorHex | `%% e<i> color:` | `color` | ja |
| fromSide | `%% e<i> fromSide:` | `fromSide` | ja |
| toSide | `%% e<i> toSide:` | `toSide` | ja |
| collapsed | `%% e<i> collapsed: true` | `collapsed` | ja |

\* **Bakåtkant** (`direction: .backward`) skrivs som framåtpil med omvända noder (`to --> from`), eftersom `<--` kraschar riktig mermaid (steg H-fyndet). Visuellt identiskt; den exakta riktnings-*flaggan* bevaras bara av state-JSON. Ren mermaid återskapar den som framåtpil med omvänd ordning — samma bild.

## Canvas-nivå

| Fält | Bärare | Överlever REN mermaid? |
|---|---|---|
| **canvasSize (w,h)** | `%% canvas-size: w,h` **(G1)** + state-JSON `canvas.width/height` | **ja (G1 — var tidigare enda fältet som tappades)** |
| legend | `%% legend <kategori>: text` + state-JSON `legend` | ja |
| title / spec_type / platform / shape_packs | `---` frontmatter (+ state-JSON) | ja (via frontmatter) |
| iphoneFrame-geometri, shapeBaseWidth/Height, unit | bara state-JSON (informativt) | nej — deriverbara konstanter, round-trippas inte (avsiktligt) |

---

## Reserverade `%%`-nycklar (framtida app-only-funktioner)

Spikade i förväg så kommande bygge (💡#6/#7) har ett fast format och inte krockar:

| Nyckel | Betydelse | Idé |
|---|---|---|
| `%% <id> z: N` | lager-ordning (fram/bak) | 💡#6 |
| `%% <id> local-pos: x,y` | position relativt sin container/skärm | 💡#6 |
| `%% e<i> route: <mode>` / `%% e<i> label-pos: x,y` | pil-routing-läge + etikett-position | 💡#6 |
| `%% <id> parent: <cid>` | förälder-länk för nästlad container i REN mermaid | 💡#7 |

Dessa **emitteras inte än** — de är reserverade så formatet är förutsägbart när funktionerna byggs.

---

## Garantin (varför det här finns)

- **Tier 1 (Kim: rita → kopiera → radera → klistra):** state-JSON ⇒ bokstavligt noll avvikelse. Tvingas av `RoundTripFidelityTests` + `StateJSONSymmetryTests` + round-trip-grind i pre-commit/deploy.
- **Tier 2 (vän i mermaid.live):** mermaid-kroppen renderar; `%%` + struktur bär det app-egna; egna former visas som närmaste native-form. Tvingas av konformitetsgrinden (`mermaid.parse`) + render-grinden (`mermaid-render-check.mjs`, headless Chrome, vid deploy).

Bygg aldrig en app-only-funktion utan att först lägga in dess bärare här (regel 3b).
