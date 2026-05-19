# MermaidCanvas — Roadmap

Versioner och vad de innehåller. Senaste först.

## Aktuell version: v34 (under utveckling)

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

## Planerat: v35

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
