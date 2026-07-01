---
title: Visuali2e v49 — Alla funktioner (104)
spec_type: general
platform: blank
shape_packs: basic
last_updated: 2026-05-22
---
# Visuali2e v49 — Alla funktioner (104)

Genererad 2026-05-22T21:13:42Z.

```mermaid
%%{init: {"flowchart": {"curve": "basis"}}}%%
flowchart TD
    ui_N0(["Visuali2e v49 — Alla funktioner (104)"]):::ui
    %% ui_N0 note: Genererad från Visuali2e-v47-Funktionsprotokoll.xlsx, uppdaterad efter v49.
    %% ui_N0 size: 2.0
    %% ui_N0 pos: 200,100
    ui_N1("Toolbar – Primärrad"):::ui
    %% ui_N1 size: 1.4
    %% ui_N1 pos: 300,300
    ui_N2("1. Formväljare (chips) ✓"):::ui
    %% ui_N2 note: Öppnar två rader med alla 12 former (cirkel, rektangel, kvadrat, romb, piller, process-pil, container, tabell, jump-link, linje, antecknings-popup). ⏎  ⏎ Åtkomst: Tap på square.on.circle-ikonen i toolbar. ⏎  ⏎ Förväntat: Sekundär rad expanderar med shape-chips. Tap igen stänger raden. ⏎  ⏎ Status sim: ✓ ⏎ Status iPhone:  ⏎ Anteckning: DragOutTests + LayoutOverflowTests
    %% ui_N2 pos: 700,300
    ui_N3("2. Färgpaket-rad"):::ui
    %% ui_N3 note: Öppnar rad med 7 färgpaket (UI, Roadmap, Arkitektur, Flow + ingen-färg) för aktuell vald form. ⏎  ⏎ Åtkomst: Tap på paintpalette-ikonen (disabled om ingen form vald). ⏎  ⏎ Förväntat: Sekundär rad visar färgcirklar; tap applicerar paket på vald form. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test för färgapplicering
    %% ui_N3 pos: 940,300
    ui_N4("3. Textstil-rad"):::ui
    %% ui_N4 note: Öppnar rad med textstorlek-val, fet, punktlista, numrerad lista, justering L/C/R, indrag in/ut. ⏎  ⏎ Åtkomst: Tap på textformat.size-ikonen (disabled om ingen form vald). ⏎  ⏎ Förväntat: Sekundär rad expanderar med text-operationsknappar. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test för textstilar
    %% ui_N4 pos: 1180,300
    ui_N5("4. Markeringsläge (multi-select)"):::ui
    %% ui_N5 note: Aktivera marquee-läge för att rita streckad rektangel och välja flera former i ett svep. ⏎  ⏎ Åtkomst: Tap på rectangle.dashed-ikonen. ⏎  ⏎ Förväntat: MarkerOverlay aktiveras; markeringsspecifik toolbar-rad visas; drag på canvas ritar streckad rektangel. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen XCUITest för marker-mode
    %% ui_N5 pos: 1420,300
    ui_N6("5. Zoom-badge ✓"):::ui
    %% ui_N6 note: Visar aktuell zoom-procent och fungerar som debug-räknare (shapeCount=N). Tap återställer zoom till 100%. ⏎  ⏎ Åtkomst: Tap på toolbar.zoom (procent-badgen). ⏎  ⏎ Förväntat: Zoom återställs till 1.0; canvas centreras på nuvarande viewport. ⏎  ⏎ Status sim: ✓ ⏎ Status iPhone:  ⏎ Anteckning: V35BugHuntTests testZoomChangesScrollViewState
    %% ui_N6 pos: 1660,300
    ui_N7("6. Ångra (undo)"):::ui
    %% ui_N7 note: Ångrar senaste åtgärd (skapa, flytta, ta bort, ändra text, etc). ⏎  ⏎ Åtkomst: Tap på arrow.uturn.backward-ikonen. ⏎  ⏎ Förväntat: Föregående snapshot återställs. Disabled när inget finns att ångra. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Disabled vid start → ingen automated test
    %% ui_N7 pos: 1900,300
    ui_N8("7. Lägen-meny (hamburger) ✓"):::ui
    %% ui_N8 note: Öppnar dropdown-meny med fil-operationer (Ny, Spara, Öppna), plattform, Mermaid-kod. ⏎  ⏎ Åtkomst: Tap på slider.horizontal.3-ikonen längst till höger. ⏎  ⏎ Förväntat: Dropdown-meny visas med menyval. ⏎  ⏎ Status sim: ✓ ⏎ Status iPhone:  ⏎ Anteckning: V33VersionVisibleTests + V29CoverageTests
    %% ui_N8 pos: 2140,300
    ui_N9("Hamburger-meny"):::ui
    %% ui_N9 size: 1.4
    %% ui_N9 pos: 300,480
    ui_N10("8. Ny canvas (välj plattform)"):::ui
    %% ui_N10 note: Startar en helt ny rityta. Användaren får välja plattform (Blank eller Godot). ⏎  ⏎ Åtkomst: Tap hamburger → 'Ny canvas (välj plattform)' (allra översta valet). ⏎  ⏎ Förväntat: NewCanvasSheet öppnas; vald plattform skapar tom canvas. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen automated test
    %% ui_N10 pos: 700,480
    ui_N11("9. Aktuell plattform (indikator)"):::ui
    %% ui_N11 note: Visar vilken plattform aktuell canvas använder. Informativ rad – ej klickbar. ⏎  ⏎ Åtkomst: Visas direkt under 'Ny canvas' som disabled grå text. ⏎  ⏎ Förväntat: Text: 'Aktuell plattform: Blank canvas' eller 'Aktuell plattform: Godot'. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen automated test
    %% ui_N11 pos: 940,480
    ui_N12("10. Visa regler för Godot"):::ui
    %% ui_N12 note: Öppnar regelbok med plattform-specifika regler (visas bara om Godot-plattform är vald). ⏎  ⏎ Åtkomst: Tap hamburger → 'Visa regler för Godot' (visas endast i Godot-läge). ⏎  ⏎ Förväntat: PlatformRulesSheet öppnas med markdown-formaterad regeltext. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Plattform-specifik, ej testad
    %% ui_N12 pos: 1180,480
    ui_N13("11. Spara"):::ui
    %% ui_N13 note: Sparar canvas till senast öppnad fil (JSON inbäddat i Mermaid-MD). ⏎  ⏎ Åtkomst: Tap hamburger → 'Spara'. Heter 'Spara…' om ingen fil är öppen. ⏎  ⏎ Förväntat: Fil skrivs till disk; status-text bekräftar. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: FileSystem ej testat i UI
    %% ui_N13 pos: 1420,480
    ui_N14("12. Spara som ny fil"):::ui
    %% ui_N14 note: Sparar canvas till en ny fil (filväljare). ⏎  ⏎ Åtkomst: Tap hamburger → 'Spara som ny fil…'. ⏎  ⏎ Förväntat: Filväljare öppnas för att välja sparplats; ny fil skapas. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: FileSystem ej testat
    %% ui_N14 pos: 1660,480
    ui_N15("13. Öppna fil"):::ui
    %% ui_N15 note: Öppnar tidigare sparad Mermaid-MD-fil och läser in canvas-state. ⏎  ⏎ Åtkomst: Tap hamburger → 'Öppna fil…'. ⏎  ⏎ Förväntat: Filväljare öppnas; vald fil parsas och canvas ersätts. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: FileSystem ej testat
    %% ui_N15 pos: 1900,480
    ui_N16("14. Importera Mermaid"):::ui
    %% ui_N16 note: Två-stegs guide för att importera AI-genererad Mermaid-kod från Claude.ai eller annan AI. ⏎  ⏎ Åtkomst: Tap hamburger → 'Importera Mermaid…'. ⏎  ⏎ Förväntat: MermaidImportSheet öppnas (steg 1: kopiera mall, steg 2: klistra in). ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: MermaidImportSheet ej UI-testad
    %% ui_N16 pos: 2140,480
    ui_N17("15. Visa Mermaid-kod ✓"):::ui
    %% ui_N17 note: Visar den live-genererade Mermaid-koden för canvas. Kan kopieras och klistras in i Claude eller mermaid.live. ⏎  ⏎ Åtkomst: Tap hamburger → 'Visa Mermaid-kod'. ⏎  ⏎ Förväntat: MermaidCodeSheet öppnas med kod-text och 'Kopiera'-knapp. ⏎  ⏎ Status sim: ✓ ⏎ Status iPhone:  ⏎ Anteckning: V29CoverageTests testT22_ShowMermaidCodeMenuItemExists
    %% ui_N17 pos: 2380,480
    ui_N18("16. Visa AppVersion ✓"):::ui
    %% ui_N18 note: Visar appens versionsnummer som info-rad i menyn. ⏎  ⏎ Åtkomst: Disabled rad längst ner i hamburger-menyn. ⏎  ⏎ Förväntat: Visar 'v46' (eller aktuell version). ⏎  ⏎ Status sim: ✓ ⏎ Status iPhone:  ⏎ Anteckning: V33VersionVisibleTests testVersionIsVisibleInLägenMenu
    %% ui_N18 pos: 2620,480
    ui_N19("Form-chips"):::ui
    %% ui_N19 size: 1.4
    %% ui_N19 pos: 300,660
    ui_N20("17. Cirkel ✓"):::ui
    %% ui_N20 note: Lägg till en cirkelform på canvas. ⏎  ⏎ Åtkomst: Tap toolbar.shapes → tap chip.circle (eller långpress + drag till canvas-position). ⏎  ⏎ Förväntat: Cirkelform skapas vid canvas-mitten eller släpp-punkten. ⏎  ⏎ Status sim: ✓ ⏎ Status iPhone:  ⏎ Anteckning: DragOutTests testTapAddsCircle + testDragCircleChipToCanvas
    %% ui_N20 pos: 700,660
    ui_N21("18. Rektangel ✓"):::ui
    %% ui_N21 note: Lägg till en rektangelform på canvas. ⏎  ⏎ Åtkomst: Tap toolbar.shapes → tap chip.rectangle (eller drag). ⏎  ⏎ Förväntat: Rektangelform skapas. ⏎  ⏎ Status sim: ✓ ⏎ Status iPhone:  ⏎ Anteckning: DragOutTests testDragRectangleChipToCanvas
    %% ui_N21 pos: 940,660
    ui_N22("19. Kvadrat"):::ui
    %% ui_N22 note: Lägg till en kvadratisk form (80×80) på canvas. ⏎  ⏎ Åtkomst: Tap toolbar.shapes → tap chip.square (eller drag). ⏎  ⏎ Förväntat: Kvadrat skapas. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Inget eget test, ingår i totalShapeCount
    %% ui_N22 pos: 1180,660
    ui_N23("20. Romb (diamant) ✓"):::ui
    %% ui_N23 note: Lägg till en romb/diamantform på canvas. ⏎  ⏎ Åtkomst: Tap toolbar.shapes → tap chip.diamond (eller drag). ⏎  ⏎ Förväntat: Rombform med rundade hörn skapas. ⏎  ⏎ Status sim: ✓ ⏎ Status iPhone:  ⏎ Anteckning: DragOutTests testAllSixChipsProduceShapes
    %% ui_N23 pos: 1420,660
    ui_N24("21. Piller (oval)"):::ui
    %% ui_N24 note: Lägg till en avlång ovalform på canvas. ⏎  ⏎ Åtkomst: Tap toolbar.shapes → tap chip.pill (eller drag). ⏎  ⏎ Förväntat: Pillerformad oval skapas. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Inget eget test, ingår i totalShapeCount
    %% ui_N24 pos: 1706,607
    ui_N25("22. Processpil"):::ui
    %% ui_N25 note: Lägg till en pentagon-formad processpil på canvas. ⏎  ⏎ Åtkomst: Tap toolbar.shapes → tap chip.processArrow (eller drag). ⏎  ⏎ Förväntat: Pentagon med spets åt höger skapas. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Inget eget test, ingår i totalShapeCount
    %% ui_N25 pos: 1900,660
    ui_N26("23. Container (subgraph)"):::ui
    %% ui_N26 note: Lägg till en streckad behållare för att gruppera andra former. ⏎  ⏎ Åtkomst: Tap toolbar.shapes → tap chip.container (eller drag). ⏎  ⏎ Förväntat: Större streckad rektangel skapas; andra former kan dras in i den. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test för container-chip
    %% ui_N26 pos: 2140,660
    ui_N27("24. Tabell ✓"):::ui
    %% ui_N27 note: Lägg till en 3×3-tabellform som kan redigeras cell för cell. ⏎  ⏎ Åtkomst: Tap toolbar.shapes → tap chip.table. ⏎  ⏎ Förväntat: Tabellform skapas; dubbelklick öppnar TableEditorSheet. ⏎  ⏎ Status sim: ✓ ⏎ Status iPhone:  ⏎ Anteckning: V27FeatureTests testTapTableChipAddsTable + testDragTableChipToCanvas
    %% ui_N27 pos: 2380,660
    ui_N28("25. Jump-link (länkat par) ✓"):::ui
    %% ui_N28 note: Lägg till två länkade former (för att hoppa mellan ställen på canvas). ⏎  ⏎ Åtkomst: Tap toolbar.shapes → tap chip.link. ⏎  ⏎ Förväntat: Två länk-former med samma nummer skapas nära canvas-mitten. ⏎  ⏎ Status sim: ✓ ⏎ Status iPhone:  ⏎ Anteckning: V27FeatureTests testTapLinkChipAddsJumpLinkPair
    %% ui_N28 pos: 2620,660
    ui_N29("26. Linje (FreeLine)"):::ui
    %% ui_N29 note: Lägg till en lös linje (ingen pil) som kan dras i båda ändar. ⏎  ⏎ Åtkomst: Tap toolbar.shapes → tap chip.line. ⏎  ⏎ Förväntat: Horisontell linje skapas; båda ändpunkter draggable. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test för line-chip
    %% ui_N29 pos: 2860,660
    ui_N30("27. Antecknings-popup"):::ui
    %% ui_N30 note: Öppnar list-vy med alla textfält (labels + notes) på canvas. ⏎  ⏎ Åtkomst: Tap toolbar.shapes → tap chip.notepopup (pratbubbla-ikon). ⏎  ⏎ Förväntat: NotePopupSheet öppnas med scrollable lista. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test
    %% ui_N30 pos: 3100,660
    ui_N31("Form-paket"):::ui
    %% ui_N31 size: 1.4
    %% ui_N31 pos: 300,840
    ui_N32("28. UI-paket"):::ui
    %% ui_N32 note: Aktivera/avaktivera UI-form-chips i toolbaren (designsystem-ikoner). ⏎  ⏎ Åtkomst: Tap toolbar.packs → toggle 'UI'. ⏎  ⏎ Förväntat: UI-pack-chips visas/döljs i shapes-raden. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Bara packs-toggle existens testad
    %% ui_N32 pos: 700,840
    ui_N33("29. Roadmap-paket"):::ui
    %% ui_N33 note: Aktivera/avaktivera Roadmap-form-chips (milstolpar, deadlines, etc). ⏎  ⏎ Åtkomst: Tap toolbar.packs → toggle 'Roadmap'. ⏎  ⏎ Förväntat: Roadmap-pack-chips visas/döljs. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen test
    %% ui_N33 pos: 940,840
    ui_N34("30. Arkitektur-paket ✓"):::ui
    %% ui_N34 note: Aktivera/avaktivera Arkitektur-form-chips (komponenter, databas, etc). ⏎  ⏎ Åtkomst: Tap toolbar.packs → toggle 'Arkitektur'. ⏎  ⏎ Förväntat: Arkitektur-pack-chips visas/döljs. ⏎  ⏎ Status sim: ✓ ⏎ Status iPhone:  ⏎ Anteckning: V29CoverageTests testT21_ArchitecturePackTogglesAddsChipInShapesRow
    %% ui_N34 pos: 1180,840
    ui_N35("31. Flow-paket"):::ui
    %% ui_N35 note: Aktivera/avaktivera Flow-form-chips (extra flödesschema-symboler). ⏎  ⏎ Åtkomst: Tap toolbar.packs → toggle 'Flow'. ⏎  ⏎ Förväntat: Flow-pack-chips visas/döljs. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen test
    %% ui_N35 pos: 1420,840
    ui_N36("Färg-rad"):::ui
    %% ui_N36 size: 1.4
    %% ui_N36 pos: 300,1020
    ui_N37("32. Applicera färgpaket"):::ui
    %% ui_N37 note: Sätt en färgkombination (fill+stroke+text) på vald form. ⏎  ⏎ Åtkomst: Välj form först → tap toolbar.colors → tap färg-cirkel. ⏎  ⏎ Förväntat: Vald forms colorPackId uppdateras; visuellt utseende ändras. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Round-trip täcker JSON, ej UI-flödet
    %% ui_N37 pos: 700,1020
    ui_N38("33. Återställ till kategori-färg"):::ui
    %% ui_N38 note: Ta bort form-specifik färg-override; använd kategori-standardfärg. ⏎  ⏎ Åtkomst: Tap 'ingen färg'-cirkel (markerad med snedstreck). ⏎  ⏎ Förväntat: colorPackId blir nil; formen använder kategori-färg. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test
    %% ui_N38 pos: 940,1020
    ui_N39("Textstil-rad"):::ui
    %% ui_N39 size: 1.4
    %% ui_N39 pos: 300,1200
    ui_N40("34. Textstorlek-popup"):::ui
    %% ui_N40 note: Välj mellan Rubrik 1, Rubrik 2, Rubrik 3 eller Brödtext. ⏎  ⏎ Åtkomst: Tap toolbar.textstyles → tap textformat.size → välj i confirmationDialog. ⏎  ⏎ Förväntat: Vald forms textStyle ändras; text storlek/vikt uppdateras. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test
    %% ui_N40 pos: 700,1200
    ui_N41("35. Fet text-toggle"):::ui
    %% ui_N41 note: Togglar mellan Rubrik 1 (fet) och Brödtext (normal vikt). ⏎  ⏎ Åtkomst: Tap toolbar.textstyles → tap 'bold'-knappen. ⏎  ⏎ Förväntat: Text byter mellan headline (.r1) och body. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test
    %% ui_N41 pos: 940,1200
    ui_N42("36. Punktlista ✓"):::ui
    %% ui_N42 note: Lägger till • framför varje rad i texten. Stänger av numrerad lista. ⏎  ⏎ Åtkomst: Tap toolbar.textstyles → tap 'list.bullet'. ⏎  ⏎ Förväntat: Shape.hasBullets togglas; hasNumberedList=false; text re-renderas. ⏎  ⏎ Status sim: ✓ (data) ⏎ Status iPhone:  ⏎ Anteckning: Round-trip via V35MermaidValidationTests testRoundTrip_v46Fields_Preserved
    %% ui_N42 pos: 1180,1200
    ui_N43("37. Numrerad lista ✓"):::ui
    %% ui_N43 note: Lägger till 1./2./3. framför varje rad. Stänger av punktlista. ⏎  ⏎ Åtkomst: Tap toolbar.textstyles → tap 'list.number'. ⏎  ⏎ Förväntat: Shape.hasNumberedList togglas; hasBullets=false. ⏎  ⏎ Status sim: ✓ (data) ⏎ Status iPhone:  ⏎ Anteckning: Round-trip via testRoundTrip_v46Fields_Preserved
    %% ui_N43 pos: 1420,1200
    ui_N44("38. Justering – vänster"):::ui
    %% ui_N44 note: Vänsterjustera texten i formen. ⏎  ⏎ Åtkomst: Tap toolbar.textstyles → tap 'text.alignleft'. ⏎  ⏎ Förväntat: Shape.textAlignment = .leading; text re-renderas. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: UI-knapparna i textStylesSecondary ej UI-testade
    %% ui_N44 pos: 1660,1200
    ui_N45("39. Justering – centrera"):::ui
    %% ui_N45 note: Centrera texten i formen. ⏎  ⏎ Åtkomst: Tap toolbar.textstyles → tap 'text.aligncenter'. ⏎  ⏎ Förväntat: Shape.textAlignment = .center. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test
    %% ui_N45 pos: 1900,1200
    ui_N46("40. Justering – höger"):::ui
    %% ui_N46 note: Högerjustera texten i formen. ⏎  ⏎ Åtkomst: Tap toolbar.textstyles → tap 'text.alignright'. ⏎  ⏎ Förväntat: Shape.textAlignment = .trailing. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test
    %% ui_N46 pos: 2140,1200
    ui_N47("41. Indrag minska ✓"):::ui
    %% ui_N47 note: Minskar indragsnivån (0–3 steg). ⏎  ⏎ Åtkomst: Tap toolbar.textstyles → tap 'decrease.indent'. ⏎  ⏎ Förväntat: Shape.indentLevel -= 1 (min 0); text indenteras mindre. ⏎  ⏎ Status sim: ✓ (data) ⏎ Status iPhone:  ⏎ Anteckning: Round-trip via testRoundTrip_v46Fields_Preserved
    %% ui_N47 pos: 2380,1200
    ui_N48("42. Indrag öka ✓"):::ui
    %% ui_N48 note: Ökar indragsnivån (0–3 steg). ⏎  ⏎ Åtkomst: Tap toolbar.textstyles → tap 'increase.indent'. ⏎  ⏎ Förväntat: Shape.indentLevel += 1 (max 3); text indenteras mer. ⏎  ⏎ Status sim: ✓ (data) ⏎ Status iPhone:  ⏎ Anteckning: Round-trip via testRoundTrip_v46Fields_Preserved
    %% ui_N48 pos: 2620,1200
    ui_N49("Multi-select rad"):::ui
    %% ui_N49 size: 1.4
    %% ui_N49 pos: 300,1380
    ui_N50("43. Räknare (N markerade)"):::ui
    %% ui_N50 note: Visar antal valda former i marker-läge. Informativ rad. ⏎  ⏎ Åtkomst: Aktivera marker-läge + välj former → räknare uppdateras. ⏎  ⏎ Förväntat: '1 markerad' / '5 markerade' visas. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen test
    %% ui_N50 pos: 700,1380
    ui_N51("44. Duplicera markerade"):::ui
    %% ui_N51 note: Skapar kopior av alla markerade former. ⏎  ⏎ Åtkomst: Marker-läge + minst 1 form vald → tap 'plus.square.on.square'. ⏎  ⏎ Förväntat: Alla valda former dupliceras med offset; multiSelection uppdateras till nya. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen test
    %% ui_N51 pos: 940,1380
    ui_N52("45. Ta bort markerade"):::ui
    %% ui_N52 note: Raderar alla markerade former och deras anslutna pilar. ⏎  ⏎ Åtkomst: Marker-läge + minst 1 form vald → tap 'trash' (röd). ⏎  ⏎ Förväntat: Alla valda former + tillhörande kanter tas bort. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen test
    %% ui_N52 pos: 1180,1380
    ui_N53("46. Centrera horisontellt"):::ui
    %% ui_N53 note: Justerar alla markerade former så de delar samma X-center. ⏎  ⏎ Åtkomst: Marker-läge + minst 2 former → tap 'align.horizontal.center'. ⏎  ⏎ Förväntat: Alla former får samma X-position; behåller sina Y-positioner. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen test
    %% ui_N53 pos: 1420,1380
    ui_N54("47. Centrera vertikalt"):::ui
    %% ui_N54 note: Justerar alla markerade former så de delar samma Y-center. ⏎  ⏎ Åtkomst: Marker-läge + minst 2 former → tap 'align.vertical.center'. ⏎  ⏎ Förväntat: Alla former får samma Y-position; behåller sina X-positioner. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen test
    %% ui_N54 pos: 1660,1380
    ui_N55("Canvas-gester"):::ui
    %% ui_N55 size: 1.4
    %% ui_N55 pos: 300,1560
    ui_N56("48. Tap på form → välj"):::ui
    %% ui_N56 note: Markera en enskild form för att redigera den. ⏎  ⏎ Åtkomst: Tap på valfri form på canvas. ⏎  ⏎ Förväntat: Formen får blå streckad markerings-ram; selection handles visas. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Implicit täckt via testT17_DoubleTapOpensEdit
    %% ui_N56 pos: 700,1560
    ui_N57("49. Tap på form i marker-läge"):::ui
    %% ui_N57 note: Lägg till/ta bort form från multi-selection. ⏎  ⏎ Åtkomst: Aktivera marker-läge → tap på form. ⏎  ⏎ Förväntat: Formen togglas in/ur multiSelection; bounding box uppdateras. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen test
    %% ui_N57 pos: 940,1560
    ui_N58("50. Drag form → flytta ✓"):::ui
    %% ui_N58 note: Flytta en form genom att dra den med fingret. ⏎  ⏎ Åtkomst: Long-press (eller direkt drag) på form → drag till ny position. ⏎  ⏎ Förväntat: Form följer fingret; auto-scroll vid kant; canvas expanderas vid behov. ⏎  ⏎ Status sim: ✓ ⏎ Status iPhone:  ⏎ Anteckning: V33SensorTests testDragCircleToKnownPosition
    %% ui_N58 pos: 1180,1560
    ui_N59("51. Drag i multi-select → flytta…"):::ui
    %% ui_N59 note: Flytta alla markerade former samtidigt. ⏎  ⏎ Åtkomst: Multi-select aktiv + drag på en vald form. ⏎  ⏎ Förväntat: Alla former i multiSelection (samt container-barn) följer med. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen test
    %% ui_N59 pos: 1420,1560
    ui_N60("52. Marquee-drag → multi-select"):::ui
    %% ui_N60 note: Rita streckad rektangel för att markera flera former samtidigt. ⏎  ⏎ Åtkomst: Aktivera marker-läge → drag på tom canvas-yta (>8pt). ⏎  ⏎ Förväntat: Streckad rektangel ritas; alla former inom blir multi-selected. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen test
    %% ui_N60 pos: 1660,1560
    ui_N61("53. Tap på tom canvas → avmarkera ✓"):::ui
    %% ui_N61 note: Töm selection när man tappar på tom yta. ⏎  ⏎ Åtkomst: Tap på tom yta utanför former. ⏎  ⏎ Förväntat: selectedShapeId = nil; multiSelection töms; edge-mode avbryts om aktivt. ⏎  ⏎ Status sim: ✓ ⏎ Status iPhone:  ⏎ Anteckning: V29CoverageTests testT16_TapBackgroundDeselects
    %% ui_N61 pos: 1900,1560
    ui_N62("54. Long-press på form → Connect…"):::ui
    %% ui_N62 note: Visa pil-handtag på formens högra sida för att skapa kant. ⏎  ⏎ Åtkomst: Långt tryck på form (≈0.5s). ⏎  ⏎ Förväntat: Blå ConnectionHandle dyker upp; drag därifrån skapar pil. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen test
    %% ui_N62 pos: 2140,1560
    ui_N63("55. Pinch zoom ✓"):::ui
    %% ui_N63 note: Zooma in/ut canvas med två-fingers nyp. ⏎  ⏎ Åtkomst: Pinch-gest på canvas (två fingrar). ⏎  ⏎ Förväntat: Zoom-nivå uppdateras; pinch-anchor stannar där fingrarna är (UIScrollView). ⏎  ⏎ Status sim: ✓ ⏎ Status iPhone:  ⏎ Anteckning: V35BugHuntTests testZoomChangesScrollViewState
    %% ui_N63 pos: 2380,1560
    ui_N64("56. Pan canvas ✓"):::ui
    %% ui_N64 note: Panorera canvas (förflytta viewport). ⏎  ⏎ Åtkomst: Drag med två fingrar (eller en finger på tom yta utanför form). ⏎  ⏎ Förväntat: Viewport-offset uppdateras inom canvas-gränser. ⏎  ⏎ Status sim: ✓ ⏎ Status iPhone:  ⏎ Anteckning: V34PanSymmetryTests testPanWorksInAllFourDirections
    %% ui_N64 pos: 2620,1560
    ui_N65("Selection handles"):::ui
    %% ui_N65 size: 1.4
    %% ui_N65 pos: 300,1740
    ui_N66("57. Proportionell resize"):::ui
    %% ui_N66 note: Skala vald form proportionellt (aspect ratio bevaras). ⏎  ⏎ Åtkomst: Drag på proportional-handtag (bottom-right hörn). ⏎  ⏎ Förväntat: Shape växer/krymper proportionellt från sitt center. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen test
    %% ui_N66 pos: 700,1740
    ui_N67("58. Fri resize"):::ui
    %% ui_N67 note: Skala vald form fritt i båda dimensioner (kan ändra aspect). ⏎  ⏎ Åtkomst: Drag på free-resize-handtag (bottom-left, 4-pil-ikon). ⏎  ⏎ Förväntat: Width och height ändras oberoende. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen test
    %% ui_N67 pos: 940,1740
    ui_N68("59. Rotation"):::ui
    %% ui_N68 note: Rotera vald form kring sitt center. ⏎  ⏎ Åtkomst: Drag på rotate-handtag (top-left). ⏎  ⏎ Förväntat: Shape.rotation uppdateras (grader). ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen test
    %% ui_N68 pos: 1180,1740
    ui_N69("60. Multi-select resize"):::ui
    %% ui_N69 note: Skala alla markerade former proportionellt från gruppens center. ⏎  ⏎ Åtkomst: Multi-select aktiv → drag på multi-resize-handtag (bottom-right av bounding box). ⏎  ⏎ Förväntat: Alla markerade former skalas proportionellt; relativ position bevaras. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen test
    %% ui_N69 pos: 1420,1740
    ui_N70("61. Connection handle drag"):::ui
    %% ui_N70 note: Skapa pil mellan två former via gummibands-drag. ⏎  ⏎ Åtkomst: Long-press på form → drag från ConnectionHandle till en annan form. ⏎  ⏎ Förväntat: Pil skapas mellan from- och to-form; default direction=forward. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen test (komplex gesture)
    %% ui_N70 pos: 1660,1740
    ui_N71("Form-actions"):::ui
    %% ui_N71 size: 1.4
    %% ui_N71 pos: 300,1920
    ui_N72("62. Dubbelklick → öppna editor ✓"):::ui
    %% ui_N72 note: Öppnar EditShapeSheet för vald form (text, stil, anteckning). ⏎  ⏎ Åtkomst: Dubbelklick på form (eller tap på 'Edit' i context-meny om sådan finns). ⏎  ⏎ Förväntat: EditShapeSheet öppnas med formens nuvarande värden. ⏎  ⏎ Status sim: ✓ ⏎ Status iPhone:  ⏎ Anteckning: V29CoverageTests testT17_DoubleTapOpensEdit
    %% ui_N72 pos: 700,1920
    ui_N73("63. Tap på note-badge → mini-sheet"):::ui
    %% ui_N73 note: Öppnar liten popup för att läsa/redigera formens anteckning. ⏎  ⏎ Åtkomst: Tap på gul note-badge (om note finns) på formen. ⏎  ⏎ Förväntat: NoteMiniSheet öppnas över formen. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen test
    %% ui_N73 pos: 940,1920
    ui_N74("64. Collapse-badge på container"):::ui
    %% ui_N74 note: Visar att container har dolda barn; tap visar dem igen. ⏎  ⏎ Åtkomst: Tap på collapse-badge under container-form. ⏎  ⏎ Förväntat: Container-barn visas/döljs. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen test
    %% ui_N74 pos: 1180,1920
    ui_N75("EditShapeSheet"):::ui
    %% ui_N75 size: 1.4
    %% ui_N75 pos: 836,1850
    ui_N76("65. Redigera text (label) ✓"):::ui
    %% ui_N76 note: Skriv eller ändra texten som visas i formen. ⏎  ⏎ Åtkomst: Dubbelklick på form → TextField 'Skriv text' överst. ⏎  ⏎ Förväntat: Shape.label uppdateras live på canvas vid Klar/Spara. ⏎  ⏎ Status sim: ✓ ⏎ Status iPhone:  ⏎ Anteckning: EndToEndTests testNoteTypedInEditSheetFollowsToMermaidCode
    %% ui_N76 pos: 700,2100
    ui_N77("66. Toggla 'Visa text'"):::ui
    %% ui_N77 note: Visa/dölj formens label på canvas (sparas i state). ⏎  ⏎ Åtkomst: EditShapeSheet → Toggle 'Visa text'. ⏎  ⏎ Förväntat: Shape.showLabel togglas; text visas/försvinner på formen. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test
    %% ui_N77 pos: 940,2100
    ui_N78("67. Stilväljare (segmented)"):::ui
    %% ui_N78 note: Välj textstil (Rubrik 1/2/3 eller Brödtext) via segmented picker. ⏎  ⏎ Åtkomst: EditShapeSheet → Picker 'Stil'. ⏎  ⏎ Förväntat: Shape.textStyle uppdateras. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Round-trip via testRoundTrip_PreservesAllShapeMetadata
    %% ui_N78 pos: 1180,2100
    ui_N79("68. Justering + bullets (inline) ✓"):::ui
    %% ui_N79 note: Snabb-rad med L/C/R-justering och bullet-toggle. ⏎  ⏎ Åtkomst: EditShapeSheet → HStack under stilväljare. ⏎  ⏎ Förväntat: Shape.textAlignment och hasBullets uppdateras. ⏎  ⏎ Status sim: ✓ (data) ⏎ Status iPhone:  ⏎ Anteckning: Via testRoundTrip_v46Fields_Preserved
    %% ui_N79 pos: 1420,2100
    ui_N80("69. Redigera anteckning (note) ✓"):::ui
    %% ui_N80 note: Skriv en privat anteckning som inte syns direkt på canvas. ⏎  ⏎ Åtkomst: EditShapeSheet → TextEditor 'Skriv anteckning här'. ⏎  ⏎ Förväntat: Shape.note uppdateras; note-badge visas på formen. ⏎  ⏎ Status sim: ✓ ⏎ Status iPhone:  ⏎ Anteckning: EndToEndTests testNoteTypedInEditSheetFollowsToMermaidCode
    %% ui_N80 pos: 1660,2100
    ui_N81("70. Ta bort form (via sheet)"):::ui
    %% ui_N81 note: Radera form från canvas via en knapp i sheet:t. ⏎  ⏎ Åtkomst: EditShapeSheet → 'Ta bort form'-knapp → BekräftelseDialog → Bekräfta. ⏎  ⏎ Förväntat: Formen och dess pilar tas bort; sheet stängs. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test
    %% ui_N81 pos: 1900,2100
    ui_N82("Kant-context"):::ui
    %% ui_N82 size: 1.4
    %% ui_N82 pos: 300,2280
    ui_N83("71. Tap på pil → context-meny"):::ui
    %% ui_N83 note: Visar context-meny för pil (label, direction, style, delete). ⏎  ⏎ Åtkomst: Tap på pil/kant på canvas. ⏎  ⏎ Förväntat: Context-meny visas vid pilen. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen test
    %% ui_N83 pos: 700,2280
    ui_N84("72. Lägg till/ändra etikett ✓"):::ui
    %% ui_N84 note: Skriv text på en pil. ⏎  ⏎ Åtkomst: Tap pil → context-meny → 'Edit label' (eller dubbelklick på pil). ⏎  ⏎ Förväntat: EdgeLabelSheet öppnas; text sparas på kanten. ⏎  ⏎ Status sim: ✓ (data) ⏎ Status iPhone:  ⏎ Anteckning: Round-trip via testRoundTrip_PreservesEdgeLabelsAndStyles_FullCycle
    %% ui_N84 pos: 940,2280
    ui_N85("73. Ändra pil-riktning ✓"):::ui
    %% ui_N85 note: Välj fram-pil (→), bak-pil (←), dubbelriktad (↔) eller ingen (—). ⏎  ⏎ Åtkomst: Tap pil → midpoint-knapp eller context-meny → välj direction. ⏎  ⏎ Förväntat: EdgeConnection.direction uppdateras; pilhuvud ritas om. ⏎  ⏎ Status sim: ✓ (data) ⏎ Status iPhone:  ⏎ Anteckning: Round-trip via testRoundTrip_EdgesWithStyles
    %% ui_N85 pos: 1180,2280
    ui_N86("74. Ändra linje-stil ✓"):::ui
    %% ui_N86 note: Växla mellan solid och streckad linje. ⏎  ⏎ Åtkomst: Tap pil → context-meny → byt style (solid/dashed). ⏎  ⏎ Förväntat: EdgeConnection.style uppdateras. ⏎  ⏎ Status sim: ✓ (data) ⏎ Status iPhone:  ⏎ Anteckning: Round-trip via testRoundTrip_EdgesWithStyles
    %% ui_N86 pos: 1420,2280
    ui_N87("75. Ta bort kant"):::ui
    %% ui_N87 note: Radera pilen mellan två former. ⏎  ⏎ Åtkomst: Tap pil → context-meny → 'Delete' (eller 'Ta bort'). ⏎  ⏎ Förväntat: EdgeConnection raderas från modellen. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test
    %% ui_N87 pos: 1660,2280
    ui_N88("Tabell-editor"):::ui
    %% ui_N88 size: 1.4
    %% ui_N88 pos: 300,2460
    ui_N89("76. Öppna tabell-editor"):::ui
    %% ui_N89 note: Öppnar redigerings-sheet för tabell-form. ⏎  ⏎ Åtkomst: Dubbelklick på tabell-form på canvas. ⏎  ⏎ Förväntat: TableEditorSheet öppnas med rutnät av celler. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test
    %% ui_N89 pos: 700,2460
    ui_N90("77. Redigera tabell-cell ✓"):::ui
    %% ui_N90 note: Skriv text i en enskild cell. ⏎  ⏎ Åtkomst: Tap i cell i TableEditorSheet → skriv text. ⏎  ⏎ Förväntat: Cell uppdateras; sparas när sheet:t stängs. ⏎  ⏎ Status sim: ✓ (data) ⏎ Status iPhone:  ⏎ Anteckning: Round-trip via testRoundTrip_v46Fields_Preserved (tableCells)
    %% ui_N90 pos: 940,2460
    ui_N91("78. Lägg till rad"):::ui
    %% ui_N91 note: Lägg till en ny tom rad längst ner i tabellen. ⏎  ⏎ Åtkomst: TableEditorSheet → 'Lägg till rad'-knapp. ⏎  ⏎ Förväntat: Ny rad läggs till; rutnätet växer en rad. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test
    %% ui_N91 pos: 1180,2460
    ui_N92("79. Lägg till kolumn"):::ui
    %% ui_N92 note: Lägg till en ny tom kolumn till höger i tabellen. ⏎  ⏎ Åtkomst: TableEditorSheet → 'Lägg till kolumn'-knapp. ⏎  ⏎ Förväntat: Ny kolumn läggs till; rutnätet växer en kolumn. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test
    %% ui_N92 pos: 1420,2460
    ui_N93("Ny canvas-sheet"):::ui
    %% ui_N93 size: 1.4
    %% ui_N93 pos: 300,2640
    ui_N94("80. Välj 'Blank canvas'"):::ui
    %% ui_N94 note: Starta tom canvas utan plattform-regler. ⏎  ⏎ Åtkomst: Hamburger → Ny canvas → tap 'Blank canvas'-kortet. ⏎  ⏎ Förväntat: Tom canvas skapas; platform = .blank. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test
    %% ui_N94 pos: 700,2640
    ui_N95("81. Välj 'Godot'"):::ui
    %% ui_N95 note: Starta canvas med Godot-plattformsregler (iPhone-ram-overlay etc). ⏎  ⏎ Åtkomst: Hamburger → Ny canvas → tap 'Godot'-kortet. ⏎  ⏎ Förväntat: Canvas skapas; platform = .godot; specifika regler aktiveras. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test
    %% ui_N95 pos: 940,2640
    ui_N96("Note-sheets"):::ui
    %% ui_N96 size: 1.4
    %% ui_N96 pos: 300,2820
    ui_N97("82. NoteMiniSheet (per form)"):::ui
    %% ui_N97 note: Liten popup för att läsa/skriva anteckning på en form. ⏎  ⏎ Åtkomst: Tap note-badge på form, eller via EditShapeSheet. ⏎  ⏎ Förväntat: TextEditor visas; ändringar sparas till shape.note. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test
    %% ui_N97 pos: 700,2820
    ui_N98("83. NotePopupSheet (alla)"):::ui
    %% ui_N98 note: Sammanställning av alla labels + notes på canvas i en lista. ⏎  ⏎ Åtkomst: Tap chip.notepopup (pratbubbla-ikonen i shapes-raden). ⏎  ⏎ Förväntat: ScrollView med alla former och deras text visas. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test
    %% ui_N98 pos: 940,2820
    ui_N99("Mermaid-export"):::ui
    %% ui_N99 size: 1.4
    %% ui_N99 pos: 300,3000
    ui_N100("84. Visa Mermaid-kod ✓"):::ui
    %% ui_N100 note: Visar live-genererad Mermaid-syntax för aktuell canvas. ⏎  ⏎ Åtkomst: Hamburger → 'Visa Mermaid-kod'. ⏎  ⏎ Förväntat: MermaidCodeSheet öppnas; text uppdateras vid varje canvas-ändring. ⏎  ⏎ Status sim: ✓ ⏎ Status iPhone:  ⏎ Anteckning: V29CoverageTests testT22_ShowMermaidCodeMenuItemExists
    %% ui_N100 pos: 700,3000
    ui_N101("85. Kopiera kod till urklipp"):::ui
    %% ui_N101 note: Kopiera Mermaid-koden för att klistra in i Claude.ai eller mermaid.live. ⏎  ⏎ Åtkomst: MermaidCodeSheet → 'Kopiera'-knapp. ⏎  ⏎ Förväntat: Kod hamnar i urklipp; knappen visar 'Kopierad' i 1.5s. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test
    %% ui_N101 pos: 940,3000
    ui_N102("Mermaid-import"):::ui
    %% ui_N102 size: 1.4
    %% ui_N102 pos: 300,3180
    ui_N103("86. Steg 1: Visa mall för AI"):::ui
    %% ui_N103 note: Visa instruktionstext att skicka till Claude.ai så den genererar rätt Mermaid-syntax. ⏎  ⏎ Åtkomst: Hamburger → 'Importera Mermaid' → Steg 1. ⏎  ⏎ Förväntat: Mall-text visas; kan kopieras. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test
    %% ui_N103 pos: 700,3180
    ui_N104("87. Steg 1: Kopiera mall"):::ui
    %% ui_N104 note: Kopierar instruktionstexten till urklipp. ⏎  ⏎ Åtkomst: Steg 1 → 'Kopiera mall'-knapp. ⏎  ⏎ Förväntat: Mall hamnar i urklipp. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test
    %% ui_N104 pos: 940,3180
    ui_N105("88. Steg 2: Klistra in Mermaid-kod"):::ui
    %% ui_N105 note: Klistra in AI-genererad Mermaid-kod i textfält. ⏎  ⏎ Åtkomst: Steg 2 → tap i TextEditor → paste från urklipp. ⏎  ⏎ Förväntat: Kod sparas i state; preview kan visas. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test
    %% ui_N105 pos: 1180,3180
    ui_N106("89. Steg 2: Importera"):::ui
    %% ui_N106 note: Parsa Mermaid-koden och ersätt canvas med resultatet. ⏎  ⏎ Åtkomst: Steg 2 → 'Importera till canvas'-knapp. ⏎  ⏎ Förväntat: CanvasModel.replaceAll() körs; canvas uppdateras; sheet stängs. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test
    %% ui_N106 pos: 1420,3180
    ui_N107("90. Navigera mellan steg"):::ui
    %% ui_N107 note: Gå mellan steg 1 (mall) och steg 2 (klistra in). ⏎  ⏎ Åtkomst: Knappar 'Nästa' / 'Tillbaka' i sheet:t. ⏎  ⏎ Förväntat: Steg-vy byts; värden bevaras. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test
    %% ui_N107 pos: 1660,3180
    ui_N108("Plattform-regler"):::ui
    %% ui_N108 size: 1.4
    %% ui_N108 pos: 300,3360
    ui_N109("91. Visa plattform-regler"):::ui
    %% ui_N109 note: Visar markdown-formaterad regelbok för aktuell plattform (t.ex. Godot). ⏎  ⏎ Åtkomst: Hamburger → 'Visa regler för [plattform]'. ⏎  ⏎ Förväntat: PlatformRulesSheet öppnas med ScrollView. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test
    %% ui_N109 pos: 700,3360
    ui_N110("Färgväljare"):::ui
    %% ui_N110 size: 1.4
    %% ui_N110 pos: 300,3540
    ui_N111("92. ColorPickerPopover – välj färg"):::ui
    %% ui_N111 note: Välj en specifik färg-override för en form (8 fördefinierade). ⏎  ⏎ Åtkomst: Långpress eller meny-val på form → ColorPickerPopover. ⏎  ⏎ Förväntat: Grid med 8 färger visas; vald sätter colorOverride. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test
    %% ui_N111 pos: 700,3540
    ui_N112("93. ColorPickerPopover – återstä…"):::ui
    %% ui_N112 note: Ta bort form-specifik färg så att kategori-paket används. ⏎  ⏎ Åtkomst: ColorPickerPopover → 'Använd kategori-färg'-knapp. ⏎  ⏎ Förväntat: colorOverride blir nil; formen visar paketets färg. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test
    %% ui_N112 pos: 940,3540
    ui_N113("94. ColorPackPopover – välj paket ✓"):::ui
    %% ui_N113 note: Välj färgpaket (7 paket: UI, Roadmap, Arkitektur, Flow + 2 + ingen). ⏎  ⏎ Åtkomst: Toolbar.colors → tap färgcirkel. ⏎  ⏎ Förväntat: colorPackId uppdateras; form-utseende ändras direkt. ⏎  ⏎ Status sim: ✓ (data) ⏎ Status iPhone:  ⏎ Anteckning: Round-trip via testGenerator_ColorPack
    %% ui_N113 pos: 1180,3540
    ui_N114("Canvas – auto"):::ui
    %% ui_N114 size: 1.4
    %% ui_N114 pos: 300,3720
    ui_N115("95. Automatisk canvas-expansion ✓"):::ui
    %% ui_N115 note: Canvas växer automatiskt när form dras nära kanten. ⏎  ⏎ Åtkomst: Drag form mot canvas-kant (inom 50pt marginal). ⏎  ⏎ Förväntat: Canvas-storlek växer; viewport scrollar med. ⏎  ⏎ Status sim: ✓ ⏎ Status iPhone:  ⏎ Anteckning: V27FeatureTests testCircleLandsNearCanvasEdge
    %% ui_N115 pos: 700,3720
    ui_N116("96. Auto-scroll under drag"):::ui
    %% ui_N116 note: Viewport panorerar långsamt när form dras mot viewport-kant. ⏎  ⏎ Åtkomst: Drag form mot synligt kant-område. ⏎  ⏎ Förväntat: Viewport glider långsamt för att följa formen. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Svår att testa automated
    %% ui_N116 pos: 940,3720
    ui_N117("97. Live update vid externa ändr…"):::ui
    %% ui_N117 note: Om någon annan ändrar canvas-filen i iCloud uppdateras vyn live. ⏎  ⏎ Åtkomst: Spara extern Mermaid-MD i iCloud-mappen. ⏎  ⏎ Förväntat: Canvas läses om automatiskt (NSFilePresenter). ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: NSFilePresenter ej testad i sim
    %% ui_N117 pos: 1180,3720
    ui_N118("FreeLine-specifik"):::ui
    %% ui_N118 size: 1.4
    %% ui_N118 pos: 300,3900
    ui_N119("98. Drag linje-slutpunkt ✓"):::ui
    %% ui_N119 note: Förläng/förkorta/rotera en fri linje genom att dra dess ände. ⏎  ⏎ Åtkomst: Tap linje → drag på endpoint-handtag. ⏎  ⏎ Förväntat: Shape.lineEnd uppdateras; linje följer. ⏎  ⏎ Status sim: ✓ (data) ⏎ Status iPhone:  ⏎ Anteckning: Round-trip via testRoundTrip_LineEnd_Preserved
    %% ui_N119 pos: 700,3900
    ui_N120("Container"):::ui
    %% ui_N120 size: 1.4
    %% ui_N120 pos: 300,4080
    ui_N121("99. Dra form in i container"):::ui
    %% ui_N121 note: När en form släpps inom en container blir den container-barn. ⏎  ⏎ Åtkomst: Drag form till position inom container-rektangel. ⏎  ⏎ Förväntat: Form blir barn till container; följer med när container flyttas. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test
    %% ui_N121 pos: 700,4080
    ui_N122("100. Dra container → barn följer …"):::ui
    %% ui_N122 note: När container flyttas följer alla dess barn-former med automatiskt. ⏎  ⏎ Åtkomst: Drag på container-form. ⏎  ⏎ Förväntat: Container + alla barn flyttas tillsammans. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test
    %% ui_N122 pos: 940,4080
    ui_N123("101. Resize container → barn skal…"):::ui
    %% ui_N123 note: När container skalas påverkas inte barn-formers storlek. ⏎  ⏎ Åtkomst: Drag på containerns resize-handtag. ⏎  ⏎ Förväntat: Endast containerns dimensioner ändras; barn behåller sina storlekar. ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen UI-test
    %% ui_N123 pos: 1180,4080
    ui_N124("Canvas – snap"):::ui
    %% ui_N124 size: 1.4
    %% ui_N124 pos: 300,4260
    ui_N125("102. Dot-grid bakgrund ✓"):::ui
    %% ui_N125 note: Visar prick-rutnät som visuell guide. ⏎  ⏎ Åtkomst: Alltid synlig som bakgrund (DotGridBackground). ⏎  ⏎ Förväntat: Prickar med ~40pt mellanrum; rörs ej av zoom. ⏎  ⏎ Status sim: ✓ ⏎ Status iPhone:  ⏎ Anteckning: Visuell verifiering i launch-screenshot
    %% ui_N125 pos: 700,4260
    ui_N126("Persistens"):::ui
    %% ui_N126 size: 1.4
    %% ui_N126 pos: 300,4440
    ui_N127("103. Autospara vid bakgrundning"):::ui
    %% ui_N127 note: Canvas sparas automatiskt när appen läggs i bakgrunden. ⏎  ⏎ Åtkomst: Tryck hem-knappen / app switch. ⏎  ⏎ Förväntat: Aktuell fil skrivs till disk (om en är öppen). ⏎  ⏎ Status sim: — ⏎ Status iPhone:  ⏎ Anteckning: Ingen test
    %% ui_N127 pos: 700,4440
    ui_N128("104. Round-trip av alla form-fält ✓"):::ui
    %% ui_N128 note: Alla form-egenskaper bevaras vid spara → öppna (numrerad lista, indrag, tabeller, etc). ⏎  ⏎ Åtkomst: Spara canvas → stäng app → öppna fil. ⏎  ⏎ Förväntat: Alla shape-fält (label, style, textAlignment, hasBullets, hasNumberedList, indentLevel, tableCells, position, size, rotation, etc) återskapas exakt. ⏎  ⏎ Status sim: ✓ ⏎ Status iPhone:  ⏎ Anteckning: FULLT TÄCKT: V35MermaidValidationTests + RoundTripTests
    %% ui_N128 pos: 940,4440
    style ui_N0 font-size:28px,padding:16px
    style ui_N1 font-size:20px,padding:11px
    style ui_N9 font-size:20px,padding:11px
    style ui_N19 font-size:20px,padding:11px
    style ui_N31 font-size:20px,padding:11px
    style ui_N36 font-size:20px,padding:11px
    style ui_N39 font-size:20px,padding:11px
    style ui_N49 font-size:20px,padding:11px
    style ui_N55 font-size:20px,padding:11px
    style ui_N65 font-size:20px,padding:11px
    style ui_N71 font-size:20px,padding:11px
    style ui_N75 font-size:20px,padding:11px
    style ui_N82 font-size:20px,padding:11px
    style ui_N88 font-size:20px,padding:11px
    style ui_N93 font-size:20px,padding:11px
    style ui_N96 font-size:20px,padding:11px
    style ui_N99 font-size:20px,padding:11px
    style ui_N102 font-size:20px,padding:11px
    style ui_N108 font-size:20px,padding:11px
    style ui_N110 font-size:20px,padding:11px
    style ui_N114 font-size:20px,padding:11px
    style ui_N118 font-size:20px,padding:11px
    style ui_N120 font-size:20px,padding:11px
    style ui_N124 font-size:20px,padding:11px
    style ui_N126 font-size:20px,padding:11px
    ui_N0 -.-> ui_N1
    ui_N0 -.-> ui_N9
    ui_N0 -.-> ui_N19
    ui_N0 -.-> ui_N31
    ui_N0 -.-> ui_N36
    ui_N0 -.-> ui_N39
    ui_N0 -.-> ui_N49
    ui_N0 -.-> ui_N55
    ui_N0 -.-> ui_N65
    ui_N0 -.-> ui_N71
    ui_N0 -.-> ui_N75
    ui_N0 -.-> ui_N82
    ui_N0 -.-> ui_N88
    ui_N0 -.-> ui_N93
    ui_N0 -.-> ui_N96
    ui_N0 -.-> ui_N99
    ui_N0 -.-> ui_N102
    ui_N0 -.-> ui_N108
    ui_N0 -.-> ui_N110
    ui_N0 -.-> ui_N114
    ui_N0 -.-> ui_N118
    ui_N0 -.-> ui_N120
    ui_N0 -.-> ui_N124
    ui_N0 -.-> ui_N126
    ui_N1 --> ui_N2
    ui_N1 --> ui_N3
    ui_N1 --> ui_N4
    ui_N1 --> ui_N5
    ui_N1 --> ui_N6
    ui_N1 --> ui_N7
    ui_N1 --> ui_N8
    ui_N9 --> ui_N10
    ui_N9 --> ui_N11
    ui_N9 --> ui_N12
    ui_N9 --> ui_N13
    ui_N9 --> ui_N14
    ui_N9 --> ui_N15
    ui_N9 --> ui_N16
    ui_N9 --> ui_N17
    ui_N9 --> ui_N18
    ui_N19 --> ui_N20
    ui_N19 --> ui_N21
    ui_N19 --> ui_N22
    ui_N19 --> ui_N23
    ui_N19 --> ui_N24
    ui_N19 --> ui_N25
    ui_N19 --> ui_N26
    ui_N19 --> ui_N27
    ui_N19 --> ui_N28
    ui_N19 --> ui_N29
    ui_N19 --> ui_N30
    ui_N31 --> ui_N32
    ui_N31 --> ui_N33
    ui_N31 --> ui_N34
    ui_N31 --> ui_N35
    ui_N36 --> ui_N37
    ui_N36 --> ui_N38
    ui_N39 --> ui_N40
    ui_N39 --> ui_N41
    %% e58 waypoint: 1220,959
    ui_N39 --> ui_N42
    ui_N39 --> ui_N43
    ui_N39 --> ui_N44
    ui_N39 --> ui_N45
    ui_N39 --> ui_N46
    ui_N39 --> ui_N47
    ui_N39 --> ui_N48
    ui_N49 --> ui_N50
    ui_N49 --> ui_N51
    ui_N49 --> ui_N52
    ui_N49 --> ui_N53
    ui_N49 --> ui_N54
    ui_N55 --> ui_N56
    ui_N55 --> ui_N57
    ui_N55 --> ui_N58
    ui_N55 --> ui_N59
    ui_N55 --> ui_N60
    ui_N55 --> ui_N61
    ui_N55 --> ui_N62
    ui_N55 --> ui_N63
    ui_N55 --> ui_N64
    ui_N65 --> ui_N66
    ui_N65 --> ui_N67
    ui_N65 --> ui_N68
    ui_N65 --> ui_N69
    ui_N65 --> ui_N70
    ui_N71 --> ui_N72
    ui_N71 --> ui_N73
    ui_N71 --> ui_N74
    ui_N75 --> ui_N76
    ui_N75 --> ui_N77
    ui_N75 --> ui_N78
    ui_N75 --> ui_N79
    ui_N75 --> ui_N80
    ui_N75 --> ui_N81
    ui_N82 --> ui_N83
    ui_N82 --> ui_N84
    ui_N82 --> ui_N85
    ui_N82 --> ui_N86
    ui_N82 --> ui_N87
    ui_N88 --> ui_N89
    ui_N88 --> ui_N90
    ui_N88 --> ui_N91
    ui_N88 --> ui_N92
    ui_N93 --> ui_N94
    ui_N93 --> ui_N95
    ui_N96 --> ui_N97
    ui_N96 --> ui_N98
    ui_N99 --> ui_N100
    ui_N99 --> ui_N101
    ui_N102 --> ui_N103
    ui_N102 --> ui_N104
    ui_N102 --> ui_N105
    ui_N102 --> ui_N106
    ui_N102 --> ui_N107
    ui_N108 --> ui_N109
    ui_N110 --> ui_N111
    ui_N110 --> ui_N112
    ui_N110 --> ui_N113
    ui_N114 --> ui_N115
    ui_N114 --> ui_N116
    ui_N114 --> ui_N117
    ui_N118 --> ui_N119
    ui_N120 --> ui_N121
    ui_N120 --> ui_N122
    ui_N120 --> ui_N123
    ui_N124 --> ui_N125
    ui_N126 --> ui_N127
    ui_N126 --> ui_N128

    classDef ui fill:#ffffff,stroke:#1e293b,color:#111827,font-weight:normal;
```

<!-- mermaidcanvas-state
{
  "platform" : "blank",
  "canvas" : {
    "shapeBaseWidth" : 120,
    "shapeBaseHeight" : 80,
    "height" : 5500,
    "iphoneFrame" : {
      "y" : 2324,
      "x" : 3804,
      "height" : 852,
      "designWidth" : 393,
      "width" : 393,
      "designHeight" : 852
    },
    "unit" : "pt",
    "width" : 8000
  },
  "specType" : "general",
  "nodes" : [
    {
      "type" : "pill",
      "label" : "Visuali2e v49 — Alla funktioner (104)",
      "showLabel" : true,
      "size" : 2,
      "note" : "Genererad från Visuali2e-v47-Funktionsprotokoll.xlsx, uppdaterad efter v49.",
      "id" : "ui_N0",
      "x" : 200,
      "y" : 100,
      "category" : "ui",
      "rotation" : 0
    },
    {
      "note" : "",
      "showLabel" : true,
      "id" : "ui_N1",
      "x" : 300,
      "rotation" : 0,
      "category" : "ui",
      "label" : "Toolbar – Primärrad",
      "type" : "rectangle",
      "y" : 300,
      "size" : 1.3999999999999999
    },
    {
      "category" : "ui",
      "label" : "1. Formväljare (chips) ✓",
      "id" : "ui_N2",
      "note" : "Öppnar två rader med alla 12 former (cirkel, rektangel, kvadrat, romb, piller, process-pil, container, tabell, jump-link, linje, antecknings-popup).\n\nÅtkomst: Tap på square.on.circle-ikonen i toolbar.\n\nFörväntat: Sekundär rad expanderar med shape-chips. Tap igen stänger raden.\n\nStatus sim: ✓\nStatus iPhone: \nAnteckning: DragOutTests + LayoutOverflowTests",
      "type" : "rectangle",
      "showLabel" : true,
      "size" : 1,
      "rotation" : 0,
      "y" : 300,
      "x" : 700
    },
    {
      "rotation" : 0,
      "note" : "Öppnar rad med 7 färgpaket (UI, Roadmap, Arkitektur, Flow + ingen-färg) för aktuell vald form.\n\nÅtkomst: Tap på paintpalette-ikonen (disabled om ingen form vald).\n\nFörväntat: Sekundär rad visar färgcirklar; tap applicerar paket på vald form.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test för färgapplicering",
      "id" : "ui_N3",
      "showLabel" : true,
      "y" : 300,
      "label" : "2. Färgpaket-rad",
      "x" : 940,
      "type" : "rectangle",
      "size" : 1,
      "category" : "ui"
    },
    {
      "x" : 1180,
      "id" : "ui_N4",
      "type" : "rectangle",
      "category" : "ui",
      "showLabel" : true,
      "rotation" : 0,
      "size" : 1,
      "note" : "Öppnar rad med textstorlek-val, fet, punktlista, numrerad lista, justering L\/C\/R, indrag in\/ut.\n\nÅtkomst: Tap på textformat.size-ikonen (disabled om ingen form vald).\n\nFörväntat: Sekundär rad expanderar med text-operationsknappar.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test för textstilar",
      "label" : "3. Textstil-rad",
      "y" : 300
    },
    {
      "y" : 300,
      "category" : "ui",
      "note" : "Aktivera marquee-läge för att rita streckad rektangel och välja flera former i ett svep.\n\nÅtkomst: Tap på rectangle.dashed-ikonen.\n\nFörväntat: MarkerOverlay aktiveras; markeringsspecifik toolbar-rad visas; drag på canvas ritar streckad rektangel.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen XCUITest för marker-mode",
      "id" : "ui_N5",
      "label" : "4. Markeringsläge (multi-select)",
      "rotation" : 0,
      "x" : 1420,
      "type" : "rectangle",
      "size" : 1,
      "showLabel" : true
    },
    {
      "category" : "ui",
      "rotation" : 0,
      "label" : "5. Zoom-badge ✓",
      "showLabel" : true,
      "note" : "Visar aktuell zoom-procent och fungerar som debug-räknare (shapeCount=N). Tap återställer zoom till 100%.\n\nÅtkomst: Tap på toolbar.zoom (procent-badgen).\n\nFörväntat: Zoom återställs till 1.0; canvas centreras på nuvarande viewport.\n\nStatus sim: ✓\nStatus iPhone: \nAnteckning: V35BugHuntTests testZoomChangesScrollViewState",
      "type" : "rectangle",
      "x" : 1660,
      "id" : "ui_N6",
      "y" : 300,
      "size" : 1
    },
    {
      "size" : 1,
      "note" : "Ångrar senaste åtgärd (skapa, flytta, ta bort, ändra text, etc).\n\nÅtkomst: Tap på arrow.uturn.backward-ikonen.\n\nFörväntat: Föregående snapshot återställs. Disabled när inget finns att ångra.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Disabled vid start → ingen automated test",
      "id" : "ui_N7",
      "label" : "6. Ångra (undo)",
      "type" : "rectangle",
      "x" : 1900,
      "showLabel" : true,
      "y" : 300,
      "rotation" : 0,
      "category" : "ui"
    },
    {
      "rotation" : 0,
      "y" : 300,
      "label" : "7. Lägen-meny (hamburger) ✓",
      "type" : "rectangle",
      "showLabel" : true,
      "size" : 1,
      "id" : "ui_N8",
      "category" : "ui",
      "x" : 2140,
      "note" : "Öppnar dropdown-meny med fil-operationer (Ny, Spara, Öppna), plattform, Mermaid-kod.\n\nÅtkomst: Tap på slider.horizontal.3-ikonen längst till höger.\n\nFörväntat: Dropdown-meny visas med menyval.\n\nStatus sim: ✓\nStatus iPhone: \nAnteckning: V33VersionVisibleTests + V29CoverageTests"
    },
    {
      "note" : "",
      "category" : "ui",
      "rotation" : 0,
      "size" : 1.3999999999999999,
      "label" : "Hamburger-meny",
      "id" : "ui_N9",
      "y" : 480,
      "type" : "rectangle",
      "showLabel" : true,
      "x" : 300
    },
    {
      "label" : "8. Ny canvas (välj plattform)",
      "type" : "rectangle",
      "category" : "ui",
      "showLabel" : true,
      "id" : "ui_N10",
      "x" : 700,
      "y" : 480,
      "rotation" : 0,
      "note" : "Startar en helt ny rityta. Användaren får välja plattform (Blank eller Godot).\n\nÅtkomst: Tap hamburger → 'Ny canvas (välj plattform)' (allra översta valet).\n\nFörväntat: NewCanvasSheet öppnas; vald plattform skapar tom canvas.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen automated test",
      "size" : 1
    },
    {
      "x" : 940,
      "size" : 1,
      "note" : "Visar vilken plattform aktuell canvas använder. Informativ rad – ej klickbar.\n\nÅtkomst: Visas direkt under 'Ny canvas' som disabled grå text.\n\nFörväntat: Text: 'Aktuell plattform: Blank canvas' eller 'Aktuell plattform: Godot'.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen automated test",
      "category" : "ui",
      "showLabel" : true,
      "id" : "ui_N11",
      "y" : 480,
      "label" : "9. Aktuell plattform (indikator)",
      "type" : "rectangle",
      "rotation" : 0
    },
    {
      "label" : "10. Visa regler för Godot",
      "showLabel" : true,
      "y" : 480,
      "note" : "Öppnar regelbok med plattform-specifika regler (visas bara om Godot-plattform är vald).\n\nÅtkomst: Tap hamburger → 'Visa regler för Godot' (visas endast i Godot-läge).\n\nFörväntat: PlatformRulesSheet öppnas med markdown-formaterad regeltext.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Plattform-specifik, ej testad",
      "type" : "rectangle",
      "category" : "ui",
      "size" : 1,
      "rotation" : 0,
      "id" : "ui_N12",
      "x" : 1180
    },
    {
      "y" : 480,
      "note" : "Sparar canvas till senast öppnad fil (JSON inbäddat i Mermaid-MD).\n\nÅtkomst: Tap hamburger → 'Spara'. Heter 'Spara…' om ingen fil är öppen.\n\nFörväntat: Fil skrivs till disk; status-text bekräftar.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: FileSystem ej testat i UI",
      "category" : "ui",
      "id" : "ui_N13",
      "x" : 1420,
      "type" : "rectangle",
      "showLabel" : true,
      "rotation" : 0,
      "label" : "11. Spara",
      "size" : 1
    },
    {
      "x" : 1660,
      "category" : "ui",
      "size" : 1,
      "rotation" : 0,
      "note" : "Sparar canvas till en ny fil (filväljare).\n\nÅtkomst: Tap hamburger → 'Spara som ny fil…'.\n\nFörväntat: Filväljare öppnas för att välja sparplats; ny fil skapas.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: FileSystem ej testat",
      "y" : 480,
      "id" : "ui_N14",
      "label" : "12. Spara som ny fil",
      "type" : "rectangle",
      "showLabel" : true
    },
    {
      "id" : "ui_N15",
      "type" : "rectangle",
      "rotation" : 0,
      "note" : "Öppnar tidigare sparad Mermaid-MD-fil och läser in canvas-state.\n\nÅtkomst: Tap hamburger → 'Öppna fil…'.\n\nFörväntat: Filväljare öppnas; vald fil parsas och canvas ersätts.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: FileSystem ej testat",
      "y" : 480,
      "x" : 1900,
      "label" : "13. Öppna fil",
      "size" : 1,
      "category" : "ui",
      "showLabel" : true
    },
    {
      "showLabel" : true,
      "rotation" : 0,
      "note" : "Två-stegs guide för att importera AI-genererad Mermaid-kod från Claude.ai eller annan AI.\n\nÅtkomst: Tap hamburger → 'Importera Mermaid…'.\n\nFörväntat: MermaidImportSheet öppnas (steg 1: kopiera mall, steg 2: klistra in).\n\nStatus sim: —\nStatus iPhone: \nAnteckning: MermaidImportSheet ej UI-testad",
      "y" : 480,
      "size" : 1,
      "label" : "14. Importera Mermaid",
      "type" : "rectangle",
      "id" : "ui_N16",
      "x" : 2140,
      "category" : "ui"
    },
    {
      "rotation" : 0,
      "note" : "Visar den live-genererade Mermaid-koden för canvas. Kan kopieras och klistras in i Claude eller mermaid.live.\n\nÅtkomst: Tap hamburger → 'Visa Mermaid-kod'.\n\nFörväntat: MermaidCodeSheet öppnas med kod-text och 'Kopiera'-knapp.\n\nStatus sim: ✓\nStatus iPhone: \nAnteckning: V29CoverageTests testT22_ShowMermaidCodeMenuItemExists",
      "category" : "ui",
      "y" : 480,
      "x" : 2380,
      "showLabel" : true,
      "type" : "rectangle",
      "id" : "ui_N17",
      "label" : "15. Visa Mermaid-kod ✓",
      "size" : 1
    },
    {
      "id" : "ui_N18",
      "y" : 480,
      "category" : "ui",
      "size" : 1,
      "label" : "16. Visa AppVersion ✓",
      "rotation" : 0,
      "type" : "rectangle",
      "note" : "Visar appens versionsnummer som info-rad i menyn.\n\nÅtkomst: Disabled rad längst ner i hamburger-menyn.\n\nFörväntat: Visar 'v46' (eller aktuell version).\n\nStatus sim: ✓\nStatus iPhone: \nAnteckning: V33VersionVisibleTests testVersionIsVisibleInLägenMenu",
      "showLabel" : true,
      "x" : 2620
    },
    {
      "type" : "rectangle",
      "showLabel" : true,
      "id" : "ui_N19",
      "size" : 1.3999999999999999,
      "rotation" : 0,
      "category" : "ui",
      "label" : "Form-chips",
      "note" : "",
      "x" : 300,
      "y" : 660
    },
    {
      "id" : "ui_N20",
      "x" : 700,
      "label" : "17. Cirkel ✓",
      "category" : "ui",
      "note" : "Lägg till en cirkelform på canvas.\n\nÅtkomst: Tap toolbar.shapes → tap chip.circle (eller långpress + drag till canvas-position).\n\nFörväntat: Cirkelform skapas vid canvas-mitten eller släpp-punkten.\n\nStatus sim: ✓\nStatus iPhone: \nAnteckning: DragOutTests testTapAddsCircle + testDragCircleChipToCanvas",
      "y" : 660,
      "type" : "rectangle",
      "size" : 1,
      "rotation" : 0,
      "showLabel" : true
    },
    {
      "note" : "Lägg till en rektangelform på canvas.\n\nÅtkomst: Tap toolbar.shapes → tap chip.rectangle (eller drag).\n\nFörväntat: Rektangelform skapas.\n\nStatus sim: ✓\nStatus iPhone: \nAnteckning: DragOutTests testDragRectangleChipToCanvas",
      "type" : "rectangle",
      "showLabel" : true,
      "category" : "ui",
      "id" : "ui_N21",
      "x" : 940,
      "y" : 660,
      "label" : "18. Rektangel ✓",
      "size" : 1,
      "rotation" : 0
    },
    {
      "y" : 660,
      "size" : 1,
      "x" : 1180,
      "type" : "rectangle",
      "showLabel" : true,
      "category" : "ui",
      "note" : "Lägg till en kvadratisk form (80×80) på canvas.\n\nÅtkomst: Tap toolbar.shapes → tap chip.square (eller drag).\n\nFörväntat: Kvadrat skapas.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Inget eget test, ingår i totalShapeCount",
      "rotation" : 0,
      "id" : "ui_N22",
      "label" : "19. Kvadrat"
    },
    {
      "note" : "Lägg till en romb\/diamantform på canvas.\n\nÅtkomst: Tap toolbar.shapes → tap chip.diamond (eller drag).\n\nFörväntat: Rombform med rundade hörn skapas.\n\nStatus sim: ✓\nStatus iPhone: \nAnteckning: DragOutTests testAllSixChipsProduceShapes",
      "y" : 660,
      "size" : 1,
      "x" : 1420,
      "type" : "rectangle",
      "label" : "20. Romb (diamant) ✓",
      "category" : "ui",
      "showLabel" : true,
      "rotation" : 0,
      "id" : "ui_N23"
    },
    {
      "size" : 1,
      "rotation" : 0,
      "note" : "Lägg till en avlång ovalform på canvas.\n\nÅtkomst: Tap toolbar.shapes → tap chip.pill (eller drag).\n\nFörväntat: Pillerformad oval skapas.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Inget eget test, ingår i totalShapeCount",
      "id" : "ui_N24",
      "showLabel" : true,
      "x" : 1706,
      "y" : 607,
      "label" : "21. Piller (oval)",
      "category" : "ui",
      "type" : "rectangle"
    },
    {
      "note" : "Lägg till en pentagon-formad processpil på canvas.\n\nÅtkomst: Tap toolbar.shapes → tap chip.processArrow (eller drag).\n\nFörväntat: Pentagon med spets åt höger skapas.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Inget eget test, ingår i totalShapeCount",
      "id" : "ui_N25",
      "y" : 660,
      "showLabel" : true,
      "type" : "rectangle",
      "x" : 1900,
      "label" : "22. Processpil",
      "category" : "ui",
      "rotation" : 0,
      "size" : 1
    },
    {
      "note" : "Lägg till en streckad behållare för att gruppera andra former.\n\nÅtkomst: Tap toolbar.shapes → tap chip.container (eller drag).\n\nFörväntat: Större streckad rektangel skapas; andra former kan dras in i den.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test för container-chip",
      "x" : 2140,
      "y" : 660,
      "label" : "23. Container (subgraph)",
      "id" : "ui_N26",
      "rotation" : 0,
      "category" : "ui",
      "showLabel" : true,
      "type" : "rectangle",
      "size" : 1
    },
    {
      "label" : "24. Tabell ✓",
      "y" : 660,
      "category" : "ui",
      "id" : "ui_N27",
      "x" : 2380,
      "type" : "rectangle",
      "showLabel" : true,
      "size" : 1,
      "rotation" : 0,
      "note" : "Lägg till en 3×3-tabellform som kan redigeras cell för cell.\n\nÅtkomst: Tap toolbar.shapes → tap chip.table.\n\nFörväntat: Tabellform skapas; dubbelklick öppnar TableEditorSheet.\n\nStatus sim: ✓\nStatus iPhone: \nAnteckning: V27FeatureTests testTapTableChipAddsTable + testDragTableChipToCanvas"
    },
    {
      "category" : "ui",
      "size" : 1,
      "id" : "ui_N28",
      "label" : "25. Jump-link (länkat par) ✓",
      "x" : 2620,
      "rotation" : 0,
      "showLabel" : true,
      "note" : "Lägg till två länkade former (för att hoppa mellan ställen på canvas).\n\nÅtkomst: Tap toolbar.shapes → tap chip.link.\n\nFörväntat: Två länk-former med samma nummer skapas nära canvas-mitten.\n\nStatus sim: ✓\nStatus iPhone: \nAnteckning: V27FeatureTests testTapLinkChipAddsJumpLinkPair",
      "type" : "rectangle",
      "y" : 660
    },
    {
      "y" : 660,
      "category" : "ui",
      "x" : 2860,
      "id" : "ui_N29",
      "label" : "26. Linje (FreeLine)",
      "size" : 1,
      "note" : "Lägg till en lös linje (ingen pil) som kan dras i båda ändar.\n\nÅtkomst: Tap toolbar.shapes → tap chip.line.\n\nFörväntat: Horisontell linje skapas; båda ändpunkter draggable.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test för line-chip",
      "type" : "rectangle",
      "showLabel" : true,
      "rotation" : 0
    },
    {
      "size" : 1,
      "rotation" : 0,
      "note" : "Öppnar list-vy med alla textfält (labels + notes) på canvas.\n\nÅtkomst: Tap toolbar.shapes → tap chip.notepopup (pratbubbla-ikon).\n\nFörväntat: NotePopupSheet öppnas med scrollable lista.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test",
      "id" : "ui_N30",
      "showLabel" : true,
      "type" : "rectangle",
      "category" : "ui",
      "y" : 660,
      "label" : "27. Antecknings-popup",
      "x" : 3100
    },
    {
      "category" : "ui",
      "showLabel" : true,
      "size" : 1.3999999999999999,
      "rotation" : 0,
      "note" : "",
      "x" : 300,
      "type" : "rectangle",
      "id" : "ui_N31",
      "label" : "Form-paket",
      "y" : 840
    },
    {
      "category" : "ui",
      "size" : 1,
      "rotation" : 0,
      "id" : "ui_N32",
      "x" : 700,
      "y" : 840,
      "label" : "28. UI-paket",
      "note" : "Aktivera\/avaktivera UI-form-chips i toolbaren (designsystem-ikoner).\n\nÅtkomst: Tap toolbar.packs → toggle 'UI'.\n\nFörväntat: UI-pack-chips visas\/döljs i shapes-raden.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Bara packs-toggle existens testad",
      "showLabel" : true,
      "type" : "rectangle"
    },
    {
      "type" : "rectangle",
      "x" : 940,
      "label" : "29. Roadmap-paket",
      "size" : 1,
      "showLabel" : true,
      "category" : "ui",
      "y" : 840,
      "id" : "ui_N33",
      "rotation" : 0,
      "note" : "Aktivera\/avaktivera Roadmap-form-chips (milstolpar, deadlines, etc).\n\nÅtkomst: Tap toolbar.packs → toggle 'Roadmap'.\n\nFörväntat: Roadmap-pack-chips visas\/döljs.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen test"
    },
    {
      "note" : "Aktivera\/avaktivera Arkitektur-form-chips (komponenter, databas, etc).\n\nÅtkomst: Tap toolbar.packs → toggle 'Arkitektur'.\n\nFörväntat: Arkitektur-pack-chips visas\/döljs.\n\nStatus sim: ✓\nStatus iPhone: \nAnteckning: V29CoverageTests testT21_ArchitecturePackTogglesAddsChipInShapesRow",
      "rotation" : 0,
      "label" : "30. Arkitektur-paket ✓",
      "category" : "ui",
      "type" : "rectangle",
      "x" : 1180,
      "id" : "ui_N34",
      "y" : 840,
      "showLabel" : true,
      "size" : 1
    },
    {
      "note" : "Aktivera\/avaktivera Flow-form-chips (extra flödesschema-symboler).\n\nÅtkomst: Tap toolbar.packs → toggle 'Flow'.\n\nFörväntat: Flow-pack-chips visas\/döljs.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen test",
      "size" : 1,
      "id" : "ui_N35",
      "showLabel" : true,
      "label" : "31. Flow-paket",
      "y" : 840,
      "type" : "rectangle",
      "category" : "ui",
      "x" : 1420,
      "rotation" : 0
    },
    {
      "showLabel" : true,
      "size" : 1.3999999999999999,
      "type" : "rectangle",
      "id" : "ui_N36",
      "category" : "ui",
      "y" : 1020,
      "note" : "",
      "x" : 300,
      "label" : "Färg-rad",
      "rotation" : 0
    },
    {
      "type" : "rectangle",
      "x" : 700,
      "note" : "Sätt en färgkombination (fill+stroke+text) på vald form.\n\nÅtkomst: Välj form först → tap toolbar.colors → tap färg-cirkel.\n\nFörväntat: Vald forms colorPackId uppdateras; visuellt utseende ändras.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Round-trip täcker JSON, ej UI-flödet",
      "id" : "ui_N37",
      "showLabel" : true,
      "category" : "ui",
      "label" : "32. Applicera färgpaket",
      "rotation" : 0,
      "y" : 1020,
      "size" : 1
    },
    {
      "showLabel" : true,
      "size" : 1,
      "id" : "ui_N38",
      "x" : 940,
      "y" : 1020,
      "label" : "33. Återställ till kategori-färg",
      "type" : "rectangle",
      "note" : "Ta bort form-specifik färg-override; använd kategori-standardfärg.\n\nÅtkomst: Tap 'ingen färg'-cirkel (markerad med snedstreck).\n\nFörväntat: colorPackId blir nil; formen använder kategori-färg.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test",
      "category" : "ui",
      "rotation" : 0
    },
    {
      "x" : 300,
      "label" : "Textstil-rad",
      "category" : "ui",
      "y" : 1200,
      "showLabel" : true,
      "note" : "",
      "id" : "ui_N39",
      "size" : 1.3999999999999999,
      "type" : "rectangle",
      "rotation" : 0
    },
    {
      "note" : "Välj mellan Rubrik 1, Rubrik 2, Rubrik 3 eller Brödtext.\n\nÅtkomst: Tap toolbar.textstyles → tap textformat.size → välj i confirmationDialog.\n\nFörväntat: Vald forms textStyle ändras; text storlek\/vikt uppdateras.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test",
      "label" : "34. Textstorlek-popup",
      "category" : "ui",
      "size" : 1,
      "x" : 700,
      "id" : "ui_N40",
      "showLabel" : true,
      "y" : 1200,
      "type" : "rectangle",
      "rotation" : 0
    },
    {
      "category" : "ui",
      "rotation" : 0,
      "x" : 940,
      "size" : 1,
      "note" : "Togglar mellan Rubrik 1 (fet) och Brödtext (normal vikt).\n\nÅtkomst: Tap toolbar.textstyles → tap 'bold'-knappen.\n\nFörväntat: Text byter mellan headline (.r1) och body.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test",
      "type" : "rectangle",
      "id" : "ui_N41",
      "y" : 1200,
      "showLabel" : true,
      "label" : "35. Fet text-toggle"
    },
    {
      "y" : 1200,
      "size" : 1,
      "rotation" : 0,
      "note" : "Lägger till • framför varje rad i texten. Stänger av numrerad lista.\n\nÅtkomst: Tap toolbar.textstyles → tap 'list.bullet'.\n\nFörväntat: Shape.hasBullets togglas; hasNumberedList=false; text re-renderas.\n\nStatus sim: ✓ (data)\nStatus iPhone: \nAnteckning: Round-trip via V35MermaidValidationTests testRoundTrip_v46Fields_Preserved",
      "id" : "ui_N42",
      "x" : 1180,
      "label" : "36. Punktlista ✓",
      "type" : "rectangle",
      "category" : "ui",
      "showLabel" : true
    },
    {
      "size" : 1,
      "showLabel" : true,
      "y" : 1200,
      "note" : "Lägger till 1.\/2.\/3. framför varje rad. Stänger av punktlista.\n\nÅtkomst: Tap toolbar.textstyles → tap 'list.number'.\n\nFörväntat: Shape.hasNumberedList togglas; hasBullets=false.\n\nStatus sim: ✓ (data)\nStatus iPhone: \nAnteckning: Round-trip via testRoundTrip_v46Fields_Preserved",
      "category" : "ui",
      "type" : "rectangle",
      "label" : "37. Numrerad lista ✓",
      "id" : "ui_N43",
      "x" : 1420,
      "rotation" : 0
    },
    {
      "y" : 1200,
      "category" : "ui",
      "x" : 1660,
      "id" : "ui_N44",
      "label" : "38. Justering – vänster",
      "showLabel" : true,
      "type" : "rectangle",
      "note" : "Vänsterjustera texten i formen.\n\nÅtkomst: Tap toolbar.textstyles → tap 'text.alignleft'.\n\nFörväntat: Shape.textAlignment = .leading; text re-renderas.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: UI-knapparna i textStylesSecondary ej UI-testade",
      "size" : 1,
      "rotation" : 0
    },
    {
      "y" : 1200,
      "category" : "ui",
      "size" : 1,
      "id" : "ui_N45",
      "showLabel" : true,
      "note" : "Centrera texten i formen.\n\nÅtkomst: Tap toolbar.textstyles → tap 'text.aligncenter'.\n\nFörväntat: Shape.textAlignment = .center.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test",
      "rotation" : 0,
      "label" : "39. Justering – centrera",
      "type" : "rectangle",
      "x" : 1900
    },
    {
      "category" : "ui",
      "size" : 1,
      "id" : "ui_N46",
      "type" : "rectangle",
      "showLabel" : true,
      "note" : "Högerjustera texten i formen.\n\nÅtkomst: Tap toolbar.textstyles → tap 'text.alignright'.\n\nFörväntat: Shape.textAlignment = .trailing.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test",
      "rotation" : 0,
      "x" : 2140,
      "label" : "40. Justering – höger",
      "y" : 1200
    },
    {
      "x" : 2380,
      "y" : 1200,
      "showLabel" : true,
      "id" : "ui_N47",
      "note" : "Minskar indragsnivån (0–3 steg).\n\nÅtkomst: Tap toolbar.textstyles → tap 'decrease.indent'.\n\nFörväntat: Shape.indentLevel -= 1 (min 0); text indenteras mindre.\n\nStatus sim: ✓ (data)\nStatus iPhone: \nAnteckning: Round-trip via testRoundTrip_v46Fields_Preserved",
      "category" : "ui",
      "label" : "41. Indrag minska ✓",
      "type" : "rectangle",
      "rotation" : 0,
      "size" : 1
    },
    {
      "showLabel" : true,
      "note" : "Ökar indragsnivån (0–3 steg).\n\nÅtkomst: Tap toolbar.textstyles → tap 'increase.indent'.\n\nFörväntat: Shape.indentLevel += 1 (max 3); text indenteras mer.\n\nStatus sim: ✓ (data)\nStatus iPhone: \nAnteckning: Round-trip via testRoundTrip_v46Fields_Preserved",
      "label" : "42. Indrag öka ✓",
      "id" : "ui_N48",
      "x" : 2620,
      "y" : 1200,
      "type" : "rectangle",
      "category" : "ui",
      "size" : 1,
      "rotation" : 0
    },
    {
      "showLabel" : true,
      "id" : "ui_N49",
      "category" : "ui",
      "x" : 300,
      "label" : "Multi-select rad",
      "type" : "rectangle",
      "y" : 1380,
      "size" : 1.3999999999999999,
      "rotation" : 0,
      "note" : ""
    },
    {
      "type" : "rectangle",
      "rotation" : 0,
      "note" : "Visar antal valda former i marker-läge. Informativ rad.\n\nÅtkomst: Aktivera marker-läge + välj former → räknare uppdateras.\n\nFörväntat: '1 markerad' \/ '5 markerade' visas.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen test",
      "showLabel" : true,
      "x" : 700,
      "label" : "43. Räknare (N markerade)",
      "id" : "ui_N50",
      "y" : 1380,
      "category" : "ui",
      "size" : 1
    },
    {
      "category" : "ui",
      "x" : 940,
      "size" : 1,
      "showLabel" : true,
      "y" : 1380,
      "label" : "44. Duplicera markerade",
      "type" : "rectangle",
      "rotation" : 0,
      "note" : "Skapar kopior av alla markerade former.\n\nÅtkomst: Marker-läge + minst 1 form vald → tap 'plus.square.on.square'.\n\nFörväntat: Alla valda former dupliceras med offset; multiSelection uppdateras till nya.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen test",
      "id" : "ui_N51"
    },
    {
      "note" : "Raderar alla markerade former och deras anslutna pilar.\n\nÅtkomst: Marker-läge + minst 1 form vald → tap 'trash' (röd).\n\nFörväntat: Alla valda former + tillhörande kanter tas bort.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen test",
      "rotation" : 0,
      "label" : "45. Ta bort markerade",
      "type" : "rectangle",
      "x" : 1180,
      "y" : 1380,
      "category" : "ui",
      "showLabel" : true,
      "size" : 1,
      "id" : "ui_N52"
    },
    {
      "rotation" : 0,
      "type" : "rectangle",
      "x" : 1420,
      "note" : "Justerar alla markerade former så de delar samma X-center.\n\nÅtkomst: Marker-läge + minst 2 former → tap 'align.horizontal.center'.\n\nFörväntat: Alla former får samma X-position; behåller sina Y-positioner.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen test",
      "label" : "46. Centrera horisontellt",
      "showLabel" : true,
      "y" : 1380,
      "size" : 1,
      "category" : "ui",
      "id" : "ui_N53"
    },
    {
      "x" : 1660,
      "y" : 1380,
      "label" : "47. Centrera vertikalt",
      "category" : "ui",
      "type" : "rectangle",
      "size" : 1,
      "rotation" : 0,
      "id" : "ui_N54",
      "note" : "Justerar alla markerade former så de delar samma Y-center.\n\nÅtkomst: Marker-läge + minst 2 former → tap 'align.vertical.center'.\n\nFörväntat: Alla former får samma Y-position; behåller sina X-positioner.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen test",
      "showLabel" : true
    },
    {
      "y" : 1560,
      "type" : "rectangle",
      "label" : "Canvas-gester",
      "size" : 1.3999999999999999,
      "rotation" : 0,
      "id" : "ui_N55",
      "category" : "ui",
      "x" : 300,
      "note" : "",
      "showLabel" : true
    },
    {
      "id" : "ui_N56",
      "type" : "rectangle",
      "y" : 1560,
      "rotation" : 0,
      "category" : "ui",
      "showLabel" : true,
      "x" : 700,
      "size" : 1,
      "note" : "Markera en enskild form för att redigera den.\n\nÅtkomst: Tap på valfri form på canvas.\n\nFörväntat: Formen får blå streckad markerings-ram; selection handles visas.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Implicit täckt via testT17_DoubleTapOpensEdit",
      "label" : "48. Tap på form → välj"
    },
    {
      "x" : 940,
      "rotation" : 0,
      "size" : 1,
      "label" : "49. Tap på form i marker-läge",
      "note" : "Lägg till\/ta bort form från multi-selection.\n\nÅtkomst: Aktivera marker-läge → tap på form.\n\nFörväntat: Formen togglas in\/ur multiSelection; bounding box uppdateras.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen test",
      "id" : "ui_N57",
      "y" : 1560,
      "showLabel" : true,
      "type" : "rectangle",
      "category" : "ui"
    },
    {
      "id" : "ui_N58",
      "note" : "Flytta en form genom att dra den med fingret.\n\nÅtkomst: Long-press (eller direkt drag) på form → drag till ny position.\n\nFörväntat: Form följer fingret; auto-scroll vid kant; canvas expanderas vid behov.\n\nStatus sim: ✓\nStatus iPhone: \nAnteckning: V33SensorTests testDragCircleToKnownPosition",
      "y" : 1560,
      "category" : "ui",
      "x" : 1180,
      "type" : "rectangle",
      "label" : "50. Drag form → flytta ✓",
      "showLabel" : true,
      "size" : 1,
      "rotation" : 0
    },
    {
      "note" : "Flytta alla markerade former samtidigt.\n\nÅtkomst: Multi-select aktiv + drag på en vald form.\n\nFörväntat: Alla former i multiSelection (samt container-barn) följer med.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen test",
      "type" : "rectangle",
      "category" : "ui",
      "id" : "ui_N59",
      "label" : "51. Drag i multi-select → flytta…",
      "showLabel" : true,
      "y" : 1560,
      "x" : 1420,
      "size" : 1,
      "rotation" : 0
    },
    {
      "y" : 1560,
      "label" : "52. Marquee-drag → multi-select",
      "rotation" : 0,
      "category" : "ui",
      "x" : 1660,
      "type" : "rectangle",
      "showLabel" : true,
      "size" : 1,
      "note" : "Rita streckad rektangel för att markera flera former samtidigt.\n\nÅtkomst: Aktivera marker-läge → drag på tom canvas-yta (>8pt).\n\nFörväntat: Streckad rektangel ritas; alla former inom blir multi-selected.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen test",
      "id" : "ui_N60"
    },
    {
      "note" : "Töm selection när man tappar på tom yta.\n\nÅtkomst: Tap på tom yta utanför former.\n\nFörväntat: selectedShapeId = nil; multiSelection töms; edge-mode avbryts om aktivt.\n\nStatus sim: ✓\nStatus iPhone: \nAnteckning: V29CoverageTests testT16_TapBackgroundDeselects",
      "y" : 1560,
      "label" : "53. Tap på tom canvas → avmarkera ✓",
      "type" : "rectangle",
      "rotation" : 0,
      "x" : 1900,
      "showLabel" : true,
      "size" : 1,
      "id" : "ui_N61",
      "category" : "ui"
    },
    {
      "id" : "ui_N62",
      "type" : "rectangle",
      "x" : 2140,
      "category" : "ui",
      "y" : 1560,
      "size" : 1,
      "showLabel" : true,
      "rotation" : 0,
      "note" : "Visa pil-handtag på formens högra sida för att skapa kant.\n\nÅtkomst: Långt tryck på form (≈0.5s).\n\nFörväntat: Blå ConnectionHandle dyker upp; drag därifrån skapar pil.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen test",
      "label" : "54. Long-press på form → Connect…"
    },
    {
      "x" : 2380,
      "y" : 1560,
      "note" : "Zooma in\/ut canvas med två-fingers nyp.\n\nÅtkomst: Pinch-gest på canvas (två fingrar).\n\nFörväntat: Zoom-nivå uppdateras; pinch-anchor stannar där fingrarna är (UIScrollView).\n\nStatus sim: ✓\nStatus iPhone: \nAnteckning: V35BugHuntTests testZoomChangesScrollViewState",
      "rotation" : 0,
      "id" : "ui_N63",
      "type" : "rectangle",
      "showLabel" : true,
      "size" : 1,
      "label" : "55. Pinch zoom ✓",
      "category" : "ui"
    },
    {
      "x" : 2620,
      "label" : "56. Pan canvas ✓",
      "category" : "ui",
      "rotation" : 0,
      "type" : "rectangle",
      "id" : "ui_N64",
      "note" : "Panorera canvas (förflytta viewport).\n\nÅtkomst: Drag med två fingrar (eller en finger på tom yta utanför form).\n\nFörväntat: Viewport-offset uppdateras inom canvas-gränser.\n\nStatus sim: ✓\nStatus iPhone: \nAnteckning: V34PanSymmetryTests testPanWorksInAllFourDirections",
      "showLabel" : true,
      "y" : 1560,
      "size" : 1
    },
    {
      "category" : "ui",
      "size" : 1.3999999999999999,
      "rotation" : 0,
      "id" : "ui_N65",
      "note" : "",
      "y" : 1740,
      "type" : "rectangle",
      "label" : "Selection handles",
      "showLabel" : true,
      "x" : 300
    },
    {
      "category" : "ui",
      "showLabel" : true,
      "note" : "Skala vald form proportionellt (aspect ratio bevaras).\n\nÅtkomst: Drag på proportional-handtag (bottom-right hörn).\n\nFörväntat: Shape växer\/krymper proportionellt från sitt center.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen test",
      "x" : 700,
      "type" : "rectangle",
      "id" : "ui_N66",
      "y" : 1740,
      "size" : 1,
      "label" : "57. Proportionell resize",
      "rotation" : 0
    },
    {
      "id" : "ui_N67",
      "label" : "58. Fri resize",
      "x" : 940,
      "size" : 1,
      "y" : 1740,
      "type" : "rectangle",
      "category" : "ui",
      "showLabel" : true,
      "rotation" : 0,
      "note" : "Skala vald form fritt i båda dimensioner (kan ändra aspect).\n\nÅtkomst: Drag på free-resize-handtag (bottom-left, 4-pil-ikon).\n\nFörväntat: Width och height ändras oberoende.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen test"
    },
    {
      "id" : "ui_N68",
      "x" : 1180,
      "label" : "59. Rotation",
      "rotation" : 0,
      "type" : "rectangle",
      "y" : 1740,
      "size" : 1,
      "note" : "Rotera vald form kring sitt center.\n\nÅtkomst: Drag på rotate-handtag (top-left).\n\nFörväntat: Shape.rotation uppdateras (grader).\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen test",
      "showLabel" : true,
      "category" : "ui"
    },
    {
      "showLabel" : true,
      "y" : 1740,
      "id" : "ui_N69",
      "note" : "Skala alla markerade former proportionellt från gruppens center.\n\nÅtkomst: Multi-select aktiv → drag på multi-resize-handtag (bottom-right av bounding box).\n\nFörväntat: Alla markerade former skalas proportionellt; relativ position bevaras.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen test",
      "label" : "60. Multi-select resize",
      "category" : "ui",
      "size" : 1,
      "rotation" : 0,
      "type" : "rectangle",
      "x" : 1420
    },
    {
      "rotation" : 0,
      "note" : "Skapa pil mellan två former via gummibands-drag.\n\nÅtkomst: Long-press på form → drag från ConnectionHandle till en annan form.\n\nFörväntat: Pil skapas mellan from- och to-form; default direction=forward.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen test (komplex gesture)",
      "label" : "61. Connection handle drag",
      "size" : 1,
      "y" : 1740,
      "x" : 1660,
      "type" : "rectangle",
      "id" : "ui_N70",
      "showLabel" : true,
      "category" : "ui"
    },
    {
      "x" : 300,
      "rotation" : 0,
      "note" : "",
      "category" : "ui",
      "id" : "ui_N71",
      "type" : "rectangle",
      "y" : 1920,
      "label" : "Form-actions",
      "size" : 1.3999999999999999,
      "showLabel" : true
    },
    {
      "category" : "ui",
      "id" : "ui_N72",
      "x" : 700,
      "label" : "62. Dubbelklick → öppna editor ✓",
      "size" : 1,
      "note" : "Öppnar EditShapeSheet för vald form (text, stil, anteckning).\n\nÅtkomst: Dubbelklick på form (eller tap på 'Edit' i context-meny om sådan finns).\n\nFörväntat: EditShapeSheet öppnas med formens nuvarande värden.\n\nStatus sim: ✓\nStatus iPhone: \nAnteckning: V29CoverageTests testT17_DoubleTapOpensEdit",
      "y" : 1920,
      "showLabel" : true,
      "type" : "rectangle",
      "rotation" : 0
    },
    {
      "x" : 940,
      "category" : "ui",
      "y" : 1920,
      "type" : "rectangle",
      "id" : "ui_N73",
      "size" : 1,
      "note" : "Öppnar liten popup för att läsa\/redigera formens anteckning.\n\nÅtkomst: Tap på gul note-badge (om note finns) på formen.\n\nFörväntat: NoteMiniSheet öppnas över formen.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen test",
      "label" : "63. Tap på note-badge → mini-sheet",
      "rotation" : 0,
      "showLabel" : true
    },
    {
      "x" : 1180,
      "label" : "64. Collapse-badge på container",
      "showLabel" : true,
      "type" : "rectangle",
      "rotation" : 0,
      "size" : 1,
      "category" : "ui",
      "id" : "ui_N74",
      "note" : "Visar att container har dolda barn; tap visar dem igen.\n\nÅtkomst: Tap på collapse-badge under container-form.\n\nFörväntat: Container-barn visas\/döljs.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen test",
      "y" : 1920
    },
    {
      "rotation" : 0,
      "type" : "rectangle",
      "note" : "",
      "size" : 1.3999999999999999,
      "label" : "EditShapeSheet",
      "y" : 1850,
      "x" : 836,
      "id" : "ui_N75",
      "showLabel" : true,
      "category" : "ui"
    },
    {
      "y" : 2100,
      "rotation" : 0,
      "note" : "Skriv eller ändra texten som visas i formen.\n\nÅtkomst: Dubbelklick på form → TextField 'Skriv text' överst.\n\nFörväntat: Shape.label uppdateras live på canvas vid Klar\/Spara.\n\nStatus sim: ✓\nStatus iPhone: \nAnteckning: EndToEndTests testNoteTypedInEditSheetFollowsToMermaidCode",
      "size" : 1,
      "x" : 700,
      "category" : "ui",
      "type" : "rectangle",
      "id" : "ui_N76",
      "label" : "65. Redigera text (label) ✓",
      "showLabel" : true
    },
    {
      "note" : "Visa\/dölj formens label på canvas (sparas i state).\n\nÅtkomst: EditShapeSheet → Toggle 'Visa text'.\n\nFörväntat: Shape.showLabel togglas; text visas\/försvinner på formen.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test",
      "x" : 940,
      "y" : 2100,
      "category" : "ui",
      "type" : "rectangle",
      "showLabel" : true,
      "size" : 1,
      "id" : "ui_N77",
      "rotation" : 0,
      "label" : "66. Toggla 'Visa text'"
    },
    {
      "x" : 1180,
      "id" : "ui_N78",
      "rotation" : 0,
      "label" : "67. Stilväljare (segmented)",
      "type" : "rectangle",
      "category" : "ui",
      "y" : 2100,
      "size" : 1,
      "note" : "Välj textstil (Rubrik 1\/2\/3 eller Brödtext) via segmented picker.\n\nÅtkomst: EditShapeSheet → Picker 'Stil'.\n\nFörväntat: Shape.textStyle uppdateras.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Round-trip via testRoundTrip_PreservesAllShapeMetadata",
      "showLabel" : true
    },
    {
      "type" : "rectangle",
      "showLabel" : true,
      "y" : 2100,
      "note" : "Snabb-rad med L\/C\/R-justering och bullet-toggle.\n\nÅtkomst: EditShapeSheet → HStack under stilväljare.\n\nFörväntat: Shape.textAlignment och hasBullets uppdateras.\n\nStatus sim: ✓ (data)\nStatus iPhone: \nAnteckning: Via testRoundTrip_v46Fields_Preserved",
      "label" : "68. Justering + bullets (inline) ✓",
      "x" : 1420,
      "rotation" : 0,
      "id" : "ui_N79",
      "category" : "ui",
      "size" : 1
    },
    {
      "type" : "rectangle",
      "showLabel" : true,
      "label" : "69. Redigera anteckning (note) ✓",
      "size" : 1,
      "category" : "ui",
      "y" : 2100,
      "rotation" : 0,
      "note" : "Skriv en privat anteckning som inte syns direkt på canvas.\n\nÅtkomst: EditShapeSheet → TextEditor 'Skriv anteckning här'.\n\nFörväntat: Shape.note uppdateras; note-badge visas på formen.\n\nStatus sim: ✓\nStatus iPhone: \nAnteckning: EndToEndTests testNoteTypedInEditSheetFollowsToMermaidCode",
      "x" : 1660,
      "id" : "ui_N80"
    },
    {
      "type" : "rectangle",
      "x" : 1900,
      "y" : 2100,
      "showLabel" : true,
      "note" : "Radera form från canvas via en knapp i sheet:t.\n\nÅtkomst: EditShapeSheet → 'Ta bort form'-knapp → BekräftelseDialog → Bekräfta.\n\nFörväntat: Formen och dess pilar tas bort; sheet stängs.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test",
      "category" : "ui",
      "label" : "70. Ta bort form (via sheet)",
      "size" : 1,
      "rotation" : 0,
      "id" : "ui_N81"
    },
    {
      "size" : 1.3999999999999999,
      "label" : "Kant-context",
      "note" : "",
      "id" : "ui_N82",
      "y" : 2280,
      "type" : "rectangle",
      "x" : 300,
      "showLabel" : true,
      "rotation" : 0,
      "category" : "ui"
    },
    {
      "category" : "ui",
      "note" : "Visar context-meny för pil (label, direction, style, delete).\n\nÅtkomst: Tap på pil\/kant på canvas.\n\nFörväntat: Context-meny visas vid pilen.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen test",
      "type" : "rectangle",
      "x" : 700,
      "y" : 2280,
      "label" : "71. Tap på pil → context-meny",
      "size" : 1,
      "rotation" : 0,
      "id" : "ui_N83",
      "showLabel" : true
    },
    {
      "id" : "ui_N84",
      "y" : 2280,
      "category" : "ui",
      "showLabel" : true,
      "size" : 1,
      "note" : "Skriv text på en pil.\n\nÅtkomst: Tap pil → context-meny → 'Edit label' (eller dubbelklick på pil).\n\nFörväntat: EdgeLabelSheet öppnas; text sparas på kanten.\n\nStatus sim: ✓ (data)\nStatus iPhone: \nAnteckning: Round-trip via testRoundTrip_PreservesEdgeLabelsAndStyles_FullCycle",
      "label" : "72. Lägg till\/ändra etikett ✓",
      "type" : "rectangle",
      "rotation" : 0,
      "x" : 940
    },
    {
      "y" : 2280,
      "rotation" : 0,
      "x" : 1180,
      "id" : "ui_N85",
      "note" : "Välj fram-pil (→), bak-pil (←), dubbelriktad (↔) eller ingen (—).\n\nÅtkomst: Tap pil → midpoint-knapp eller context-meny → välj direction.\n\nFörväntat: EdgeConnection.direction uppdateras; pilhuvud ritas om.\n\nStatus sim: ✓ (data)\nStatus iPhone: \nAnteckning: Round-trip via testRoundTrip_EdgesWithStyles",
      "label" : "73. Ändra pil-riktning ✓",
      "category" : "ui",
      "size" : 1,
      "type" : "rectangle",
      "showLabel" : true
    },
    {
      "label" : "74. Ändra linje-stil ✓",
      "category" : "ui",
      "rotation" : 0,
      "size" : 1,
      "y" : 2280,
      "type" : "rectangle",
      "note" : "Växla mellan solid och streckad linje.\n\nÅtkomst: Tap pil → context-meny → byt style (solid\/dashed).\n\nFörväntat: EdgeConnection.style uppdateras.\n\nStatus sim: ✓ (data)\nStatus iPhone: \nAnteckning: Round-trip via testRoundTrip_EdgesWithStyles",
      "x" : 1420,
      "id" : "ui_N86",
      "showLabel" : true
    },
    {
      "label" : "75. Ta bort kant",
      "id" : "ui_N87",
      "x" : 1660,
      "y" : 2280,
      "type" : "rectangle",
      "category" : "ui",
      "showLabel" : true,
      "size" : 1,
      "note" : "Radera pilen mellan två former.\n\nÅtkomst: Tap pil → context-meny → 'Delete' (eller 'Ta bort').\n\nFörväntat: EdgeConnection raderas från modellen.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test",
      "rotation" : 0
    },
    {
      "category" : "ui",
      "size" : 1.3999999999999999,
      "rotation" : 0,
      "showLabel" : true,
      "id" : "ui_N88",
      "type" : "rectangle",
      "x" : 300,
      "note" : "",
      "label" : "Tabell-editor",
      "y" : 2460
    },
    {
      "showLabel" : true,
      "label" : "76. Öppna tabell-editor",
      "rotation" : 0,
      "category" : "ui",
      "y" : 2460,
      "note" : "Öppnar redigerings-sheet för tabell-form.\n\nÅtkomst: Dubbelklick på tabell-form på canvas.\n\nFörväntat: TableEditorSheet öppnas med rutnät av celler.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test",
      "size" : 1,
      "type" : "rectangle",
      "id" : "ui_N89",
      "x" : 700
    },
    {
      "label" : "77. Redigera tabell-cell ✓",
      "type" : "rectangle",
      "y" : 2460,
      "category" : "ui",
      "x" : 940,
      "showLabel" : true,
      "rotation" : 0,
      "note" : "Skriv text i en enskild cell.\n\nÅtkomst: Tap i cell i TableEditorSheet → skriv text.\n\nFörväntat: Cell uppdateras; sparas när sheet:t stängs.\n\nStatus sim: ✓ (data)\nStatus iPhone: \nAnteckning: Round-trip via testRoundTrip_v46Fields_Preserved (tableCells)",
      "size" : 1,
      "id" : "ui_N90"
    },
    {
      "type" : "rectangle",
      "category" : "ui",
      "note" : "Lägg till en ny tom rad längst ner i tabellen.\n\nÅtkomst: TableEditorSheet → 'Lägg till rad'-knapp.\n\nFörväntat: Ny rad läggs till; rutnätet växer en rad.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test",
      "x" : 1180,
      "y" : 2460,
      "id" : "ui_N91",
      "label" : "78. Lägg till rad",
      "size" : 1,
      "showLabel" : true,
      "rotation" : 0
    },
    {
      "category" : "ui",
      "type" : "rectangle",
      "rotation" : 0,
      "showLabel" : true,
      "note" : "Lägg till en ny tom kolumn till höger i tabellen.\n\nÅtkomst: TableEditorSheet → 'Lägg till kolumn'-knapp.\n\nFörväntat: Ny kolumn läggs till; rutnätet växer en kolumn.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test",
      "x" : 1420,
      "label" : "79. Lägg till kolumn",
      "size" : 1,
      "y" : 2460,
      "id" : "ui_N92"
    },
    {
      "type" : "rectangle",
      "size" : 1.3999999999999999,
      "category" : "ui",
      "x" : 300,
      "y" : 2640,
      "showLabel" : true,
      "note" : "",
      "rotation" : 0,
      "label" : "Ny canvas-sheet",
      "id" : "ui_N93"
    },
    {
      "showLabel" : true,
      "id" : "ui_N94",
      "size" : 1,
      "label" : "80. Välj 'Blank canvas'",
      "note" : "Starta tom canvas utan plattform-regler.\n\nÅtkomst: Hamburger → Ny canvas → tap 'Blank canvas'-kortet.\n\nFörväntat: Tom canvas skapas; platform = .blank.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test",
      "rotation" : 0,
      "y" : 2640,
      "x" : 700,
      "type" : "rectangle",
      "category" : "ui"
    },
    {
      "label" : "81. Välj 'Godot'",
      "y" : 2640,
      "note" : "Starta canvas med Godot-plattformsregler (iPhone-ram-overlay etc).\n\nÅtkomst: Hamburger → Ny canvas → tap 'Godot'-kortet.\n\nFörväntat: Canvas skapas; platform = .godot; specifika regler aktiveras.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test",
      "x" : 940,
      "type" : "rectangle",
      "size" : 1,
      "rotation" : 0,
      "showLabel" : true,
      "category" : "ui",
      "id" : "ui_N95"
    },
    {
      "label" : "Note-sheets",
      "size" : 1.3999999999999999,
      "x" : 300,
      "rotation" : 0,
      "note" : "",
      "showLabel" : true,
      "type" : "rectangle",
      "y" : 2820,
      "category" : "ui",
      "id" : "ui_N96"
    },
    {
      "label" : "82. NoteMiniSheet (per form)",
      "id" : "ui_N97",
      "type" : "rectangle",
      "rotation" : 0,
      "x" : 700,
      "y" : 2820,
      "size" : 1,
      "showLabel" : true,
      "note" : "Liten popup för att läsa\/skriva anteckning på en form.\n\nÅtkomst: Tap note-badge på form, eller via EditShapeSheet.\n\nFörväntat: TextEditor visas; ändringar sparas till shape.note.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test",
      "category" : "ui"
    },
    {
      "label" : "83. NotePopupSheet (alla)",
      "note" : "Sammanställning av alla labels + notes på canvas i en lista.\n\nÅtkomst: Tap chip.notepopup (pratbubbla-ikonen i shapes-raden).\n\nFörväntat: ScrollView med alla former och deras text visas.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test",
      "size" : 1,
      "rotation" : 0,
      "x" : 940,
      "category" : "ui",
      "y" : 2820,
      "id" : "ui_N98",
      "type" : "rectangle",
      "showLabel" : true
    },
    {
      "note" : "",
      "id" : "ui_N99",
      "category" : "ui",
      "rotation" : 0,
      "type" : "rectangle",
      "showLabel" : true,
      "label" : "Mermaid-export",
      "size" : 1.3999999999999999,
      "y" : 3000,
      "x" : 300
    },
    {
      "x" : 700,
      "y" : 3000,
      "rotation" : 0,
      "showLabel" : true,
      "id" : "ui_N100",
      "category" : "ui",
      "size" : 1,
      "label" : "84. Visa Mermaid-kod ✓",
      "type" : "rectangle",
      "note" : "Visar live-genererad Mermaid-syntax för aktuell canvas.\n\nÅtkomst: Hamburger → 'Visa Mermaid-kod'.\n\nFörväntat: MermaidCodeSheet öppnas; text uppdateras vid varje canvas-ändring.\n\nStatus sim: ✓\nStatus iPhone: \nAnteckning: V29CoverageTests testT22_ShowMermaidCodeMenuItemExists"
    },
    {
      "id" : "ui_N101",
      "rotation" : 0,
      "size" : 1,
      "category" : "ui",
      "note" : "Kopiera Mermaid-koden för att klistra in i Claude.ai eller mermaid.live.\n\nÅtkomst: MermaidCodeSheet → 'Kopiera'-knapp.\n\nFörväntat: Kod hamnar i urklipp; knappen visar 'Kopierad' i 1.5s.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test",
      "label" : "85. Kopiera kod till urklipp",
      "x" : 940,
      "y" : 3000,
      "showLabel" : true,
      "type" : "rectangle"
    },
    {
      "x" : 300,
      "id" : "ui_N102",
      "note" : "",
      "showLabel" : true,
      "label" : "Mermaid-import",
      "y" : 3180,
      "category" : "ui",
      "rotation" : 0,
      "type" : "rectangle",
      "size" : 1.3999999999999999
    },
    {
      "label" : "86. Steg 1: Visa mall för AI",
      "category" : "ui",
      "showLabel" : true,
      "size" : 1,
      "id" : "ui_N103",
      "x" : 700,
      "type" : "rectangle",
      "rotation" : 0,
      "note" : "Visa instruktionstext att skicka till Claude.ai så den genererar rätt Mermaid-syntax.\n\nÅtkomst: Hamburger → 'Importera Mermaid' → Steg 1.\n\nFörväntat: Mall-text visas; kan kopieras.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test",
      "y" : 3180
    },
    {
      "label" : "87. Steg 1: Kopiera mall",
      "id" : "ui_N104",
      "y" : 3180,
      "size" : 1,
      "showLabel" : true,
      "type" : "rectangle",
      "x" : 940,
      "note" : "Kopierar instruktionstexten till urklipp.\n\nÅtkomst: Steg 1 → 'Kopiera mall'-knapp.\n\nFörväntat: Mall hamnar i urklipp.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test",
      "category" : "ui",
      "rotation" : 0
    },
    {
      "type" : "rectangle",
      "id" : "ui_N105",
      "y" : 3180,
      "label" : "88. Steg 2: Klistra in Mermaid-kod",
      "category" : "ui",
      "rotation" : 0,
      "x" : 1180,
      "showLabel" : true,
      "size" : 1,
      "note" : "Klistra in AI-genererad Mermaid-kod i textfält.\n\nÅtkomst: Steg 2 → tap i TextEditor → paste från urklipp.\n\nFörväntat: Kod sparas i state; preview kan visas.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test"
    },
    {
      "label" : "89. Steg 2: Importera",
      "size" : 1,
      "note" : "Parsa Mermaid-koden och ersätt canvas med resultatet.\n\nÅtkomst: Steg 2 → 'Importera till canvas'-knapp.\n\nFörväntat: CanvasModel.replaceAll() körs; canvas uppdateras; sheet stängs.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test",
      "id" : "ui_N106",
      "y" : 3180,
      "x" : 1420,
      "rotation" : 0,
      "showLabel" : true,
      "category" : "ui",
      "type" : "rectangle"
    },
    {
      "y" : 3180,
      "type" : "rectangle",
      "x" : 1660,
      "category" : "ui",
      "showLabel" : true,
      "id" : "ui_N107",
      "rotation" : 0,
      "label" : "90. Navigera mellan steg",
      "size" : 1,
      "note" : "Gå mellan steg 1 (mall) och steg 2 (klistra in).\n\nÅtkomst: Knappar 'Nästa' \/ 'Tillbaka' i sheet:t.\n\nFörväntat: Steg-vy byts; värden bevaras.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test"
    },
    {
      "type" : "rectangle",
      "label" : "Plattform-regler",
      "size" : 1.3999999999999999,
      "id" : "ui_N108",
      "y" : 3360,
      "category" : "ui",
      "showLabel" : true,
      "rotation" : 0,
      "note" : "",
      "x" : 300
    },
    {
      "label" : "91. Visa plattform-regler",
      "id" : "ui_N109",
      "showLabel" : true,
      "x" : 700,
      "size" : 1,
      "note" : "Visar markdown-formaterad regelbok för aktuell plattform (t.ex. Godot).\n\nÅtkomst: Hamburger → 'Visa regler för [plattform]'.\n\nFörväntat: PlatformRulesSheet öppnas med ScrollView.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test",
      "y" : 3360,
      "category" : "ui",
      "type" : "rectangle",
      "rotation" : 0
    },
    {
      "note" : "",
      "label" : "Färgväljare",
      "type" : "rectangle",
      "size" : 1.3999999999999999,
      "id" : "ui_N110",
      "y" : 3540,
      "showLabel" : true,
      "rotation" : 0,
      "x" : 300,
      "category" : "ui"
    },
    {
      "note" : "Välj en specifik färg-override för en form (8 fördefinierade).\n\nÅtkomst: Långpress eller meny-val på form → ColorPickerPopover.\n\nFörväntat: Grid med 8 färger visas; vald sätter colorOverride.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test",
      "size" : 1,
      "category" : "ui",
      "type" : "rectangle",
      "x" : 700,
      "id" : "ui_N111",
      "y" : 3540,
      "showLabel" : true,
      "label" : "92. ColorPickerPopover – välj färg",
      "rotation" : 0
    },
    {
      "showLabel" : true,
      "rotation" : 0,
      "id" : "ui_N112",
      "x" : 940,
      "size" : 1,
      "category" : "ui",
      "y" : 3540,
      "note" : "Ta bort form-specifik färg så att kategori-paket används.\n\nÅtkomst: ColorPickerPopover → 'Använd kategori-färg'-knapp.\n\nFörväntat: colorOverride blir nil; formen visar paketets färg.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test",
      "label" : "93. ColorPickerPopover – återstä…",
      "type" : "rectangle"
    },
    {
      "showLabel" : true,
      "note" : "Välj färgpaket (7 paket: UI, Roadmap, Arkitektur, Flow + 2 + ingen).\n\nÅtkomst: Toolbar.colors → tap färgcirkel.\n\nFörväntat: colorPackId uppdateras; form-utseende ändras direkt.\n\nStatus sim: ✓ (data)\nStatus iPhone: \nAnteckning: Round-trip via testGenerator_ColorPack",
      "size" : 1,
      "type" : "rectangle",
      "label" : "94. ColorPackPopover – välj paket ✓",
      "id" : "ui_N113",
      "x" : 1180,
      "y" : 3540,
      "rotation" : 0,
      "category" : "ui"
    },
    {
      "y" : 3720,
      "size" : 1.3999999999999999,
      "category" : "ui",
      "showLabel" : true,
      "note" : "",
      "id" : "ui_N114",
      "x" : 300,
      "label" : "Canvas – auto",
      "type" : "rectangle",
      "rotation" : 0
    },
    {
      "x" : 700,
      "showLabel" : true,
      "y" : 3720,
      "label" : "95. Automatisk canvas-expansion ✓",
      "type" : "rectangle",
      "note" : "Canvas växer automatiskt när form dras nära kanten.\n\nÅtkomst: Drag form mot canvas-kant (inom 50pt marginal).\n\nFörväntat: Canvas-storlek växer; viewport scrollar med.\n\nStatus sim: ✓\nStatus iPhone: \nAnteckning: V27FeatureTests testCircleLandsNearCanvasEdge",
      "id" : "ui_N115",
      "category" : "ui",
      "rotation" : 0,
      "size" : 1
    },
    {
      "x" : 940,
      "size" : 1,
      "showLabel" : true,
      "note" : "Viewport panorerar långsamt när form dras mot viewport-kant.\n\nÅtkomst: Drag form mot synligt kant-område.\n\nFörväntat: Viewport glider långsamt för att följa formen.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Svår att testa automated",
      "id" : "ui_N116",
      "type" : "rectangle",
      "label" : "96. Auto-scroll under drag",
      "category" : "ui",
      "rotation" : 0,
      "y" : 3720
    },
    {
      "rotation" : 0,
      "showLabel" : true,
      "note" : "Om någon annan ändrar canvas-filen i iCloud uppdateras vyn live.\n\nÅtkomst: Spara extern Mermaid-MD i iCloud-mappen.\n\nFörväntat: Canvas läses om automatiskt (NSFilePresenter).\n\nStatus sim: —\nStatus iPhone: \nAnteckning: NSFilePresenter ej testad i sim",
      "size" : 1,
      "y" : 3720,
      "type" : "rectangle",
      "id" : "ui_N117",
      "x" : 1180,
      "label" : "97. Live update vid externa ändr…",
      "category" : "ui"
    },
    {
      "label" : "FreeLine-specifik",
      "y" : 3900,
      "note" : "",
      "id" : "ui_N118",
      "type" : "rectangle",
      "category" : "ui",
      "showLabel" : true,
      "x" : 300,
      "size" : 1.3999999999999999,
      "rotation" : 0
    },
    {
      "x" : 700,
      "type" : "rectangle",
      "note" : "Förläng\/förkorta\/rotera en fri linje genom att dra dess ände.\n\nÅtkomst: Tap linje → drag på endpoint-handtag.\n\nFörväntat: Shape.lineEnd uppdateras; linje följer.\n\nStatus sim: ✓ (data)\nStatus iPhone: \nAnteckning: Round-trip via testRoundTrip_LineEnd_Preserved",
      "id" : "ui_N119",
      "label" : "98. Drag linje-slutpunkt ✓",
      "category" : "ui",
      "y" : 3900,
      "showLabel" : true,
      "rotation" : 0,
      "size" : 1
    },
    {
      "y" : 4080,
      "showLabel" : true,
      "x" : 300,
      "rotation" : 0,
      "note" : "",
      "size" : 1.3999999999999999,
      "label" : "Container",
      "id" : "ui_N120",
      "type" : "rectangle",
      "category" : "ui"
    },
    {
      "category" : "ui",
      "id" : "ui_N121",
      "type" : "rectangle",
      "label" : "99. Dra form in i container",
      "rotation" : 0,
      "y" : 4080,
      "showLabel" : true,
      "size" : 1,
      "x" : 700,
      "note" : "När en form släpps inom en container blir den container-barn.\n\nÅtkomst: Drag form till position inom container-rektangel.\n\nFörväntat: Form blir barn till container; följer med när container flyttas.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test"
    },
    {
      "rotation" : 0,
      "x" : 940,
      "y" : 4080,
      "note" : "När container flyttas följer alla dess barn-former med automatiskt.\n\nÅtkomst: Drag på container-form.\n\nFörväntat: Container + alla barn flyttas tillsammans.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test",
      "label" : "100. Dra container → barn följer …",
      "id" : "ui_N122",
      "category" : "ui",
      "size" : 1,
      "showLabel" : true,
      "type" : "rectangle"
    },
    {
      "id" : "ui_N123",
      "showLabel" : true,
      "category" : "ui",
      "label" : "101. Resize container → barn skal…",
      "type" : "rectangle",
      "y" : 4080,
      "x" : 1180,
      "rotation" : 0,
      "size" : 1,
      "note" : "När container skalas påverkas inte barn-formers storlek.\n\nÅtkomst: Drag på containerns resize-handtag.\n\nFörväntat: Endast containerns dimensioner ändras; barn behåller sina storlekar.\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen UI-test"
    },
    {
      "note" : "",
      "id" : "ui_N124",
      "showLabel" : true,
      "y" : 4260,
      "size" : 1.3999999999999999,
      "rotation" : 0,
      "label" : "Canvas – snap",
      "category" : "ui",
      "x" : 300,
      "type" : "rectangle"
    },
    {
      "id" : "ui_N125",
      "label" : "102. Dot-grid bakgrund ✓",
      "category" : "ui",
      "type" : "rectangle",
      "showLabel" : true,
      "rotation" : 0,
      "x" : 700,
      "note" : "Visar prick-rutnät som visuell guide.\n\nÅtkomst: Alltid synlig som bakgrund (DotGridBackground).\n\nFörväntat: Prickar med ~40pt mellanrum; rörs ej av zoom.\n\nStatus sim: ✓\nStatus iPhone: \nAnteckning: Visuell verifiering i launch-screenshot",
      "y" : 4260,
      "size" : 1
    },
    {
      "showLabel" : true,
      "x" : 300,
      "id" : "ui_N126",
      "type" : "rectangle",
      "note" : "",
      "y" : 4440,
      "label" : "Persistens",
      "category" : "ui",
      "rotation" : 0,
      "size" : 1.3999999999999999
    },
    {
      "id" : "ui_N127",
      "label" : "103. Autospara vid bakgrundning",
      "showLabel" : true,
      "rotation" : 0,
      "category" : "ui",
      "size" : 1,
      "note" : "Canvas sparas automatiskt när appen läggs i bakgrunden.\n\nÅtkomst: Tryck hem-knappen \/ app switch.\n\nFörväntat: Aktuell fil skrivs till disk (om en är öppen).\n\nStatus sim: —\nStatus iPhone: \nAnteckning: Ingen test",
      "x" : 700,
      "type" : "rectangle",
      "y" : 4440
    },
    {
      "size" : 1,
      "x" : 940,
      "category" : "ui",
      "note" : "Alla form-egenskaper bevaras vid spara → öppna (numrerad lista, indrag, tabeller, etc).\n\nÅtkomst: Spara canvas → stäng app → öppna fil.\n\nFörväntat: Alla shape-fält (label, style, textAlignment, hasBullets, hasNumberedList, indentLevel, tableCells, position, size, rotation, etc) återskapas exakt.\n\nStatus sim: ✓\nStatus iPhone: \nAnteckning: FULLT TÄCKT: V35MermaidValidationTests + RoundTripTests",
      "y" : 4440,
      "id" : "ui_N128",
      "label" : "104. Round-trip av alla form-fält ✓",
      "type" : "rectangle",
      "showLabel" : true,
      "rotation" : 0
    }
  ],
  "shapePacks" : [
    "basic"
  ],
  "edges" : [
    {
      "style" : "dashed",
      "from" : "ui_N0",
      "to" : "ui_N1",
      "direction" : "forward",
      "label" : ""
    },
    {
      "to" : "ui_N9",
      "label" : "",
      "from" : "ui_N0",
      "direction" : "forward",
      "style" : "dashed"
    },
    {
      "style" : "dashed",
      "from" : "ui_N0",
      "direction" : "forward",
      "to" : "ui_N19",
      "label" : ""
    },
    {
      "style" : "dashed",
      "label" : "",
      "direction" : "forward",
      "from" : "ui_N0",
      "to" : "ui_N31"
    },
    {
      "style" : "dashed",
      "direction" : "forward",
      "label" : "",
      "from" : "ui_N0",
      "to" : "ui_N36"
    },
    {
      "to" : "ui_N39",
      "direction" : "forward",
      "label" : "",
      "style" : "dashed",
      "from" : "ui_N0"
    },
    {
      "style" : "dashed",
      "direction" : "forward",
      "from" : "ui_N0",
      "to" : "ui_N49",
      "label" : ""
    },
    {
      "label" : "",
      "from" : "ui_N0",
      "to" : "ui_N55",
      "style" : "dashed",
      "direction" : "forward"
    },
    {
      "direction" : "forward",
      "label" : "",
      "style" : "dashed",
      "from" : "ui_N0",
      "to" : "ui_N65"
    },
    {
      "to" : "ui_N71",
      "label" : "",
      "style" : "dashed",
      "direction" : "forward",
      "from" : "ui_N0"
    },
    {
      "label" : "",
      "to" : "ui_N75",
      "style" : "dashed",
      "from" : "ui_N0",
      "direction" : "forward"
    },
    {
      "direction" : "forward",
      "label" : "",
      "style" : "dashed",
      "to" : "ui_N82",
      "from" : "ui_N0"
    },
    {
      "direction" : "forward",
      "from" : "ui_N0",
      "to" : "ui_N88",
      "style" : "dashed",
      "label" : ""
    },
    {
      "label" : "",
      "from" : "ui_N0",
      "to" : "ui_N93",
      "direction" : "forward",
      "style" : "dashed"
    },
    {
      "from" : "ui_N0",
      "label" : "",
      "to" : "ui_N96",
      "direction" : "forward",
      "style" : "dashed"
    },
    {
      "label" : "",
      "from" : "ui_N0",
      "direction" : "forward",
      "style" : "dashed",
      "to" : "ui_N99"
    },
    {
      "to" : "ui_N102",
      "from" : "ui_N0",
      "style" : "dashed",
      "label" : "",
      "direction" : "forward"
    },
    {
      "label" : "",
      "from" : "ui_N0",
      "style" : "dashed",
      "to" : "ui_N108",
      "direction" : "forward"
    },
    {
      "label" : "",
      "to" : "ui_N110",
      "from" : "ui_N0",
      "style" : "dashed",
      "direction" : "forward"
    },
    {
      "from" : "ui_N0",
      "to" : "ui_N114",
      "label" : "",
      "direction" : "forward",
      "style" : "dashed"
    },
    {
      "style" : "dashed",
      "label" : "",
      "from" : "ui_N0",
      "to" : "ui_N118",
      "direction" : "forward"
    },
    {
      "style" : "dashed",
      "label" : "",
      "to" : "ui_N120",
      "from" : "ui_N0",
      "direction" : "forward"
    },
    {
      "to" : "ui_N124",
      "label" : "",
      "direction" : "forward",
      "style" : "dashed",
      "from" : "ui_N0"
    },
    {
      "to" : "ui_N126",
      "from" : "ui_N0",
      "direction" : "forward",
      "label" : "",
      "style" : "dashed"
    },
    {
      "to" : "ui_N2",
      "direction" : "forward",
      "style" : "solid",
      "label" : "",
      "from" : "ui_N1"
    },
    {
      "style" : "solid",
      "from" : "ui_N1",
      "label" : "",
      "to" : "ui_N3",
      "direction" : "forward"
    },
    {
      "direction" : "forward",
      "style" : "solid",
      "from" : "ui_N1",
      "to" : "ui_N4",
      "label" : ""
    },
    {
      "label" : "",
      "from" : "ui_N1",
      "direction" : "forward",
      "to" : "ui_N5",
      "style" : "solid"
    },
    {
      "from" : "ui_N1",
      "to" : "ui_N6",
      "label" : "",
      "style" : "solid",
      "direction" : "forward"
    },
    {
      "label" : "",
      "direction" : "forward",
      "to" : "ui_N7",
      "style" : "solid",
      "from" : "ui_N1"
    },
    {
      "style" : "solid",
      "to" : "ui_N8",
      "direction" : "forward",
      "label" : "",
      "from" : "ui_N1"
    },
    {
      "style" : "solid",
      "label" : "",
      "from" : "ui_N9",
      "to" : "ui_N10",
      "direction" : "forward"
    },
    {
      "from" : "ui_N9",
      "label" : "",
      "style" : "solid",
      "to" : "ui_N11",
      "direction" : "forward"
    },
    {
      "from" : "ui_N9",
      "label" : "",
      "direction" : "forward",
      "style" : "solid",
      "to" : "ui_N12"
    },
    {
      "label" : "",
      "to" : "ui_N13",
      "from" : "ui_N9",
      "style" : "solid",
      "direction" : "forward"
    },
    {
      "direction" : "forward",
      "from" : "ui_N9",
      "to" : "ui_N14",
      "label" : "",
      "style" : "solid"
    },
    {
      "from" : "ui_N9",
      "to" : "ui_N15",
      "label" : "",
      "style" : "solid",
      "direction" : "forward"
    },
    {
      "label" : "",
      "direction" : "forward",
      "style" : "solid",
      "to" : "ui_N16",
      "from" : "ui_N9"
    },
    {
      "from" : "ui_N9",
      "to" : "ui_N17",
      "label" : "",
      "direction" : "forward",
      "style" : "solid"
    },
    {
      "label" : "",
      "direction" : "forward",
      "from" : "ui_N9",
      "style" : "solid",
      "to" : "ui_N18"
    },
    {
      "to" : "ui_N20",
      "direction" : "forward",
      "label" : "",
      "from" : "ui_N19",
      "style" : "solid"
    },
    {
      "to" : "ui_N21",
      "label" : "",
      "direction" : "forward",
      "from" : "ui_N19",
      "style" : "solid"
    },
    {
      "label" : "",
      "direction" : "forward",
      "style" : "solid",
      "from" : "ui_N19",
      "to" : "ui_N22"
    },
    {
      "to" : "ui_N23",
      "label" : "",
      "direction" : "forward",
      "from" : "ui_N19",
      "style" : "solid"
    },
    {
      "direction" : "forward",
      "label" : "",
      "to" : "ui_N24",
      "from" : "ui_N19",
      "style" : "solid"
    },
    {
      "to" : "ui_N25",
      "from" : "ui_N19",
      "direction" : "forward",
      "style" : "solid",
      "label" : ""
    },
    {
      "from" : "ui_N19",
      "label" : "",
      "to" : "ui_N26",
      "direction" : "forward",
      "style" : "solid"
    },
    {
      "from" : "ui_N19",
      "to" : "ui_N27",
      "direction" : "forward",
      "style" : "solid",
      "label" : ""
    },
    {
      "to" : "ui_N28",
      "from" : "ui_N19",
      "label" : "",
      "direction" : "forward",
      "style" : "solid"
    },
    {
      "label" : "",
      "direction" : "forward",
      "style" : "solid",
      "from" : "ui_N19",
      "to" : "ui_N29"
    },
    {
      "to" : "ui_N30",
      "from" : "ui_N19",
      "style" : "solid",
      "label" : "",
      "direction" : "forward"
    },
    {
      "to" : "ui_N32",
      "style" : "solid",
      "direction" : "forward",
      "from" : "ui_N31",
      "label" : ""
    },
    {
      "from" : "ui_N31",
      "label" : "",
      "style" : "solid",
      "to" : "ui_N33",
      "direction" : "forward"
    },
    {
      "label" : "",
      "from" : "ui_N31",
      "to" : "ui_N34",
      "direction" : "forward",
      "style" : "solid"
    },
    {
      "from" : "ui_N31",
      "label" : "",
      "direction" : "forward",
      "style" : "solid",
      "to" : "ui_N35"
    },
    {
      "from" : "ui_N36",
      "style" : "solid",
      "label" : "",
      "to" : "ui_N37",
      "direction" : "forward"
    },
    {
      "from" : "ui_N36",
      "to" : "ui_N38",
      "direction" : "forward",
      "style" : "solid",
      "label" : ""
    },
    {
      "to" : "ui_N40",
      "style" : "solid",
      "direction" : "forward",
      "from" : "ui_N39",
      "label" : ""
    },
    {
      "to" : "ui_N41",
      "style" : "solid",
      "waypoints" : [
        {
          "x" : 1219.5175862865656,
          "y" : 958.82620870986318
        }
      ],
      "from" : "ui_N39",
      "label" : "",
      "direction" : "forward"
    },
    {
      "to" : "ui_N42",
      "label" : "",
      "from" : "ui_N39",
      "direction" : "forward",
      "style" : "solid"
    },
    {
      "from" : "ui_N39",
      "to" : "ui_N43",
      "direction" : "forward",
      "style" : "solid",
      "label" : ""
    },
    {
      "direction" : "forward",
      "label" : "",
      "to" : "ui_N44",
      "from" : "ui_N39",
      "style" : "solid"
    },
    {
      "style" : "solid",
      "from" : "ui_N39",
      "to" : "ui_N45",
      "label" : "",
      "direction" : "forward"
    },
    {
      "label" : "",
      "style" : "solid",
      "direction" : "forward",
      "from" : "ui_N39",
      "to" : "ui_N46"
    },
    {
      "style" : "solid",
      "to" : "ui_N47",
      "label" : "",
      "direction" : "forward",
      "from" : "ui_N39"
    },
    {
      "label" : "",
      "style" : "solid",
      "to" : "ui_N48",
      "direction" : "forward",
      "from" : "ui_N39"
    },
    {
      "from" : "ui_N49",
      "to" : "ui_N50",
      "label" : "",
      "direction" : "forward",
      "style" : "solid"
    },
    {
      "label" : "",
      "to" : "ui_N51",
      "direction" : "forward",
      "from" : "ui_N49",
      "style" : "solid"
    },
    {
      "from" : "ui_N49",
      "to" : "ui_N52",
      "label" : "",
      "style" : "solid",
      "direction" : "forward"
    },
    {
      "to" : "ui_N53",
      "style" : "solid",
      "direction" : "forward",
      "from" : "ui_N49",
      "label" : ""
    },
    {
      "to" : "ui_N54",
      "direction" : "forward",
      "style" : "solid",
      "from" : "ui_N49",
      "label" : ""
    },
    {
      "to" : "ui_N56",
      "label" : "",
      "style" : "solid",
      "direction" : "forward",
      "from" : "ui_N55"
    },
    {
      "from" : "ui_N55",
      "to" : "ui_N57",
      "label" : "",
      "direction" : "forward",
      "style" : "solid"
    },
    {
      "to" : "ui_N58",
      "style" : "solid",
      "from" : "ui_N55",
      "label" : "",
      "direction" : "forward"
    },
    {
      "from" : "ui_N55",
      "direction" : "forward",
      "style" : "solid",
      "label" : "",
      "to" : "ui_N59"
    },
    {
      "to" : "ui_N60",
      "from" : "ui_N55",
      "label" : "",
      "direction" : "forward",
      "style" : "solid"
    },
    {
      "from" : "ui_N55",
      "style" : "solid",
      "to" : "ui_N61",
      "label" : "",
      "direction" : "forward"
    },
    {
      "to" : "ui_N62",
      "direction" : "forward",
      "label" : "",
      "style" : "solid",
      "from" : "ui_N55"
    },
    {
      "direction" : "forward",
      "to" : "ui_N63",
      "style" : "solid",
      "label" : "",
      "from" : "ui_N55"
    },
    {
      "from" : "ui_N55",
      "to" : "ui_N64",
      "direction" : "forward",
      "label" : "",
      "style" : "solid"
    },
    {
      "to" : "ui_N66",
      "from" : "ui_N65",
      "label" : "",
      "direction" : "forward",
      "style" : "solid"
    },
    {
      "from" : "ui_N65",
      "style" : "solid",
      "label" : "",
      "direction" : "forward",
      "to" : "ui_N67"
    },
    {
      "label" : "",
      "style" : "solid",
      "to" : "ui_N68",
      "from" : "ui_N65",
      "direction" : "forward"
    },
    {
      "direction" : "forward",
      "label" : "",
      "from" : "ui_N65",
      "to" : "ui_N69",
      "style" : "solid"
    },
    {
      "direction" : "forward",
      "from" : "ui_N65",
      "label" : "",
      "to" : "ui_N70",
      "style" : "solid"
    },
    {
      "direction" : "forward",
      "style" : "solid",
      "from" : "ui_N71",
      "label" : "",
      "to" : "ui_N72"
    },
    {
      "direction" : "forward",
      "to" : "ui_N73",
      "label" : "",
      "from" : "ui_N71",
      "style" : "solid"
    },
    {
      "to" : "ui_N74",
      "label" : "",
      "direction" : "forward",
      "style" : "solid",
      "from" : "ui_N71"
    },
    {
      "label" : "",
      "from" : "ui_N75",
      "to" : "ui_N76",
      "direction" : "forward",
      "style" : "solid"
    },
    {
      "from" : "ui_N75",
      "label" : "",
      "style" : "solid",
      "direction" : "forward",
      "to" : "ui_N77"
    },
    {
      "from" : "ui_N75",
      "direction" : "forward",
      "label" : "",
      "to" : "ui_N78",
      "style" : "solid"
    },
    {
      "from" : "ui_N75",
      "direction" : "forward",
      "to" : "ui_N79",
      "label" : "",
      "style" : "solid"
    },
    {
      "to" : "ui_N80",
      "direction" : "forward",
      "style" : "solid",
      "label" : "",
      "from" : "ui_N75"
    },
    {
      "from" : "ui_N75",
      "to" : "ui_N81",
      "label" : "",
      "style" : "solid",
      "direction" : "forward"
    },
    {
      "from" : "ui_N82",
      "to" : "ui_N83",
      "label" : "",
      "direction" : "forward",
      "style" : "solid"
    },
    {
      "label" : "",
      "direction" : "forward",
      "style" : "solid",
      "from" : "ui_N82",
      "to" : "ui_N84"
    },
    {
      "from" : "ui_N82",
      "label" : "",
      "style" : "solid",
      "to" : "ui_N85",
      "direction" : "forward"
    },
    {
      "to" : "ui_N86",
      "direction" : "forward",
      "from" : "ui_N82",
      "style" : "solid",
      "label" : ""
    },
    {
      "label" : "",
      "style" : "solid",
      "direction" : "forward",
      "to" : "ui_N87",
      "from" : "ui_N82"
    },
    {
      "from" : "ui_N88",
      "label" : "",
      "style" : "solid",
      "direction" : "forward",
      "to" : "ui_N89"
    },
    {
      "style" : "solid",
      "to" : "ui_N90",
      "from" : "ui_N88",
      "direction" : "forward",
      "label" : ""
    },
    {
      "from" : "ui_N88",
      "direction" : "forward",
      "style" : "solid",
      "label" : "",
      "to" : "ui_N91"
    },
    {
      "from" : "ui_N88",
      "to" : "ui_N92",
      "direction" : "forward",
      "style" : "solid",
      "label" : ""
    },
    {
      "direction" : "forward",
      "style" : "solid",
      "from" : "ui_N93",
      "label" : "",
      "to" : "ui_N94"
    },
    {
      "from" : "ui_N93",
      "label" : "",
      "direction" : "forward",
      "style" : "solid",
      "to" : "ui_N95"
    },
    {
      "to" : "ui_N97",
      "style" : "solid",
      "label" : "",
      "from" : "ui_N96",
      "direction" : "forward"
    },
    {
      "from" : "ui_N96",
      "direction" : "forward",
      "style" : "solid",
      "label" : "",
      "to" : "ui_N98"
    },
    {
      "direction" : "forward",
      "style" : "solid",
      "from" : "ui_N99",
      "to" : "ui_N100",
      "label" : ""
    },
    {
      "from" : "ui_N99",
      "label" : "",
      "style" : "solid",
      "to" : "ui_N101",
      "direction" : "forward"
    },
    {
      "style" : "solid",
      "label" : "",
      "direction" : "forward",
      "from" : "ui_N102",
      "to" : "ui_N103"
    },
    {
      "style" : "solid",
      "from" : "ui_N102",
      "to" : "ui_N104",
      "direction" : "forward",
      "label" : ""
    },
    {
      "from" : "ui_N102",
      "to" : "ui_N105",
      "direction" : "forward",
      "label" : "",
      "style" : "solid"
    },
    {
      "to" : "ui_N106",
      "label" : "",
      "direction" : "forward",
      "style" : "solid",
      "from" : "ui_N102"
    },
    {
      "to" : "ui_N107",
      "label" : "",
      "style" : "solid",
      "direction" : "forward",
      "from" : "ui_N102"
    },
    {
      "direction" : "forward",
      "label" : "",
      "to" : "ui_N109",
      "from" : "ui_N108",
      "style" : "solid"
    },
    {
      "label" : "",
      "direction" : "forward",
      "style" : "solid",
      "from" : "ui_N110",
      "to" : "ui_N111"
    },
    {
      "style" : "solid",
      "to" : "ui_N112",
      "label" : "",
      "from" : "ui_N110",
      "direction" : "forward"
    },
    {
      "direction" : "forward",
      "from" : "ui_N110",
      "label" : "",
      "style" : "solid",
      "to" : "ui_N113"
    },
    {
      "label" : "",
      "to" : "ui_N115",
      "direction" : "forward",
      "style" : "solid",
      "from" : "ui_N114"
    },
    {
      "label" : "",
      "direction" : "forward",
      "from" : "ui_N114",
      "style" : "solid",
      "to" : "ui_N116"
    },
    {
      "label" : "",
      "from" : "ui_N114",
      "direction" : "forward",
      "style" : "solid",
      "to" : "ui_N117"
    },
    {
      "to" : "ui_N119",
      "label" : "",
      "direction" : "forward",
      "style" : "solid",
      "from" : "ui_N118"
    },
    {
      "direction" : "forward",
      "from" : "ui_N120",
      "to" : "ui_N121",
      "style" : "solid",
      "label" : ""
    },
    {
      "style" : "solid",
      "label" : "",
      "from" : "ui_N120",
      "direction" : "forward",
      "to" : "ui_N122"
    },
    {
      "label" : "",
      "style" : "solid",
      "to" : "ui_N123",
      "from" : "ui_N120",
      "direction" : "forward"
    },
    {
      "to" : "ui_N125",
      "from" : "ui_N124",
      "direction" : "forward",
      "label" : "",
      "style" : "solid"
    },
    {
      "from" : "ui_N126",
      "direction" : "forward",
      "label" : "",
      "to" : "ui_N127",
      "style" : "solid"
    },
    {
      "direction" : "forward",
      "label" : "",
      "style" : "solid",
      "from" : "ui_N126",
      "to" : "ui_N128"
    }
  ]
}
-->