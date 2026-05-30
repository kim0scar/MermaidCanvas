# Metod: Claude Code CLI som parallell arbetare (MCP-brygga)

*Skapad: 2026-05-30 (v50.6). Portabel metod — gäller alla projekt.*

## Vad det är

Vi kör **Claude Code CLI** som en EXTRA arbetare bredvid huvud-Claude, via
MCP-bryggan `claude_code`. Huvud-Claude och CLI:n jobbar **samtidigt på två
spår**: huvud-Claude bygger/redigerar/testar, CLI:n granskar parallellt och
rapporterar fynd. Två oberoende analyser av samma kod fångar olika sorters fel.

CLI:n har **eget kontextfönster** och är **multimodal** (läser screenshots själv).

## Varför — bevisat värde

I v50.6-sessionen hittade en parallell CLI-scan saker som varken kod-läsning
eller skärmdumpar fångat:
- **Missionskritisk round-trip-bugg:** texten `-->` i en form trunkerade hela
  JSON-sparblocket → all fidelity tappades.
- **Tabell-krasch:** 0 rader/kolumner kraschade appen.

Olika felklasser: huvud-Claude + sim-screenshots ser *visuella* fel; en parallell
CLI-kodscan ser *krascher, parsing-/round-trip-buggar, logik* som aldrig syns i bild.

## När använda

- Du ska köra ett långt bygge/test → låt CLI:n bug-jaga under tiden.
- Du vill ha en oberoende **andra-åsikt** på en diagnos/design innan commit.
- Du vill **djupgranska ett missionskritiskt delsystem** (persistens, parsing,
  round-trip) parallellt med annat arbete.

Mindre värt för småfix där huvud-Claude är snabbare själv.

## Hur — arbetssätt

1. **Starta CLI-spåret parallellt.** I SAMMA meddelande som du startar ditt egna
   tunga jobb, anropa `claude_code` med ett read-only granskningsuppdrag.
2. **Gör ditt eget jobb** (bygg/test/redigera) medan CLI:n kör. Blockera inte.
3. **Läs rapportfilen** — inte tool-svaret (se fallgrop nedan).
4. **Triagera + verifiera** varje fynd mot riktig kod innan fix.

### Prompt-mall (bug-jakt)

```
ANALYSIS ONLY — do NOT modify any source file. You may only write ONE report
file to <RAPPORT-PATH>. Parallel read-only bug-hunt while another agent edits.

Scope: <vilka filer/delsystem — håll fokuserat>.
Hunt for: crashes, round-trip/parsing data loss, race conditions, force-unwraps,
off-by-one, escaping bugs.
For each finding: file:line, severity (HIGH/MED/LOW), what's wrong, one-line fix.
Also list a short "Checked and OK" section.
Write findings to <RAPPORT-PATH> and print a 6-line summary to stdout.
Touch no other file.
```

Anropet behöver `workFolder` = projektroten (absolut path).

## Hårda regler (lärt av faktisk körning)

1. **READ-ONLY mot källkod.** CLI:n får bara skriva EN rapportfil. Den får INTE
   editera källkod medan huvud-Claude också gör det → fil-krockar.
2. **En rapportfil, känd path** (t.ex. `/tmp/cli-bug-scan.md`). Kommunicera via
   fil, inte via chatt — då kan huvud-Claude läsa när som helst.
3. **Bryggan är opålitlig på långa körningar.** Den kan svara
   `MCP error -32000: Connection closed` MEN ändå ha skrivit klart rapporten.
   → Verifiera ALLTID genom att läsa rapportfilen. Saknas den → kör om snävare.
4. **Verifiera fynd mot riktig kod innan fix.** CLI:n kan ha fel radnummer eller
   missförstå. Behandla fynd som KANDIDATER tills bekräftade. (Fångade ett falskt
   "per-edge collapse"-fynd i praktiken.)

## Andra lägen (samma brygga, annan prompt)

- **Andra-åsikt / refute:** "ANALYSIS ONLY. Här är min plan/diagnos: … Försök
  motbevisa den. Peka på risker/hål."
- **Djupgranska delsystem:** snäv scope, be om både fynd OCH "Checked and OK".

## Var det bor

- **Skill:** `~/.claude/skills/cli-parallell-arbetare/SKILL.md` (kodifierar metoden).
- **Brygga:** MCP-verktyg `claude_code` (param: `prompt`, `workFolder`).
- **Trigger-fraser:** "kör CLI som parallell bug-scanner", "extra ögon på koden",
  "andra åsikt från Code", "dubbelkolla med CLI".

## Relation till andra metoder

- Kompletterar `code-cli-companion`-pluginet (CLI-flaggor/sessionsteknik) — ingen
  överlapp.
- Skild från användartest-metoden (se `METOD-ANVANDARTEST-UI.md`) som DRIVER appen
  i simulatorn. Denna metod granskar KOD.
