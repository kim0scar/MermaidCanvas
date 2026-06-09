# HANDOVER v72 — beslutslogg + nuläge (för /clear och nästa session)

*Datum: 2026-06-09. Save-version: v72 (dokumentations-milstolpe, ingen feature-ändring).*
*Läs denna + `~/.claude/plans/vi-ska-bygga-en-magical-knuth.md` + `ROADMAP.md` för full bild.*

Det här dokumentet beskriver **vad vi gjort, varför, och vägvalen** under v69→v72, så att en
ny session (eller Kim själv) snabbt förstår läget. Versionsdetaljer i `ROADMAP.md`; den
arkitektoniska helheten i `ARKITEKTUR-MERMAID.md`; beslut även i memory `project_mfp_pipeline`.

---

## 0. Det stora sammanhanget

Kims riktiga mål med appen: **rita skill-kedjor** (n8n-likt) i Visuali2e → mermaid-koden blir
**Claude Code-skills**. Konkret första produkt: en **MFP-pipeline** (multifunktionsskrivare)
som inför upphandling hittar tillverkares officiella sortiment och extraherar produktdata.

Under v69→v72 gick vi från "appen kan rita flöden" till "appen kan rita en **pålitlig**,
**spårbar** skill-pipeline, och en första riktig skill är byggd, körd och validerad."

---

## 1. Rådgivnings-domen (utgångspunkt)

Kim fick råd från två AI-källor om MFP-produkten. Min dom efter granskning:
- **Båda hade rätt i det stora:** gå **djupt på EN kedja**, filer som överlämning, skills+subagents.
- **Rätt startpunkt = site-intelligence**, INTE "skrapa sida". Börja från *leverantör + marknad +
  produktområde* → hitta & verifiera officiell källa → klassa webbteknik → rekommendera metod,
  **innan** något skrapas. Det ger upphandlingsvärde + spårbarhet.
- **Mycket fanns redan:** container=skill, memory-nod=överlämningsfil, `%% prompt`-kontrakt,
  "Kopiera som skill". Rådgivaren visste inte det.

---

## 2. Vägval — och VARFÖR (det viktigaste)

| Vägval | Beslut | Varför |
|---|---|---|
| Process-vokabulär | **Byggt** (v69): Grind/Bevis/Manual/Script | En pålitlig kedja behöver "måste-passera"-grind (≠ router), bevis, manuell-stopp |
| Nod-inspektör (9 fält/nod) | **MEDVETET BORTVALT** | Skadar Kims visuella flöde (dyslexi/ADHD/2e). Kontraktfält bor i nodens `prompt` i stället |
| Flikar = en fil per skill | **Bortvalt** till förmån för EN fil | Fler filer = sämre "helhet", mer friktion. En fil = helheten, rumslig navigering |
| Skill-containrar | **Vald arkitektur** (v70): EN pipeline-fil, varje skill = en container, varje container ejectbar | Matchar SKILL-KEDJA-KONTRAKTet; fanns redan ~80% (`generateForContainer`) |
| Mermaid → skill | **Konvertera till prosa-steg** i SKILL.md, mermaid som referens | Pålitligare/deterministiskt (verifierat mot Claude Code-dok). `flode` gör redan detta |
| Skill anropar skill? | Nej — en **dirigent** (`flode`) orkestrerar | Claude Code-skills stödjer inte direkt skill→skill; orkestrering sker på agent-nivå |
| Note vs prompt i skill | **Bara `prompt` blir skill** | `note` = Kims privata kommentar; round-trippar i filen men ingår ALDRIG i skillen (kontraktet) |
| Legend | **Auto-fyll** (v71) från använda formtyper | Var manuell + oftast tom = ingen översättare. Nu alltid med, översätter formtypen, Kim kan skriva över |

---

## 3. Vad byggdes (v69→v72)

- **v69** — Process-kontroll: kategorierna **Grind** (gate, romb), **Bevis** (evidence, ny
  cylinder-form = native mermaid `[(...)]`), **Manual** (octagon), **Script** (cyan).
  n8n-paletten → 13 chips i 3 rader. Första MFP-kedjan ritad + skill byggd + **validerad mot
  Canon Sverige** → `official_source_map.md`.
- **v70** — **Skill-containrar:** "Spara skill som fil" (tryck-håll container → egen `.md` i
  iCloud, utan att byta aktuell fil). `containerSubset()` utbruten. Hexagon-markör på skill-
  containrar. `mfp-pipeline.md` (4 skill-containrar i en fil).
- **v71** — **Legend som översättare:** `generate()` auto-fyller `%% legend <kategori>: <text>`
  per använd formtyp (manuell rad vinner, annars `pickerHint`). MermaidCodeSheet skickar legend.
- **v72** — Denna save: dokumentation/handover + CLAUDE.md pekar på allt. Ingen feature-ändring.

Tester: 129/129 unit gröna vid v71 (V69/V70/V71-sviterna + V35 utökad). Kör BARA
`-only-testing:MermaidCanvasUnitTests` (UI-test-målet är långsamt/flakigt — separat spår).

---

## 4. MFP-pipelinens nuläge

EN fil = helheten: **`mfp-pipeline.md`** (iCloud Mermaid-mapp), 4 skill-containrar:

1. **mfp-site-intelligence** — KLAR. Skill: `~/.claude/skills/mfp-site-intelligence/SKILL.md`.
   Ritad: `mfp-site-intelligence.md`. **Körd + validerad mot Canon Sverige** →
   `mfp-site-intelligence/official_source_map.md` (+ `evidence/`). Fynd: Canon ligger bakom
   **Akamai bot-skydd** (403 på curl/WebFetch) → Skill 2 behöver **Playwright**.
2. **mfp-sortiment** — STUBBE. Läser official_source_map.md, hämtar sidor (Playwright), listar modeller.
3. **mfp-spec** — STUBBE. Extraherar specar → CSV.
4. **mfp-dashboard** — STUBBE. Jämför/kravmatchar.

Dirigent som kör hela kedjan: skillen **`flode`** ("bygg/kör flödet mfp-pipeline").

---

## 5. Nästa steg

1. **Verifiera v70/v71 på iPhone** (Kim): "Spara skill som fil" skapar verkligen filen;
   legend-rader syns i kod-vyn. (Logiken är test-grön; knapptrycket ej exercerat på enhet.)
2. **Bygg Skill 2 (mfp-sortiment):** start från `official_source_map.md`, Playwright mot canon.se
   (förbi Akamai), lista produktfamiljer/modeller → `product_candidates.md`. Ingen spec-extraktion än.
3. Sedan Skill 3 (spec → CSV) och Skill 4 (dashboard).

---

## 6. Var allt finns (snabb-pekare)
- Kod + styrdokument: `/Users/kim/2e Mermaid Code/` (git + GitHub kim0scar/MermaidCanvas).
- Version: `app/MermaidCanvas/Sources/App/AppVersion.swift` = **v72**. Tagg `v72` + ZIP i iCloud.
- MFP-skill: `~/.claude/skills/mfp-site-intelligence/`. Dirigent: `~/.claude/skills/flode/`.
- iCloud canvas: `…/00000. Claude Code/1. Mermaid/` (`mfp-pipeline.md`, `mfp-site-intelligence.md`,
  `mfp-site-intelligence/official_source_map.md` + `evidence/`).
- Memory: `~/.claude/projects/-Users-kim-2e-Mermaid-Code/memory/` (`project_mfp_pipeline`).
- Kontrakt: `SKILL-KEDJA-KONTRAKT.md`, `N8N-FLODE-KONTRAKT.md`, `MERMAID-FAKTA.md`, `METOD-VISUELL-DIALOG.md`.
