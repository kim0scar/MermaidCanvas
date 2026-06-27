# PROJEKTPLAN — projektets lag <!-- max 100 rader · formatet FRYST · ändras bara via Revideringar -->
NU: ⏳ Milstolpe 1.4 — buggar + anteckning-pratbubbla + polish (Kims v1.3-test-feedback, plan godkänd 2026-06-27). v1.3 Fas 1 ✅ accepterad (Kim: "fantastiskt arbete" + uppföljnings-fynd → 1.4). Bygger: mörkt läge, cirkel-wrap, punktlista-syns, pratbubbla, kompakt meny+grabber, markeringsknapp, 8 numrerade färger, minus-position. Rik text (markera ord/nya storlekar/fet-kursiv) = Milstolpe 1.5. n8n + M4 PAUSADE.
[grundappen MB: █████████░] V79-svep byggt · 💡 Idébanken: 12 fångade, 3 byggda
SENAST KLART: Steg 14 ✅ (2026-06-14) — Skill Protocol Export v1: schema + referens-.skill.md + främmande-kontext-test PASS + audit
MÅL: Mermaid-koden ÄR skillen. Kim ritar → Claude kompilerar → körningen bevisar sig själv.

## Milstolpe M1 — exportkedjan bevisad ✅ 🎉 (2026-06-10, se 🎉-listan)

## Milstolpe M2 — exporten självbärande + appen testad på riktigt
En exporterad skill-fil ska fungera på VILKEN Claude Code som helst (kontrakt + legend
inbäddat), skill-containern får namn + kedjenummer, och Claude kör appen själv
(UI-test + skärmdumpar) — gör exporten själv och städar UI:t Apple-snyggt.

## Steg  (☐ ej påbörjad · ⏳ PÅGÅR, max 1 · ✅ klar · ✂ struken)

### ✅ Steg 6 — Portabelt export-format (bevis för hand)
Skriv EXPORT-KONTRAKT.md (frusen standardtext) + bygg en portabel testfil för hand.
Klart när: en agent UTAN skills och UTAN projekt kör filen och får samma resultat som flode-körningen.
Kräver: —

### ✅ Steg 7 — Skill-nummer + round-trip i appen
skillNumber i modellen, "%% skill-nr"-kommentar, state-JSON, parser-fix (subgraph-kategori), fält i redigeringen.
Klart när: unit-tester gröna för round-trip via state-JSON OCH via ren mermaid.
Kräver: Steg 6 ✅

### ✅ Steg 8 — Portabel export i appen
SkillFileComposer: "Spara skill som fil" bäddar in kontraktet + legend + skill-frontmatter.
Klart när: composer-test grönt och den exporterade filen parsas tillbaka till samma flöde.
Kräver: Steg 7 ✅

### ✅ Steg 9 — Claude kör appen själv (UI-test + skärmdumpar)
Driv appen i simulator: gör exporten själv via UI:t, granska containrar/ikoner/helhet, fixa det röriga.
Klart när: export-fil skapad AV APPEN är verifierat portabel + före/efter-skärmdumpar visade för Kim.
Kräver: Steg 8 ✅

### ⏳ Steg 10 — Deploy v74 + Kims ögon
Deploya till iPhone enligt VERSIONSHANTERING.md.
Klart när: Kim ser skill-containern, gör en export och säger "klart" på iPhone.
Kräver: Steg 9 ✅

### ⏳ Steg 11 — demo-skill-3-subagents (vokabulärsbeviset)
Ny ritning: input → script → två subagents (tool = metadata i prompten) → egna filer → gap-agent (läser bara filerna) → gate → resultatfil/manual → output. Inget app-bygge, ingen MFP.
Klart när: filen öppnas i appen + exporteras med Spara skill som fil (Kims bock); exporten har legend/kontrakt; främmande Claude förstår subagent som egen nodtyp; RUN_REPORT ren.
Kräver: Steg 8 ✅

### ✅ Steg 12 — Revisionssäkra demo-skill-3 (run_id + manifest)
Varje körning får unik run_id under runs/<run_id>/ med run_manifest.md (input, status, aktiv outputfil, gateutfall); latest/ pekar på senaste; PASS-run utan aktiv manual, FAIL-run utan resultat.md.
Klart när: FAIL-run har manual_review.md utan aktiv resultat.md; PASS-run tvärtom; latest/run_manifest.md pekar rätt; ingen gammal fil kan misstolkas som aktiv; RUN_REPORT uppdaterad.
Kräver: Steg 11 (maskindel) ✅

### ✅ Steg 13 — Run-hygiene-validator (scripts/validate_run_hygiene.py)
Python-validator kontrollerar varje run: manifest-fält, PASS/FAIL-regler, fillista, latest-pekare, ren rot, gateutfall mot gap_analys.md; rapport i validation_report.md.
Klart när: validatorn ger PASS för båda runs + latest; arkivet markerat inaktivt; RUN_REPORT uppdaterad med att validatorn passerar.
Kräver: Steg 12 ✅

## Milstolpe M3 — Skill Protocol Export v1 (definiera + testa formatet INNAN app-kod)
Princip: form → node contract → Mermaid + Skill Protocol. Mermaid = visuell vy, YAML node/edge contracts = exekverbar spec, prompten bär inte all logik. Ingen app-kod/UI/datamodell; demo-skill-3 skrivs aldrig över — nya filer bredvid.

### ✅ Steg 14 — Skill Protocol Export v1 (normativt schema + handskrivet referensprotokoll + test + audit)
Klart när (Kims kriterier): (1) SKILL_PROTOCOL_SCHEMA.md finns + är normativt (MUST/SHOULD/MAY); (2) demo-skill-3-subagents.skill.md följer schemat + är självbärande; (3) filen ensam räcker för noder/edges/run-mapp/manifest/gate/output/validatorregler; (4) främmande Claude Code dry-runar utan lokala projektfiler; (5) demo-skill-3/skill_protocol_audit.md visar PASS/FAIL per kriterium + gap innan app-kod ändras.
Kräver: M2-maskinarbetet ✅ (steg 10+11 = Kims bockar kvar; M3 är spec-only, rör inte appen).

## Milstolpe MA — Omstrukturering & verktyg (arkitektur-spår, parallellt med produkt-M4)
Behåll kärnan, bygg om STEGVIS. Tre spår: C (Claude ser appen i sim) → B (maskinellt tvingad arkitektur) → A (skyddsnät + bryt monoliterna < 300 rader). Granulära delsteg: ~/.claude/plans/jag-vill-att-du-peaceful-whistle.md.

### ✅ Steg 15 — Spår C: "se-appen"-loop (simulator)
Claude bygger/startar sim, tar egen skärmbild, läser UI + trycker/drar; state-dump (-uitest-dump-state) + skill se-appen. Demonstrerat: scenario 08/17, tap diamant, läst dump. (Kims egen "titta på appen"-bock kvarstår som trevlig bekräftelse.)

### ✅ Steg 16 — Spår B: maskinellt tvingad arkitektur
ARKITEKTUR-REGLER.md + scripts/arch-check.py + baseline + pre-commit-hook + version-sync. Grön mot nuvarande kod; injektionstestat (grow-monolit/SwiftUI-i-Mermaid/View-i-Model blockeras alla); byggd bundle = 1.77.0/77.

### ✅ Steg 17 — Spår A: skyddsnät + bryt monoliterna
Skyddsnät: A0 Equatable + A1 djup round-trip + A2 per-fält-symmetri + A3 CanvasModel-spec (36 tester). Dekomposition KLAR — alla fyra monoliter < 300 rader: CanvasView 1781→297 (EdgeGeometry/EdgeDrawing/EdgeMidpointHandle/EdgesView + CanvasView+Helpers), ToolbarView 1069→237 (6 extension-rader), ContentView 691→225 (+Files/+Sheets), CanvasModel 857→56 (7 ansvars-extensions, @Published-fasad kvar). WIP=1, varje steg verifierat (171 tester + se-appen + arch-check ratchet).
Klart: alla fyra filer < 300 ✅, hela testsviten grön ✅, arch-check grön ✅, sim visar oförändrad canvas + add/undo ✅.
Kräver: Steg 15 ✅ + Steg 16 ✅

## Milstolpe MB — Grundappen sitter (basen solid INNAN vidare bygge · Kims order 2026-06-18)
n8n + M4 pausade. Bygg enligt arkitektur-metoden (tester + arch-grind gröna, se-appen, Kims iPhone-bock för gester). WIP=1.
- ✅ Steg 0 — Städa roten: HANDOVER v50.7, BUGSVEP-v60, GAP-ANALYS-v61, UI-PLACERINGS-FYND-v49, v47.xlsx → arkiv/ (git mv, historik bevarad). Inga lösa version-fynd i roten; bygg+arch-check oförändrat.
- ⏳ Steg 1 — Kontroll-genomgång av HELA UI-ytan (breddat från UX-111–122) enligt Metoder/KONTROLL-GENOMGANG.md: 4 dim (Me/UI/Ber/Plats) per funktion, sub-agents + adversariell verifiering. Klart: FUNKTIONSKarta ifylld (maskin-bockar + bevis) + KONTROLL-FYND.md + fynd fixade i WIP=1; UI-känsla/relevans = Kims iPhone-bock.
- ☐ Steg 2 — UX-111 pan-stölden: större träffyta på pilhandtag + "hoppa till innehåll". Klart: Kim bekräftar på iPhone att drag nära handtag inte panorerar bort allt.
- ☐ Steg 3 — UX-112: klampa handtag (resize/rotate/connection) till synlig yta. Klart: Kim når alla handtag på iPhone.
- ☐ Steg 4 — UX-113: pålitlig dubbeltapp → Redigera + text-ledtråd i tomt-läge. Klart: Kim öppnar Redigera med dubbeltapp reproducerbart.
- ☐ Steg 5 — UX-114: a11y-labels på allt interaktivt + textstil-knappar in i vy + Klar/Stäng/Kopiera nåbara. Klart: ux-driver ser alla knappar + de är tappbara.
- ✅ Steg 6 — Round-trip-härdning (Kims tre figurer): tabell (typ+celler), jump-länk (typ) och kollaps överlever REN mermaid via osynliga `%%`-rader (shape-type + table-cells). 3 nya fallback-tester gröna (175 totalt). KVAR (mindre, senare): waypoints i fallback + stabila nod-ID:n.
- ✅ Steg 7 — Mermaid-validering (FÖRST, Kims order "bygg allt nu"): fräscht facit (2 agenter) → MERMAID-FAKTA.md sekt. K + maskinell grind som kör appens mermaid genom officiella mermaid.parse (scripts/mermaid-conformance.mjs + korpus-test + extract-skript) + pre-commit + regel 3/14. Bevis: 2/2 fixtures = flowchart-v2, injicerat fel → exit 1, 177 tester gröna, arch-check grön, pre-commit körde grinden live vid commit a171dfa.
- ✅ Steg F — Noll-avvikelse-garantin (Kims order, FÖRST). KLAR (commits 3114384, b5e33fe + putts): exakt Double-position; 5 former + textjust/listor/waypoints + container-note/style i ren mermaid; clamp BORT (Kims beslut "filen är sanningen" — extremvärden round-trippar exakt); round-trip-grind maskinell i pre-commit + deploy; CLAUDE.md regel 3 omskriven (a/b/c + Apple-robust + metodiskt-genom-former); MERMAID-FAKTA sektion L (två-lager + KAN-INTE) + chmod 444. Bevis: 186 tester gröna, 3/3 fixtures flowchart-v2, 2 agent-par hittade 2 luckor (clamp + container-style) → tätade + re-verifierade "stängda, inga nya fel". KVAR pre-existerande (parkerat 💡#7): nästlad container tappar förälder-länk i REN mermaid (state-JSON OK).
- ✅ Steg G — Metodisk form-genomgång + Kims feedback: G2 ✅ (basfigur-polish — triangel/romb text-inset, länk bär kategori-färg, tabell-text ovanpå grid, Pill/Rektangel/Kvadrat åtskilda; 6 snapshots om-inspelade). G1 ✅ (EXTENDED-FORMAT.md = komplett app-only-spec + `%% canvas-size` round-trippar nu i REN mermaid (enda fält som tappades) + reserverade nycklar 💡#6/#7 + wire CLAUDE.md; 187 tester gröna). steg 8 del 2 + steg 9 byggs härnäst. Kims iPhone-bock på formerna kvarstår vid deploy.
- ⏳ Steg H — Export till bild (fidelity-fundament, Kims order 2026-06-19): meny "Exportera som bild" → PNG av RITADE ytan (bbox, ej hela canvasen) via SAMMA render-väg (ShapeView/EdgesView i exportläge, ingen chrome) → sparas i appen (Filer) + delningsmeny; sen renderar Claude mermaid-kroppen (playwright) och jämför ritad bild ↔ mermaid-bild ↔ mermaid-text. Klart: appen skapar PNG av ritade ytan, se-appen visar ren bild, fidelity-jämförelse körd, grind+tester gröna, Kims iPhone-bock.
- ✅ Steg 8 — Skill-flöde-meny: DEL 1 ✅ (commit 17d4144). DEL 2 ✅ — container-note round-trippar (Gen:164), skill-korpus i konformitetstest (test_corpus_skillFlow), fil-glyf på canvas (2d: MD=doc.text, Excel=tablecells i ShapeRenderer, scenario 37). Allt round-trippar, 187 tester + render-grind gröna.
- ✅ Steg 9 — UI-mall: Mallar-menyn borta; iPhone 15/16 Pro som chips under UI; namn UTANPÅ ramen (skärmytan fri); bara proportionell resize (phoneFrame); device-namn round-trippar som label. **phoneFrame-som-container** ✅: `ShapeType.actsAsContainer` → former på skärmen blir barn (childOfContainerId), följer med vid flytt, round-trippar via state-JSON (test). Pure-mermaid parent-lucka = 💡#7 (visuellt bevarat). 188 tester gröna. KVAR: Kims iPhone-bock (gester) vid v82.

## Milstolpe 1.0 — skarp release (Kims order 2026-06-22)
Städa version (dubbel→ren "1.0"), klassisk Apple-ikon, fixa färgmeny-avklippning + markeringsverktyg tillbaka + snyggare paketfärger, och BEVISA två-lager-fundamentet (AI-ramverket bäddas in i export så det alltid följer med).
- ⏳ Steg 1.0 — release-svepet. ✅ DEPLOYAD 2026-06-24 (1.0 på iPhone, tagg v1.0 + ZIP, 204 tester/conformance/render gröna; embed-test + BEVIS-TVÅLAGER.md klara; EN version bekräftad). KVAR: bara Kims iPhone-bock på ikon/färgmeny/markeringsknapp-känsla.
  Kräver: MB Steg 1 (maskindelen) ✅

## Milstolpe 1.1 — total genomgång + dual-platform (Kims Goal 2026-06-24)
Tre spår: (1) TOTAL sim-driven genomgång — varje meny/val körd i simulator, UI/UX perfekt, alla beroende-streck + former funkar; (2) fritt förbättra/lägga till; (3) dual-platform: DELAD hjärna (en modul) + **macOS menyrads-popup** (klick i menyraden → canvas fälls ut, samma iCloud-filer som iPhone — Kims val "bäst kvalitet"). Inga parallella appar — en hjärna, två ansikten.
- ⏳ Del 1 — total sim-genomgång. ✅ MASKINDEL KLAR: hela UITest-sviten (126) + unit (205) körda, alla 16 ytor behavior/unit-täckta, enda riktiga fyndet (V74 inaktuellt test) fixat, V48-fel = flakighet, drill fullt unit-testad. GENOMGÅNG-FYND.md komplett. KVAR: bara **Kims iPhone-bock på pixel-känslan** (sim avgör ej känsla) — separat användar-acceptans, ej maskinellt stängbar.
- ⏳ Del 2 — dual-platform (6 faser, plan godkänd 2026-06-24): delad hjärna + macOS menyrads-popup, samma iCloud-filer. iOS grön efter varje fas. ✅ Fas 1 (abstraktioner) + ✅ Fas 2 (entré+orientering #if os; macOS MenuBarExtra i koden). ✅ Fas 3 KLAR — **macOS-targeten KOMPILERAR** (appen är dual-platform; Color+Platform.swift + PlatformModifiers.swift gjorde delade vyer cross-platform; macOS BUILD SUCCEEDED, iOS 204 gröna). Lärdom: macOS-plist måste ligga UTANFÖR Sources/ (delad-sökväg förorenade iOS-target). ✅ Fas 4 (NSScrollView-tvilling = äkta zoom/pan på Mac, riskigaste steget) — macOS BUILD SUCCEEDED. ✅ **Mac-appen KÖR i menyraden** (process verifierad, MenuBarExtra). Filöppning funkar via standard-paneler (osandlådad → når iCloud-mappen). ✅ **Fas 5+6: Mac-appen funktionellt KLAR + INSTALLERAD** i /Applications/Visuali2e.app (Release, signerad, körande i menyraden, permanent). ✅ zoom/pan · ✅ kom-ihåg-filen (menyrads-klick återöppnar senaste canvas) · ✅ användbar popup-storlek · ✅ delning (visa i Finder/kopiera sökväg) · filöppning via paneler når iCloud-mappen. ✅ **Mac-canvasen RENDERAR maskinellt bevisat** (nytt macOS-testtarget `MermaidCanvasMacTests` — formerna + parsad fil → giltig PNG på macOS via delade render-vägen). KVAR: bara **zoom/pan-KÄNSLAN på Mac** (subjektiv, kräver Kims styrplatta) + iPhone-känsla-bock. iOS grön hela vägen. Allt i CLAUDE.md spar-tabell + ARKITEKTUR-DUAL-PLATFORM.md.
  Kräver: Steg 1.0 deployad ✅

## Milstolpe 1.2 — UI/UX-städning: topprad + meny (Kims order 2026-06-24, plan godkänd)
Kim såg att topprads-ikoner klipps av kanterna → bredare städning. Mål: topprad+meny som Apple byggt den. Två låsta val: Formpaket smälter in i Former (flikar Grundformer/Paket/Mallar); marker-knapp bort → dubbelklick på tom yta. Format/bärare orörda (inga nya former). WIP=1, grön checkpoint mellan varje. Detaljplan: ~/.claude/plans/jag-vill-att-du-peaceful-whistle.md.
- ✅ Steg 1 — Zoom → ren info (behöll .isButton + diagnosticsValue, noll teständring; onResetZoom → menyrad). V27/V34 gröna.
- ✅ Steg 2 — Marker-knappen borttagen ur primärraden (+ död def städad).
- ✅ Steg 3 — Markering via dubbelklick på tom canvas (count:2 före count:1) + hint i "Börja här" + "Klar"-knapp. test30 PASS (dubbeltryck→Klar-knapp), test31 marquee PASS.
- ✅ Steg 4 — Former = ett "lägg till"-ställe (flikar Grundformer/Paket/Mallar + verktygsrad; packs-knapp + Notis-chip bort). **Overflow MASKINELLT FIXAD** (LayoutOverflowTests 2/2). V74 skill-export + test03/90 gröna (retry mot XCUITest segment-flakighet).
- ✅ Steg 5 — Meny-sektioner (Skapa/Fil/Kod&export/Visa/Om appen) + "Funktionsöversikt" + "Alla anteckningar" + Mallar-undermeny bort. Section-rubriker verifierat renderar i Menu (skärmdump). unit 205/0.
- ✅ Deploy 1.2: version 1.0→1.2, grindar gröna (conformance 3/3, render 3/3, unit 205/0), **installerad på iPhone**, tagg v1.2 + ZIP. Full svit: 1 riktigt fel (V33 version under-fold → FIXAT, version överst) + 6 flakiga/scratch (DragOut/V27/V48 passerar på omkörning, Takeover=Files-dialog, DispatchTest=scratch som startar Claude-appen). KVAR: bara **Kims iPhone-bock på känslan**.
  Kräver: Steg 1.0 deployad ✅

## Milstolpe 1.3 — Lucidchart-interaktion + redigeringsytan som fundament (Kims order 2026-06-26, plan godkänd)
Kim testade 1.2, gav 5 interaktionsfel + pekade ut redigeringsytan som appens VIKTIGASTE del (skriv direkt på canvas, två ytor, EN konsekvent meny). Designtävling (3 Plan-agenter, konvergerade). TVÅ faser; per rad = rubrik+fet+justering (Kims val). Detaljplan: ~/.claude/plans/jag-vill-att-du-peaceful-whistle.md.
- ✅ Paket A — emoji-väljare (visuellt rutnät + neutral ikon).
- ✅ fix2 — kollaps-badge i eget lager ÖVER former (z-order, Kims "döljs").
- ✅ fix3 — mål-ankare (toSide): välj inkommande sida på mål-formen; full regel-15-kedja grön.
- ✅ fix4 — orthogonal routing: lämnar/anländer vinkelrätt mot valda sidor.
- ⏳ Fas 1 (v1.3) — ren redigeringsyta (INGEN ny bärare): ✅ S1.1 aldrig-fast · ✅ S1.2 anteckning=EN väg · ✅ S1.3 EN formateringsmeny (FormattingBar i två lägen) · ✅ S1.4 audit+rensa. ✅ DEPLOYAD v1.3 (iPhone installerad+startad, tagg+ZIP, 205 unit · conformance/render 3/3 · arch · sim-bevis · git synkat). KVAR: bara Kims iPhone-bock på känslan.
- ✅ Fas 1 ACCEPTERAD: Kim testade v1.3 ("fantastiskt arbete"), gav uppföljnings-fynd → Milstolpe 1.4. (Per-rad-idén ersatt av Kims rikare önskan: markera ORD → egen färg/storlek = Milstolpe 1.5.)
  Kräver: Milstolpe 1.2 deployad ✅

## Milstolpe 1.4 — buggar + anteckning-pratbubbla + polish (Kims v1.3-test, plan godkänd 2026-06-27)
Kim testade v1.3, älskar fundamentet, gav fynd: 3 buggar + anteckning-omdesign + meny-polish. INGEN ny bärare (allt View/UI → regel 15 trivialt grön). Detaljplan: ~/.claude/plans/jag-vill-att-du-peaceful-whistle.md.
- ⏳ A1 mörkt läge: adaptiv `Color.appChipBackground`; chips/swatches syns i dark; canvas force-light kvar. Klart: dark-skärmdump, menyer syns.
- ☐ A2 cirkel-radbrytning: `case .circle` i textHorizontalInset (proportionell). Klart: lång text wrappar inuti cirkeln.
- ☐ A3 punktlista/indrag syns: FormattingBar `showListsAndIndent`-flagga (keyboard-host döljer dem, selected-bar visar). Klart: markera form → punkter syns direkt.
- ☐ B1 anteckning→pratbubbla: gul bubbla + svans + vik-ikon (ingen X), bara note-redigering direkt; NoteBadge→bubble-glyf. Klart: ser ut som elegant kommentar, viks in/ut.
- ☐ B2 visa/dölj alla anteckningar på markering (en/många → openCards). Klart: markera + "Visa/Dölj anteckningar".
- ☐ C1 kompakt FormattingBar (lists→1 ikon, justering→1 ikon, popup). C2 dra-in-grabber. C3 markeringsknapp tillbaka. C4 mindre luft.
- ☐ D1 8 numrerade färgpaket (ids stabila). D2 minus-badge ut från gröna + (radial 6→36).
- ☐ Deploy v1.4 → iPhone + Kims känsla-bock.
  Kräver: Milstolpe 1.3 deployad ✅

## Milstolpe 1.5 — rik text (markera ord → egen färg/storlek, EGEN milstolpe)
Run-baserad text (attribut per teckenintervall) + UITextView-representable-editor + visuell stil-galleri (storlekar i verklig storlek, ~40 max) + fet/kursiv/understruken. EN ny bärare (runs-JSON, `tableCells`-mönstret, full regel-15). Löser även punktlista-LIVE-medan-man-skriver. Designtävling vid 1.5-start.
- ☐ Byggs efter v1.4 + Kims bock.
  Kräver: Milstolpe 1.4 deployad

## Efter MB (pausat, Kims order) + Efter M3
- MC — n8n klar: kontrakt-synk (4 saknade noder) + n8n-paket→spec_type:flow + konformitetstest.
- M4: appen lagrar node contracts per figur + exporterar .skill.md (om auditen håller) · Styrningsregler (nivå A–D, R0–R4) · Skill 3 mfp-spec + Skill 4 dashboard · Upphandlings-paketet

## 💡 Idébanken — fångas direkt, byggs ALDRIG nu (väljs ur vid milstolpe-slut · max 15 rader)
- 2026-06-10 · 💡#1 Metoden som portabelt paket för nya projekt · BYGGD på Kims order
- 2026-06-10 · 💡#2 Ritad vy av planen i appen · BYGGD på Kims order
- 2026-06-11 · 💡#3 "Kopiera som skill" (urklipp) får också kontraktet inbäddat · väntar
- 2026-06-11 · 💡#4 Promptprotokoll v0.1 fullt ut (11 nodtypsmallar + mall-knapp i appen + MFP-omritning) · parkerad — gap-analysen klar, väntar efter steg 11
- 2026-06-13 · 💡#5 Prompt-kompilator: appen GENERERAR nod-prompten från hög-nivå-val (du slipper skriva metodtexten själv) · väntar — kärnan av "n8n för Claude Code"-visionen
- 2026-06-18 · 💡#6 UI-prototyp-lagret (Figma-lite): localPos (relativ-i-skärm), zIndex (lager fram/bak), edge route-modes + ankare/sidport + label-pos · parkerat — phoneFrame-som-container (roten) byggs riktat i steg 9; resten byggs om/när UI-mockups blir kärn-fallet
- 2026-06-20 · 💡#9 Mac-app: Catalyst-basen FINNS redan (universal; musklick + två-finger/högerklick→.contextMenu funkar). NYTT (Kim 2026-06-22): menyrads-variant (status-bar-popover) = egen liten native-macOS-target som DELAR modell/canvas-modulerna (Catalyst gör ej MenuBarExtra rent) · stort/exploratoriskt — efter 1.0
- 2026-06-20 · 💡#10 "Hoppa in" på en form (Visio-drill, en nivå djupare = en hel process bor i formen) + multi-fil-import → en container med länkar/flikar för navigering · navigerings-mönster, exploratoriskt
- 2026-06-20 · 💡#11 Edge-routing-ombyggnad (4 prickar, gå runt former ej container/iPhone, böj, 3 prickar under pil) + inline T-text-redigering på canvas + UI-färgbygg + save-state-snabbknapp · UX-polering (L), efter att kärnan satt sig
- 2026-06-19 · 💡#8 Render-trogen mermaid-grind · BYGGD på Kims val ("render-koll vid deploy"): `scripts/mermaid-render-check.mjs` (headless Chrome renderar fixturerna → fångar allt riktig mermaid kraschar på) i VERSIONSHANTERING-deploy + snabb lint mot `<--`/`<-.-` i konformitetsgrinden (pre-commit). Bevisat: fångar gamla buggen (exit 1), 3/3 fixtures renderar nu
- 2026-06-19 · 💡#7 Nästlad container (container-i-container) ska bära förälder-länk i REN mermaid (idag bara via state-JSON; `childOfContainerId` emitteras ej för containrar) · fångat i STEG F:s re-verifiering, pre-existerande Tier-2-lucka · byggs ihop med containment-arbetet (steg 9 / 💡#6)
- 2026-06-21 · 💡#12 Markdown-läsare i appen (read-only): öppna en .md (t.ex. FUNKTIONSKarta) och läsa den formaterad — rubriker + tabeller · kräver markdown-render-lib (SwiftUI-inbyggd renderar ej tabeller) = eget litet bygge + nytt beroende + scope-fråga (PRODUKT.md: appen är ritverktyg, ej dok-läsare) · väntar

## Revideringar — datum · vad · varför (en mening var · skrivs FÖRE arbetet)
- 2026-06-27 · Milstolpe 1.4 + 1.5 satta (Kims v1.3-test-feedback): Kim testade v1.3, älskade fundamentet ("fantastiskt arbete"), gav fynd → 1.4 (buggar: mörkt läge/cirkel-wrap/punktlista-syns; anteckning som elegant pratbubbla med vik-ikon + visa/dölj-alla; meny-polish: kompakt + grabber + markeringsknapp + mindre luft; 8 numrerade färger; minus-position) + 1.5 (rik text: markera ORD → egen färg/storlek, visuell stil-galleri med större rubriker, fet/kursiv/understruken — run-baserad modell + rich-editor, EN ny bärare). Tre Kim-val: mörk ram + vit rityta; visuell stil-meny; polish först (1.4) sen rik text (1.5). Designtävling (2 Explore rotorsak + 2 Plan design) → konvergens. Den gamla "per-rad"-idén ersatt av Kims rikare "markera ord"-önskan. Varför: testning på riktig iPhone avslöjade buggar + att redigeringen behöver bli ännu rikare/elegantare för att kännas Apple-grad.
- 2026-06-26 · Milstolpe 1.3 satt (Kims order): 5 interaktionsfel + redigeringsytan utpekad som appens viktigaste yta, ska bli Apple-grad. Designtävling (3 Plan-agenter → konvergens på samma fundament). TVÅ Kim-val: leverans i två steg (v1.3 städa+ena, v1.4 per-rad), per rad = rubrik+fet+justering. Emoji + 4 edge-fixar (fix2/3/4) redan committade; Fas 1 = aldrig-fast + EN anteckningsväg + EN formateringsmeny + rensa bluff-fet/död kod (ingen ny bärare → regel 15 trivialt grön); Fas 2 = individuell text per rad (EN ny bärare `line-styles`, full regel-15-kedja). Varför: Kim pekade ut "skriv direkt på canvas, två ytor, EN konsekvent meny" som det mest kritiska för användbarhet — fynd i koden: stuck-risk (isEditing avslutas bara av fokus, ej markering), anteckning har 3 divergerande vägar, menyn motsäger sig själv, bluff-fet-knapp + död kod.
- 2026-06-24 · Milstolpe 1.2 satt (Kims order efter startskärm-koll): topprad-ikoner klipps av kanterna → bredare UI/UX-städning. Kartläggning (3 Explore) + design (2 Plan-agenter) → 5 steg. Två låsta Kim-val: (1) Formpaket smälter in i Former med flikar Grundformer/Paket/Mallar; (2) marker-knapp bort → dubbelklick på tom yta + hint + Klar-knapp. Zoom→info, meny får namngivna sektioner, Notis-chip→"Alla anteckningar" i menyn. Varför: Kim vill ha en topprad+meny "som Apple byggt den" — allt synligt, tydligt grupperat, ett ställe per sak. Format/export orört (inga nya former → regel 15 ej triggad).
- 2026-06-24 · Milstolpe 1.1 satt (Kims Goal): total sim-driven genomgång av alla menyer/val + fritt förbättra + dual-platform via DELAD hjärna + macOS menyrads-popup (Kim valde "bäst kvalitet"; uttryckligt: inga parallella appar, mest delas, vill kunna trycka upp/visualisera/spara på samma plats som iPhone). Detaljplan i planläge före bygge.
- 2026-06-24 · EN enda version (Kims order "aldrig två"): AppVersion.version driver BÅDE app-etikett OCH bundle (MARKETING_VERSION = CURRENT_PROJECT_VERSION = samma nummer); bygg-räknaren vN slopad; arch-check version-sync + VERSIONSHANTERING omskrivna; tagg `v1.0`, ZIP `Visuali2e-1.0.zip`. Varför: Kim vill aldrig se två versionsnummer.
- 2026-06-22 · Milstolpe 1.0 på Kims order: ren version, klassisk Apple-ikon, färgmeny-avklippning lagas + markeringsverktyg åter i toppen + snyggare paketfärger (behåll färg-knapp separat per Kims val), OCH AI-ramverket (frameworkText) bäddas in i VARJE exportfil + maskinellt embed-test + BEVIS-TVÅLAGER.md. Varför: Kim vill ha en skarp 1.0 OCH tekniskt bevis att export/import alltid bär "vad är mermaid / vad är app-lagret" — appens fundament (gapet: spec:en låg bara bakom in-app-knappar, följde ej med filen).
- 2026-06-22 · MB Steg 1 breddat + startat på Kims /goal: kontroll-genomgång av HELA UI-ytan (ej bara UX-111–122) enligt Metoder/KONTROLL-GENOMGANG.md — sub-agents per yta, 4 dim (Me/UI/Ber/Plats), adversariell verifiering, fixa fynd i WIP=1, fråga vid vägval. Output: ifylld FUNKTIONSKarta + KONTROLL-FYND.md. Varför: Kim vill ha bevisad kontroll på att allt sitter rätt/ser rätt ut/funkar/behövs innan vidare bygge.
- 2026-06-20 · V79-FEEDBACK-SVEP på Kims /goal ("bygg klart, var innovativ, använd sub agents"): 3 scoping-agenter kartlade → byggde 7 klara features (lås+3 lager med mermaid-round-trip, redo, "Spara Mermaid inom container", beroendepil-meny i kategorier, container-fri-resize-höger, marker-flera ut ur huvudmenyn). Resten av V79-listan triagead: redan byggt (v80–83) eller idébank 💡#9–#11 (OSX-app, Visio-drill, multi-fil-import, edge-routing-ombyggnad, inline-text, UI-färgbygg — exploratoriskt/stort). Varför idébank: en-användar-linsen + risk; kärnan + lås/lager först.
- 2026-06-19 · Steg H-FYND (export+render-jämförelse i praktiken): appens bakåtpil `<--` gav "Syntax error" i RIKTIG mermaid (mermaid.live) och `<-.-` tappade pilspetsen tyst — men konformitetsgrinden (mermaid.parse) släppte igenom båda (parse ≠ render). Fixat (commit 5dc4d16): bakåtkant skrivs som omvänd framåtpil. KVAR (Kims vägval, 💡#8): grinden bör bli render-trogen så denna klass fångas maskinellt — annars kan nästa parse-men-ej-render-glapp smyga in. Detta är bokstavligen "fundamentet" Kim bad om.
- 2026-06-19 · Steg H tillagt på Kims order FÖRE resten: Export-till-bild (PNG av ritade ytan, ej hela canvasen) — dels en bild Kim kan dela, dels FUNDAMENTET för visuell fidelity-validering (ritad bild ↔ ren-mermaid-rendering ↔ mermaid-texten). G2 klart; G1 (Extended-format-doc) görs efter H. Varför Kim: "det som är ritat ska matcha exporten av mermaid OCH den faktiska mermaiden — det är ju fundamentet". Bilden återanvänder samma render-väg (ingen parallell ritkod → ingen avvikelse).
- 2026-06-18 · Strategiskt avstämt (extern AI-analys + kodgranskning): appen ÄR ett två-lager-system (Mermaid=transport + app=renderare med eget %%-tilläggslager) — bekräftar STEG F (härdar lager 2), ändrar det inte. Enda riktiga roten i UI-fallet: phoneFrame är en FORM, inte en container → skärm-innehåll hänger inte ihop logiskt. Kims vägval: (1) gör klart STEG F först (fundament); (2) RIKTAT — phoneFrame blir container i steg 9; localPos/zIndex/route-styrning → 💡#6 (ej nu). "Extended"-lagret namnges tydligt i F4 (MERMAID-FAKTA) + F5 (CLAUDE.md).
- 2026-06-18 · STEG F + G tillagda FÖRST på Kims order, FÖRE resten av steg 8: noll-avvikelse-garantin ska bevisas, tätas, institutionaliseras (skrivskyddad facit + CLAUDE.md regel 3 omskriven) och verifieras med två agent-par innan vidare bygge. Grundas på 3-agents-kodgranskning som hittade konkreta luckor: positioner avrundas (state-JSON), 5 former + textjust/listor/edge-waypoints degraderar/försvinner tyst i ren mermaid, round-trip ej maskinellt tvingad, facit ej skrivskyddad. Varför: "exakt det jag ser ska andra få + jag ska kunna rita→kopiera→radera→klistra→exakt samma, noll avvikelse" får aldrig mer bli en fråga. Steg 8 del 2 + steg 9 flyttas in i steg G (metodisk form-genomgång).
- 2026-06-18 · MB omformad på Kims order: tre nya steg FÖRST — 7 mermaid-validering (research-facit + maskinell grind mot riktig mermaid + regel), 8 Skill-flöde-meny (ersätt n8n/Prompt-Process; prompt bara på skill-former; MCP/Plugin/Fil), 9 UI-mall (iPhone 15/16 Pro under UI, namn utanpå, proportionell resize) · UX-111–114 + städa-rot flyttas EFTER. Varför: Kim vill kunna skissa skills visuellt + att inget byggs ovaliderat mot riktig mermaid; ordning Kims val (validering före bygge).
- 2026-06-18 · Omprioritering på Kims order: ny milstolpe MB "Grundappen sitter" FÖRST (fixa UX-111–114 + round-trip-härdning); n8n (MC) + M4 pausade tills basen sitter. Grundas på 3-agents-granskning (kärnan funkar, 4 blocker-buggar kvar, auditen v72 ej om-verifierad mot v79).
- 2026-06-17 · Förbättring under dekomposition: ShapeGeometry flyttad till Models/ (inte Views/Canvas/ som planen sa) · CanvasModel använde den redan → den hörde hemma i Model-lagret, inte View. ShapeView/EdgesView är själva >300 → delas internt (ShapeRenderer m.fl.) innan de flyttas, inte bara flyttas.
- 2026-06-18 · På Kims order (M4 pausad): vän-distribution — skill `visuali2e-bjorn` lägger käll-ZIP i iCloud-mappen "Versioner till Björn" (per version), Kim skickar manuellt; + `scripts/friend-setup.sh` (ett-kommando-signering) + fräschad `INSTALL-FÖR-VÄNNEN.md`. Ingen app-kod (Filer-väljaren räcker för vännens iCloud). M4 återupptas på "ja".
- 2026-06-18 · På Kims order: arkitektur-sättet destillerat till portabelt `ios-arkitektur-kit` (`~/.claude/templates/` + iCloud-ZIP) — config-driven arch-check + METOD + se-appen, för framtida iOS-appar. Utanför detta repo; MermaidCanvas egna scripts orörda (analogt med hur projektplan-metoden = 💡#1 hanterades).
- 2026-06-17 · MA startad på Kims order: granska + bygg om STEGVIS (behåll kärnan) · 3 spår C→B→A, maskinellt tvingade regler, Claude ser appen i sim · detaljplan i ~/.claude/plans/jag-vill-att-du-peaceful-whistle.md · M2/M3 Kims-bockar oberoende, WIP=1 gäller arbetssteg.
- 2026-06-10 · Planen skapad · startläge för M1.
- 2026-06-10 · 💡#1+#2 byggda direkt (mall+ZIP+intervju, ritad vy) · Kim bad explicit; rör inga M1-steg.
- 2026-06-10 · Kim beordrade "/goal bygg allt" · stegen körs i följd med maskinbevis; Kims iPhone-bockar samlas i slutkontroll.
- 2026-06-11 · Steg 11 tillagt på Kims order: vokabulärsbeviset (subagent egen nod, tool = metadata) FÖRE all MFP/app-fortsättning · demo-skill-2 har fel mönster (tool-nod i researchsteg) — rättas efter steg 11. Steg 10 ⏳ kvarstår: endast Kims bock återstår, WIP=1 gäller arbetssteg.
- 2026-06-11 · Steg 10 utökat efter Kims test: exporten hamnade osynligt i appens mapp (sandlåda) → "Spara skill som fil" får riktig Spara som-dialog; + demo-skill-2.md byggs (komplett LR-skill med verktyg + exakta in/ut-filer).
- 2026-06-11 · M2 detaljerad på Kims order · export till främmande dator + skill-container (namn+nummer, ordning i kedjan) + Claude UI-testar appen själv och städar containrarnas utseende.
- 2026-06-11 · Steg 12 tillagt på Kims order: demo-skill-3:s FAIL- och PASS-filer låg sida vid sida och motsade varandra → run_id + runs/<run_id>/ + run_manifest.md + latest/ · MFP och appbygge fortsatt stoppat.
- 2026-06-11 · Steg 13 tillagt på Kims order: revisionshygienen ska vara maskinellt verifierbar (validate_run_hygiene.py) · demo-skill-3 godkänd som arkitekturmönster; MFP/dashboard/appbygge fortsatt stoppat tills validatorn är grön.
- 2026-06-14 · M3.1 på Kims order: stäng G1–G6 (run_id-format, PARTIAL/ARKIV, trasig research-fil, static_fetch-capability, root_path, manifest-ordning) i ENBART schema + .skill.md + audit · ny ren-kontext-dry-run: alla CLOSED, 0 öppna gap. Ingen app-kod. M3 ännu ej förseglad (väntar Kims OK).
- 2026-06-14 · M3 startad på Kims order: Skill Protocol Export v1 — definiera+testa formatet (schema + handskrivet .skill.md + test i ren kontext + audit) INNAN app-export · ingen app-kod/UI/datamodell, demo-skill-3 skrivs aldrig över (nya filer bredvid); M2 steg 10+11 kvar som Kims iPhone-bockar.
- 2026-06-12 · Kims order "iphone-takeover: granska UI/UX + fixa grafiken" (del av steg 11-bocken) · fynd: ritningen saknade containerstorlek (orange minilåda) + CylinderShape-bugg (bottenbåge = cirkel med radie halva bredden → kopp-utseende) + gate-text kapad · fix: storlek/bredd-meta i ritningen + ellips-botten i CanvasShapes + deploy.

## 🎉 Klart — avbockade steg flyttas hit (datum + en rad)
- 2026-06-17 · Steg 16 ✅ MA spår B: ARKITEKTUR-REGLER.md + arch-check.py (lager/filstorlek-ratchet/version-sync) + pre-commit-hook; injektionstestat; CLAUDE.md regel 14
- 2026-06-17 · Steg 15 ✅ MA spår C: se-appen — Claude bygger/startar sim, tar egen skärmbild, läser UI + state-dump, trycker/drar; skill + scripts/see-app.sh
- 2026-06-14 · Steg 14 ✅ M3 Skill Protocol Export v1: SKILL_PROTOCOL_SCHEMA.md (normativt) + handskrivet demo-skill-3-subagents.skill.md (13 noder/15 edges, konsistens-verifierad) + främmande Claude-kontext dry-runade ur ENBART filen (0 verktygsanrop) + skill_protocol_audit.md (PASS, G1–G6 gap listade för M4)
- 2026-06-10 · Steg 0 ✅ visual-flow-test.md skapad, parser-stöd verifierat i kod (Kims iPhone-koll: slutlistan)
- 2026-06-10 · Steg 1 ✅ pass-körning → resultat.md, fail-injektion → manual_review.md
- 2026-06-10 · Steg 2 ✅ visual-flow-compiler byggd; visual-flow-test installerad som riktig skill + körd (kaffe)
- 2026-06-10 · Steg 3 ✅ prompt-mall + skill-gräns + "installera skillen" i kontraktet; RUN_REPORT ren
- 2026-06-10 · Steg 4 ✅ mfp-skillsen pekar-modell (bootloader + flow.md + REN rapport, 0 saknade fält)
- 2026-06-10 · Steg 5 ✅ Canon-körningen: konsensus 77/89, 0 olösta · official_source_map.md COMPLETE + 3 scope-beslut i manual_review.md
- 2026-06-11 · Steg 9 ✅ UI-test skapade skill-container + Skill 1 + exporterade i appen; främmande agent verifierade filen (stoppade ärligt på tom nod); mfp-ritningarna fick skill-nr 1+2
- 2026-06-11 · Steg 13 ✅ validate_run_hygiene.py grön för båda runs + latest + rot + arkiv (validation_report.md); fel-injektion bevisade att den fångar brott (exit 1); RUN_REPORT uppdaterad
- 2026-06-11 · Steg 12 ✅ run_id + runs/<run_id>/ + run_manifest.md + latest-pekare; FAIL-run (elcyklar: manual, ingen resultat) + PASS-run (regler-elcyklar: resultat, ingen manual) i separata mappar; gamla rotfiler arkiverade; RUN_REPORT + parser-test uppdaterade
- 2026-06-11 · Steg 7 ✅ skillNumber + skill-nr-kommentar + parserfix (subgraph-kategori) — round-trip grön båda vägar
- 2026-06-11 · Steg 8 ✅ SkillFileComposer + SkillExportContract — portabel fil med kontrakt, 23 testsviter gröna
- 2026-06-11 · Steg 6 ✅ EXPORT-KONTRAKT.md v1 + visual-flow-test-portabel.md körd av främmande agent: pass → resultat.md, fail-injektion → manual_review.md
- 2026-06-10 · 🎉 M1 KLAR — ritning → kompilator → installerad skill → skarp körning. Kims slutkontroll: (1) visual-flow-test + projektplan i appen, (2) 3 scope-beslut i manual_review.md
