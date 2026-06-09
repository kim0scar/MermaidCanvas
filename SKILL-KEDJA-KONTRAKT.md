# SKILL-KEDJA-KONTRAKT — från ritat flöde till kedja av Claude Code-skills

*Kontrakt för Claude Code. Kim ritar en kedja i Visuali2e → kopierar mermaid-koden
(eller delar av den) → Claude kör eller bygger skills av den. Systerdokument till
`N8N-FLODE-KONTRAKT.md` (n8n-mål); detta dokument gäller mål = Claude Code-skills.*

---

## Idén i en bild

```
[trigger] → ┌─ SKILL 1 ─┐ → (fil 1) → ┌─ SKILL 2 ─┐ → (fil 2) → ┌─ SKILL 3 ─┐ → [svar]
            │ steg, steg │             │ steg, steg │             │ steg, steg │
            └────────────┘             └────────────┘             └────────────┘
```

Skills avlöser varandra. Varje överlämning är en **markdown-fil** — synlig som en
nod på canvasen och läsbar för både Kim och Claude. Allt som behövs för att köra
står I flödet: inga gissningar.

---

## Rit-konvention (vad varje sak på canvasen betyder)

| Canvas-element | Betyder | Krav |
|---|---|---|
| **`input`-nod** (grön) | Kedjans trigger | `prompt` = trigger-fras/villkor ("kör morgonkoll", "varje morgon 07:00") |
| **Container** (subgraph) | **EN skill** | Containerns namn = skillens namn. Containerns `prompt` = skillens syfte i en mening. |
| **`agent`-nod i container** | Ett subagent-steg i skillen | `prompt` = HELA subagent-instruktionen: vad, hur, format på resultatet |
| **`tool`-nod i container** | Verktygs-steg (Gmail, web, fil, MCP...) | `prompt` = exakt vad verktyget ska göra + parametrar |
| **`memory`-nod** (violett) MELLAN containrar | **Överlämnings-fil** (output → input) | `label` = filnamn. `prompt` = sökväg + förväntat innehållsformat |
| **`router`-nod** | Villkor | Gren-etikett = villkoret; gren utan etikett = annars |
| **`gate`-nod** (rosa romb) | **Grind** — måste-passera-kontroll | `prompt` = villkoret + vad som händer vid STOPP. Grind ≠ router: den släpper igenom eller stoppar, väljer aldrig väg. |
| **`subagent`-nod** (lila) | Väg i en redundans-våg | `prompt` = hela väginstruktionen + VERKTYG + egen rapportfil. Blind för systervägarna. |
| **`evidence`-nod** (cylinder) | Bevis-lager | `prompt` = sökväg till `evidence/`. Allt som hävdas ska gå att härleda hit. |
| **`manual`-nod** (åttahörning) | Mänsklig koll — automatiken stoppar | `prompt` = filens sökväg + format. Gissa aldrig i stället för att flagga. |
| **`output`-nod** (röd) | Kedjans slutresultat | `prompt` = vart: "svar i chatten", fil, mejl... |
| **Kant-etikett** | Villkor eller vad som lämnas över | |

**Detaljnivå-regel:** varje `prompt` ska vara komplett nog att ge en subagent som
ALDRIG sett kedjan. Skriv alltid: (1) input — vad steget får, (2) uppgiften,
(3) output — exakt format och var det ska sparas.

## Körregler för Claude

1. **Ordning** = topologisk ordning från pilarna. Container körs när dess inputs finns.
2. **En container = en subagent-körning** (eller flera om containern har flera steg-noder
   — då körs noderna i pil-ordning inom containern).
3. **Överlämning:** skriv ALLTID memory-nodens fil innan nästa container startar.
   Filen är kontraktet — nästa skill läser bara filen, inte föregående skills kontext.
4. **Fil-plats:** memory-nodens `prompt` anger sökväg. Saknas sökväg → lägg i
   `<canvas-filens mapp>/<kedjenamn>/<filnamn>` så Kim ser allt i iCloud.
5. **Router:** läs villkoret från gren-etiketten; default-gren = utan etikett.
6. **Fel i ett steg:** stoppa kedjan, skriv vad som hänt i den fil steget skulle
   producerat (under rubriken `## FEL`), rapportera till Kim.
7. **Gissa aldrig credentials/konton** — använd det som redan är inloggat (MCP),
   annars stoppa och fråga.

## Två kommandon

| Kim säger | Claude gör |
|---|---|
| **"kör flödet"** (+ mermaid/filnamn) | Exekverar kedjan EN gång, nu. Subagent per container. |
| **"bygg skills av flödet"** | Skapar en permanent skill per container i `~/.claude/skills/<namn>/SKILL.md` + en kedje-skill som kopplar ihop dem. |

Skill-namn: containerns namn i kebab-case. Trigger-fraser: input-nodens prompt +
containernamnet.

## Delar av koden räcker

Kim kan kopiera BARA en container (med sina noder) — då körs/byggs bara den skillen.
Memory-noder i kanten av urklippet tolkas som skillens input-/output-filer.
**v66:** appen har knappen för detta — tryck-håll en container → **"Kopiera som skill"**
ger exakt den delmängden (container + barn + memory-noder i kanten) som självbärande mermaid.

## Regler som låstes i v66

- **Prompt vs anteckning:** nodens `prompt` är subagent-instruktionen och ingår i skillen.
  Nodens `note` (anteckning) är Kims egen kommentar — den round-trippar i mermaid
  (`%% id note:`) men ingår ALDRIG i skill-prompten.
- **En skill = EN container.** Skill-i-skill stöds inte. **Undantag (v73): en inre
  container INUTI en skill-container är en VÅG-GRUPP, inte en skill** — se nedan.
- **Pilar går nod → nod, aldrig till/från själva containern.** Containern är skill-GRÄNSEN.
- **Legend:** `%% legend <kategori>: <text>`-rader i mermaid-blocket är Kims förklaring
  av vad varje form/kategori betyder — läs dem som kontext, de är inte noder.

## Redundans-mönstret (v73 — Kims arkitektur från !MERMAID BETA)

Det här mönstret är hur en kedja blir PÅLITLIG i stället för en gissning. Det består av
fem delar som alltid hänger ihop:

1. **Våg-grupp** — en inre container inuti en skill-container. Den är INTE en egen skill.
   Dess barn (subagent-noder) löser SAMMA uppgift med OLIKA metoder/verktyg, körs
   **parallellt** som egna subagents, **blinda för varandra**. Varje väg skriver sin EGEN
   rapportfil (samma format — formatet står i memory-noden vågen pekar på).
   Våg-gruppens `prompt` = uppgiften + redundanspolicyn.
2. **Gap-analys** (agent-nod) — läser ENBART vägarnas rapportfiler. Klassar varje
   påstående: BEKRÄFTAT (≥2 vägar) / ENSAMT (1 väg) / KONFLIKT (motsägelse).
3. **Konsensus-grind** (gate-nod) — släpper bara igenom det BEKRÄFTADE. Diffar går till
   verifieringsvågen. Max 2 varv (varv-räknare i gap-analys-filen).
4. **Verifieringsvåg** (agent-nod, loop-pil tillbaka till gap-analysen) — utreder ENBART
   diffarna, med starkaste verktyget för fallet, och noterar VARFÖR vägarna diffade.
   "Varför" säger var processen ska brytas ner djupare.
5. **Manual-utgång** — kvarstående diff efter 2 varv flaggas i manual-nodens fil och
   leveransens Status sätts till PARTIAL. Aldrig tyst igenom, aldrig gissat.

**Redundanspolicy (default):** 4 vägar i discovery (okänd terräng), 2 vägar (par) i
extraktion (känd terräng). Ger 10 körningar i rad full konsensus utan verifieringsvarv →
dra ner antalet vägar ett steg. Vid första diff → upp igen.

**Körregel för våg-grupp:** en BLOCKERAD väg (bot-skydd, nätfel) är INTE ett kedjefel —
den noteras med orsak i sin rapport och de andra vägarna fortsätter. Kedjefel = ALLA
vägar blockerade.

**Referens-exempel:** `mfp-site-intelligence.md` (4-vägs discovery) och
`mfp-sortiment.md` (E1/E2-par) i iCloud-Mermaid-mappen.

---

## Referens-exempel

`morgonkoll-flode.md` (i Kims iCloud-Mermaid-mapp) är referens-kedjan:
mejl-svep → sammanfatta → rapport, med alla prompts på subagent-detaljnivå.
Den är också testad på riktigt — körningen ligger i `morgonkoll/`-mappen bredvid.

---

*Utvecklas bakåtkompatibelt, samma regler som METOD-VISUELL-DIALOG.md. När en ny
konvention behövs: lägg till här + i exempel-flödet i samma commit.*
