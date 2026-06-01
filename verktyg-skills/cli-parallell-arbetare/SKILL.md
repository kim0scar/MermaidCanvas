---
name: cli-parallell-arbetare
description: >
  Kör Claude Code CLI (via MCP-bryggan claude_code) som en EXTRA parallell
  arbetare medan huvud-Claude jobbar — oftast som READ-ONLY bug-jägare/andra-
  ögon, men även som andra-åsikt på en design eller djupgranskning av en
  delsystem. Mönstret bevisat: i en session hittade en parallell CLI-scan en
  missionskritisk round-trip-bugg + en krasch som varken kod-läsning eller
  screenshots fångat. Trigga på: "kör CLI som parallell bug-scanner", "låt
  CLI:n leta buggar medan du jobbar", "extra ögon på koden", "andra åsikt från
  Code", "dubbelkolla med CLI", "parallell granskning", "/cli-parallell-arbetare".
  Använd INTE för: att DRIVA en app i simulatorn (ux-personas-test), känd
  bugg→fix (multi-agent-bug-fix), eller CLI-flagg-referens (code-cli-guide).
version: 1
---

# Skill: cli-parallell-arbetare (v1)

## Syfte
Huvud-Claude och CLI:n (claude_code-bryggan) jobbar **samtidigt på två spår**.
Huvud-Claude bygger/redigerar/testar; CLI:n granskar parallellt och rapporterar
fynd. Två oberoende analyser av samma kod fångar olika fel. CLI:n är multimodal
(läser screenshots själv) och har eget kontextfönster.

**Bevisat värde:** olika felklasser. Huvud-Claude + sim-screenshots ser visuella
fel; en parallell CLI-kodscan ser krascher, parsing-/round-trip-buggar, logik
som aldrig syns i en bild.

## När använda
- Du står i begrepp att köra ett långt bygge/test → låt CLI:n bug-jaga under tiden.
- Du vill ha en oberoende andra-åsikt på en diagnos/design innan du committar.
- Du vill djupgranska ett missionskritiskt delsystem (t.ex. persistens, parsing,
  round-trip) parallellt med annat arbete.

## Hårda regler (lärt av faktisk körning)

1. **READ-ONLY mot källkod, normalt.** CLI:n får ANALYSERA + skriva EN rapportfil.
   Den får INTE editera .swift/källkod medan huvud-Claude också gör det → fil-krockar.
   Säg explicit i prompten: "ANALYSIS ONLY — do NOT modify any source file. You may
   only write one report file at <path>."
2. **En rapportfil per CLI-körning**, känd path (t.ex. `/tmp/cli-bug-scan.md`).
   Kommunicera via fil, inte via chatt-svar — då kan huvud-Claude läsa den när som.
3. **Bryggan är opålitlig för långa körningar.** Den kan rapportera
   `MCP error -32000: Connection closed` eller liknande MEN ändå ha skrivit klart
   rapportfilen. ALLTID: verifiera genom att läsa rapportfilen, lita inte på
   tool-svaret. Om filen saknas → kör om med snävare scope.
4. **Verifiera CLI:ns fynd mot riktig kod innan fix.** CLI:n kan ha fel radnummer
   eller missförstå. Behandla fynd som KANDIDATER tills huvud-Claude bekräftat
   mot källan. (Detta fångade ett falskt "per-edge collapse"-fynd i praktiken.)
5. **Ge `workFolder`** = projektroten (absolut path) i varje anrop.

## Arbetssätt

### Steg 1 — starta CLI-spåret parallellt
I SAMMA meddelande som du startar ditt eget tunga jobb (build/test), anropa
`claude_code` med ett read-only granskningsuppdrag. Då löper båda samtidigt.

Prompt-mall (bug-jakt):
```
ANALYSIS ONLY — do NOT modify any source file. You may only write ONE report
file to <RAPPORT-PATH>. Parallel read-only bug-hunt while another agent edits.

Scope: <vilka filer/delsystem — håll det fokuserat>.
Hunt for: <t.ex. crashes, round-trip/parsing data loss, race conditions,
force-unwraps, off-by-one, escaping bugs>.
For each finding: file:line, severity (HIGH/MED/LOW), what's wrong, one-line fix.
Also list a short "Checked and OK" section so I know what you cleared.
Write findings to <RAPPORT-PATH> and print a 6-line summary to stdout.
Touch no other file.
```
workFolder = projektroten.

### Steg 2 — gör ditt eget jobb
Bygg/testa/redigera som vanligt medan CLI:n kör. Blockera inte på den.

### Steg 3 — läs rapporten (inte tool-svaret)
När ditt jobb är klart: `Read` rapportfilen. Även om bryggan rapporterade fel —
kolla filen. Saknas den → kör om med snävare scope.

### Steg 4 — triagera + verifiera
Gå igenom fynden. För varje du tänker agera på: öppna källan och BEKRÄFTA
(rätt fil, rätt rad, äkta problem). Avfärda falska positiver. Fixa de äkta
(ev. via multi-agent-bug-fix för komplexa), lägg regressionstest på krascher/
round-trip. Säg till Kim vad CLI:n hittade vs vad som bekräftades.

## Andra lägen (samma brygga, annan prompt)
- **Andra-åsikt på design/diagnos:** "ANALYSIS ONLY. Här är min plan/diagnos: …
  Försök motbevisa den. Peka på risker/hål. Skriv till <path>." (refute-läge).
- **Djupgranska delsystem:** snäv scope, be om både fynd OCH "Checked and OK".

## Var saker bor
- Bryggans verktyg: MCP `claude_code` (param: `prompt`, `workFolder`).
- Rapporter: `/tmp/cli-*.md` (tillfälligt) eller projektets `.cli-scan/` om du vill spara.

## Relation till andra skills
- `code-cli-guide` — CLI-flaggor/sessionsteknik (INTE parallell-arbete). Komplement.
- `ux-personas-test` — DRIVER appen i sim via idb. Annan sak.
- `multi-agent-bug-fix` — fixar KÄNDA buggar med 3-agent-konsensus. Använd EFTER
  att denna skill hittat något komplext värt full fix-process.

## Ändringslogg
- v1: kodifierar det bevisade mönstret (parallell read-only bug-jakt + andra-åsikt),
  inkl. lärdomar: bryggan kan tappa anslutning men ändå skriva rapport; verifiera
  alltid fynd mot källkod; read-only för att undvika fil-krockar.
