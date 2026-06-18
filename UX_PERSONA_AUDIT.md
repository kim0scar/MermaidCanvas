# UX-Persona Audit v72 (full svep) — 2026-06-10

## Sammanfattning
- **Testare:** Claude själv (egen genomgång via idb) + alla 6 personas (P1 nybörjare,
  P2 stressad, P3 nyfiken/edge, P4 Kim, P5 designgranskare, P6 tillgänglighet).
- **Läge:** FOKUS (skill-resan: rita kedja → container → prompt → spara skill) + UTFORSKA.
- **Sim:** iPhone 17 + iPhone 17 Pro, iOS 26.4 | **Motor:** idb (venv ombyggt till Py3.13).
- **Råfynd:** ~35 → efter dedup: **22 unika** + flera positiva.
- **Inga krascher** — P3 misshandlade appen (13 noder, 200-teckensnamn, extrem resize,
  off-screen-drag) utan en enda frysning, och mermaid-koden förblev hel.
- **9 fynd är redan FIXADE** i v73 WIP under samma session (se nedan).

**Helhetsdom mot skill-kedje-målet:** Kärnresan FUNGERAR — rita kedja, container, prompt,
spara skill, kod-vy med auto-legend håller ihop. Tre saker stod mellan v72 och målet:
(1) skill-objekten var anonyma (tomma noder, "Grupp", "skill.md") — fixat;
(2) containerns tysta beteenden (slukar noder, trasiga pil-ankare, mermaid/JSON-inkonsistens)
— delvis kvar, högsta prio; (3) canvasen var osynlig för a11y — fix inlagd, kräver verifiering.

---

## FIXADE i v73 WIP (samma session — verifieras vid nästa deploy)

| ID | Fynd | Sett av | Fix |
|---|---|---|---|
| UX-101 | Nya noder staplas på samma punkt (v50.6 UX-004 — kaskaden fanns men steget 28pt < formstorlek) | Claude, P2, P3, P4 | Kaskad-steg 96pt |
| UX-102 | "Spara skill som fil" frågar inte efter namn → "skill.md"/"Grupp" | Claude, P4 | Namn-dialog som även döper containern |
| UX-103 | Prompt-fältet (skillens kärna) gömt under vecket + rubrik "för n8n-flöde" | Claude | Flyttat överst + rubrik "instruktionen till Claude" |
| UX-104 | Svep/feltap i Redigera-arket stänger det och KASTAR inskriven text | Claude, P4 | `interactiveDismissDisabled` vid osparade ändringar |
| UX-105 | Canvas-former finns inte i a11y-trädet — VoiceOver/AI-agenter ser ingenting (HÖG, P6:s kärnfynd) | Claude, P6 | `accessibilityElement` + svensk label per form — **verifiera i sim** |
| UX-106 | Tomma n8n-noder: bara form+färg skiljer Script från Bevis | P2, P4 | Svag typ-platshållare i tomma noder (bara visning) |
| UX-107 | "Prompt-Process"-chipet radbryts → ojämn rad | Claude, P5 | lineLimit(1) + minimumScaleFactor |
| UX-108 | UI- och Prompt-Process-segmenten är DÖDA (chips byggdes aldrig — `availableCategories` var död kod) | P5 | Chips byggda enligt n8n-mönstret |
| UX-109 | Pilhandtaget heter "arrow.up.right" (rått symbolnamn, 27pt) | Claude, P6 | Svensk a11y-label "Skapa pil — dra till en annan form" |

---

## KVARSTÅENDE — HÖG

*(Tom — UX-110 löst 2026-06-18, se nedan.)*

### ✅ UX-110 [FIXAD v73, LÅST 2026-06-18] Container-medlemskap: mermaid och state-JSON säger OLIKA saker
- **LÖST:** roten (generatorn använde positionsbaserad `shapesInside()` i stället för explicit
  `childOfContainerId`) fixades i v73 — `MermaidGenerator.containerChildrenIds` använder nu
  `childOfContainerId`, samma sanning som state-JSON. Verifierat + permanent låst 2026-06-18 av
  `RoundTripFidelityTests.test_ux110_mermaidMembershipFollowsChildOf`: en nod som bara LIGGER på
  containern hamnar inte i subgraph-blocket. (Auditen markerades bara aldrig om förrän nu.)
- **Sett av:** P3 (verifierat via kopierad kod), P4 ("containern slukar min nod"), Claude (trasiga pil-ankare)
- **Vad:** En nod som bara råkar LIGGA på containern exporteras som subgraph-MEDLEM i
  mermaid-blocket trots att state-JSON saknar `childOfContainerId`. Protokollbrott mot
  METOD-VISUELL-DIALOG (round-trip-regeln) — Claude Code och appen ser olika strukturer.
  Samma rot ger: container som spawnar ovanpå noder adopterar dem tyst (P4), och
  pil-ankare som ritas som långa streck över hela canvasen tills containern flyttas (Claude).
- **Repro:** Input-chip → Skill-chip (hamnar ovanpå) → Kopiera Mermaid-kod → jämför
  subgraph-innehåll med nodernas `childOfContainerId`.
- **Trolig rot:** generatorn använder positionsbaserad `shapesInside()` medan state-JSON
  använder explicit `childOfContainerId` (teknisk skuld listad redan i v46-auditen).
- **Väg:** multi-agent-bug-fix. Högsta prio — det här är round-trip-kärnan.

---

## KVARSTÅENDE — MEDEL

### UX-111 [BUGG] Miss på pilhandtaget = panorering som "tappar bort" allt
- **Sett av:** P2 (BEKRÄFTAT av P3:s variant) | Drag ~15–20pt från handtaget tolkas som pan
  → hela innehållet utanför skärmen, tom canvas. P3: drag på nod blir panorering när noder
  överlappar. Räddning finns (100%) men inget pekar dit.
- **Väg:** större träffyta på handtaget + ev. "hoppa till innehåll"-knapp när canvasen är tom men noder finns.

### UX-112 [BUGG] Handtag hamnar utanför skärmen
- **Sett av:** P2 (container-pilhandtag utanför högerkanten), P4 (rotera/resize avklippta vid vänsterkanten)
- **Väg:** klampa handtagens position till synlig yta.

### UX-113 [FÖRBÄTTRING] Ingen ledtråd om hur man får text i en form
- **Sett av:** P1 (3 gissningar; dubbeltapp gör inget), Claude (samma resa)
- **Notera:** dubbeltapp ÄR kopplad till redigering i koden men P1 + Claude fick inget ark
  på dubbeltapp i praktiken — undersök varför (gesture-ordning?). Empty-state nämner inte text.
- **Väg:** låt dubbeltapp öppna Redigera pålitligt + en rad i empty-state.

### UX-114 [BUGG] a11y-luckor i ark och paneler (P6)
- Redigera-arkets fält/knappar utan labels (Klar går inte att nå via label — verifierat),
  Textstil-raden engelska + två knappar UTANFÖR skärmen (x=392, 436 på 402pt), kodvyns
  Stäng/Kopiera onåbara, "Edit"-knappen heter engelska "Edit".
- **Väg:** svenska labels på allt interaktivt; flytta in textstil-knapparna.

### UX-115 [FÖRBÄTTRING] Gest-enda funktioner utan alternativ väg (P6)
- Redigera/Ta bort/Spara skill m.m. nås BARA via long-press; pil BARA via drag.
- **Väg:** spegla long-press-menyn för markerad form i Edit-menyn (eller en markerings-rad).

### UX-116 [FÖRBÄTTRING] Long-press-menyn visas uppe till vänster, frikopplad från formen
- **Sett av:** Claude, P1, P4 (BEKRÄFTAT 3 källor — höjd från LÅG)
- **Väg:** ankra popovern vid formen.

---

## KVARSTÅENDE — LÅG (urval, grupperat)

- **UX-117 P1-friktion:** första chip-trycket gav ingen form (timing?); long-press ger ark
  på markerad form men meny på omarkerad (inkonsekvent); tap på "Redigera"-raden missade.
- **UX-118 P3-edge:** rotation kräver lång båge; ingen minsta form-storlek (~30×15 går);
  100% gör ingen "visa allt"; 200-teckensnamn svämmar ut under formen.
- **UX-119 P5-polish:** Edit-menyns rader radbryts ojämnt; Mallar-dropdown ovanpå segmentraden;
  Legend-kortet visar rå kategorikod ("ui") + mest tomrum; UI och Mallar har samma ikon;
  Former-panelen blandar språk/etikettstilar ("Container" bland svenska); "Skärmläge" ger
  ingen synlig effekt; Textstil-raden klipps utan scroll-indikation.
- **UX-120 Pil-badges omärkta:** magenta minus + mittenpil på kanter skrämmer nybörjare (P1).
- **UX-121 Skill-chipet ser ut som en nod-chip** men skapar stor container (P2) — överraskning.
- **UX-122 Mallar har bara "iPhone 16 Pro"** — ingen skill-kedje-mall trots att skill-kedjor
  är appens mål (Claude). Idé: mall som lägger ut Input → våg-grupp → gap → grind → output.

---

## Jämförelse mot v50.6-auditen

| v50.6-fynd | Status v72 |
|---|---|
| UX-001 VoiceOver tekniska namn | Toolbar/chips FIXADE (svenska). Nya fall hittade (Textstil, ark) = UX-114 |
| UX-002 Undo tömmer allt | EJ REPRO — P2 bekräftar att ångra tar exakt rätt saker. Stängd. |
| UX-003 Ingen onboarding | FIXAD — "Börja här" bar P1 genom grunduppgiften. |
| UX-004 Former staplas | KVAR i v72 → FIXAD nu (UX-101). |
| UX-005 Markeringsfeedback | FIXAD — handtag + highlight syns direkt. |
| UX-006 Träffytor <44pt | DELVIS KVAR — chips 52×36, handtag 27pt (UX-109/114). |
| UX-007 Handtag saknas i a11y | FIXAD (Rotera/Ändra storlek har labels); pilhandtaget fixat nu. |
| UX-008 Drag kräver tap först | FIXAD — P2:s 0,3s-drag registrerades direkt. |
| UX-009 Pil-upptäckbarhet | FIXAD — P1 hittade pilen på första försöket via hint-texten. |
| UX-010 Toolbar-ikoner otydliga | FIXAD — svenska labels. |

8 av 14 v50.6-fynd är åtgärdade och bekräftade av nya svepet.

## Positivt (Apple-nivå redan)
- Stabilitet: noll krascher under hela svepet inkl. P3:s misshandel.
- Round-trip: 200-teckensnamn, rotation, storlek, positioner — allt bevaras exakt i filen.
- Ångra: exakt rätt saker i rätt ordning (P2).
- Multi-select: marquee + kontextuell rad (Duplicera/Ta bort/Centrera) är tydlig.
- Tomt-tillstånd + pil-hint bar en nybörjare hela vägen utan hjälp.
- Kod-vyn: komplett med prompts + auto-legend — översättaren till Claude fungerar.

## Rekommenderad väg
1. **UX-110 (container-medlemskap)** — multi-agent-bug-fix. Round-trip-kärnan, högsta prio.
2. **UX-111/112 (pan-stölden + handtag off-screen)** — gesture/layout-fix, verifieras på riktig iPhone (`ui-verifiering-ios`).
3. **UX-113/116 (text-ledtråd + meny-ankring)** — små UX-fixar med stor nybörjar-effekt.
4. **UX-114/115 (a11y)** — svenska labels + meny-alternativ till gester.
5. LÅG-listan tas i mån av tid; UX-122 (skill-kedje-mall) är liten och ger direkt värde för MFP-arbetet.

*Screenshots: /tmp/ux-audit-v72/ (persona-prefix p1–p6 + Claudes 00–32). Persona-rapporter:
persona-P1-P2-P3.md, persona-P4-P5-P6.md i samma mapp.*
