# PROJEKTPLAN — projektets lag <!-- max 100 rader · formatet FRYST · ändras bara via Revideringar -->
NU: ⏳ M2 — steg 10+11 väntar Kims bock (allt maskinarbete klart, inkl. steg 12+13)
[█████████░░░] 6/8 — 75%   ·   💡 Idébanken: 4 fångade, 2 byggda
SENAST KLART: Steg 9 ✅ (2026-06-11) — appen körd av Claude via UI-test: export gjord i appen, bevisad portabel
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

## Efter M2 (bara rubriker — detaljeras först när M2 är 🎉)
- n8n-initiera (byggar-skillen: intervju → research → ritat utkast på canvasen)
- Styrningsregler i kontraktet (nivå A–D, R0–R4, gap-frågelistan)
- Skill 3 mfp-spec (Excel) + Skill 4 dashboard
- Upphandlings-paketet i appen
- Skill-builder/debugger-metaskillen (växer ur 2–3 verkliga körningar)

## 💡 Idébanken — fångas direkt, byggs ALDRIG nu (väljs ur vid milstolpe-slut · max 15 rader)
- 2026-06-10 · 💡#1 Metoden som portabelt paket för nya projekt · BYGGD på Kims order
- 2026-06-10 · 💡#2 Ritad vy av planen i appen · BYGGD på Kims order
- 2026-06-11 · 💡#3 "Kopiera som skill" (urklipp) får också kontraktet inbäddat · väntar
- 2026-06-11 · 💡#4 Promptprotokoll v0.1 fullt ut (11 nodtypsmallar + mall-knapp i appen + MFP-omritning) · parkerad — gap-analysen klar, väntar efter steg 11

## Revideringar — datum · vad · varför (en mening var · skrivs FÖRE arbetet)
- 2026-06-10 · Planen skapad · startläge för M1.
- 2026-06-10 · 💡#1+#2 byggda direkt (mall+ZIP+intervju, ritad vy) · Kim bad explicit; rör inga M1-steg.
- 2026-06-10 · Kim beordrade "/goal bygg allt" · stegen körs i följd med maskinbevis; Kims iPhone-bockar samlas i slutkontroll.
- 2026-06-11 · Steg 11 tillagt på Kims order: vokabulärsbeviset (subagent egen nod, tool = metadata) FÖRE all MFP/app-fortsättning · demo-skill-2 har fel mönster (tool-nod i researchsteg) — rättas efter steg 11. Steg 10 ⏳ kvarstår: endast Kims bock återstår, WIP=1 gäller arbetssteg.
- 2026-06-11 · Steg 10 utökat efter Kims test: exporten hamnade osynligt i appens mapp (sandlåda) → "Spara skill som fil" får riktig Spara som-dialog; + demo-skill-2.md byggs (komplett LR-skill med verktyg + exakta in/ut-filer).
- 2026-06-11 · M2 detaljerad på Kims order · export till främmande dator + skill-container (namn+nummer, ordning i kedjan) + Claude UI-testar appen själv och städar containrarnas utseende.
- 2026-06-11 · Steg 12 tillagt på Kims order: demo-skill-3:s FAIL- och PASS-filer låg sida vid sida och motsade varandra → run_id + runs/<run_id>/ + run_manifest.md + latest/ · MFP och appbygge fortsatt stoppat.
- 2026-06-11 · Steg 13 tillagt på Kims order: revisionshygienen ska vara maskinellt verifierbar (validate_run_hygiene.py) · demo-skill-3 godkänd som arkitekturmönster; MFP/dashboard/appbygge fortsatt stoppat tills validatorn är grön.
- 2026-06-12 · Kims order "iphone-takeover: granska UI/UX + fixa grafiken" (del av steg 11-bocken) · fynd: ritningen saknade containerstorlek (orange minilåda) + CylinderShape-bugg (bottenbåge = cirkel med radie halva bredden → kopp-utseende) + gate-text kapad · fix: storlek/bredd-meta i ritningen + ellips-botten i CanvasShapes + deploy.

## 🎉 Klart — avbockade steg flyttas hit (datum + en rad)
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
