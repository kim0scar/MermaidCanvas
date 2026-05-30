# Metod: Användartest av UI med AI-personas (idb)

*Skapad: 2026-05-30 (v50.6). Portabel metod — gäller iOS-projekt med UI.*

## Vad det är

AI-agenter som **fritt navigerar appen som riktiga användare** i simulatorn,
ser allt, gör saker, och rapporterar UX-fel + förbättringar — inte bara kodbuggar.
De är INTE förinspelade test: de väljer själva nästa steg baserat på vad de ser.

Kim säger en kort svensk fras → ett smart-prompt-lager expanderar den till ett
rikt testuppdrag. (Kim slipper skriva bra prompts.)

## Kan vi testa appen helt fritt? Ja.

Agenterna kan:
- **Trycka, dra, svepa, skriva** var som helst (fri navigering, inte ett script)
- **Läsa skärmen visuellt** (screenshots) + **a11y-trädet** (alla element, namn, storlek)
- **Välja nästa steg själva** baserat på vad de ser — som en människa
- Köra som **6 olika personligheter** med olika uppmärksamhetsfilter

**Begränsning:** körs i **simulatorn** (snabbt, parallellt). Känsla/tröghet/exakt
fingertryck måste bekräftas på riktig iPhone. Allt visuellt + funktionellt ses fritt.

## Motorn: idb

`idb` (iOS Development Bridge) ger agenten "händer" i simulatorn — tap/swipe/text
+ a11y-trädet som JSON. `simctl` ensam kan bara ta bilder, inte trycka.

**Setup (icke-uppenbart — sparar felsökning):**
- `idb_companion`: `brew install facebook/fb/idb-companion` (companion-formeln togs
  bort ur homebrew-core; facebook/fb-tappen funkar).
- Python-klienten `fb-idb` **kraschar på Python 3.14** (`asyncio.get_event_loop`
  borttagen). Kör i venv med **Python 3.13**: `~/.idb-venv`.
- idb exponerar appens `accessibilityIdentifier` som **AXLabel** (inte AXIdentifier)
  + frame → element nås semantiskt.
- idb tap kräver **heltals**-koordinater.

## De 6 personerna

| Persona | Lins (vad den märker) |
|---|---|
| **P1 Nybörjare** | upptäckbarhet, ikon-begriplighet, "vad gör jag nu?" |
| **P2 Stressad** | svarstid, gesture-konflikter, gör undo det jag tror? |
| **P3 Nyfiken/edge** | gränsfall, krascher, tillstånd som inte återställs |
| **P4 Kim själv** | ikon-tydlighet, träffytor ≥44pt, text-aldrig-enda-signalen |
| **P5 Designgranskare** | Apple-nivå: alignment, spacing, kontrast, konsistens |
| **P6 Tillgänglighet** | VoiceOver-labels, träffytor, fokus-ordning |

Två lägen: **FOKUS** (gör en uppgift, rapportera all friktion) och **UTFORSKA**
(roam fritt efter persona-mål, rapportera allt som känns off).

## Hur — arbetssätt

1. **Smart-prompt-expansion:** Kims fras → persona(er) + läge + mål. Visa 2-raders
   tolkning, fråga aldrig tillbaka, kör.
2. **Sim-setup:** boota simulator, installera appen, skapa körmapp.
3. **Kör personas** (var och en `reset`+`launch` → loop: läs a11y-träd → välj drag
   i karaktär → agera → screenshot → läs bilden visuellt → notera fynd).
4. **Syntes:** dedupa fynd, sätt konsensus (2+ personas = bekräftat) + severity +
   bugg/förbättring-tagg → `UX_PERSONA_AUDIT.md`.
5. **Grind:** kritiska fynd verifieras på riktig iPhone (ui-verifiering-ios).

### Verktyget

`~/.claude/skills/ux-personas-test/bin/ux-driver.sh <UDID> <kommando>`:
`labels` (läs element), `tap <label>`, `double`, `long`, `swipe`, `text`,
`step <namn> <mapp>` (screenshot+träd), `reset`, `launch`.

## Resultatformat: UX_PERSONA_AUDIT.md

Fynd sorterade HÖG→LÅG med: vilka personas som såg det (konsensus), bugg vs
förbättring, repro-steg, screenshot-path, severity, och topp-3-rekommendation.

## Första svepet (v50.6) — exempel på utfall

14 unika fynd, 0 krascher. Topp-3: former staplas osynligt (4/6 personas),
ingen markeringsfeedback (3/6), blockerande nybörjarbuggar (andra form går ej att
lägga till, dubbeltap-redigering saknas). Detta är fel en kod- eller
screenshot-koll aldrig fångar.

## Var det bor

- **Skill:** `~/.claude/skills/ux-personas-test/` (SKILL.md, personas.md,
  prompt-mappning.md, bin/).
- **Trigger-fraser:** "testa appen som en nybörjare", "låt en stressad testa
  pilarna", "känns det tydligt", "hitta UX-problem", "är det snyggt".
- **Körningar (lokalt, gitignorerade):** `.ux-personas-test/`.

## Lärdom om parallellism

CLI-bryggan (`claude_code`) kan driva personas parallellt MEN är opålitlig på
långa körningar (tappar anslutning). Robustast: huvud-Claude kör personas själv
via `ux-driver.sh` + egen multimodal bildläsning. En bridge-körning kan rapportera
fel men ändå ha skrivit klart sin JSON — verifiera filen.

## Relation till andra metoder

- Skild från `METOD-CLI-PARALLELL.md` (granskar KOD). Denna DRIVER appen.
- Kompletterar befintliga skills: `ios-sim-validation` (funktions-audit),
  `iphone-autonom-monkey-test` (random fuzz på riktig enhet),
  `ui-verifiering-ios` (tvingar iPhone-bekräftelse innan "klart").
