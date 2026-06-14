---
skill_protocol_version: 0.1
kind: skill
skill_id: demo-skill-3-subagents
skill_number: 3
title: Demo Skill 3 — Subagents (vokabulärsbeviset)
trigger: "kör demo-skill-3"  # + valfritt ämne, default 'elcyklar'
---

# demo-skill-3-subagents — Skill Protocol Package (referens)

Detta är ett **självbärande** Skill Protocol Package. Det beskriver ett helt
flöde — noder, kopplingar, körmodell, manifest, grind, output och validatorregler
— i en enda fil. En läsare som aldrig sett projektet ska kunna förstå och
**dry-runa** flödet enbart utifrån denna fil.

Mönstret som bevisas: **subagent är en egen nodtyp** (egen agent, eget
kontextfönster, egen uppgift) och **verktyg är metadata i nodens kontrakt** —
inte en egen nod. Två subagenter tar olika vägar, blinda för varandra, och
skriver var sin fil. En gap-agent jämför **enbart filerna**. En grind avgör utan
att skapa fakta. Resultatet är en **fil**.

---

## Så här läser och kör du detta protokoll (självbärande regler)

**Källordning:** `Node contracts` (YAML) är den exekverbara sanningen. `Mermaid`
är en vy av samma graf. Vid konflikt vinner contractet. `prompt`-fältet är bara
en naturlig instruktion — all hård logik (verktyg, läsrättigheter, skrivmål,
pass/fail) står i strukturerade fält, inte i prompten.

**Nodtyper (`type`):**
- `input` — det användaren ger när skillen startar.
- `script` — deterministiskt steg (kod, inte LLM).
- `subagent` — egen agent med eget kontextfönster; verktyg står i kontraktet
  (`allowed_tools`/`forbidden_tools`) och blindhet i `forbidden_reads`.
- `agent` — LLM som analyserar/syntetiserar **från redan skapade filer**; surfar
  aldrig.
- `gate` — kontrollpunkt; läser, utvärderar, dirigerar. **Skapar aldrig fakta.**
- `memory` — överlämningsfil (markdown) mellan steg; har en ägare och ett format.
  `role` förfinar: `handoff`, `result_writer`, `manifest`.
- `manual` — automatiken stoppar och flaggar till en människa.
- `output` — slutsteg; visar den aktiva outputfilen och pekar `latest/` rätt.

**Kant-typer (`kind`):** `normal` (kontrollflöde) · `pass`/`fail` (utgår från en
grind) · `writes` (en nod skriver till en memory-fil) · `reads` (en nod läser en
memory-fil).

**Var allt bottnar (root_path):** alla sökvägar nedan är relativa till
`<root_path>/<run_root>/`. Här är `root_path: skill_dir` (katalogen där denna fil
ligger) och `run_root: demo-skill-3`. Så `runs/<run_id>/s1_research.md` betyder
`<denna-fils-katalog>/demo-skill-3/runs/<run_id>/s1_research.md`. Lös upp en gång
vid start; skriv aldrig utanför den mappen.

**Körmodell:**
1. Skapa ett unikt `run_id` = `YYYY-MM-DD_HHMM_<slug>` (lokal tid Europe/Stockholm).
   `<slug>`: gemener, `å/ä→a` `ö→o`, blanksteg/`/`→`-`, bara `[a-z0-9-]`, max 40
   tecken, tomt → `amne`. **Unikhet:** finns `runs/<run_id>/` redan, lägg på `_2`,
   `_3`, … tills mappen är ny. Återanvänd aldrig en run-mapp.
2. Skapa run-mappen `runs/<run_id>/`. **Allt** skrivs där — aldrig i run_root och
   aldrig i en äldre run-mapp.
3. Följ kanterna. Noder i samma parallella grupp körs samtidigt och MÅSTE vara
   blinda för varandras filer.
4. **Manifest-ordning (samma för PASS och FAIL):** script skapar manifestet
   (status STARTAD, aktiv outputfil PENDING) → grinden sätter PASS/FAIL + aktiv
   outputfil + gateutfall (FÖRE grenvalet) → [bara vid FAIL] manual skriver filen
   → output slutför fillistan + kopierar till `latest/run_manifest.md`.
5. `latest/run_manifest.md` är alltid en kopia av senaste runnens manifest.

**Statusar:** bara `STARTAD`, `PASS`, `FAIL`, `ARKIV`. Ingen `PARTIAL`. (ARKIV
sätts för hand för pensionerade runs, aldrig av flödet.)

**PASS/FAIL:** grindens utfall följer av `gap_analys.md`. Men FÖRST kollas båda
research-filerna: saknas en (`missing_file`), bryter formatet (`format_fail`)
eller har < 3 källrader (`source_count_fail`) ⇒ **FAIL → manual** (grinden räknar
aldrig konsensus på trasig data, fabricerar aldrig). Annars: PASS ⇒ aktiv output
`resultat.md` (ingen aktiv `manual_review.md`); FAIL ⇒ aktiv output
`manual_review.md` (ingen `resultat.md`). Manifestets `status` och `aktiv
outputfil` MÅSTE matcha utfallet.

---

## Mermaid

```mermaid
flowchart LR
    input_amne["Input: ämne"]
    script_mapp["Skapa run-mapp"]
    subagent_s1["Subagent S1: webbsök"]
    subagent_s2["Subagent S2: statisk hämtning"]
    memory_s1[("s1_research.md")]
    memory_s2[("s2_research.md")]
    agent_gap["Gap-agent: jämför filerna"]
    memory_gap[("gap_analys.md")]
    gate_konsensus{"Konsensus?"}
    memory_resultat[("resultat.md")]
    memory_manifest[("run_manifest.md")]
    manual_koll["manual_review.md"]
    output_visa["Visa aktiv output"]

    input_amne --> script_mapp
    script_mapp --> subagent_s1
    script_mapp --> subagent_s2
    subagent_s1 -->|writes| memory_s1
    subagent_s2 -->|writes| memory_s2
    memory_s1 -->|reads| agent_gap
    memory_s2 -->|reads| agent_gap
    agent_gap -->|writes| memory_gap
    memory_gap -->|reads| gate_konsensus
    gate_konsensus -->|pass| memory_resultat
    gate_konsensus -->|fail| manual_koll
    gate_konsensus -->|writes| memory_manifest
    memory_resultat -->|reads| output_visa
    memory_manifest -->|reads| output_visa
    manual_koll -->|reads| output_visa
```

---

## Skill metadata

```yaml
skill_id: demo-skill-3-subagents
title: "Demo Skill 3 — Subagents (vokabulärsbeviset)"
description: "Två blinda subagenter researchar via olika verktyg, en gap-agent jämför enbart filerna, en grind avgör utan att skapa fakta, resultatet är en fil."
input: "ett ämne (fritext); default 'elcyklar'"
output: "runs/<run_id>/ med run_manifest.md + aktiv outputfil; latest/run_manifest.md pekar på senaste körningen"
root_path: skill_dir            # katalogen där denna .skill.md ligger
run_root: "demo-skill-3"        # mappnamn under root_path
```

---

## Node contracts

```yaml
nodes:
  - id: input_amne
    type: input
    title: "Input: ämne"
    inputs: []
    outputs: [ämne]
    pass_conditions: "alltid (fältet har default 'elcyklar')"
    prompt: "Trigger: användaren säger 'kör demo-skill-3' + valfritt ämne. Obligatoriskt: nej. Default: 'elcyklar'."

  - id: script_mapp
    type: script
    role: run_initializer
    title: "Skapa run-mapp"
    inputs: [ämne]
    outputs: [run_id, "runs/<run_id>/", "runs/<run_id>/run_manifest.md"]
    allowed_tools: [Bash]            # date, mkdir -p
    forbidden_tools: [WebSearch]
    write_scope: "runs/<run_id>/"
    pass_conditions: "run-mappen och run_manifest.md finns efteråt med run_id, input, status: STARTAD, aktiv outputfil: PENDING"
    fail_behavior: "gå till manual_koll med felet"
    prompt: "Skapa run_id = YYYY-MM-DD_HHMM_<slug> (lokal tid; slug-regler enligt läs-guiden; om runs/<run_id>/ finns, lägg på _2/_3...). Skapa runs/<run_id>/, skriv run_manifest.md: run_id, input (ämnet), status: STARTAD, aktiv outputfil: PENDING."

  - id: subagent_s1
    type: subagent
    role: researcher
    title: "Subagent S1: webbsök"
    inputs: [ämne, run_id]
    outputs: ["runs/<run_id>/s1_research.md"]
    allowed_tools: [WebSearch]
    forbidden_tools: [static_fetch]
    allowed_reads: []
    forbidden_reads: ["runs/<run_id>/s2_research.md"]     # blind för syskonet
    write_scope: "runs/<run_id>/s1_research.md"
    pass_conditions: "filen har H1 'S1 Research: <ämne>' + exakt 3 rader '- <fakta> (källa: <URL>)' + raden 'Sökfraser:'"
    fail_behavior: "skriv rubriken FEL + orsaken i filen och fortsätt (gap-agenten ser felet)"
    prompt: "Hitta 3 aktuella fakta om ämnet, var och en med källa, via webbsökning. Hitta aldrig på källor."

  - id: subagent_s2
    type: subagent
    role: researcher
    title: "Subagent S2: statisk hämtning"
    inputs: [ämne, run_id]
    outputs: ["runs/<run_id>/s2_research.md"]
    allowed_tools: [static_fetch]    # capability: HTTP GET av känd URL (curl); INTE sökmotor
    forbidden_tools: [WebSearch]
    allowed_reads: []
    forbidden_reads: ["runs/<run_id>/s1_research.md"]     # blind för syskonet
    write_scope: "runs/<run_id>/s2_research.md"
    pass_conditions: "filen har H1 'S2 Research: <ämne>' + exakt 3 rader '- <fakta> (källa: <URL>)' + raden 'Hämtade sidor:'"
    fail_behavior: "om GET blockeras → fallback browser_nav mot samma URL; faller även det → skriv rubriken FEL + orsaken i filen och fortsätt. ALDRIG sökmotor, ALDRIG påhittade källor."
    prompt: "Hitta 3 aktuella fakta om ämnet via en ANNAN väg än S1: hämta rå text direkt från kända källsidor. Hitta aldrig på källor."

  - id: memory_s1
    type: memory
    role: handoff
    title: "s1_research.md"
    outputs: ["runs/<run_id>/s1_research.md"]
    write_scope: "runs/<run_id>/s1_research.md (ägare: subagent_s1)"
    pass_conditions: "filen finns och följer formatet (H1 + 3 källrader + 'Sökfraser:')"

  - id: memory_s2
    type: memory
    role: handoff
    title: "s2_research.md"
    outputs: ["runs/<run_id>/s2_research.md"]
    write_scope: "runs/<run_id>/s2_research.md (ägare: subagent_s2)"
    pass_conditions: "filen finns och följer formatet (H1 + 3 källrader + 'Hämtade sidor:')"

  - id: agent_gap
    type: agent
    role: synthesizer
    title: "Gap-agent: jämför filerna"
    inputs: ["runs/<run_id>/s1_research.md", "runs/<run_id>/s2_research.md"]
    outputs: ["runs/<run_id>/gap_analys.md"]
    allowed_reads: ["runs/<run_id>/s1_research.md", "runs/<run_id>/s2_research.md"]
    forbidden_tools: [WebSearch, static_fetch]   # surfar aldrig, skapar ingen ny fakta
    forbidden_reads: ["runs/<annan_run_id>/*"]   # aldrig filer från andra runs
    write_scope: "runs/<run_id>/gap_analys.md"
    preconditions: "kolla FÖRST båda research-filerna: missing_file (saknas) / format_fail (fel H1 eller saknar källrad-mönstret eller märkt FEL) / source_count_fail (< 3 källrader). Vilken som helst ⇒ notera felmoden i gap_analys.md och låt utfallet bli FAIL."
    pass_conditions: "båda filerna passerar preconditions OCH varje påstående har en status (BEKRÄFTAT/ENSAMT/KONFLIKT)"
    fail_behavior: "skriv felmoden i gap_analys.md och gå till manual_koll — fabricera ALDRIG saknade påståenden"
    prompt: "Validera först båda filerna (se preconditions). Jämför sedan påståendena och klassa varje: BEKRÄFTAT (båda), ENSAMT (en väg), KONFLIKT (motsäger). Skriv en tabell Påstående | S1 | S2 | Status."

  - id: memory_gap
    type: memory
    role: handoff
    title: "gap_analys.md"
    outputs: ["runs/<run_id>/gap_analys.md"]
    write_scope: "runs/<run_id>/gap_analys.md (ägare: agent_gap)"
    pass_conditions: "H1 'Gap-analys: <ämne>' + tabell med kolumnen Status ifylld för varje rad"

  - id: gate_konsensus
    type: gate
    title: "Konsensus?"
    allowed_reads: ["runs/<run_id>/gap_analys.md"]    # ENDAST aktuell run
    forbidden_tools: [WebSearch, static_fetch]        # skapar aldrig fakta
    pass_conditions: "research-preconditions OK (annars FAIL) OCH minst 2 påståenden BEKRÄFTAT OCH ingen olöst KONFLIKT"
    fail_behavior: "vidare till manual_koll"
    write_scope: "runs/<run_id>/run_manifest.md (endast bokföring: gatevillkor, gateutfall, status, aktiv outputfil)"
    prompt: "GRIND. Läs bara gap_analys.md i aktuell run-mapp. Sätt status PASS/FAIL + aktiv outputfil i run_manifest.md FÖRE grenvalet. PASS ⇒ resultat.md. FAIL (inkl. trasig research-fil) ⇒ manual_review.md. Skapar aldrig fakta."

  - id: memory_resultat
    type: memory
    role: result_writer
    title: "resultat.md"
    outputs: ["runs/<run_id>/resultat.md"]
    write_scope: "runs/<run_id>/resultat.md (ägare: kedjan; skrivs ENBART efter PASS, ALDRIG i en FAIL-run)"
    pass_conditions: "H1 'Resultat: <ämne>' + rader run_id, Status: PASS, Gate-villkor, + de BEKRÄFTADE påståendena med båda källorna"

  - id: memory_manifest
    type: memory
    role: manifest
    title: "run_manifest.md"
    outputs: ["runs/<run_id>/run_manifest.md"]
    write_scope: "runs/<run_id>/run_manifest.md (kedjan: script skapar, gate+output uppdaterar)"
    pass_conditions: "rader run_id, input, status, aktiv outputfil, 'Skapade filer', gatevillkor, gateutfall finns OCH PASS/FAIL-reglerna håller"

  - id: manual_koll
    type: manual
    title: "manual_review.md"
    outputs: ["runs/<run_id>/manual_review.md"]
    write_scope: "runs/<run_id>/manual_review.md (ägare: kedjan vid FAIL)"
    pass_conditions: "innehåller run_id, vilket villkor som föll, vad som testats, varför automatiken stoppar, exakt vad användaren ska kontrollera"
    prompt: "STOPP — mänsklig koll. Gissa inte, reparera inte tyst. I en PASS-run får filen bara finnas om den är märkt 'Scope-beslut'."

  - id: output_visa
    type: output
    title: "Visa aktiv output"
    inputs: ["runs/<run_id>/run_manifest.md"]
    allowed_reads: ["runs/<run_id>/run_manifest.md", "runs/<run_id>/resultat.md", "runs/<run_id>/manual_review.md"]
    write_scope: "runs/<run_id>/run_manifest.md (slutför fillistan) + latest/run_manifest.md"
    pass_conditions: "den aktiva outputfilen (enligt manifest) visas ordagrant; latest/run_manifest.md är en kopia av aktuella manifestet; första raden i svaret är PASS eller FAIL"
    prompt: "Visa den aktiva outputfilen enligt run_manifest.md i AKTUELL run-mapp. Komplettera manifestets fillista. Skriv latest/run_manifest.md som kopia."
```

---

## Edge contracts

```yaml
edges:
  - { from: input_amne,     to: script_mapp,     kind: normal }
  - { from: script_mapp,    to: subagent_s1,     kind: normal }
  - { from: script_mapp,    to: subagent_s2,     kind: normal }
  - { from: subagent_s1,    to: memory_s1,       kind: writes }
  - { from: subagent_s2,    to: memory_s2,       kind: writes }
  - { from: memory_s1,      to: agent_gap,       kind: reads }
  - { from: memory_s2,      to: agent_gap,       kind: reads }
  - { from: agent_gap,      to: memory_gap,      kind: writes }
  - { from: memory_gap,     to: gate_konsensus,  kind: reads }
  - { from: gate_konsensus, to: memory_resultat, kind: pass }
  - { from: gate_konsensus, to: manual_koll,     kind: fail }
  - { from: gate_konsensus, to: memory_manifest, kind: writes }
  - { from: memory_resultat, to: output_visa,    kind: reads }
  - { from: memory_manifest, to: output_visa,    kind: reads }
  - { from: manual_koll,    to: output_visa,     kind: reads }
```

---

## Execution policy

```yaml
execution:
  root_path: skill_dir                             # katalogen där denna fil ligger
  run_root: demo-skill-3                            # mappnamn under root_path
  run_id_format: "YYYY-MM-DD_HHMM_<slug>"          # lokal tid Europe/Stockholm; t.ex. 2026-06-14_0930_elcyklar
  run_id_slug: "gemener; å/ä→a, ö→o; blanksteg och / → -; bara [a-z0-9-]; max 40 tecken; tomt → amne"
  run_id_uniqueness: "om runs/<run_id>/ finns, lägg på _2/_3/... ; återanvänd aldrig en run-mapp"
  run_dir: "runs/<run_id>/"                        # relativt <root_path>/<run_root>/
  parallel_groups:
    - [subagent_s1, subagent_s2]                   # blinda för varandra
  ordering: follow_edges
  manifest:
    file: run_manifest.md
    required_fields: [run_id, input, status, "aktiv outputfil"]
    written_by: script_mapp
    updated_by: [gate_konsensus, output_visa]
    lifecycle:                                     # exakt ordning, samma för PASS/FAIL
      - "script_mapp: status STARTAD, aktiv outputfil PENDING"
      - "gate_konsensus: status PASS|FAIL + aktiv outputfil + gatevillkor + gateutfall (FÖRE grenvalet)"
      - "manual_koll: ENDAST vid FAIL — skriv manual_review.md"
      - "output_visa: slutför 'Skapade filer' + kopiera till latest/run_manifest.md"
  latest:
    dir: "latest/"
    copy_of: run_manifest.md
  rules:
    - "Allt en körning skapar skrivs under run_dir — aldrig i run_root eller i en äldre run."
    - "gate_konsensus skapar aldrig fakta; den läser, utvärderar och dirigerar."
    - "subagent_s1 och subagent_s2 är blinda för varandras filer (forbidden_reads)."
```

---

## Validator spec

```yaml
validator:
  manifest_required_fields: [run_id, input, status, "aktiv outputfil"]
  filelist_section: "Skapade filer"
  statuses: [STARTAD, PASS, FAIL, ARKIV]     # ingen PARTIAL i v0.1
  outcomes:
    STARTAD:                                 # övergående tills grinden kört
      active: PENDING
    PASS:
      active: resultat.md
      must_exist: [resultat.md]
      forbid_active: [manual_review.md]      # får bara finnas märkt "Scope-beslut"
    FAIL:
      active: manual_review.md
      must_exist: [manual_review.md]
      must_not_exist: [resultat.md]
    ARKIV:                                    # sätts för hand, aldrig av flödet
      active: INGEN
  research_preconditions:                     # G3 — kollas FÖRE konsensus
    required_files: [s1_research.md, s2_research.md]
    required_source_rows: 3
    on_missing_file: FAIL
    on_format_fail: FAIL
    on_source_count_fail: FAIL
  gate_from_file:
    source_file: gap_analys.md
    count_column: Status
    pass_when: { min: { BEKRÄFTAT: 2 }, max: { KONFLIKT: 0 } }
  manifest_lifecycle:                          # G6 — exakt ordning, samma för PASS/FAIL
    - "script: STARTAD + aktiv PENDING"
    - "gate: PASS|FAIL + aktiv outputfil + gateutfall (före grenval)"
    - "manual: endast vid FAIL"
    - "output: slutför fillista + kopiera latest"
  scope:
    write_must_be_under: "runs/<run_id>/"
    each_memory_single_owner: true           # undantag: role: manifest ägs av kedjan
  latest:
    must_copy_latest: true
```

---

## Verktygs-kapabiliteter (capabilities)

Värdena i `allowed_tools`/`forbidden_tools` är kapabiliteter, inte produktnamn.

| Capability | Får | Får INTE | Fallback | Evidens |
|---|---|---|---|---|
| `web_search` | Fråga en sökmotor, öppna träffar | Hitta på URL:er; läsa annan nods fil | Annan sökmotor | Käll-URL per fakta + raden `Sökfraser:` |
| `static_fetch` | HTTP GET av en **namngiven känd URL** (curl) | Sökmotor (= web_search); JS/klick (= browser_nav); påhittade URL:er | `browser_nav` mot samma URL om GET blockeras | Käll-URL per fakta + raden `Hämtade sidor:` |
| `browser_nav` | Rendera JS, klicka, scrolla | Hitta på innehåll | — (sista utväg) | Käll-URL + kort interaktionsnot |
| `Bash` | Deterministiska kommandon (date, mkdir, cp) | Nätåtkomst utan web_search/static_fetch | — | — |

Regel: en nod får bara operationer dess kapabilitet tillåter. `static_fetch` får
ALDRIG falla tillbaka på en sökmotor — bara på `browser_nav`. Faller även det bort
gäller nodens `fail_behavior`; data hittas aldrig på.

---

## Dry-run-checklista (för en läsare som vill verifiera förståelsen)

1. Användaren säger "kör demo-skill-3 elcyklar". `input_amne` ger ämne=elcyklar.
2. `script_mapp` bygger `run_id` = `YYYY-MM-DD_HHMM_elcyklar` (t.ex.
   `2026-06-14_0930_elcyklar`; finns mappen redan → `_2`), skapar
   `<denna-fils-katalog>/demo-skill-3/runs/<run_id>/` och `run_manifest.md`
   (status STARTAD, aktiv outputfil PENDING).
3. `subagent_s1` (web_search) och `subagent_s2` (static_fetch) körs parallellt,
   blinda för varandra, och skriver `s1_research.md` resp. `s2_research.md`.
4. `agent_gap` läser BARA de två filerna. FÖRST prekontroll: saknad fil /
   formatfel / < 3 källrader ⇒ notera felmoden och utfall FAIL. Annars skriver
   den `gap_analys.md` (tabell med Status per påstående). Surfar aldrig.
5. `gate_konsensus` läser bara `gap_analys.md`. Sätter status + aktiv outputfil i
   manifestet FÖRE grenvalet. ≥2 BEKRÄFTAT och 0 KONFLIKT (och prekontroll OK)
   ⇒ PASS, annars FAIL.
6. PASS ⇒ `resultat.md` skrivs; manifest: status PASS, aktiv outputfil resultat.md.
   FAIL ⇒ `manual_review.md` skrivs; ingen resultat.md; manifest aktiv = manual_review.md.
7. `output_visa` visar aktiv outputfil, slutför manifestets fillista och kopierar
   manifestet till `<denna-fils-katalog>/demo-skill-3/latest/run_manifest.md`.
8. Giltig run ⇔ alla validatorregler ovan håller.
