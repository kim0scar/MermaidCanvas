# Buggsvep efter v60 (→ v60.1)

*Datum: 2026-06-03. Metod: idb-driven utforskning i iOS-simulator (äntligen riktiga
interaktioner — idb installerades denna session) + kodgranskning + fix + verifiering.*

## Bakgrund
Kim testade v60 på sin iPhone och rapporterade flera fel (bilder IMG_0446–0454), främst
ett trasigt landskapsläge. Tidigare "verifiering" var inte äkta — test-skillsen kräver
idb/XcodeBuildMCP som saknades. Denna session installerades **idb** (fb-idb i venv +
idb-companion via brew) och simulatorn drevs som en riktig användare.

## Fel som hittades och fixades

### BUG-1 (KRITISK): Forcerad landskap → svart nedre halva / sidledes
- **Symptom (enhet):** "Skärmläge → Landskap" gav innehåll i övre halvan + svart nedre halva.
  (I sim: innehållet sidledes i ett porträtt-fönster.)
- **Root cause:** SwiftUI `WindowGroup` gav en hosting-controller som rapporterade `.all`
  orienteringar → orienteringslåset gick INTE att tvinga igenom. Dessutom använde
  `requestGeometryUpdate` den tvetydiga `.landscape`-masken (left|right) → iOS valde inget
  håll. Resultat: ett landskaps-fönster pressades in i en porträtt-skärm.
- **Fix (commit 6b97841):**
  - UIKit-livscykel (`main.swift` + `AppDelegate`/`SceneDelegate`) som äger ett scene-anslutet
    fönster via `OrientationLockedHostingController` (override `supportedInterfaceOrientations`
    = låset). Explicit scene-manifest i `Info.plist`.
  - Konkret `.landscapeRight` i `requestGeometryUpdate`.
  - Autosave hårdad mot `didEnterBackground` (UIKit-livscykeln kan göra `scenePhase` mindre
    pålitlig → ingen dataförlust).
- **Verifierat (sim, idb):** porträtt-bas → tvinga landskap → FULL landskap med vänster-sidebar,
  ingen svart halva. Geometri 402×874 ↔ 874×402 växlar korrekt.

### BUG-2 (UX): Container-barn följer inte med vid flytt
- **Symptom:** former som lagts in i en container följde inte alltid med när containern flyttades
  ("följer inte allt med").
- **Root cause:** former som lades till FÖRE containern har `childOfContainerId = nil` och
  matchades bara via positions-fallback. Under drag flyttas barnen live medan containerns bounds
  är statiska (positionen uppdateras först vid drag-slut) → barnen glider ut ur de statiska bounds
  och tappas mitt i flytten.
- **Fix (commit 891ff76):** `claimChildren` körs nu när containern VÄLJS → alla former inom den
  får explicit `childOfContainerId` → matchas position-oberoende och följer med hela vägen.
- **Verifierat (sim, idb):** kvadrat i container följer med när containern dras uppåt.

## Verifierat som FUNGERAR (inga fel — testades via idb)
- **C** Container i Lucidchart-stil (mörk header + ljus kropp + ram) ✓
- **D** Container namnbyte (dubbeltap → redigera-sheet "Namn / text i form") ✓
- **G** Prompt + namn per form ("Prompt (för n8n-flöde)"-fält i redigera-sheet) ✓
- **F** Alla 8 former på översta raden (porträtt) ✓
- **A** Beroendepil möter målet rakt (vinkelrätt) — även diagonalt ✓
- **B** Processpilens högerspets rundad (chip) ✓
- "🔗 1"-brickor = hopplänk-par (feature), blå cirkel = drag-preview — INTE fel.

## Regressionsskydd
- `UnitTests/OrientationTests.swift` låser fast konkret `.landscapeRight` (mot återfall till
  tvetydiga `.landscape`). Hela sviten: **49/49 gröna**.

## Kvar att bekräfta på Kims enhet
- Forcerad landskap på riktig iPhone (sim kan inte fysiskt rotera via script — geometrin är
  verifierad, men den fysiska rotationen bekräftas bäst på enheten). Kims hårdvara hålls porträtt
  (rotationslås) → "tvinga landskap"-knappen är exakt det scenario som nu är fixat.
- Eventuell känsla i container-drag/resize på pekskärm.

## Verktyg (för framtida äkta verifiering)
- idb installerat: `idb-companion` (brew) + `fb-idb` i venv `/tmp/idbvenv` (en patch i
  `cli/main.py` krävdes för Python 3.14). `idb ui describe-all/tap/swipe` + `xcrun simctl io
  screenshot` (porträtt-native buffer; rotera PNG med `sips` för landskap).
