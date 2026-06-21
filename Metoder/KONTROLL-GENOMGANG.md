# Metod: KONTROLL-GENOMGÅNG av hela UI-ytan

**Vad:** systematiskt bevisa att varje funktion i appen sitter rätt, ser rätt ut, funkar och behövs.
**Arbetslista:** `FUNKTIONSKarta.md` (~142 funktioner, 16 ytor). Varje rad har 4 bockar: **Me · UI · Ber · Plats**.
**Mål:** fyll varje bock med **bevis, inte gissning**. Output = ifylld FUNKTIONSKarta + fynd-lista + fixar i WIP=1.
**Trigger:** Kim kör `/goal`. Då lyfts detta in som **MB Steg 1** (breddat från UX-111–122 → hela UI-ytan) med revideringsrad.

---

## Princip: dela de 4 dimensionerna efter hur de BÄST bevisas

| Dim. | Vad | Bevisas av | Kan maskin? |
|---|---|---|---|
| **Me** | Mermaid: exporteras + round-trippar exakt i koden | Round-trip-test + conformance (`mermaid.parse`) + render-grind (headless Chrome) per form/edge/feature | ✅ Helt maskinellt |
| **UI** | Ser rätt/snyggt ut i meny + på canvas, inom kant | "Se-appen"-loopen (sim): scenario per yta → skärmbild → agent läser av → **Kims iPhone-slutbock** | 🟡 Maskin + Kims öga |
| **Ber** | Beroenden funkar (kräver/påverkar rätt, inga krockar) | Funktionella tester + sim-interaktion (tänd funktion + det den kräver) | 🟡 Mest maskin |
| **Plats** | Rätt meny, rätt plats, nåbar, inom kant — **och behövs** (ingen död/dubblett) | Kod-analys (agent läser toolbar/meny/canvas-kod) + sim (inom kant/ej skymd) | 🟡 Maskin + Kims omdöme |

**Regel:** maskin-bockar sätts av agent + adversariell motkontroll. UI-"känns rätt"-bockar och relevans-beslut är **Kims** (iPhone/omdöme) — markeras tydligt som "väntar Kims bock".

---

## Faser (WIP-disciplin: audit hela vägen → triagé → fix i småbitar)

**Fas 0 — Lås arbetslistan.** FUNKTIONSKarta.md = facit. Frys raderna; varje rad får ett ID (yta-nr.rad-nr).

**Fas 1 — Maskinsvep (Me).** Sub-agent-par per yta/feature genererar + kör round-trip (state-JSON + ren mermaid),
conformance och render-grind för varje funktion som rör mermaid. Bocka `✅`/`⚠️` i **Me** med **testnamn som bevis** i Not.
Funktioner med `–` (ren UI-chrome) hoppas i Me.

**Fas 2 — Sim-svep (UI + Plats-inom-kant).** Se-appen-loopen kör **yta för yta**: scenario öppnar varje meny/rad/gest,
tar skärmbild, agent läser av (renderar rätt? inom kant? nåbar? ikon+etikett stämmer?). Bocka **UI** + inom-kant-delen av **Plats**.
Skärmbild-referens i Not.

**Fas 3 — Kod-analys (Plats + behov).** Agent-par läser `ToolbarView*`, `LägenMenu`, `ShapeContextMenu`,
`EdgeMidpointHandle`, canvas-vyerna mot FUNKTIONSKarta: ligger funktionen logiskt rätt? nåbar? **död eller dubblerad?**
inget hårdkodat utanför kant i layouten? Bocka **Plats**, flagga relevans-tvivel som `⚠️`.

**Fas 4 — Beroende-svep (Ber).** Funktionella tester/sim som tänder funktion + dess krav och verifierar inga krockar
(t.ex. Färg kräver markerad form; Pil kräver två former; drill kräver underflöde; lås blockar drag). Bocka **Ber**.

**Fas 5 — Triagé.** Alla `⚠️` samlas i `KONTROLL-FYND.md` (allvar · yta · funktion · vad · föreslagen fix).

**Fas 6 — Fix i WIP=1.** Varje fynd → minsta fix → alla grindar gröna → om-verifiera → bocka. En cluster-commit per yta.
(Kim kan välja: bara audit nu, fix sen — då stannar metoden efter Fas 5.)

**Fas 7 — Kims iPhone-slutbock.** Deploy → Kim går igenom de bockar bara hans ögon ger (känns rätt på riktig enhet,
relevans-beslut). Sista raden per yta.

---

## Sub-agent-arkitektur (parallellt, adversariellt)

- **Fan-out per yta** (16 ytor) × **dimensions-agent** (Me-agent / sim-agent / kod-agent / ber-agent). Kör parallellt.
- **Adversariell verifiering:** innan en `✅` sätts — en andra agent försöker **motbevisa** påståendet ("visa att det
  INTE round-trippar / INTE är inom kant / ÄR dödkod"). Håller bocken bara om motbeviset misslyckas.
- **Completeness-kritiker:** en sista agent frågar "vilken funktion saknar bevis? vilken yta missades?" → ny runda.

## Grindar (icke förhandlingsbara, regel 14/15)
`scripts/arch-check.py` · round-trip-testerna · `scripts/mermaid-conformance.mjs` · `scripts/mermaid-render-check.mjs`
· `AppCapabilitiesCoverageTests` — **gröna hela vägen**. Inga uppmjukade tester. Bevis loggas, inte påstås.

## Output-artefakter
1. **FUNKTIONSKarta.md** — ifylld (maskin-bockar + bevis i Not.; Kims bockar markerade "väntar").
2. **KONTROLL-FYND.md** — alla `⚠️` med allvar + föreslagen fix.
3. **Commits** — en cluster-commit per åtgärdad yta (om Fas 6 körs).
4. **Sammanfattning till Kim** — "X/142 maskin-verifierade, Y fynd, Z fixade, W väntar din iPhone."

## Vad bara Kim kan bocka (ärligt)
UI-"känns rätt/snyggt" på riktig enhet · "behövs den här funktionen alls" (relevans) · gester som bara syns på iPhone
(simulator ljuger ibland — t.ex. ScrollView-tap-buggen). Allt annat bevisas maskinellt först.
