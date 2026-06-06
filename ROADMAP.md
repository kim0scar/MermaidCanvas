# MermaidCanvas — Roadmap

Versioner och vad de innehåller. Senaste först.

## Aktuell version: v62 (deployad till iPhone)

*Tema:* Kims tre fynd från v61.2-granskningen — pilspetsar, etikettplacering, separat färg

**v62:**
- **Pilspets-fix (kritisk):** spetsen följer nu den SYNLIGA linjens riktning vid änden
  (bezier-tangent t=0.92/0.08 på faktiska kontrollpunkter, inkl. obstacle-routade).
  v60 hade låst vinkeln till sidans normal → skeva spetsar på diagonala pilar.
  Visuellt verifierad i sim (förstorad screenshot av båda gren-pilarna).
- **Kant-etikett ovanför/under:** nytt fält `labelPlacement` (above/below, default below),
  segmented-val i Pil-text-sheeten, round-trippar via state-JSON + `%% e<i> labelPlacement:`.
  Demo-filerna har nu både "ja" och "nej" på grenarna.
- **Separat fyllnings- och ram-färg:** `strokeColorOverride` per form; färg-raden har
  segmenten **Paket | Fyllning | Ram** (swatchar + ta bort-chip). Egen fyllning ger
  automatiskt svart/vit text via luminans. `colorOverride` påverkar nu även renderingen
  i appen (tidigare bara exporten). Round-trip: state-JSON `strokeColor` + `%% stroke:`.
- Nya tester: `V62RoundTripTests` (5 st). Unit-sviten: **73/73 gröna.**

## v61.2 (deployad till iPhone)

*Tema:* Skill-kedjor — slutmålet: rita flöde → kedja av Claude Code-skills

**v61.2:**
- **Parser: subgraph-medlemskap → `childOfContainerId` i fallback.** Utan den såg
  edge-routingen containern som hinder för barnens pilar → pilarna svepte långt åt
  sidan. Nu raka pilar genom container-gränser. Test: `V61KedjeFilTests` (68/68 gröna).
- **Nytt koncept levererat + testat på riktigt:**
  - `SKILL-KEDJA-KONTRAKT.md` — container = skill, violett memory-nod = överlämnings-fil,
    prompt per nod = subagent-instruktion.
  - Skill `~/.claude/skills/flode/` — "kör flödet X" / "bygg skills av flödet".
  - Referens-kedja `morgonkoll-flode.md` (iCloud): mejl-svep → steg1-mejl.md →
    sammanfatta → steg2-sammanfattning.md → rapport → svar i chatten.
  - **E2E-körd på riktigt:** 20 Gmail-trådar → 3 filer i `morgonkoll/` → färdig
    morgonrapport. Visuellt verifierad i simulatorn (screenshots).

## v61.1 (deployad till iPhone)

*Tema:* Öppna-fil-buggen Kim hittade — vyn centrerar nu på innehållet

**v61.1:**
- **"Demon gick inte att öppna" = vyn stod på canvas-mitten (1500,1500) medan Claude-ritade
  former låg på (115–285, 160–670)** → tomt vitt papper. Fix: `openFile` centrerar vyn på
  innehållets mittpunkt; live-reload centrerar BARA om inget innehåll syns (stör inte mitt i arbete).
- `centerOnPoint` flyttad CanvasView `@State` → ContentView-ägd `@Binding` (jump-links opåverkade).
- **Visuellt verifierad i simulatorn** (idb): demo-filen öppnad via Files-pickern → lagrad
  TD-layout, kategorifärger, "ja"-etikett, allt centrerat. Screenshot-bevisad.
- Nytt test: `V61DemoFileTests` (demo-filens exakta innehåll → 5 former/4 kanter/layout-ordning).

## v61 (2026-06-05)

*Tema:* "Ren mermaid i backend" — gap-analys + Claude→Kim-riktningen fixad (natt-session)

**v61 (denna session — 4 granskar-agenter + adversarial verifiering, se `GAP-ANALYS-v61.md`):**
- **Rå mermaid från Claude → riktigt flödesschema.** Ny `MermaidAutoLayout`: lagrad
  BFS-layout som följer `flowchart TD/LR/BT/RL`. Cirkel-placeringen borta.
- **Mermaid-blocket självbärande.** Ny `MermaidMetaComments`: fallback-parsern läser nu
  ALLA `%%`-kommentarer (pos, size, rot, width/height, color, pack, style, note, prompt,
  name, hidden-label, collapsed, link, table, line-end) → full round-trip utan state-JSON.
- **Claude-typisk syntax stöds:** inline-kanter (`a["X"] --> b["Y"]`), ocitate labels
  (`a[X]`), nakna id:n (`A --> B`), `==>`, `-- text -->`, `subgraph id` utan label,
  `:::kategori`-suffix utan fantomnoder.
- **iCloud-säker live-reload:** `FileChangeObserver` (NSFilePresenter) + innehålls-hash;
  datum-polling kvar som fallback. Claudes ändringar syns utan omöppning.
- **1-tryck "Kopiera Mermaid-kod"** i Lägen-menyn + pil-tips i tom-canvas-hinten (UX-009 delvis).
- **`N8N-FLODE-KONTRAKT.md`:** kategori→n8n-nodtyp, kantetikett→villkor, prompt→trigger —
  Claude bygger workflow/skill utan gissningar. Refereras i CLAUDE.md.
- Nya tester: `V61FallbackParserTests` (13) + `V61LiveReloadTests` (2). Unit-sviten grön.
- **41 gamla UI-tester lagade** (commit 544c5fa — föråldrade efter v50.2/v60: porträtt-launch-arg,
  riktningsspecifika `connection.handle.*`, scenario-launch i stället för syntetiska drag).
  Full svit: 66/66 unit + 107/111 UI i en sittning; de 4 (V48) är ordnings-flaky — 15/15 gröna
  isolerat, direkt efter V46:s 30 utforskningstester kan 3–4 tima ut. Ingen app-regression.
- **Kvar:** Kims verifiering på iPhonen (v61-punkterna i ARKITEKTUR-MERMAID.md + v60.1:
  forcerad landskap, container-känsla). Backlog: nice-to-have-listan i `GAP-ANALYS-v61.md`.
  Demo-fil att öppna: `v61-demo-från-claude.md` i iCloud-Mermaid-mappen.

## v60.1 (deployad)

*Tema:* Buggsvep efter v60 — forcerad rotation + container-barn (äkta idb-verifiering)

**v60.1 (denna session — idb installerat, riktig sim-utforskning):**
- **Forcerad landskap fixad (svart nedre halva på enhet / sidledes i sim):** root cause var att
  SwiftUI `WindowGroup` inte lät orienteringslåset gälla + tvetydig `.landscape`-mask i
  `requestGeometryUpdate`. Fix: UIKit-livscykel (`main.swift` + `AppDelegate`/`SceneDelegate` +
  `OrientationLockedHostingController`), explicit scene-manifest, konkret `.landscapeRight`.
  Autosave hårdad mot `didEnterBackground`. Verifierat i sim via idb (full landskap + vänster-sidebar).
- **Container-barn följer nu med vid flytt:** `claimChildren` körs när containern väljs → barn får
  explicit `childOfContainerId` → tappas inte mitt i en flytt. Verifierat via idb.
- **Verifierat som redan fungerande** (via idb): container-look (C), namnbyte (D), prompt/namn (G),
  8-form-rad (F), rak pil-entré även diagonalt (A), rundad processpil (B).
- Nytt regressionstest (`OrientationTests`) → 49/49 gröna. Full rapport: `BUGSVEP-v60.md`.
- **Kvar:** Kim bekräftar forcerad landskap + container-känsla på sin iPhone.

**v60 (föregående session — multi-agent-konsensus):**
- **A — beroende-pilar möter rakt:** `outwardNormal` är nu rotations-medveten + pilhuvudet pekar längs sidans inåt-normal → pilen går in vinkelrätt (även diagonalt/roterat), inte snett.
- **B — processpilens spets rundad** (höger spets), i både form och chip, med degenerations-cap.
- **C — container i Lucidchart-stil:** solid header-rad med titel + ljus kropp + tunn ram (canvas + chip).
- **D — container valbar/namnbar:** containrar z-ordnas under barn → tap/namnbyte fungerar.
- **E — container-barn följer alltid med:** `childOfContainerId` sätts vid skapande + container "adopterar" former vid släpp; barn följer vid flytt.
- **F — alla 8 geometriska former på översta raden** (40pt, ≥44pt tap) + **landskap = vänster vertikal sidebar** (adaptiv layout, äkta orientering).
- **G — prompt + namn per form (n8n):** nytt `prompt`-fält (EditShapeSheet), namn = label; båda exporteras i Mermaid-koden (`%% name:` / `%% prompt:`) för att kopiera flöden till n8n. Round-trippar.
- Test-target: nya tester (kant, prompt, octagon) + snapshots omrecordade. Hela sviten grön.

> **Verifiera på iPhone:** landskaps-sidebaren (kan ej rotera simulatorn via script), container drag/resize-känsla, diagonala pilar.

**v51.2 (föregående):**

*Tema:* Landskapsläge (punkt 6) — äkta orientering

**v51.2 (denna session):**
- **Skärmläge porträtt/landskap** i Lägen-menyn ("Skärmläge"). Äkta orientering via `AppDelegate` + `requestGeometryUpdate` (iOS 16+) — UIKit roterar hela koordinatsystemet så drag-släpp, UIScrollView-pan/zoom, sheets och tangentbord följer med korrekt. Valet sparas (`@AppStorage`).
- Avvisade "rotera ikonerna 90°"-idén (enhällig panel: skulle desynka drag/scroll/sheets/tangentbord). Med äkta orientering behövs ingen ikon-rotation — allt står rätt.
- `project.yml`: låste upp Landscape Left/Right. Ny `Orientation.swift`.
- Verifierat i sim (roterar utan krasch, porträtt default). **Slutlig känsla (drag/zoom i landskap) verifieras på iPhone.**

**v51.1 (föregående):**

*Tema:* Åttahörning + chip-omordning (punkt 5)

**v51.1 (denna session):**
- **Ny form: åttahörning (octagon)** med rundade hörn (`OctagonShape`), bas 80×80. Round-trippar förlustfritt via state-JSON (`type: "octagon"`); Mermaid-syntax-fallback = rundad rektangel.
- Hanterad i alla form-switchar (kompilator-verifierat) + de tysta `default`-fällorna i `ShapeGeometry` (explicit 80×80).
- **Chip-raderna omordnade** (rundade först): Rad A = cirkel, pill, rektangel, kvadrat, container; Rad B = diamant, processpil, åttahörning, tabell, länk, linje, anteckningar. Chip-blocken refaktorerade till `geoChip`-helper (DRY).

**v51.0 (föregående):**

*Tema:* Dark mode — beroende-pilarna syns nu (punkt 4)

**v51.0 (denna session):**
- **Dark mode-fix:** kanter/pilar/etiketter var osynliga i iPhone dark mode (ritades med `.primary` = vit, mot canvasens fasta vita papper). Canvasen är medvetet ett vitt ritbräde (ColorPack-färger + Mermaid-export är ljusa), så lösningen är `.environment(\.colorScheme, .light)` på hela canvas-subträdet → allt bläck blir mörkt och syns i båda lägena. Toolbar/menyer förblir adaptiva.

**v50.9 (föregående):**

*Tema:* Form-polish (punkt 1–3 av Kims lista)

**v50.9 (denna session):**
- **ProcessArrow** ("pilen") rundare hörn: `processArrowCornerRadiusRatio` 0.18→0.30 (spetsen kvar skarp; extra höjd-cap mot degenerering vid platt resize).
- **Diamant** lite rundare: `diamondCornerRadiusRatio` 0.075→0.10 (chip+canvas via delad token).
- **Cirkel-chippen** ritas nu som riktig `Circle()` via `iconSize` — matchar övriga chips storlek (var för liten som SF Symbol).

**v50.8 (föregående):**

*Tema:* Chip ↔ canvas — äkta single source (formerna matchar på riktigt)

**v50.8 (denna session):**
- **Grundfix:** `DesignTokens` enade tidigare bara hörn-radie + stroke — **inte aspect ratio**. Chip-ikonernas storlekar var hårdkodade oberoende av canvas → glidning ("åter igen").
- Chip-ikonernas **storlek härleds nu från canvas** (`Chip.iconSize(for:)` läser `ShapeGeometry`-bas-ratio) → chip och canvas kan aldrig divergera i proportion.
- **Alla** hörn-radier uttrycks som ratio (`Shape.cornerRadius(for:height:)`); canvas slutade hårdkoda 14/16 och stroke 1,5 → läser tokens.
- **Diamant**: `DiamondShape` bytte absolut hörn-radie → ratio (missades i v50.5). Chip var knubbig (30% rundning), canvas vass (7,5%) — nu samma proportion.
- Rättat pill-ratio (1,625, inte 1,875) och **reverterat v50.7 UX-012-regressionen** (rektangel 2,0 → 1,5).
- `ComponentGallery` (chip vs canvas-jämförelse) läser nu samma källa → sann jämförelse.

**v50.7 (föregående):**
- **UX-004** — kaskad-offset på nya former (slutar stapla osynligt; 4/6 personas).
- **UX-005** — mjuk markerings-outline direkt vid tap (syntes tidigare först vid drag).
- **UX-001/007/010/013** — läsbara VoiceOver-labels på toolbar-knappar, form-chips och resize/rotation-handtag (läste tidigare råa SF Symbol-namn).
- **UX-006** — ≥44pt träffytor på collapse-badge och 100%-zoomknapp (visuell storlek oförändrad).
- **UX-003** — tomt-tillstånd (`EmptyCanvasHint`) vägleder förstagångsanvändare.
- **UX-012** — rektangel-chip tydligare avlångt (skiljs från kvadrat).
- **Verifierat icke-buggar (ingen ändring):** UX-002 (undo korrekt per-steg), UX-008 (drag funkar på omarkerad form; snabbsvep = scroll by design), UX-014 (kosmetiskt animations-kantfall).
- **Follow-up (kräver design):** UX-009 (pil-upptäckbarhet), UX-011 (tabell-redigerings-affordance).
- Arkitektur-doc omskriven: `ARKITEKTUR-MERMAID.md` speglar nu v50.7 (var v39). v39 arkiverad.

**v50.6 (föregående):**
- **6 buggar fixade** (hittade via parallell Claude Code CLI-bugjakt + sim-agenter):
  - BUG1 (missionskritisk): `-->` i nodtext/notis trunkerade JSON-state-blocket → all fidelity tappades. Fix: matcha `\n-->`.
  - H1/H2: tabell med 0 rader/kol kraschade. Fix: `max(1,…)`-klamp.
  - M1: container hoppade till 2,4× vid resize-handtag. Fix: typ-specifik bas.
  - M3: long-press popade meny i edge-mode. Fix: `guard !edgeMode`.
  - F11: minus-badge överlappade marker-handle. Fix: min 55pt offset.
  - F13: haptic feedback på long-press.
  - 2 regressionstester (RoundTripTests): `-->` i text + 0-rader-tabell.
- **Nytt verktyg: `ux-personas-test` (v1.0)** — AI-testanvändare (6 personas) driver
  appen i simulatorn via **idb** och hittar UX-fel + förbättringar. Smart-prompt-lager
  expanderar korta svenska fraser till rika testuppdrag. Ligger i `~/.claude/skills/`.
- **Första UX-svep:** `UX_PERSONA_AUDIT.md` — 14 unika fynd (0 krascher). Topp-3:
  former staplas osynligt, ingen markeringsfeedback, blockerande nybörjarbuggar.

> **OBS dokumentationsdrift:** `ARKITEKTUR-MERMAID.md` speglar v39 och historiken nedan
> stannar vid v34. Koden har gått till v50.6 via många små iterationer utan full
> arkitektur-omskrivning. En full ARKITEKTUR-uppdatering är en egen framtida uppgift.

---

## Tidigare: v34 (under utveckling)

**Tema:** Canvas-omtag + modulär arkitektur

- UIScrollView-baserad canvas (löser drop/pan/zoom-buggar)
- Fast 4000×4000pt canvas (Microsoft Whiteboard-stil borttagen för MVP)
- Minimap bortplockad (med fit-zoom som min behövs den inte)
- Apple `.dropDestination` ersätter manuell ShapeDragController
- Apple `.draggable` ersätter manuell DragGesture-controller
- AppVersion: v34 (bumpa från v34-wip vid release)

## v33 (released)

- 44pt-knappar enligt Apple HIG
- Haptic feedback vid drop + toolbar-toggle
- Smooth spring-animation vid toolbar expand/collapse
- markerButton flyttad till Lägen-menyn
- V33VersionVisibleTests bevisar att "v33" syns i UI

## v32 / v31 (released)

Se `arkiv/ARKITEKTUR-MERMAID-v32.md` och `arkiv/ARKITEKTUR-MERMAID-v31.md` för detaljer.

## Bakåt: v25 - v30

Se `arkiv/ARKITEKTUR-MERMAID-v25.md` till v30 för historia.

## v50 (under utveckling)

**Tema:** Visuell placerings-bugjakt + 2 root-cause-fixar

- **Ny test-infrastruktur:** `UITests/V50PlacementTests.swift` + `UITests/V50PlacementMatrix.md`
  + `Sources/App/UITestScenarios.swift` — 23 deterministiska scenarier byggs
  via `-uitest-place-*` launch-args, screenshot per scenario, granskning post-hoc
- **F-02 fix:** Pilar mellan barn i en container gick rakt upp ur skärmen.
  Container sågs som obstakel av routing-algoritmen även för pilar mellan
  dess egna barn. Fix i `CanvasView.drawEdge` + ny `edgeAnchors` — hoppa över
  container när from/to har `childOfContainerId == container.id`.
- **F-03 fix:** Midpoint-handle och kant-etikett saknades på böjda bezier-pilar.
  Mid beräknades som rak mid mellan endpoints → hamnade inuti obstaklet.
  Fix: ny `EdgeAnchors`-helper räknar mid + tangent vid bezier t=0.5.
- Fullständig rapport: `UI-PLACERINGS-FYND-v49.md`

## v49 (released)

- Multi-agent-konsensus-metod för pilspets-asymmetri + minus-badge-state
- Launch-arg-baserade test-scenarier för visuell verifiering

## Planerat: v51+

(Backlog — Kim styr prioritering)

- Collaborative cursors (om Kim vill det)
- Splittning av kvarvarande monoliter (ToolbarView, CanvasModel, ContentView)
- Eventuell infinite-expand-canvas om 4000² blir för litet
- MVP2 från `mvp2.md`-spec

## Planerat: v40+ (långsiktigt)

- Infinite-expand-canvas (Microsoft Whiteboard-stil) om Kim når 4000²-kanten
- Realtidssamarbete på samma canvas

## Filer

- `CLAUDE.md` — konstitutionen, läses först
- `PRODUKT.md` — produktvision
- `ARKITEKTUR-MERMAID.md` — aktuell arkitektur (uppdateras per release)
- `ARKITEKTUR-SWIFT.md` — modulstruktur (uppdateras per release)
- `ROADMAP.md` — denna fil
- `VERSIONSHANTERING.md` — deploy-checklista
- `MERMAID-FAKTA.md` — Mermaid-syntax-referens
- `METOD-VISUELL-DIALOG.md` — protokoll för visuellt språk Kim ↔ Claude Code
- `Start för ios appar Kim.md` — iOS-deploy
- `arkiv/` — versionshistorik
