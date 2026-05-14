# MermaidCanvas

iPhone-app: visuell flödesschema-editor utan skrivande. Dra former, allt sparas som mermaid-kod i iCloud Drive — Claude Code kan läsa och skriva i samma fil.

## För Claude Code

Läs i denna ordning:
1. `CLAUDE.md` — konstitutionen
2. `PRODUKT.md` — vad appen är, för vem, varför (scope-ankare)
3. `MERMAID-FAKTA.md` — blueprint för Mermaid (syntax, fallgropar, rendering)
4. `VERSIONSHANTERING.md` — checklista vid varje deploy
5. `ARKITEKTUR-MERMAID.md` — aktuell arkitektur
6. `Start för ios appar Kim.md` — iPhone-deploy-flödet

## Status

**v1**: projektstruktur klar. Själva canvas-features bygger vi i v2 och framåt.

## Mappstruktur

```
.
├── CLAUDE.md                       konstitutionen
├── VERSIONSHANTERING.md            checklista
├── ARKITEKTUR-MERMAID.md           alltid senaste arkitektur
├── README.md                       den här filen
├── Start för ios appar Kim.md      iPhone-deploy-playbook
├── arkiv/                          gamla arkitektur-versioner
└── app/MermaidCanvas/              Xcode-projekt
```
