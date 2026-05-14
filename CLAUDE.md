# CLAUDE.md — Konstitutionen för MermaidCanvas

Detta är styrdokumentet för Claude Code i det här projektet. Kort med flit. När du som Claude Code öppnar projektet — läs den här filen först.

## Vad projektet är

En iPhone-app (native SwiftUI) som är en **visuell flödesschema-editor**:
- Drag-och-släpp av cirklar, trianglar, fyrkanter på en canvas (känsla: Lucidchart)
- Text bara *i* formerna; inget annat skrivande i appen
- Riktade pilar mellan former
- Allt persistas som **mermaid-kod** i en markdown-fil i iCloud Drive
- Claude Code läser och skriver i samma fil → tvåvägs visuellt språk mellan Kim och Claude Code

Användarens canvas-fil:
`~/Library/Mobile Documents/com~apple~CloudDocs/ClaudeCanvas/canvas.md`

## Regler för Claude Code (icke förhandlingsbara)

1. **Versionshantering**: följ alltid `VERSIONSHANTERING.md`. Hoppa inte över steg.
2. **Modulär kod**: små filer, en sak per fil. Hellre fler filer än en stor. Inga monolitfiler — även om det blir mer kod totalt.
3. **Arkitektur som sanning**: efter varje deploy ska `ARKITEKTUR-MERMAID.md` uppdateras så att diagrammet alltid speglar nuvarande kod.
4. **iOS-deploy**: följ `Start för ios appar Kim.md` för Team ID, signing och devicectl-flödet. Allt står där.
5. **Språk**: svenska i kod-kommentarer (få sådana) och commit-meddelanden. Korta meningar.
6. **Frågestil**: Kim är inte utvecklare. Gör rimliga antaganden, fråga bara vid riktiga vägval. Inget utvecklarjargong i svar.
7. **Innan du ändrar kod**: läs `ARKITEKTUR-MERMAID.md` så du vet var saker bor.

## Filer du som Claude Code styrs av

| Fil | Vad den säger |
|---|---|
| `CLAUDE.md` | Den här filen — konstitutionen |
| `VERSIONSHANTERING.md` | Exakt checklista vid varje deploy / ny version |
| `ARKITEKTUR-MERMAID.md` | Aktuell arkitektur: mermaid-diagram + fil-tabell |
| `Start för ios appar Kim.md` | iPhone-deploy: signing, build, devicectl |
| `arkiv/ARKITEKTUR-MERMAID-vN.md` | Historik över hur appen sett ut tidigare |

## Användarens profil (kort)

Kim har dyslexi / ADHD / 2e-profil. Tänker visuellt och rumsligt. Föredrar bilder framför ord.
När du svarar Kim:
- Korta meningar
- Inga onödiga ord
- Visa hellre än förklara
- Svenska
