---
name: ux-personas-test
description: >
  AI-testanvändare med olika personas (nybörjare, stressad, Kim-själv) driver
  iPhone-appen som riktiga användare via idb i simulatorn och hittar UX-fel +
  förbättringar — inte bara kodbuggar. Ett smart-prompt-lager expanderar korta
  svenska fraser till rika persona-uppdrag (Kim slipper skriva bra prompts). Kör
  parallellt via claude_code-bryggan, syntetiserar en UX_PERSONA_AUDIT.md med
  severity + bugg/förbättring-tagg. Trigga på: "låt en [nybörjare/stressad/...]
  testa X", "testa appen som en användare", "känns det tydligt", "hitta UX-problem",
  "är det snyggt", "funkar X för en nybörjare", "testanvändare", "låt någon prova
  appen", "/ux-personas-test". Använd INTE för känd-bugg+fix (multi-agent-bug-fix),
  random fuzz på fysisk iPhone (iphone-autonom-monkey-test), eller ren
  funktions-audit (ios-sim-validation).
version: 1.0
---

# Skill: ux-personas-test (v1.0)

## Syfte
Låt agenter *använda* appen som olika människor och rapportera friktion som
varken kod-läsning eller en enstaka screenshot avslöjar (träffytor,
upptäckbarhet, gesture-konflikter, "känns off"). Inte bara buggar — även
förbättringar. Anpassat för Kim: korta svenska fraser → rika testuppdrag.

## Motor (verifierad fungerande)
**idb** driver simulatorn (tap/swipe + a11y-träd). Installerat:
- `idb_companion` via brew (`/opt/homebrew/bin`).
- `idb`-klient i venv `~/.idb-venv` (Python 3.13 — fb-idb kraschar på 3.14).
- Wrapper: `~/.claude/skills/ux-personas-test/bin/idb` (sätter PATH automatiskt).
- Hjälplager: `~/.claude/skills/ux-personas-test/bin/ux-driver.sh` (semantiska
  kommandon: `labels`, `tap <label>`, `double`, `long`, `swipe`, `text`, `step`,
  `reset`, `launch`). Element nås via **AXLabel** (chip.diamond, Shape, Undo …)
  + frame — INTE råa pixlar.

idb läser a11y-trädet som AXLabel + frame (AXIdentifier är tomt — appens
accessibilityIdentifiers syns som AXLabel, vilket räcker). Reserv om idb dör vid
OS-uppgradering: omkompilerings-fri JSON-tolk `ExplorationDriverTest.swift` (se plan).

## Vad skillen INTE löser
- Känd bugg som ska fixas → `multi-agent-bug-fix`.
- Random fuzz på fysisk iPhone → `iphone-autonom-monkey-test`.
- Snabb funktions-/regressions-audit → `ios-sim-validation`.
- Den FIXAR inget — den rapporterar. Fix går via multi-agent-bug-fix.

## Personas (v1.0 — alla 6)
P1 NYBÖRJARE, P2 STRESSAD, P3 NYFIKEN/EDGE-CASE, P4 KIM SJÄLV,
P5 DESIGNGRANSKARE (Apple-nivå estetik), P6 TILLGÄNGLIGHET — fullständiga i
`personas.md`. Smart-prompt-lagret väljer relevant delmängd; fraser som "allt",
"Apple-nivå", "hela appen", "v1.0" → **FULL SVEP** med alla 6.

## Faser (orchestrator — huvud-Claude dispatchar, kör inte UI själv)

### Fas 0 — Smart-prompt-expansion
Läs `prompt-mappning.md`. Tolka Kims fras → persona(er) + läge + mål. Visa
2-raders tolkning. Fråga ALDRIG tillbaka — gissa och kör.

### Fas 1 — Sim-setup
- Hämta booted UDID: `xcrun simctl list devices booted | grep iPhone`.
  (Saknas booted sim → boota en, t.ex. iPhone 17, iOS 26.)
- Säkerställ appen installerad (bygg vid behov, se projektets CLAUDE.md).
- Skapa körmapp: `<repo>/.ux-personas-test/<tidsstämpel>/` med `exec/` + `screenshots/<persona>/`.

### Fas 2 — Parallell persona-exekvering
För varje persona: ett `claude_code`-anrop (CLI-bryggan, `workFolder`=repo) med
den expanderade prompten (mall i `prompt-mappning.md`). CLI:n är multimodal —
läser sina egna screenshots. Kör personas i SAMMA meddelande (parallellt).
- **Read-only källkod.** Ingen rör .swift.
- **Isolering:** en sim räcker för MVP men personor delar då sim → kör dem
  SEKVENTIELLT om de krockar, eller en `reset`+`launch` mellan varje. (Klona sim
  för äkta parallellism först om det behövs senare.)
- Varje persona `reset`+`launch`-ar appen först (ren canvas).

### Fas 3 — Syntes + konsensus
Spawna en syntes-agent (sub-agent) som läser alla `exec/*.json`:
- Dedup (samma element + symptom = ett fynd; spåra vilka personas).
- Konsensus: 2+ personas = BEKRÄFTAT, 1 = KANDIDAT.
- Severity via matris i `personas.md` (bugg×blockerande).
- Skriv `<repo>/UX_PERSONA_AUDIT.md` (format nedan).

### Fas 4 — Grind (vid behov)
HÖG + bekräftade MEDEL som rör gester/träffytor/känsla → verifiera på Kims
iPhone via `ui-verifiering-ios` (iPhone-kolumn fylls bara av Kim). Estetik/a11y
kan oftast avgöras på sim.

## UX_PERSONA_AUDIT.md — format
```markdown
# UX-Persona Audit — <datum tid>
## Sammanfattning
Personas: P1,P2,P4 | Läge: <…> | Sim: iPhone 17 (iOS 26)
Fynd: X HÖG, Y MEDEL, Z LÅG | A buggar, B förbättringar
## HÖG
### UX-001 [BUGG] <rubrik>
- Sett av: P2,P4 (BEKRÄFTAT 2/3) | Lins: <…>
- Repro: <steg> | Screenshot: screenshots/P2/step_NN.png
- Severity: HÖG | Tagg: BUGG
## MEDEL … ## LÅG …
## Rekommendation
1. UX-001 → multi-agent-bug-fix.  2. UX-002 → ui-verifiering-ios (iPhone) före fix.
```

## Felhantering
- idb svarar inte → `idb kill; idb connect <UDID>`; verifiera `idb describe`.
- Element hittas ej via AXLabel → kör `labels` och välj rätt namn; annars `tapxy`.
- App kraschar under körning → det ÄR ett HÖG-fynd; logga screenshot + sista steg.
- Sim saknas → boota; om allt fallerar, använd JSON-tolk-reserven.

## Ändringslogg
- v1 (MVP): motor idb verifierad på iOS 26; P1/P2/P4; smart-prompt-lager; driver-wrapper.
