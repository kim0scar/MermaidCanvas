# KONTROLL-FYND — maskinell genomgång av hela UI-ytan

**Datum:** 2026-06-22 · **Steg:** MB Steg 1 (breddat) · **Metod:** `Metoder/KONTROLL-GENOMGANG.md`

## Sammanfattning
- **138 funktioner** auditerade (16 ytor, 4 dim) av **51 sub-agenter**, varje fynd **adversariellt verifierat**.
- **Me-lagret (Mermaid) bevisat maskinellt:** 199 enhetstester gröna · conformance 3/3 · render 3/3 (headless Chrome) · arch-check grön.
- **23 bekräftade fynd** (🔴 1 hög · 🟠 8 medel · 🟡 14 låg). **12 falska larm** motbevisades.
- **UI-känsla på riktig enhet = Kims iPhone-bock** (inte maskin-dömbart — sim ljuger).

> **Status-koder:** ÖPPEN = ej åtgärdad · FIXAD = åtgärdad + grindar gröna · VÄGVAL = väntar Kims beslut (dödkod/beteende).

---

## Bekräftade fynd

### K1 · 🔴 HÖG · 4. Verktygsrad – Text-rad
**Funktion:** Text-rad (alla 9 funktioner) — **Dimension:** Ber

- **Problem:** Hela Text-raden mutar model.shapes[idx] DIREKT utan snapshotForUndo() — applyTextStyle (ToolbarView+TextStylesRow.swift:180-184), Fet (rad 37-41), Punkter (51-56), Numrerad (64-69), justering V/C/H (79-99) och Indrag-/+ (106-115). Jämför färg-raden som går via model.setFillColor/setStrokeColor (CanvasModel+Edges.swift:92-103) som anropar snapshotForUndo() FÖRE mutationen. Följd: alla text-stilsändringar är osynliga för Ångra/Gör om — Kim kan inte ångra en felaktig storlek/lista/justering, tvärtemot resten av appen. (Persistens funkar ändå: autosave läser model.shapes vid scenePhase .background, ContentView+Sheets.swift:235-236.)
- **Föreslagen fix:** Lägg model-metoder (t.ex. setTextStyle/toggleBullets/toggleNumbered/setTextAlignment/changeIndent på CanvasModel) som kallar snapshotForUndo() före mutationen, och låt knapparna anropa dem — exakt som färg-raden. Minsta fix: lägg model.snapshotForUndo() som första rad i varje action-closure i ToolbarView+TextStylesRow.swift.
- **Status:** ÖPPEN

### K2 · 🟠 MEDEL · 1. Verktygsrad – Huvudrad
**Funktion:** Former/Formpaket/Färg/Textstil-knapp (toggle) — **Dimension:** Plats

- **Problem:** I markerMode tvingas visad rad till .multiSelect: 'let activeRow = model.markerMode ? .multiSelect : secondaryRow' (ToolbarView.swift:72). Men toggleButton skriver/läser fortfarande secondaryRow direkt och markeras som aktiv via isActive: secondaryRow == row (ToolbarView.swift:146, 138-142). Resultat: i markerMode kan Former/Formpaket-knappen tryckas, highlightas som 'på', men raden den lovar öppna visas aldrig (multiSelect-raden ligger kvar). Knappen ljuger om sitt tillstånd.
- **Föreslagen fix:** I markerMode: antingen disabla Former/Formpaket-togglarna, eller låt isActive räkna på den effektiva activeRow (model.markerMode ? false : secondaryRow == row) så knappen inte highlightas när dess rad inte syns.
- **Status:** ÖPPEN

### K3 · 🟠 MEDEL · 10. Canvas – Pil-meny
**Funktion:** Dra midpunkt → waypoint — **Dimension:** Ber

- **Problem:** Waypoint-dragen i EdgeMidpointHandle.swift:195-205 (midpointGesture, edge.waypoints = [EdgeWaypoint(newPoint)]) muterar via @Binding UTAN att anropa snapshotForUndo(). Alla 7 syskon-mutatorer i CanvasModel+Edges.swift (setEdgeDirection rad 60, setEdgeColor 68, setEdgeFromSide 75, setEdgeLineShape 84, setEdgeLabel 107, setEdgeStyle 115, addEdge 49) tar snapshot först. Att böja en pil går alltså inte att ångra — inkonsekvent och oväntat för användaren.
- **Föreslagen fix:** Lägg en model-metod (t.ex. setEdgeWaypoint(id:point:)) som anropar snapshotForUndo() vid drag-START (onChanged första gången / .onEnded), och låt handtaget ropa den i stället för att skriva @Binding direkt — så böj kan ångras som allt annat.
- **Status:** ÖPPEN

### K4 · 🟠 MEDEL · 10. Canvas – Pil-meny
**Funktion:** Räta ut pil — **Dimension:** Ber

- **Problem:** "Räta ut pil"-knappen sätter edge.waypoints = [] direkt via @Binding (EdgeMidpointHandle.swift:156) utan snapshotForUndo(). Samma operation via setEdgeLineShape(.straight) tar däremot snapshot (CanvasModel+Edges.swift:84-88). Att räta ut en böjd pil går därför inte att ångra.
- **Föreslagen fix:** Låt knappen anropa en model-metod (t.ex. återanvänd setEdgeLineShape-mönstret eller en clearWaypoints(id:) med snapshotForUndo()) i stället för att nolla edge.waypoints direkt i vyn.
- **Status:** ÖPPEN

### K5 · 🟠 MEDEL · 12. Canvas – Läs-lapp (NoteCard)
**Funktion:** Reglage-knapp — **Dimension:** UI

- **Problem:** Reglage-knappen (NoteCard.swift:64-69, slider.horizontal.3 → onEdit/öppnar avancerad redigering) saknar både accessibilityLabel och accessibilityIdentifier, medan grann-knappen stäng-kryss har 'notecard.close' (rad 76) och namn/anteckning har egna id:n (rad 62,100). En SF-symbol-knapp utan label är osynlig/namnlös för VoiceOver, UI-test och AI-agenter som läser a11y-trädet (appen bryr sig uttryckligen om detta, ShapeView.swift:150-157).
- **Föreslagen fix:** Lägg .accessibilityIdentifier("notecard.edit") + .accessibilityLabel("Redigera (reglage)") på reglage-knappen i NoteCard.swift (efter rad 69).
- **Status:** ÖPPEN

### K6 · 🟠 MEDEL · 16. Sheets / dialoger
**Funktion:** Importera Mermaid (MermaidImportSheet) — **Dimension:** Me

- **Problem:** importMermaid() i MermaidImportSheet.swift:104-112 anropar model.replaceAll(...) UTAN legend:-argumentet. Parsern fyller parsed.legend (MermaidParser.swift:39-50, 322-324) men replaceAll defaultar legend=[:] (CanvasModel+Platform.swift:64) och sätter sedan self.legend = legend (rad 68) → all legend-text i importerad mermaid raderas tyst. De ordinarie fil-open-vägarna passerar legend korrekt (ContentView+Files.swift:22, :41), så det är en isolerad import-läcka. AI-mallen (frameworkText) dokumenterar %% legend, så en AI kan mycket väl producera det — bryter mot noll-avvikelse/regel 3b.
- **Föreslagen fix:** Lägg till legend: parsed.legend i replaceAll-anropet i MermaidImportSheet.swift:104-112 (samma rad som de andra fälten).
- **Status:** ÖPPEN

### K7 · 🟠 MEDEL · 3. Verktygsrad – Färg-rad
**Funktion:** Paket: Ingen färg / Persika–Lila / UI Blå–Mörk (applyColorPack) — **Dimension:** Ber

- **Problem:** applyColorPack (app/MermaidCanvas/Sources/App/Views/Toolbar/ToolbarView+ColorsRow.swift:137-141) muterar model.shapes[idx].colorPackId DIREKT utan att anropa snapshotForUndo(). Undo är helt manuell (CanvasModel+Undo.swift:34-39 — shapes har ingen didSet-auto-snapshot, CanvasModel.swift:21). Följd: (1) att byta färgpaket går inte att ångra; (2) den efterföljande redigering som snapshottar fryser post-pack-tillståndet som sitt 'före', så att ångra DEN heller inte återställer den gamla paketfärgen — paket-bytet blir osynligt för hela ångra-historiken. Avviker från syskon-vägen: fyllning/ram-pricken går via setFillColor/setStrokeColor (CanvasModel+Edges.swift:92-103) som snapshottar korrekt, och praktiskt taget varje annan mutation i modellen (CanvasModel+Shapes.swift) snapshottar.
- **Föreslagen fix:** Flytta paket-mutationen till en model-metod setColorPack(id:packId:) i CanvasModel+Edges.swift som anropar snapshotForUndo() före shapes[idx].colorPackId = ..., och låt applyColorPack anropa den (spegla exakt setFillColor/setStrokeColor). Minsta fix: lägg model.snapshotForUndo() överst i applyColorPack.
- **Status:** ÖPPEN

### K8 · 🟠 MEDEL · 6. Verktygsrad – Markera-flera-rad
**Funktion:** Hela Markera-flera-raden (Duplicera, Ta bort, Centrera H, Centrera V) — **Dimension:** UI

- **Problem:** Inga av de fyra knapparna har accessibilityIdentifier eller accessibilityLabel. ToolbarView+MultiSelectRow.swift (hela filen, multiSelectButton rad 40-57) saknar varje accessibility-modifier — till skillnad från alla andra verktygsrads-knappar (toggleButton ToolbarView.swift:151-152, zoomBadge:176-177, chips ToolbarView+Chips.swift:53-54, packs ToolbarView+PacksRow.swift:17-18 har alla både id + label). Konsekvens: knapparna är oåtkomliga för XCUITest-automation och osynliga/otydliga för VoiceOver (bara den lilla 9pt-texten finns).
- **Föreslagen fix:** Lägg .accessibilityIdentifier("multiselect.<duplicate|delete|alignH|alignV>") + .accessibilityLabel(label) på Button i multiSelectButton (ToolbarView+MultiSelectRow.swift:55-56), t.ex. ta in en accId-param likt övriga knappar.
- **Status:** ÖPPEN

### K9 · 🟠 MEDEL · 8. Canvas – Form-gester
**Funktion:** Dra container/telefon-ram + Låst form → dra — **Dimension:** Ber

- **Problem:** `moveContainerChildren` flyttar ALLA former inuti containern utan att hoppa över låsta — `CanvasModel+Containers.swift:82-87` saknar `&& !child.locked`-checken som finns i `moveSelection` (`CanvasModel+Selection.swift:34`). Konsekvens: en låst form bryter FUNKTIONSKarta-löftet 'Står still, kan inte flyttas' så fort dess container dras. Inkonsekvent med grupp-flytt som DÄREMOT respekterar låset.
- **Föreslagen fix:** Lägg `, !shapes[i].locked` (eller motsvarande filter på child) i loopen i `moveContainerChildren` (CanvasModel+Containers.swift:82-87) så låsta barn står still även vid container-drag — exakt som `moveSelection` redan gör på rad 34.
- **Status:** ÖPPEN

### K10 · 🟡 LÅG · 11. Canvas – Form-långtrycksmeny
**Funktion:** Skapa underflöde / Hoppa in → — **Dimension:** Me

- **Problem:** Carrier-texten för Visio-underflödet lovar en mermaid-markör som inte finns. AppCapabilities.swift:73 anger carrier '%% subprocess + subCanvas i state-JSON', men strängen 'subprocess' förekommer ENBART där — generatorn emitterar aldrig något '%% subprocess' (MermaidGenerator.swift / +StateJSON.swift emitterar bara subCanvas i state-JSON), parsern läser det aldrig, och 'subprocess' saknas i allCarrierKeys (AppCapabilities.swift:113-122). En extern AI som läser frameworkText() / facit-menyn skulle förvänta sig en '%% subprocess'-markör i ren mermaid som inte existerar. Bijektions-testet fångar inte detta eftersom features[].carrier är fritext, inte kontrollerad mot allCarrierKeys.
- **Föreslagen fix:** Ändra carrier-strängen i AppCapabilities.swift:73 till att spegla verkligheten, t.ex. 'subCanvas i state-JSON (bara i state-blocket)', så facit/AI-ramverket inte lovar en '%% subprocess'-markör som koden inte skriver. (Funktionen i sig fungerar och round-trippar — endast dokumentationssträngen överdriver.)
- **Status:** ÖPPEN

### K11 · 🟡 LÅG · 14. Canvas – Handtag + markeringsläge
**Funktion:** Storlek/Rotera-handtag (intern hjälpfunktion) — **Dimension:** Plats

- **Problem:** selectionCornerRadius(for:) i SelectionHandles.swift:140-148 är dödkod — definieras men anropas aldrig (grep ger noll call-sites). Markeringsramen ritas numera av SelectionOutline som beräknar geometrin själv (SelectionOutline.swift:46-52). Funktionen + dess kommentar :133-148 är kvarlämnad efter refaktorn.
- **Föreslagen fix:** Ta bort den oanvända private func selectionCornerRadius(for:) och dess MARK-kommentar i SelectionHandles.swift:133-148.
- **Status:** ÖPPEN

### K12 · 🟡 LÅG · 14. Canvas – Handtag + markeringsläge
**Funktion:** Skala hela markeringen (≥2) — **Dimension:** Plats

- **Problem:** MultiSelectResizeHandle.swift:53 har accessibilityIdentifier('multiselect.resize') men saknar accessibilityLabel — alla övriga handtag (SelectionHandles.swift:80,106,129; LineEndpointHandle.swift:42) har label. Glapp mot aktiv milstolpe-punkt 'Steg 5 – UX-114: a11y-labels på allt interaktivt'.
- **Föreslagen fix:** Lägg .accessibilityLabel("Skala markeringen") + .accessibilityAddTraits(.isButton) på MultiSelectResizeHandle.swift:53 för paritet med övriga handtag.
- **Status:** ÖPPEN

### K13 · 🟡 LÅG · 15. Canvas – Övrigt
**Funktion:** Expandera gren (grön plus-bricka) — **Dimension:** Plats

- **Problem:** EdgeStubBadge-docstringen är inaktuell: EdgeCollapseBadges.swift:5 säger 'Tryck → expandera (onTap → toggleCollapse på from-shape)', men den faktiska wiren är per-gren: EdgesView.swift:133 anropar onToggleCollapseEdge(edge.id) (per KANT, inte per from-shape). Samma per-gren-modell beskrivs korrekt på rad 31-34 för minus-badgen. Kommentaren beskriver det gamla v48-beteendet (per nod) som ersattes i v63. Ingen funktionsbugg — bara missvisande kommentar som kan vilseleda framtida ändring.
- **Föreslagen fix:** Uppdatera docstringen EdgeCollapseBadges.swift:5 till '(onTap → toggleCollapseEdge på denna gren)' så den matchar v63 per-gren-modellen och den korrekta texten på rad 31-34.
- **Status:** ÖPPEN

### K14 · 🟡 LÅG · 16. Sheets / dialoger
**Funktion:** Mermaid-kod / Hur funkar appen (sheets) — **Dimension:** Plats

- **Problem:** PreviewSheet.swift (struct PreviewSheet) är fullständigt dödkod — definierad men presenteras ingenstans i app eller tester (grep efter PreviewSheet utanför egen fil ger noll träffar). Den ligger i Views/ bredvid aktiva sheets och kan förvirra (anropar UIRenderer som om det vore en levande funktion).
- **Föreslagen fix:** Antingen wire:a in den (knapp/launch-arg som visar PreviewSheet) eller ta bort filen PreviewSheet.swift. Inte i ytans FUNKTIONSKarta-lista, men hör hemma här som dödkod — fråga Kim innan radering (regel 3).
- **Status:** ÖPPEN

### K15 · 🟡 LÅG · 2. Verktygsrad – Former-rad
**Funktion:** Emoji — **Dimension:** Plats

- **Problem:** Emoji-chipet (ToolbarView+ShapesRow.swift:67) anropar shapeChip(.emoji, accId: "chip.emoji"), vars accessibilityLabel sätts av a11yLabel(for: "chip.emoji"). Men switchen i a11yLabel (ToolbarView+Chips.swift:263-276) saknar case för "chip.emoji" — den faller till default (ToolbarView+Chips.swift:277-279) och returnerar den RÅA strängen "chip.emoji". VoiceOver läser alltså upp "chip.emoji" istället för "Emoji". Detta är exakt den UX-buggen (UX-001/010/013) som a11yLabel byggdes för att fixa — regredierad för den nya emoji-formen.
- **Föreslagen fix:** Lägg till en rad i switchen i ToolbarView+Chips.swift (~rad 274): case "chip.emoji": return "Emoji"
- **Status:** ÖPPEN

### K16 · 🟡 LÅG · 4. Verktygsrad – Text-rad
**Funktion:** textStyleChip (hjälpvy) — **Dimension:** Plats

- **Problem:** func textStyleChip(_:) (ToolbarView+TextStylesRow.swift:128-147) refereras ingenstans (grep: enda förekomsten är definitionen). Död kod — kvarleva från den gamla per-chip-stilväljaren innan v40:s enda storlek-knapp + confirmationDialog (rad 12-29) ersatte den.
- **Föreslagen fix:** Ta bort func textStyleChip (rad 127-147) och den nu enda kvarvarande anroparen av textStyleChip (ingen) — pre-existing dödkod, ta bort först efter Kims ok enligt regel 3.
- **Status:** ÖPPEN

### K17 · 🟡 LÅG · 4. Verktygsrad – Text-rad
**Funktion:** Text-rads knappar (Fet/Punkter/Numrerad/justering/indrag) — **Dimension:** UI

- **Problem:** Inga accessibilityIdentifier/Label på de interaktiva knapparna (ToolbarView+TextStylesRow.swift saknar all accessibility — textActionButton 150-169 har bara en SF Symbol-Image utan textetikett). Färg-raden sätter däremot a11y-id (ToolbarView+ColorsRow.swift:31,67). Gör knapparna svåra att nå deterministiskt i XCUITest och svaga för VoiceOver.
- **Föreslagen fix:** Lägg .accessibilityLabel(label) (parametern label finns redan, rad 151) på Button i textActionButton, samt en .accessibilityIdentifier på storlek-knappen (rad 12).
- **Status:** ÖPPEN

### K18 · 🟡 LÅG · 5. Verktygsrad – Formpaket-rad
**Funktion:** packChip (oanvänd funktion) — **Dimension:** Plats

- **Problem:** packChip är definierad i ToolbarView+PacksRow.swift:10-19 men anropas ALDRIG i produktionskod. Den live packs-raden (packsSecondary, PacksRow.swift:24-40) bygger bara packToggle + skillFlowChips + uiPackChips — aldrig packChip. Enda referensen är UI-testet V29CoverageTests.swift:158-159 som letar efter knappen chip.pack.promptProcess. Den knappen kan inte längre renderas: Steg 8 tog bort .promptProcess ur ShapePack.userToggleable (ShapePack.swift:28 = [.ui, .skillFlow]). Resultat: död produktionsfunktion + ett UI-test som testar en borttagen funktion (toggle.pack.promptProcess + chip.pack.promptProcess existerar inte i nuvarande build → testet failar/är inaktuellt).
- **Föreslagen fix:** Ta bort packChip (PacksRow.swift:10-19) samt motsvarande gren chip.pack.<rawValue> i a11yLabel (Chips.swift:278). Ta bort eller skriv om V29CoverageTests-fallet (rad ~145-162) som testar borttagna promptProcess-togglar/-chips. Surgical: rör inte packToggle/skillFlowChips/uiPackChips.
- **Status:** ÖPPEN

### K19 · 🟡 LÅG · 6. Verktygsrad – Markera-flera-rad
**Funktion:** Centrera H / Centrera V — **Dimension:** Me

- **Problem:** alignSelectionHorizontally() och alignSelectionVertically() (CanvasModel+Selection.swift:101,112) saknar enhetstest, trots att grannfunktionerna duplicateSelection/deleteSelection/moveSelection alla har dedikerade test i CanvasModelMutationTests.swift (rad 62-228). Align ändrar positioner som round-trippar, men själva snäpp-logiken (median-Y/median-X via sorted()[count/2]) verifieras ingenstans — en regress i median-valet skulle gå tyst igenom.
- **Föreslagen fix:** Lägg två test i CanvasModelMutationTests.swift: skapa 3 former med kända positioner, kör alignSelectionHorizontally / -Vertically, assert:a att alla får median-Y resp. median-X (och no-op vid count<2).
- **Status:** ÖPPEN

### K20 · 🟡 LÅG · 7. Verktygsrad – Lägen-meny
**Funktion:** Markera flera — **Dimension:** Plats

- **Problem:** LägenMenu.swift:23 påstår att onToggleMarker '...används ej i menyn längre' (v39-kommentar), men callbacken anropas aktivt på LägenMenu.swift:107-110 (knappen 'Markera flera') och är wire:ad ContentView.swift:94→model.toggleMarkerMode(). Kommentaren är stale och vilseledande — en framtida läsare kan tro parametern är död och ta bort den, vilket bryter knappen.
- **Föreslagen fix:** Uppdatera doc-kommentaren på LägenMenu.swift:23 till att spegla att onToggleMarker används av 'Markera flera'-posten (V79-svep flyttade hit den, jfr rad 106).
- **Status:** ÖPPEN

### K21 · 🟡 LÅG · 7. Verktygsrad – Lägen-meny
**Funktion:** Importera flera filer (jämför)… — **Dimension:** UI

- **Problem:** Ikon-dubblett: 'Importera flera filer (jämför)…' (LägenMenu.swift:76) och 'Mallar'-undermenyn (LägenMenu.swift:48) använder båda systemImage 'square.grid.2x2'. Två orelaterade menyposter med samma symbol gör menyn svårare att skanna visuellt — extra känsligt för Kims visuella/2e-profil.
- **Föreslagen fix:** Byt ikon på 'Importera flera filer' till något import/jämför-tydligt (t.ex. 'square.on.square.dashed' eller 'doc.on.doc') så den inte krockar med Mallar-ikonen.
- **Status:** ÖPPEN

### K22 · 🟡 LÅG · 8. Canvas – Form-gester
**Funktion:** Dubbeltryck (öppna lapp) i markeringsläge — **Dimension:** Plats

- **Problem:** `onTapGesture(count:2)` (ShapeView.swift:168-175) har ingen `markerMode`-guard, till skillnad från `onTapGesture(count:1)` (rad 177-180 returnerar tidigt i markerMode). I markeringsläge öppnar dubbeltryck alltså lappen (onSelect+onQuickRead) i stället för att bara hantera markering — inkonsekvent gest-beteende mellan enkel- och dubbeltryck i samma läge.
- **Föreslagen fix:** Spegla enkeltryckets markerMode-gren i count:2-gesten: i markerMode låt dubbeltryck bara köra onSelect() (eller no-op) i stället för att öppna lappen, om avsikten är att markeringsläget ska vara ren multiselect.
- **Status:** ÖPPEN

### K23 · 🟡 LÅG · 9. Canvas – Anslutningsprickar (rita pil)
**Funktion:** Gummiband-förhandsvisning — **Dimension:** UI

- **Problem:** Gummibandets startpunkt är formens centrum, inte sidan/pricken man drog ifrån. CanvasView.swift:138 anropar ConnectionRubberBand(from: fromShape.position, ...) — fromShape.position är formens mittpunkt. Eftersom hela poängen med V79-svepet ('Fyra prickarna') är att pilen GÅR UT från just den sidan man drog ifrån, är det missvisande att förhandsvisningen börjar i mitten. Den färdiga pilen ritas från sidan (EdgeGeometry.sidePoint via fromSide) men förhandsvisningen gör det inte → siktningen matchar inte resultatet.
- **Föreslagen fix:** Låt onDragChanged bära med startsidan (eller dess sidePoint) i ConnectionDrag och rita gummibandet från EdgeGeometry.sidePoint(for: fromShape, side:) i stället för fromShape.position, så förhandsvisning och färdig pil börjar på samma punkt.
- **Status:** ÖPPEN

---

## Motbevisade (falska larm — 12 st)
Dessa restes av audit-agenter men motbevisades av den adversariella kontrollen (kod läst, problemet fanns inte / var avsiktligt / försumbart):

- **1. Verktygsrad – Huvudrad :: Färg-knapp / Textstil-knapp** (Ber, low) — Falskt larm — avsiktlig design, inte en bugg. Kodfakta stämmer (ToolbarView.swift:115-116 `disabled: model.selectedShapeId == nil`; CanvasModel+Selection.swift:48-49 nollställer selectedShapeId i markerMode), MEN slutsatsen "grå knapp utan 
- **2. Verktygsrad – Former-rad :: Emoji** (UI, low) — Den faktiska koden bekräftar divergensen, men den är försumbar — inte värd fixen som påstådd. BEVIS: tap = ToolbarView+ShapesRow.swift:67-68 (shapeChip(.emoji)→addShape(.emoji, at:, label:"😀")); drag = ToolbarView+Chips.swift:174-195 (gene
- **9. Canvas – Anslutningsprickar (rita pil) :: Skapa pil från en sida** (UI, low) — Försumbart + premissen är delvis fel. Koden stämmer ytligt: ConnectionOverlay.swift:42-47 lägger handtagen på offset ±w/2±gap (gap = size/2 + 8/scale) utan klamp, och shape-positionen klampas inte heller vid drag (ShapeView.swift:283-284). 
- **10. Canvas – Pil-meny :: Dra midpunkt → waypoint** (UI, low) — Kod-faktum stämmer men praktisk skada är försumbar. EdgeMidpointHandle.swift:197-203 skriver `newPoint = v.location` oklampat, och handtaget positioneras på waypointen (rad 74→48), så det följer med ut. Canvasen är fast 4000×4000 UIScrollVi
- **10. Canvas – Pil-meny :: Dra midpunkt → waypoint** (Plats, low) — Den faktiska KOD-detaljen stämmer: handtags-ZStacken i EdgeMidpointHandle.swift:62-75 saknar accessibilityIdentifier/Label. MEN det bärande påståendet — "utan identifier går pilmenyn/handtaget inte att nå i UI-test" — är fel, och därmed är 
- **11. Canvas – Form-långtrycksmeny :: Lager → Underst / Mellan / Överst** (UI, low) — Inte värt att fixa — påståendet motbevisas på båda punkter. (1) Beteendet: skillnaden finns visserligen (ShapeView.swift:227 saknar `showContextMenu = false` som rad 210-225 alla har), men det är AVSIKTLIGT, vilket granskaren själv medger. 
- **12. Canvas – Läs-lapp (NoteCard) :: Prompt (visning)** (UI, low) — Den påstådda ORSAKEN är fel, och det kvarvarande verkliga fallet är försumbart. Kodavvikelsen finns: NoteCard.swift:84 gatar bara på `!p.isEmpty` medan badge (ShapeView.swift:115) och edit-sheet (ContentView+Sheets.swift:66 `showsPrompt: sh
- **13. Canvas – Brödsmulor (Visio-drill) :: 🏠 Huvudflöde / exitToRoot** (Plats, low) — FAKTA STÄMMER men problemet är försumbart. Verifierat: exitToRoot() (CanvasModel+Drill.swift:54) har noll anropare — grep i hela repot (inkl UnitTests + UI-tester) ger bara definitionsraden. Hem-knappen i brödsmulan (DrillBreadcrumbBar.swif
- **13. Canvas – Brödsmulor (Visio-drill) :: 🏠 Huvudflöde + Mellanliggande smula** (UI, low) — Faktiskt korrekt om koden men EJ värt att fixa. DrillBreadcrumbBar.swift:18 har "drill.exit" på Ut-knappen; crumb-Button:arna (rad 27-34) saknar accessibilityIdentifier. MEN premissen "kan inte adresseras stabilt av tester" är falsk: (1) En
- **14. Canvas – Handtag + markeringsläge :: Skala hela markeringen (≥2)** (UI, med) — Kodfaktan stämmer ytligt men slutsatsen håller inte. MultiSelectResizeHandle.swift:14-15 sätter pos = bbox.maxX/maxY + offset utan viewport-klamp — bekräftat. contentSize är 4000×4000 (CanvasModel.swift:48-49, korrekt path App/Models/), och
- **14. Canvas – Handtag + markeringsläge :: Skala hela markeringen (≥2)** (Ber, low) — Fakta stämmer men det är ingen bugg värd att fixa (claimanten medger själv "Inte en bugg"). Bevis: MultiSelectResizeHandle har EN enda call-site, CanvasView+Selection.swift:96, gated av `multiSelection.count >= 2` (rad 95). Den interna guar
- **16. Sheets / dialoger :: Komponentgalleri (ComponentGallery)** (Plats, low) — Factual claims verified but problem is försumbart/gold-plating. CONFIRMED: gallery is launch-arg only — showComponentGallery is set true ONLY at ContentView.swift:165 (no UI button anywhere; grep found no other setter), so Kim cannot reach 

---

*Genererad ur audit-svepet (ui-kontroll-genomgang). Maskin-bevisen är hårda; UI-känslan är Kims.*
