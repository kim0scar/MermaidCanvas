---
skill_protocol_version: 0.1
kind: schema
title: Skill Protocol Schema
status: normative
---

# SKILL_PROTOCOL_SCHEMA — normativt schema för `.skill.md`

Detta dokument är **normativt**. Nyckelorden **MUST**, **MUST NOT**, **SHOULD**,
**SHOULD NOT** och **MAY** har sin vanliga betydelse (RFC 2119): MUST = krav,
SHOULD = stark rekommendation som får frångås med dokumenterat skäl, MAY = valfritt.

Ett **Skill Protocol Package** är en enda fil med ändelsen `.skill.md`. Filen ska
vara **självbärande**: en främmande Claude Code-kontext utan tillgång till repot,
appen, tidigare konversation eller andra skills MUST kunna läsa filen ensam och
förstå alla noder, edges, run-mapp, manifest, gate, output och validatorregler —
tillräckligt för att dry-runa flödet.

## Grundprincip (icke förhandlingsbar)

```
form  →  node contract  →  Mermaid + Skill Protocol
```

1. **Mermaid är den visuella representationen.** Den visar grafen, inte logiken.
2. **YAML node contracts är den exekverbara specifikationen.** Logiken bor här.
3. **`prompt`-fältet MUST NOT bära all logik.** Allt som kan uttryckas som ett
   strukturerat fält (inputs, outputs, tools, reads, write_scope, pass/fail)
   MUST ligga i det fältet — inte gömt i fritext. `prompt` är den naturliga
   instruktionen som ramar in uppgiften, inte kontraktet i sig.

---

## 1. Filstruktur för `.skill.md`

Filen MUST innehålla dessa sektioner, i denna ordning:

| # | Sektion | Form | Krav |
|---|---|---|---|
| 1 | Protocol-header | YAML frontmatter (`---`) | MUST |
| 2 | Titel + beskrivning | Markdown (`# …` + stycke) | MUST |
| 3 | `## Mermaid` | ` ```mermaid `-block | MUST |
| 4 | `## Skill metadata` | ` ```yaml `-block | MUST |
| 5 | `## Node contracts` | ` ```yaml `-block | MUST |
| 6 | `## Edge contracts` | ` ```yaml `-block | MUST |
| 7 | `## Execution policy` | ` ```yaml `-block | MUST |
| 8 | `## Validator spec` | ` ```yaml `-block | MUST |

Filen MAY innehålla ytterligare markdown-sektioner (förklaringar, exempel) efter
sektion 8. Dessa är icke-normativa och påverkar aldrig exekvering.

---

## 2. Protocol-header (frontmatter)

YAML-frontmatter överst. Fält:

| Fält | Krav | Beskrivning |
|---|---|---|
| `skill_protocol_version` | MUST | Protokollets version, t.ex. `0.1`. |
| `kind` | MUST | `skill` för ett körbart paket (`schema` reserverat för detta dokument). |
| `skill_id` | MUST | Stabil maskin-id, kebab-case, t.ex. `demo-skill-3-subagents`. |
| `skill_number` | SHOULD | Heltal — paketets plats i en kedja. |
| `title` | MUST | Människoläsbar titel. |
| `trigger` | SHOULD | Hur skillen startas (fras/argument). |

Filen MUST NOT vara körbar om `skill_protocol_version` saknas eller är okänd för
läsaren.

---

## 3. Mermaid-sektion (visuell vy)

` ```mermaid `-block med `flowchart`. Reglerna:

- Varje nod i grafen MUST ha exakt ett node contract med samma `id` (sektion 5).
- Varje edge i grafen MUST ha exakt ett edge contract (sektion 6).
- Mermaid-blocket MUST NOT innehålla logik som inte också finns i contracten.
  Vid konflikt mellan graf och contract är **contractet sanning**; grafen är vy.
- Nodformen (rektangel, romb, cylinder, oktagon …) SHOULD spegla nodens `type`
  men är icke-normativ — `type` i contractet avgör, inte formen.

---

## 4. YAML-schema: Skill metadata

```yaml
skill_id: <kebab-case>        # MUST — matchar headern
title: <text>                 # MUST
description: <text>           # MUST — en mening om vad skillen gör
input: <text>                 # MUST — vad användaren ger
output: <text>                # MUST — vad körningen lämnar (oftast en fil + manifest)
root_path: <abs | skill_dir>  # MUST — se 4.1 (var run_root bottnar)
run_root: <mappnamn>          # MUST — basmappens NAMN under root_path, t.ex. demo-skill-3
```

### 4.1 root_path- och run_root-upplösning (G5 — normativt)

`run_root` är ett **mappnamn**, aldrig en sökväg med snedstreck. Var den bottnar
avgörs av `root_path`, som MUST ha exakt ett av två värden:

| `root_path` | Betyder | Upplöses till |
|---|---|---|
| `skill_dir` | Katalogen där `.skill.md`-filen ligger | `<dir för .skill.md>/<run_root>/` |
| en absolut sökväg (börjar med `/` eller `~`) | Den katalogen | `<root_path>/<run_root>/` |

Regler:
- `root_path: skill_dir` är default-rekommendationen — då är paketet portabelt:
  släpp filen var som helst och körningar hamnar bredvid den.
- Alla sökvägar i node contracts och execution policy är **relativa till
  `<root_path>/<run_root>/`**. Dvs `runs/<run_id>/s1_research.md` betyder fullt ut
  `<root_path>/<run_root>/runs/<run_id>/s1_research.md`.
- En läsare MUST lösa upp `root_path` EN gång vid körstart och därefter aldrig
  skriva utanför den upplösta `<root_path>/<run_root>/`.

---

## 5. YAML-schema: Node contracts

`nodes:` är en lista. Varje nod:

```yaml
nodes:
  - id: <kebab-case>          # MUST — unik, matchar Mermaid-noden
    type: <node_type>         # MUST — se 5.1
    role: <subtype>           # SHOULD — semantisk underkategori (se 5.2)
    title: <text>             # MUST — etiketten i grafen
    inputs: [<...>]           # vad noden tar emot (värden och/eller filer)
    outputs: [<...>]          # vad noden producerar
    allowed_tools: [<...>]    # verktyg noden FÅR använda
    forbidden_tools: [<...>]  # verktyg noden ALDRIG får använda
    allowed_reads: [<...>]    # filer/källor noden FÅR läsa
    forbidden_reads: [<...>]  # filer/källor noden ALDRIG får läsa
    write_scope: <glob>       # var noden FÅR skriva (oftast runs/<run_id>/...)
    pass_conditions: <text>   # vad som räknas som lyckat
    fail_behavior: <text>     # vad som händer vid fel (oftast → manual-noden)
    prompt: <text>            # naturlig instruktion — INTE kontraktet (se princip 3)
```

Vilka fält som är MUST beror på `type` — se 5.3.

### 5.1 Tillåtna `type`-värden (visuell palett)

`input` · `script` · `subagent` · `agent` · `gate` · `memory` · `manual` · `output`

Listan är sluten i v0.1. Nya behov MUST uttryckas med `role` på en befintlig
`type` (se 5.2) — inte genom att uppfinna en ny `type`.

### 5.2 `role` / subtype (utan ny palettform)

Nya begrepp introduceras som `role` på en befintlig `type`. Exempel:

| Begrepp | type | role |
|---|---|---|
| Överlämningsfil | `memory` | `handoff` |
| Resultatskrivare | `memory` | `result_writer` |
| Run-manifest | `memory` | `manifest` |
| Validator | `gate` eller `script` | `validator` |
| Parallell forskare | `subagent` | `researcher` |
| Syntes/jämförelse | `agent` | `synthesizer` |

`role` är SHOULD för memory-, gate- och script-noder, MAY för övriga. Läsaren
MUST tolka en okänd `role` som ren etikett (ingen särskild semantik) men ändå
respektera `type`.

### 5.3 Required fields per node type

| type | MUST-fält (utöver id/type/title) | Noteringar |
|---|---|---|
| `input` | `outputs` | `pass_conditions` MAY anges; default-värde anges i `prompt`. |
| `script` | `write_scope`, `pass_conditions`, `fail_behavior` | `allowed_tools` SHOULD (t.ex. `Bash`). Deterministiskt, ej LLM. |
| `subagent` | `inputs`, `outputs`, `allowed_tools`, `forbidden_tools`, `forbidden_reads`, `write_scope`, `pass_conditions`, `fail_behavior`, `prompt` | Egen agent, eget kontextfönster. `forbidden_reads` MUST lista syskon-subagentens fil om de ska vara blinda för varandra. |
| `agent` | `allowed_reads`, `forbidden_tools`, `pass_conditions`, `fail_behavior` | Läser bara filer. `forbidden_tools` MUST inkludera webb-/sökverktyg om noden inte får skapa ny fakta. |
| `gate` | `allowed_reads`, `pass_conditions`, `fail_behavior` | MUST NOT skriva fakta (se 7). `allowed_reads` MUST peka på EN fil i aktuell run-mapp. |
| `memory` | `role`, `write_scope`, `outputs`, `pass_conditions` | `write_scope` MUST namnge ägaren (en enda skrivare). |
| `manual` | `write_scope`, `pass_conditions` | Stopp för människa. MUST NOT gissa eller reparera tyst. |
| `output` | `allowed_reads`, `write_scope`, `pass_conditions` | Visar aktiv output enligt manifest; MUST uppdatera `latest/`. |

Saknas ett MUST-fält är noden **ogiltig** och flödet MUST NOT köras (validatorn
rapporterar; aldrig tyst ifyllt).

### 5.4 Verktygs-kapabiliteter (capabilities) (G4 — normativt)

Värdena i `allowed_tools`/`forbidden_tools` är **kapabiliteter**, inte konkreta
produktnamn. En kapabilitet säger vad noden FÅR och INTE FÅR göra, vilken
fallback som gäller, och vilket evidenskrav resultatet har. Konkreta verktyg
(WebSearch, curl, Playwright …) är implementationer av en kapabilitet.

| Capability | Tillåtna operationer | Förbjudna operationer | Fallback | Evidenskrav |
|---|---|---|---|---|
| `web_search` | Fråga en sökmotor/sök-API; öppna träffar för att läsa | Hitta på URL:er; läsa annan nods fil | Annan sökmotor | Varje fakta MUST ha käll-URL; raden `Sökfraser:` listar använda frågor |
| `static_fetch` | Hämta rå text/HTML från en **namngiven, känd URL** via enkel HTTP GET (curl/wget) | Sökmotor (= `web_search`); JS-rendering/klick/interaktion (= `browser_nav`); hitta på URL:er | `browser_nav` mot samma URL om GET blockeras (t.ex. 403/bot-skydd) | Varje fakta MUST ha käll-URL som faktiskt hämtades; raden `Hämtade sidor:` listar URL:erna |
| `browser_nav` | Rendera sida med JS, klicka, scrolla, läsa dynamiskt innehåll (headed/headless browser) | Hitta på innehåll; läsa annan nods fil | — (sista utväg) | Varje fakta MUST ha käll-URL + kort not om vilken interaktion som behövdes |
| `read` | Läsa filer i `allowed_reads` | Läsa filer i `forbidden_reads`; surfa | — | — |
| `bash` | Köra deterministiska skal-kommandon (date, mkdir, cp) | Nätåtkomst om inte också `web_search`/`static_fetch` finns | — | — |

Regler:
- En nod MUST NOT använda en operation som tillhör en kapabilitet den inte har.
  Exempel: en `static_fetch`-nod MUST NOT falla tillbaka på en sökmotor — bara på
  `browser_nav`.
- Faller även fallbacken bort MUST noden agera enligt sin `fail_behavior` (oftast:
  skriv rubriken FEL + orsaken i sin fil och fortsätt) — aldrig hitta på data.
- Ett paket MAY definiera fler kapabiliteter i en egen `capabilities:`-sektion;
  saknas en sådan gäller tabellen ovan.

---

## 6. YAML-schema: Edge contracts

`edges:` är en lista. v0.1 MVP-kinds:

```yaml
edges:
  - from: <node_id>           # MUST
    to: <node_id>             # MUST
    kind: <edge_kind>         # MUST — se nedan
    label: <text>             # MAY — etikett i grafen
```

| kind | Betydelse | Regel |
|---|---|---|
| `normal` | Vanligt kontrollflöde | Default. |
| `pass` | Tas när källans gate ger PASS | `from` MUST vara en `gate`. |
| `fail` | Tas när källans gate ger FAIL | `from` MUST vara en `gate`; `to` SHOULD vara `manual`. |
| `writes` | Noden skriver till en memory-fil | `to` MUST vara `memory`; måste rymmas i nodens `write_scope`. |
| `reads` | Noden läser en memory-fil | `from` MUST vara `memory`; måste rymmas i `to`-nodens `allowed_reads`. |

En `gate`-nod MUST ha minst en `pass`-edge och minst en `fail`-edge utgående.

---

## 7. Execution policy

```yaml
execution:
  run_id_format: "YYYY-MM-DD_HHMM_<slug>"        # MUST — se 7.1 (exakt + unik)
  run_dir: "<run_root>/runs/<run_id>/"           # MUST — ALLT skrivs här
  parallel_groups:                               # SHOULD — noder som körs parallellt
    - [subagent_s1, subagent_s2]
  ordering: follow_edges                          # MUST — exekvera enligt edges
  manifest:                                       # MUST
    file: run_manifest.md
    required_fields: [run_id, input, status, "aktiv outputfil"]
    written_by: <script-nod-id>
    updated_by: [<gate-nod-id>, <output-nod-id>]
  latest:                                         # MUST
    dir: "<run_root>/latest/"
    copy_of: run_manifest.md
```

Regler:
- Alla filer en körning skapar MUST ligga under `run_dir`. Skrivning i `run_root`
  eller i en äldre run-mapp är MUST NOT.
- En `gate`-nod MUST NOT skapa fakta — den läser, utvärderar och dirigerar.
- Subagenter i samma `parallel_groups`-grupp MUST vara blinda för varandras filer
  (sätts via `forbidden_reads`).

### 7.1 run_id: format, slug, unikhet (G1 — normativt)

Ett `run_id` MUST byggas som `YYYY-MM-DD_HHMM_<slug>`:

- **Datum/tid:** `YYYY-MM-DD` + `_` + `HHMM`, 24-timmars, nollutfyllt, i lokal tid
  (tidszon `Europe/Stockholm`). Exempel: `2026-06-14_0930`.
- **`<slug>`** härleds från inputtexten med exakt dessa steg, i ordning:
  1. gör om till gemener;
  2. translitterera: `å→a`, `ä→a`, `ö→o`, `é→e`, `ü→u` (övriga icke-ASCII tas bort);
  3. ersätt blanksteg och `/` med `-`;
  4. ta bort alla tecken utanför `[a-z0-9-]`;
  5. slå ihop upprepade `-` till ett, och trimma `-` i början/slutet;
  6. korta av till **max 40 tecken** (trimma avslutande `-` efteråt);
  7. blir resultatet tomt → använd `amne`.
- **Unikhet (MUST):** `run_id` MUST vara unikt. Skapandet av mappen
  `runs/<run_id>/` ÄR unikhetskontrollen: om mappen redan finns MUST `_2`
  (sedan `_3`, …) läggas till på `run_id` tills en oanvänd mapp kan skapas.
  Två körningar samma minut med samma ämne ger alltså `…_0930_elcyklar` och
  `…_0930_elcyklar_2`. En körning MUST NOT återanvända en befintlig run-mapp.

---

## 8. Validator spec

Den maskinella kontrollen. Alla regler MUST vara uppfyllda för att en run ska
räknas som giltig.

```yaml
validator:
  manifest_required_fields: [run_id, input, status, "aktiv outputfil"]
  filelist_section: "Skapade filer"
  statuses: [STARTAD, PASS, FAIL, ARKIV]     # PARTIAL finns INTE i v0.1 (se 8.4)
  outcomes:
    STARTAD:                                 # övergående: satt av script tills grinden kört
      active: PENDING
    PASS:
      active: resultat.md
      must_exist: [resultat.md]
      forbid_active: [manual_review.md]      # om den finns MUST den vara märkt "Scope-beslut"
    FAIL:
      active: manual_review.md
      must_exist: [manual_review.md]
      must_not_exist: [resultat.md]
    ARKIV:                                    # lifecycle-status, sätts för hand (se 8.4)
      active: INGEN
  gate_from_file:                            # gateutfallet MUST följa av filinnehållet
    source_file: gap_analys.md
    count_column: Status
    pass_when: { min: { BEKRÄFTAT: 2 }, max: { KONFLIKT: 0 } }
  research_preconditions:                     # G3 — kollas FÖRE konsensus räknas
    required_files: [s1_research.md, s2_research.md]
    on_missing_file: FAIL                     # filen finns inte
    on_format_fail: FAIL                      # fel H1/saknar källrad-format/markerad FEL
    on_source_count_fail: FAIL                # färre än required_source_rows källrader
    required_source_rows: 3
  manifest_lifecycle:                          # G6 — exakt ordning, samma för PASS/FAIL
    - script: "skapa run_manifest.md, status: STARTAD, aktiv outputfil: PENDING"
    - gate: "sätt status: PASS|FAIL + aktiv outputfil + gatevillkor + gateutfall"
    - manual: "ENDAST vid FAIL: skriv manual_review.md"
    - output: "slutför 'Skapade filer' + kopiera till latest/run_manifest.md"
  scope:
    write_must_be_under: "runs/<run_id>/"
    each_memory_single_owner: true           # exakt en skrivare per memory-fil (undantag: role manifest)
  latest:
    must_copy_latest: true
```

### 8.1 PASS/FAIL-regler (normativt)

- En **PASS-run** MUST ha `resultat.md` som aktiv output och MUST NOT ha en aktiv
  `manual_review.md` (en sådan får bara finnas märkt `Scope-beslut`).
- En **FAIL-run** MUST ha `manual_review.md` som aktiv output och MUST NOT
  innehålla `resultat.md`.
- `status` i manifestet MUST matcha gatens utfall enligt `gate_from_file`.
  Ingen mänsklig eller LLM-override utan att det noteras som `Scope-beslut`.

### 8.2 Read/write-scope-regler (normativt)

- Varje nods skrivningar MUST rymmas i dess `write_scope`, och `write_scope` MUST
  ligga under `runs/<run_id>/`.
- Varje memory-fil MUST ha exakt en ägare (skrivare). Andra noder MAY läsa, MUST
  NOT skriva. **Undantag:** en memory med `role: manifest` ägs av kedjan (script
  skapar den, gate och output uppdaterar den) — undantaget MUST deklareras
  explicit i nodens `write_scope` (t.ex. "kedjan: script skapar, gate+output
  uppdaterar"), annars gäller enkel ägare.
- En nod MUST NOT läsa en källa som ligger i dess `forbidden_reads`.

### 8.3 Manifest- och aktiv-output-regler (normativt)

- `run_manifest.md` MUST finnas i varje run-mapp med `manifest_required_fields`.
- Fältet `aktiv outputfil` MUST namnge exakt den fil som är resultatet av runnen
  (`resultat.md` vid PASS, `manual_review.md` vid FAIL).
- `latest/run_manifest.md` MUST vara en kopia av senaste runnens manifest.
- En arkiverad run MUST ha `status: ARKIV` och `aktiv outputfil: INGEN`.

### 8.4 Tillåtna statusar (G2 — normativt)

`status` i ett manifest MUST vara exakt ett av: **STARTAD**, **PASS**, **FAIL**,
**ARKIV**. Inga andra värden är giltiga i v0.1.

- **STARTAD** — övergående. Sätts av script-noden vid start; `aktiv outputfil`
  är då `PENDING`. En run MUST NOT lämnas i STARTAD efter att grinden kört.
- **PASS / FAIL** — slutstatus från grinden, enligt `gate_from_file`.
- **ARKIV** — *lifecycle-status, inte ett flödesutfall*. Sätts **för hand** när en
  gammal run pensioneras (t.ex. `000-arkiv-…`). Flödet självt producerar ALDRIG
  ARKIV. En ARKIV-run MUST ha `aktiv outputfil: INGEN`.
- **PARTIAL** — **finns inte i v0.1.** Ett delvis lyckat steg leder ändå till en
  binär grind: räcker bevisen ⇒ PASS, annars ⇒ FAIL → manual. Ordet PARTIAL MUST
  NOT förekomma i ett v0.1-paket.

### 8.5 Trasig research-fil (G3 — normativt)

Innan grinden räknar konsensus MUST varje fil i
`research_preconditions.required_files` valideras. Tre felmoder, alla ⇒ **FAIL**
(routas till manual, med felmoden namngiven i `gap_analys.md` och i manifestet):

| Felmod | Innebörd | Utfall |
|---|---|---|
| `missing_file` | Filen finns inte i run-mappen | FAIL — gaten räknar aldrig konsensus på ofullständig data |
| `format_fail` | Filen finns men bryter sitt format (fel/saknad H1, saknar källrad-mönstret, eller är märkt `FEL` av subagenten) | FAIL — raderna från den filen är oanvändbara |
| `source_count_fail` | Filen har färre än `required_source_rows` giltiga källrader | FAIL |

Gap-agenten MUST notera felmoden per fil i `gap_analys.md`. Grinden MUST NOT
fabricera, gissa eller "läka" saknade påståenden för att nå PASS.

### 8.6 Manifest-livscykel och ordning (G6 — normativt)

`run_manifest.md` MUST uppdateras i exakt denna ordning, **identisk för PASS och
FAIL** (enda skillnaden är manual-steget):

1. **script** skapar manifestet: `status: STARTAD`, `aktiv outputfil: PENDING`,
   raderna `run_id` och `input`.
2. **gate** sätter `status: PASS|FAIL`, `aktiv outputfil` (`resultat.md` vid PASS,
   `manual_review.md` vid FAIL) samt `gatevillkor` och `gateutfall`. Detta sker
   **före** grenvalet — manifestet är alltså sant även om FAIL-grenen tas.
3. **manual** (ENDAST vid FAIL) skriver `manual_review.md`.
4. **output** kompletterar `## Skapade filer` och kopierar manifestet till
   `latest/run_manifest.md`.

En run där grinden inte hunnit sätta steg 2 MUST behandlas som ofullständig
(`STARTAD`), aldrig som PASS.

---

## 9. Exempel — giltig nod

```yaml
- id: subagent_s1
  type: subagent
  role: researcher
  title: "Subagent S1: webbsök"
  inputs: [ämne, run_id]
  outputs: [s1_research.md]
  allowed_tools: [WebSearch]
  forbidden_tools: [static_fetch]
  allowed_reads: []
  forbidden_reads: [s2_research.md]          # blind för syskonet
  write_scope: "runs/<run_id>/s1_research.md"
  pass_conditions: "filen har H1 + exakt 3 rader '- <fakta> (källa: <URL>)' + raden 'Sökfraser:'"
  fail_behavior: "skriv rubriken FEL + orsaken i filen och fortsätt (gap-agenten ser felet)"
  prompt: "Hitta 3 aktuella fakta om ämnet, var och en med källa, via webbsökning."
```

Varför giltig: alla MUST-fält för `subagent` finns; `forbidden_reads` gör den
blind för S2; `write_scope` ligger under run-mappen; logiken bor i fälten, inte
i `prompt`.

## 10. Exempel — ogiltig nod

```yaml
- id: subagent_s1
  type: subagent
  title: "Subagent S1"
  prompt: "Hitta fakta om ämnet med webbsök, undvik att titta på S2:s fil,
           skriv till s1_research.md, klart när 3 källor finns."
```

Varför ogiltig:
- Saknar MUST-fält: `inputs`, `outputs`, `allowed_tools`, `forbidden_tools`,
  `forbidden_reads`, `write_scope`, `pass_conditions`, `fail_behavior`.
- Bryter mot princip 3: hela logiken (tools, blindhet, write-mål, pass-villkor)
  ligger gömd i `prompt` istället för i strukturerade fält.

Validatorn MUST avvisa denna nod och MUST NOT köra flödet.

---

## 11. Versionering

`skill_protocol_version: 0.1`. Bakåtinkompatibla ändringar bumpar minor (0.2 …).
En läsare MUST vägra köra ett paket vars major-version är högre än läsaren känner.
