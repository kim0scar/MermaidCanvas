# V50 placerings-matris — visuell bugjakt på v49

**Syfte:** Generera ~20 deterministiska scenarier som var och en exponerar en
potentiell visuell placeringsbugg. Varje scenario byggs på modellen via
launch-arg → screenshot tas → sub-agent granskar mot förväntad placering.

**Mönster:** `-uitest-place-<NN>-<slug>` läses i
`ContentView.applyUITestScenarioIfNeeded()` → bygger upp scenariot direkt
på `model.shapes` / `model.edges` / `model.selectedShapeId`. Inga
XCUITest-drag-gester (kringgår simulator-bugg).

**Granskningens checklista per pil:**
1. Start- och slutpunkt landar **exakt på formens kant**, inte i mitten och
   inte utanför.
2. Pilspetsen är **vinkelrät mot riktningen** och symmetrisk (ingen
   skev ut-sticking från `.round`-cap).
3. Midpoint-handle sitter **på linjens visuella mitt** och **roterar med
   linjen**.
4. Kant-etikett, om det finns, sitter **vid midpoint** utan att
   krocka med formen.

**Granskningens checklista per badge / kollaps:**
1. Minus-badge syns bara på from-shape när from-shape är markerad.
2. Plus-badge på stub syns alltid när to-shape är kollapsad-osynlig.
3. Stub-streckad linje börjar vid from-formens kant och slutar där
   to-formen *skulle ha varit*.

**Granskningens checklista per container:**
1. Containerns ram omsluter alla `childOfContainerId == container.id`-barn.
2. Barn vars position är *utanför* containerns visuella ram syns ändå
   (de räknas som barn, men är "frikopplade visuellt" — räknas det som
   bug eller feature?).
3. Pilar mellan barn ligger *innanför* eller *utanför* korrekt — pilar
   som startar inuti och slutar utanför ska gå genom kanten utan att
   "klippas".

---

## Scenario-tabell

| # | Slug | Bygger | Förväntad placering |
|---|---|---|---|
| 01 | `tight-horizontal` | 2 rektanglar nära varandra horisontellt (120pt avstånd) | Pilen pekar horisontellt rakt; start/slut på rektanglarnas vertikala kanter; pilspets centrerad i höjdled |
| 02 | `tight-vertical` | 2 rektanglar nära varandra vertikalt | Pilen pekar nedåt rakt; start/slut på rektanglarnas horisontella kanter; midpoint-ikonen ska rotera 90° |
| 03 | `diagonal` | 2 cirklar diagonalt placerade | Pilen pekar diagonalt; pilspets vinkelrät mot riktningen |
| 04 | `very-close` | 2 cirklar med endast 40pt avstånd center-till-center (kort < radie) | Pilen ska INTE klippas genom formerna; om den blir oläslig är det en bug |
| 05 | `arrowhead-8-directions` | 1 central rektangel, 8 cirklar runt i 45°-intervall, pil från center till var och en | Pilspetsen ska vara symmetrisk (inte skev) i alla 8 riktningar; ingen ska sticka ut |
| 06 | `arrowhead-on-diamond` | pil till en diamant | Pilspetsen pekar mot diamantens vinklade kant, inte mitten |
| 07 | `arrowhead-on-pill` | pil till en pill (kapsel) | Pilen landar på den rundade ändens kant |
| 08 | `arrow-each-shape-type` | 1 källa, pilar till alla 9 form-typer i en cirkulär layout | Alla pilar landar på respektive forms kant; pilspetsar symmetriska |
| 09 | `processarrow-as-source` | pil från processArrow till en cirkel | Pilen startar från processArrow-formens kant, inte mitten |
| 10 | `container-as-target` | pil från extern cirkel till en container | Pilen landar på containerns ram, inte inuti |
| 11 | `collapsed-single` | A→B, A markerad, B kollapsad | Minus-badge syns vid kantstart på A; stub-streckad linje + plus-badge syns där B skulle ha varit |
| 12 | `collapsed-chain` | A→B→C, B kollapsad | A→B fortfarande synlig; B→C blir stub med plus; C blir osynlig |
| 13 | `minus-badge-position` | rektangel→cirkel, rektangel markerad | Minus-badge sitter på rektangelns kant där pilen startar — inte i hörnet |
| 14 | `bidir-with-label` | A↔B med etikett "kallar" | Två pilspetsar (en i varje ände), etikett vid midpoint utan krock |
| 15 | `dashed-edge` | A→B med streckad linje | Streckad heldragen, pilspets fortfarande solid |
| 16 | `backward-edge` | A→B med direction=backward | Pilspetsen sitter på A-änden, inte B |
| 17 | `container-with-3-children` | container + 3 cirklar med childOfContainerId satt, pilar mellan dem | Alla 3 cirklar visuellt innanför containerns ram; interna pilar fungerar |
| 18 | `nested-containers` | Container1 innehåller Container2 som innehåller 2 cirklar | Hierarkin syns visuellt; cirklarna inuti Container2 inuti Container1 |
| 19 | `child-outside-container` | container + cirkel med childOfContainerId satt men position 500pt utanför | Cirkeln syns där positionen säger (utanför), inte teleporterad — men relationen kvarstår logiskt |
| 20 | `multi-select-3-shapes` | 3 cirklar i rad, multiSelection = alla 3, model.moveSelection(+50,+50) körd | Alla 3 cirklar har flyttats +50,+50; deras position-relation bevarad |
| 21 | `multi-select-with-edges` | 3 cirklar + pilar mellan dem, alla 3 markerade, moveSelection(+50,0) | Cirklarna flyttar; pilarna följer (endpunkterna fortsätter sitta på kanter) |
| 22 | `edge-after-resize` | 2 rektanglar + pil, rektanglen storleksändrad (widthMultiplier=2.0) | Pilen ska sitta på den nya kanten, inte den gamla |
| 23 | `edge-with-label-curved` | pil som böjs runt obstakel + etikett | Etiketten sitter vid kurvans midpoint, inte rak mellan endpunkter |

---

## Bygg + kör

```bash
cd app/MermaidCanvas
xcodegen generate      # om nya filer lagts till
xcodebuild test -project MermaidCanvas.xcodeproj -scheme MermaidCanvas \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,id=A658C63E-DA34-433B-9EC1-84F50711A8EA" \
  -derivedDataPath DerivedData-sim \
  -only-testing:MermaidCanvasUITests/V50PlacementTests
```

Screenshots ligger sedan i `.xcresult`-paketet och extraheras till
`UI-PLACERINGS-FYND-v49/screenshots/` via xcresulttool.
