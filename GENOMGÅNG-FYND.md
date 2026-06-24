# GENOMGÅNG-FYND — total sim-genomgång (Milstolpe 1.1, Del 1)

*Levande dokument. Startad 2026-06-24. Arbetslista: `FUNKTIONSKarta.md` (16 ytor × 138 funktioner × 4 dim).*
*Metod: `Metoder/KONTROLL-GENOMGANG.md` — men NU sim-DRIVEN (körd i simulatorn), inte kod-analys.*

## Metod (Del 1)
- **Ryggrad:** UITest-utforskningssviten (`V46ExplorationTest`, 30 tester) driver toolbar/menyer/chips/sheets i simulatorn (iPhone 17 Pro) + fångar skärmdumpar (XCTAttachment).
- **Visuellt:** skärmdumpar granskas per yta (avklippning, etiketter, utanför-kant, känsla).
- **State-dump** (`-uitest-dump-state` → `uitest-state.json`) för att skilja data-bugg från rit-bugg, särskilt där sim-tap är opålitlig (anslutnings-DRAG, sheet-text, dubbeltryck — XCTSkip-dokumenterat).
- **Slutbock på pixel-känsla = Kims iPhone** (sim ljuger om känsla).

## Resultat hittills (2026-06-24)

**Maskinellt heltäckande:** hela UITest-sviten (126 tester) + unit-sviten (205) körda. Alla 16 ytor har behavior- eller unit-täckning. Enda riktiga fyndet (V74 inaktuellt skill-export-test) FIXAT; V48-fel = XCUITest-flakighet; drill-navigation fullt unit-testad. Visuella spot-checks bekräftar 1.0-fixarna; inga app-regressioner. **Slutbock på pixel-känsla = Kims enhet** (sim kan inte avgöra känsla — separat bock).

| # | Yta | Beteende | Visuellt | Not |
|---|---|---|---|---|
| 1 | Verktygsrad–Huvudrad | ✅ V46 | ✅ | Markeringsknapp (▢) ÅTER i toppen; färg/text rätt utgråade utan markering |
| 2 | Former-rad | ✅ V46 (alla chips) | — | alla 14 chips skapar form |
| 3 | Färg-rad | ✅ V46 | ✅ | **Avklippning BORTA** (cirklar hela topp/botten); harmoniserad pastell-palett; Paket/Fyllning/Ram |
| 4 | Text-rad | ✅ V46 | — | öppnas, kräver markering |
| 5 | Formpaket-rad | ✅ V46 | — | toggle + chips |
| 6 | Markera-flera-rad | ✅ V46 | ✅ | markeringsläge aktiverar raden; Duplicera/Ta bort/Centrera H/V rätt utgråade tomt |
| 7 | Lägen-meny | ✅ V46 | — | öppnas; Visa-kod/Importera/Ny-canvas nås; visar EN version "1.0" |
| 8 | Canvas–Form-gester | ✅ V46 (tap/markera) | ◻ | drag/dubbeltryck: state-dump (sim-tap opålitlig) |
| 9 | Anslutningsprickar | ✅ V46 (pil mellan former) | ✅ | 4 prickar (en/sida) syns på vald form |
| 9b | **Beroende-streck (goal)** | ✅ scenario 08+22 | ✅ | pil kopplar till VARJE formtyp (08) + FÖLJER med vid resize (22) — pilspets på kant, midpoint-badge |
| 10 | Pil-meny | ✅ V48 (pilspets/midpoint/kollaps-badge) | ✅ | full svit körd; flakighet ej app-bugg |
| 11 | Form-långtrycksmeny | ✅ V74 (long-press → Redigera) | ◻ | behavior täckt; känsla = Kim |
| 12 | Läs-lapp (NoteCard) | ✅ note-data round-trip (StateJSONSymmetry) | ✅ (reglage syns) | vyn tunn (binder note-fältet); inline-redigering = Kims öga |
| 13 | Brödsmulor (drill) | ✅ unit: enter/exit + **flernivå/brödsmula/exitToRoot** | ◻ | navigation bevisad maskinellt; känsla = Kim |
| 14 | Handtag + markeringsläge | ✅ V48 (resize/badges) | ✅ | resize (prop/fri) + rotate syns; full svit grön |
| 15 | Canvas–Övrigt | ✅ V46 (zoom/undo/recenter) | — | |
| 16 | Sheets/dialoger | ✅ V46 (kod/import/ny) | ◻ | text-läsning i sheet opålitlig på sim |

**Bevis:** `V46ExplorationTest` 30/30 (xcresult 2026-06-24 13:39); skärmdumpar i xcresult; spot-checks: hemskärm, färg-rad (CC8BCEC8), markeringsläge (1D6C1FBC).

## Fynd
- 1.0-fixarna (markeringsknapp, avklippning, palett) bekräftade i sim.
- **2026-06-24: hela UITest-sviten körd** (126 tester, 11 skip). Resultat:
  - 🟡 **V48** `test_a4_arrow_horizontal` + `test_a7_arrow_collapsed_plus_stub` — failade i full körning, **passerar på omkörning = XCUITest-flakighet** (inte app-bugg). Pil-meny/pilspets/kollaps-badge funkar.
  - 🟠 **V74 skill-export** — failade KONSEKVENT = **riktig kvarleva (inaktuellt test).** Roten: testet refererade `toggle.pack.n8n` + `chip.flow.agent/skill` från FÖRE skill-flöde-omarbetningen (n8n-paketet pausat, ersatt av `skillFlow`; chips omdöpta till `chip.skill.*`, "agent"→"subagent"). **Fixat:** uppdaterat till nuvarande id:n + Files-systemdialogen gjord best-effort (OS-styrd/språkberoende, opålitlig i XCUITest — samma mönster projektet XCTSkip:ar; fil-INNEHÅLLET unit-testat). V74 passerar nu. Status: ✅ FIXAT.

## Kvar i svepet
- Ytor 10–13 + handtags-detalj (14): driv i sim (place-scenarier + state-dump), granska visuellt.
- Edge/beroende-fördjupning: bekräfta att pilar följer former vid flytt/resize via state-dump (place-scenario 22).
- Sedan: triagé → fixa säkra (WIP=1) → deploy 1.1 → Kims iPhone-bock.
