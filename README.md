# MermaidCanvas

> iPhone-app: visuell flödesschema-editor utan skrivande.
> Dra former, allt sparas som **mermaid-kod** i iCloud Drive — Claude Code kan läsa och skriva i samma fil.

[![Latest Release](https://img.shields.io/github/v/release/kim0scar/MermaidCanvas)](https://github.com/kim0scar/MermaidCanvas/releases)
![Platform](https://img.shields.io/badge/platform-iOS%2017+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)

## Vad är det

En SwiftUI-app för iPhone där du **ritar flödesscheman med fingret** istället för att skriva mermaid-kod. Dra former på en oändlig canvas, koppla dem med pilar, lägg anteckningar — appen sparar allt som en `.md`-fil i iCloud Drive med mermaid-syntax. Filen blir då ett *delat språk* mellan dig och Claude Code: du ritar visuellt, Claude förstår och skriver text-koden bakåt, ändringar syns direkt nästa gång du öppnar appen.

## För vem

- Den som tänker visuellt (dyslexi, ADHD, 2e-profiler) och vill rita istället för skriva
- Den som vill ge AI-agenter (Claude) ett strukturerat input/output-språk
- Den som planerar appar, agent-flöden, eller arkitektur och vill ha en levande canvas

## Snabbstart

### Bygga själv

```bash
git clone https://github.com/kim0scar/MermaidCanvas
cd MermaidCanvas/app/MermaidCanvas
brew install xcodegen
xcodegen generate
open MermaidCanvas.xcodeproj
```

Sen i Xcode: välj din device/simulator och tryck Cmd+R. iOS 17+ krävs.

### Ladda färdig version

Se [Releases](https://github.com/kim0scar/MermaidCanvas/releases) — färdig `.app`-bundle per version. Kräver Apple Developer-cert (gratis fri-tier räcker för 3 appar samtidigt på din enhet).

## Aktuella features (v31)

- 6 basformer: cirkel, rektangel, diamant, pill (capsule), text, tabell
- 4 special-symboler: jump-link, lös linje, lös pil, anteckning-popup
- 3 plattformar: Blank, Godot, iOS SwiftUI
- 2 form-paketer: UI, Prompt-Process (Claude/agent-flow)
- Drag-och-släpp + zoom-mot-finger + pan med kantclamp
- Resize: proportional och fri-scale via separata handtag
- Round-trip mermaid: skapa → spara iCloud → öppna i Claude → ändringar speglas tillbaka

## Arkitektur

Källkoden är uppdelad i tre tydliga moduler:

```
Sources/
├── App/          — Vyer, modeller, persistens, UI-logik
├── Mermaid/      — Generator + parser för mermaid-syntax + state-JSON
└── ClaudeCode/   — Plattform-regler, form-paketer, kategori-system + MD-regler
    └── Rules/
        ├── godot-lexicon.md
        ├── ios-swiftui-rules.md
        ├── prompt-process-rules.md
        └── claude-canvas-protocol.md
```

Se `ARKITEKTUR-MERMAID.md` för senaste arkitektur-diagram.

## För bidragsgivare / Claude Code

Läs i denna ordning:
1. `CLAUDE.md` — konstitution + arbetsregler
2. `PRODUKT.md` — scope och vad som hör hemma i appen
3. `MERMAID-FAKTA.md` — mermaid-syntax-blueprint
4. `METOD-VISUELL-DIALOG.md` — protokoll för visuell dialog Kim ↔ Claude
5. `VERSIONSHANTERING.md` — deploy-checklista
6. `ARKITEKTUR-MERMAID.md` — kod-överblick
7. `Start för ios appar Kim.md` — Xcode/iPhone-deploy

## Licens

Kim Lundqvist — privat hobby-projekt, publicerat så andra kan studera/inspireras.
Ingen explicit licens — fråga om du vill använda/forka kommersiellt.
