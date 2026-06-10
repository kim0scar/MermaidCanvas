# PROJEKTPLAN — projektets lag <!-- max 100 rader · formatet FRYST · ändras bara via Revideringar -->
NU: Steg 0 av 6 — Mini-testflöde med gate + manual
[░░░░░░░░░░░░] 0/6 — 0%   ·   💡 Idébanken: 0 fångade, 0 byggda
SENAST KLART: — (planen skapad 2026-06-10)
MÅL: Mermaid-koden ÄR skillen. Kim ritar → Claude kompilerar → körningen bevisar sig själv.

## Milstolpe M1 — exportkedjan bevisad
Ett ritat flöde med grind + manual kan köras och kompileras till en skill — utan
handpåläggning. Det är beviset hela n8n-idén står eller faller med.

## Steg  (☐ ej påbörjad · ⏳ PÅGÅR, max 1 · ✅ klar · ✂ struken)

### ⏳ Steg 0 — Mini-testflöde med gate + manual
Skapa `visual-flow-test.md` i iCloud-Mermaid, i appens format: input → script → agent → grind → pass: output / fail: manual, prompts enligt mallen.
Klart när: filen öppnas i appen och round-trippar utan diff — Kim säger "klart" efter att ha sett den på iPhone.
Kräver: —

### ☐ Steg 1 — Körtest via flode
Kör mini-flödet med skillen `flode` — inget får fyllas i tyst, saknat = fel.
Klart när: pass-körningen ger resultatfilen OCH fail-körningen (filen borttagen) ger manual_review.md — båda exakt enligt ritningen.
Kräver: Steg 0 ✅

### ☐ Steg 2 — visual-flow-compiler
Ny skill som läser en exporterad canvas-fil, validerar varje nod och bygger skill-mapp + RUN_REPORT.md (saknade fält rapporteras, aldrig tyst ifyllda).
Klart när: körd på visual-flow-test ger en installerad skill vars körning ger samma resultat som Steg 1 + ärlig RUN_REPORT.
Kräver: Steg 1 ✅

### ☐ Steg 3 — Prompt-mall + skill-gräns in i kontraktet
Mallen `Input:/Uppgift:/Output:/PASS:/FAIL:`, skill-gräns-kriterierna och kommandot "installera skillen" in i SKILL-KEDJA-KONTRAKT.md + flode.
Klart när: kompilatorn validerar mot mallen och testflödets RUN_REPORT är ren (noll saknade fält).
Kräver: Steg 2 ✅

### ☐ Steg 4 — mfp-skills till pekar-modellen
Kompilera om mfp-site-intelligence + mfp-sortiment: ritningen blir enda sanningen, handskrivna SKILL.md ersätts av kompilerad bootloader.
Klart när: noll dubblerad logik i SKILL.md-filerna och RUN_REPORT ren för båda.
Kräver: Steg 3 ✅

### ☐ Steg 5 — MFP Canon-körning (skarpt prov)
Kör "mfp-site-intelligence Canon Sverige multifunktionsskrivare" med den kompilerade skillen.
Klart när: official_source_map.md har konsensus-spår och allt obevisat står i manual_review.md — inget gissat.
Kräver: Steg 4 ✅

## Efter M1 (bara rubriker — detaljeras först när M1 är 🎉)
- n8n-initiera (byggar-skillen: intervju → research → ritat utkast på canvasen)
- Styrningsregler i kontraktet (nivå A–D, R0–R4, gap-frågelistan)
- Skill 3 mfp-spec (Excel) + Skill 4 dashboard
- Upphandlings-paketet i appen
- Skill-builder/debugger-metaskillen (växer ur 2–3 verkliga körningar)

## 💡 Idébanken — fångas direkt, byggs ALDRIG nu (väljs ur vid milstolpe-slut · max 15 rader)
(tom)

## Revideringar — datum · vad · varför (en mening var · skrivs FÖRE arbetet)
- 2026-06-10 · Planen skapad · startläge för M1.

## 🎉 Klart — avbockade steg flyttas hit (datum + en rad)
(tomt)
