# PROJEKTPLAN — projektets lag <!-- max 100 rader · formatet FRYST · ändras bara via Revideringar -->
NU: MB pågår. ✅ Steg 6 (tabell/länk/kollaps överlever ren mermaid — Kims figurer). KVAR: steg 0 (städa rot), 1 (om-verifiera v79), 2–5 (UX-111/112/113/114). n8n + M4 PAUSADE. MA + M3 klara.
[grundappen MB: █░░░░░░] 1/7   ·   💡 Idébanken: 5 fångade, 2 byggda
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
- ☐ Steg 0 — Städa roten: version-stämplade fynd (HANDOVER v50.7, BUGSVEP-v60, GAP-ANALYS-v61, UI-PLACERINGS-FYND-v49, v47.xlsx) → arkiv/; lös dubbletter. Klart: inga lösa version-fynd i roten, bygg+arch-check oförändrat.
- ☐ Steg 1 — Om-verifiera UX-111–122 mot v79 (se-appen + iPhone). Klart: färsk lever/dött-lista, döda bockas i auditen.
- ☐ Steg 2 — UX-111 pan-stölden: större träffyta på pilhandtag + "hoppa till innehåll". Klart: Kim bekräftar på iPhone att drag nära handtag inte panorerar bort allt.
- ☐ Steg 3 — UX-112: klampa handtag (resize/rotate/connection) till synlig yta. Klart: Kim når alla handtag på iPhone.
- ☐ Steg 4 — UX-113: pålitlig dubbeltapp → Redigera + text-ledtråd i tomt-läge. Klart: Kim öppnar Redigera med dubbeltapp reproducerbart.
- ☐ Steg 5 — UX-114: a11y-labels på allt interaktivt + textstil-knappar in i vy + Klar/Stäng/Kopiera nåbara. Klart: ux-driver ser alla knappar + de är tappbara.
- ✅ Steg 6 — Round-trip-härdning (Kims tre figurer): tabell (typ+celler), jump-länk (typ) och kollaps överlever REN mermaid via osynliga `%%`-rader (shape-type + table-cells). 3 nya fallback-tester gröna (175 totalt). KVAR (mindre, senare): waypoints i fallback + stabila nod-ID:n.

## Efter MB (pausat, Kims order) + Efter M3
- MC — n8n klar: kontrakt-synk (4 saknade noder) + n8n-paket→spec_type:flow + konformitetstest.
- M4: appen lagrar node contracts per figur + exporterar .skill.md (om auditen håller) · Styrningsregler (nivå A–D, R0–R4) · Skill 3 mfp-spec + Skill 4 dashboard · Upphandlings-paketet

## 💡 Idébanken — fångas direkt, byggs ALDRIG nu (väljs ur vid milstolpe-slut · max 15 rader)
- 2026-06-10 · 💡#1 Metoden som portabelt paket för nya projekt · BYGGD på Kims order
- 2026-06-10 · 💡#2 Ritad vy av planen i appen · BYGGD på Kims order
- 2026-06-11 · 💡#3 "Kopiera som skill" (urklipp) får också kontraktet inbäddat · väntar
- 2026-06-11 · 💡#4 Promptprotokoll v0.1 fullt ut (11 nodtypsmallar + mall-knapp i appen + MFP-omritning) · parkerad — gap-analysen klar, väntar efter steg 11
- 2026-06-13 · 💡#5 Prompt-kompilator: appen GENERERAR nod-prompten från hög-nivå-val (du slipper skriva metodtexten själv) · väntar — kärnan av "n8n för Claude Code"-visionen

## Revideringar — datum · vad · varför (en mening var · skrivs FÖRE arbetet)
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
