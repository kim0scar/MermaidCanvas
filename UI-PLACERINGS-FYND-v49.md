# UI-placerings-fynd — v49

**Datum:** 2026-05-23
**Scenarier granskade:** 23 (`UI-PLACERINGS-FYND-v49/screenshots/`)

## Klassificering

- **3 BUG** (allvarliga)
- **3 DEGRADERING** (fungerar men ser fel ut)
- **1 KOSMETISKT**
- **16 OK**

---

## Topp-prioriterade fynd

### F-01 [BUG] — Pil mellan överlappande former syns inte
**Scenario:** `place_04-very-close.png`
**Förväntan:** En pil ska synas (även om kort) mellan två cirklar som är väldigt nära (40pt avstånd, radius 50pt).
**Faktiskt:** Båda cirklarna syns överlappande, MEN pilen mellan dem är helt osynlig. Inget streck, ingen pilspets, ingen midpoint-handle.
**Möjlig kod-pekare:** `Sources/App/Views/EdgesView.swift` — v48-fixen drar in endpoint med `lineWidth/2`. Om resulterande edgePoint-distance < 0 ritas inget.

### F-02 [BUG] — Pilar i container går åt fel håll
**Scenario:** `place_17-container-with-3-children.png`
**Förväntan:** 3 cirklar på rad inuti container. Pilar cirkel1→cirkel2 och cirkel2→cirkel3 ska gå horisontellt.
**Faktiskt:** Fyra långa "stångar" går RAKT UPP UR SKÄRMEN. Pilarna har fel waypoints / fel start- och slutpunkt när from/to är barn till container.
**Möjlig kod-pekare:** `Sources/App/Views/EdgesView.swift` eller `EdgeRouting.swift` — kant-koordinaterna beräknas möjligen i fel coordinate-space när shape är child av container.

### F-03 [BUG] — Midpoint-handle och etikett saknas på böjd pil
**Scenario:** `place_23-edge-with-label-curved.png`
**Förväntan:** Pil som böjs runt obstakel ska ha midpoint-handle vid kurvans topp + etikett "förbi" nära midpoint.
**Faktiskt:** Pilen böjer sig fint, MEN ingen midpoint-handle syns alls och etiketten "förbi" saknas.
**Möjlig kod-pekare:** `Sources/App/Views/EdgesView.swift` — midpoint-beräkningen använder förmodligen linjär mid(from,to) snarare än bezier-mid(0.5).

---

## Degraderingar

### F-04 [DEGRADERING] — Diagonala pilar böjs onödigt
**Scenario:** `place_05-arrowhead-8-directions.png`
**Faktiskt:** 8 pilar från central hub-rektangel till 8 cirklar i 45°-intervall. Pilarna till nord/syd/öst/väst är raka. Pilarna till NE/NW/SE/SW är BÖJDA (bezier-kurva), när de borde vara raka diagonaler.
**Möjlig kod-pekare:** `EdgeRouting.swift` — algoritmen ser hub-rektangeln som obstakel även för pilar som startar PÅ den.

### F-05 [DEGRADERING] — Pil-endpunkt på diamant använder bbox
**Scenario:** `place_06-arrowhead-on-diamond.png`
**Faktiskt:** Pilen slutar strax innanför diamantens vänstra spets, inte exakt på den vinklade kanten. Edge-detektering använder diamantens bounding-box (rektangel), inte den faktiska rhomb-formen.
**Möjlig kod-pekare:** `Sources/App/Views/ShapeGeometry.swift` (om existerar) — `edgePoint(for:from:)` för diamant.

### F-06 [DEGRADERING] — Minus-badge och midpoint-handle överlappar
**Scenario:** `place_13-minus-badge-position.png`
**Faktiskt:** På korta pilar hamnar minus-badge (kant-startpunkt) och midpoint-handle på exakt samma position → de döljer varandra. Den lila pricken är synlig delvis bakom den blå pil-cirkeln.
**Möjlig kod-pekare:** `EdgeCollapseBadges.swift` + `EdgesView.swift` — ingen kollisions-detektion mellan badges.

---

## Kosmetiskt

### F-07 [KOSMETISKT] — Stub-streck saknas vid kollapsad-chain
**Scenario:** `place_12-collapsed-chain.png`
**Faktiskt:** A→B→C med B kollapsad. Plus-badge för stub syns vid B:s högerkant men det streckade stub-strecket mellan B och var C "skulle ha varit" är knappt synligt.
**Möjlig kod-pekare:** `EdgeCollapseBadges.swift` — stub-streck-längden för kort.

---

## OK — inga avvikelser

- `place_01-tight-horizontal` ✅
- `place_02-tight-vertical` ✅
- `place_03-diagonal` ✅
- `place_07-arrowhead-on-pill` ✅
- `place_08-arrow-each-shape-type` ✅ (mestadels — container-pil avviker men inte tydligt fel)
- `place_09-processarrow-as-source` ✅
- `place_10-container-as-target` ✅
- `place_11-collapsed-single` ✅
- `place_14-bidir-with-label` ✅
- `place_15-dashed-edge` ✅
- `place_16-backward-edge` ✅
- `place_18-nested-containers` ✅
- `place_19-child-outside-container` ✅
- `place_20-multi-select-3-shapes` ✅
- `place_21-multi-select-with-edges` ✅
- `place_22-edge-after-resize` ✅

---

## Sammanfattande iakttagelser

1. **Pil-rendering är generellt bra** för normala fall (horisontell, vertikal, diagonal, lång pil). Problem uppstår på *kantfall*: mycket korta avstånd (F-01), former-i-container (F-02), böjda pilar (F-03, F-04).

2. **Edge-detektering är bbox-baserad**, inte form-medveten — påverkar diamant (F-05). Mindre problem för andra former (cirkel, rektangel, pill) som naturligt är bbox-vänliga.

3. **Multi-select + drag fungerar bra** (scenario 20–21). v46-arbetet har stått sig.

4. **Container-renderingen själv är OK**, men interaktion mellan container-barn och pilar är trasig (F-02).

5. **Badge-placering har overlap-problem** vid korta pilar (F-06).
