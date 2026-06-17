# ARKITEKTUR-REGLER — de mätbara reglerna (MA spår B)

Det här är de **maskinellt tvingade** arkitekturreglerna för MermaidCanvas. Till
skillnad från BLUEPRINT.md (som beskriver var saker bor i prosa) är reglerna här
objektivt kontrollerbara: `scripts/arch-check.py` läser koden och **stoppar en commit**
som bryter mot dem. Det betyder att appen inte tyst kan glida tillbaka till "allt hänger
ihop"-tillståndet, oavsett vem (eller vilken AI) som skriver koden.

> Kort: BLUEPRINT.md säger *var* saker ska bo. Den här filen säger *vad som mäts* och
> *vad som blockerar*. CLAUDE.md regel 14 binder ihop dem.

## Lagren — beroenden pekar bara nedåt

```
View      (Sources/App/Views, /Canvas, /Handles, ContentView)
  │        ritar pixlar, fångar fingrar
  ▼
Model     (Sources/App/Models, CanvasModel)
  │        vad finns, var, undo — INGA pixlar
  ▼
Mermaid (Sources/Mermaid)  +  Persistence (Sources/App/Persistence)
           översätter till/från text + sparar fil — INGEN UI
```

En övre låda får använda en undre. En undre får ALDRIG känna till en övre. Det är
det som gör att en ändring i en del inte välter en annan.

## Reglerna

**R1 — Mermaid-lagret rör aldrig UI.** Ingen `import SwiftUI`/`import UIKit` i `Sources/Mermaid/`.
*Varför:* Mermaid-koden är det delade språket mellan dig och Claude (CLAUDE.md regel 11).
Blandas rit-kod in i översättningen går det inte längre att lita på att filen och bilden
säger samma sak — den vanligaste buggen historiskt. *Hård: noll undantag.*

**R2 — Model-lagret ritar aldrig.** Ingen `var body`, `: View`, `some View`, `@State`,
`@Binding` eller `@ViewBuilder` i `Sources/App/Models/`.
*Varför:* modellen är hjärnan, inte ögat. Blandas de kan en liten textändring krascha hela
canvasen. *Hård.*

**R3 — View ändrar modellen bara via metoder.** Vyer muterar inte `model.shapes` direkt;
de anropar `CanvasModel`-metoder (så undo fungerar och Claude kan resonera om vad som ändras).
*Granskas (svår att vattentäta maskinellt) — efterlevs i kod-review, inte hård spärr ännu.*

**R4 — Inga otäcka kraschpunkter i hjärnan.** Inga `fatalError(`, `try!` eller `as!` i
Model- och Mermaid-lagret. *Varför:* en krasch där = du kan tappa en ritning. Baslinjen är
0 idag och ska förbli 0. *Hård.*

**R5 — En fil = en sak.** Nya filer ≤ 300 rader. De befintliga jättefilerna är frysta som
tak i `scripts/arch-baseline.json` och får bara **krympa**, aldrig växa.
*Varför:* en 1781-radersfil går inte att ändra säkert — översikten tappas och buggar smyger
in. Vi fryser dagens siffror och låter dem bara sjunka (ratchet). *Hård uppåt; krymp påminns om.*

**Version — en sanningskälla.** `AppVersion.swift` (`vN`) är källan. `arch-check.py` kräver att
`project.yml` har `MARKETING_VERSION = 1.N.0` och `CURRENT_PROJECT_VERSION = N`, och att
Info.plist refererar `$(MARKETING_VERSION)`. *Varför:* annars säger appen "1.0" i App Store
medan vi internt är på v77. *Hård.* Vid version-bump: ändra AppVersion.swift **och** de två
raderna i project.yml (samma nummer).

## Round-trip — deploy-grind (körs separat)

Round-trip (canvas → mermaid → canvas måste ge samma bild, CLAUDE.md regel 11) bevisas av
unit-testerna (`RoundTripTests`, `V62/V63/V64RoundTripTests` + de djupare som byggs i spår A).
De körs **inte** i pre-commit (de kräver simulator och vore för långsamma) utan som grind
före deploy:

```
xcodebuild test -scheme MermaidCanvas -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:MermaidCanvasUnitTests
```

Måste vara grön innan en version skapas (lägg in i VERSIONSHANTERING.md steg 0).

## Hur grinden körs

- **Varje commit:** `scripts/hooks/pre-commit` kör `arch-check.py` (statiskt, <1 s).
  Installeras en gång: `git config core.hooksPath scripts/hooks`. Nödutgång: `git commit --no-verify`.
- **Vid milstolpe (filer krympt):** `scripts/arch-check.py --lower-baseline` sänker taken.
- **Inför App Store:** `scripts/arch-check.py --appstore` kör lanseringschecklistan (privacy
  manifest, version-sync, ikon, launch screen, encryption-deklaration).

## App Store-status (AS-checklistan)

Klart idag: app-ikon, launch screen, bundle-ID/team, encryption-deklaration, version-sync.
**Kvar inför lansering:** `PrivacyInfo.xcprivacy` (AS1), betald Apple Developer-profil,
privacy policy. Kör `--appstore` för aktuell status.
