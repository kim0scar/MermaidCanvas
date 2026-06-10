# PROJEKTPLAN — projektets lag <!-- max 100 rader · formatet FRYST · ändras bara via Revideringar -->
NU: ⏳ M2 — steg 10: deploy v74 + Kims ögon
[█████████▓░░] 4/5 — 80%   ·   💡 Idébanken: 3 fångade, 2 byggda
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

## Revideringar — datum · vad · varför (en mening var · skrivs FÖRE arbetet)
- 2026-06-10 · Planen skapad · startläge för M1.
- 2026-06-10 · 💡#1+#2 byggda direkt (mall+ZIP+intervju, ritad vy) · Kim bad explicit; rör inga M1-steg.
- 2026-06-10 · Kim beordrade "/goal bygg allt" · stegen körs i följd med maskinbevis; Kims iPhone-bockar samlas i slutkontroll.
- 2026-06-11 · M2 detaljerad på Kims order · export till främmande dator + skill-container (namn+nummer, ordning i kedjan) + Claude UI-testar appen själv och städar containrarnas utseende.

## 🎉 Klart — avbockade steg flyttas hit (datum + en rad)
- 2026-06-10 · Steg 0 ✅ visual-flow-test.md skapad, parser-stöd verifierat i kod (Kims iPhone-koll: slutlistan)
- 2026-06-10 · Steg 1 ✅ pass-körning → resultat.md, fail-injektion → manual_review.md
- 2026-06-10 · Steg 2 ✅ visual-flow-compiler byggd; visual-flow-test installerad som riktig skill + körd (kaffe)
- 2026-06-10 · Steg 3 ✅ prompt-mall + skill-gräns + "installera skillen" i kontraktet; RUN_REPORT ren
- 2026-06-10 · Steg 4 ✅ mfp-skillsen pekar-modell (bootloader + flow.md + REN rapport, 0 saknade fält)
- 2026-06-10 · Steg 5 ✅ Canon-körningen: konsensus 77/89, 0 olösta · official_source_map.md COMPLETE + 3 scope-beslut i manual_review.md
- 2026-06-11 · Steg 9 ✅ UI-test skapade skill-container + Skill 1 + exporterade i appen; främmande agent verifierade filen (stoppade ärligt på tom nod); mfp-ritningarna fick skill-nr 1+2
- 2026-06-11 · Steg 7 ✅ skillNumber + skill-nr-kommentar + parserfix (subgraph-kategori) — round-trip grön båda vägar
- 2026-06-11 · Steg 8 ✅ SkillFileComposer + SkillExportContract — portabel fil med kontrakt, 23 testsviter gröna
- 2026-06-11 · Steg 6 ✅ EXPORT-KONTRAKT.md v1 + visual-flow-test-portabel.md körd av främmande agent: pass → resultat.md, fail-injektion → manual_review.md
- 2026-06-10 · 🎉 M1 KLAR — ritning → kompilator → installerad skill → skarp körning. Kims slutkontroll: (1) visual-flow-test + projektplan i appen, (2) 3 scope-beslut i manual_review.md
