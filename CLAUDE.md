# CLAUDE.md — Konstitutionen för MermaidCanvas

Detta är styrdokumentet för Claude Code i det här projektet. Kort med flit. När du som Claude Code öppnar projektet — läs den här filen först.

---

## Var allt finns sparat (sanningskälla)

Den här tabellen är **alltid aktuell**. Uppdatera den så fort en ny sparplats tillkommer.

| Vad | Var | Synkat till |
|---|---|---|
| **Projektkod + styrdokument** | `/Users/kim/2e Mermaid Code/` | git (lokalt) + GitHub |
| **GitHub-repo (privat)** | https://github.com/kim0scar/MermaidCanvas | molnbackup, `kim0scar`-kontot |
| **App-källkod (Swift)** | `app/MermaidCanvas/Sources/` (Models, Views, Mermaid, Persistence) | git |
| **Xcode-projekt** | `app/MermaidCanvas/MermaidCanvas.xcodeproj/` (regenereras från `project.yml` via `xcodegen`) | git |
| **Build-artefakter** | `app/MermaidCanvas/DerivedData/` — *.gitignored*, regenereras vid build | endast lokalt |
| **Aktuell arkitektur** | `ARKITEKTUR-MERMAID.md` (senaste version) | git |
| **Tidigare arkitektur-versioner** | `arkiv/ARKITEKTUR-MERMAID-vN.md` (en per deploy) | git |
| **Appen på iPhone** | bundle-ID `com.kimlundqvist.mermaidcanvas`, Team `SFXR8MV6MP` | enbart på iPhone tills nästa deploy från Mac |
| **Kims canvas-filer (i drift)** | `~/Library/Mobile Documents/com~apple~CloudDocs/00000. Claude Code/1. Mermaid/` | iCloud Drive — syns på både iPhone och Mac |
| **Memory (för framtida sessioner)** | `~/.claude/projects/-Users-kim-2e-Mermaid-Code/memory/` | endast lokalt på Macen |
| **Plan-fil** | `~/.claude/plans/vi-ska-bygga-en-magical-knuth.md` | endast lokalt på Macen |
| **App-ikon (planerat v14)** | `app/MermaidCanvas/Sources/Assets.xcassets/AppIcon.appiconset/` | git (när skapad) |

**Verifiera sparat-status:** `git status` (ska säga clean) + `git log --oneline -5` (sista commit syns) + `git status -sb` (ska säga `up to date with origin/main`).

Senast deployade version på iPhone: se senaste commit-meddelande utan WIP-flagga (`git log --oneline | grep -v WIP`).

---

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

1. **Var-allt-finns-sparat-tabellen ovan är sanningskällan.** När en ny sparplats tillkommer (ny mapp, nytt moln, nytt verktyg) — uppdatera tabellen i samma commit. Det är denna fil som svarar på "är allt sparat?".
2. **Vid scope-tvivel — läs `PRODUKT.md` först.** Den definierar vad som hör/inte hör hemma i appen.
3. **Vid Mermaid-tvivel — läs `MERMAID-FAKTA.md`.** Den är blueprinten för hur Mermaid faktiskt fungerar. Gissa aldrig syntax.
4. **Versionshantering**: följ alltid `VERSIONSHANTERING.md`. Hoppa inte över steg.
5. **Modulär kod**: små filer, en sak per fil. Hellre fler filer än en stor. Inga monolitfiler — även om det blir mer kod totalt.
6. **Arkitektur som sanning**: efter varje deploy ska `ARKITEKTUR-MERMAID.md` uppdateras så att diagrammet alltid speglar nuvarande kod.
7. **iOS-deploy**: följ `Start för ios appar Kim.md` för Team ID, signing och devicectl-flödet. Allt står där.
8. **Språk**: svenska i kod-kommentarer (få sådana) och commit-meddelanden. Korta meningar.
9. **Frågestil**: Kim är inte utvecklare. Gör rimliga antaganden, fråga bara vid riktiga vägval. Inget utvecklarjargong i svar.
10. **Innan du ändrar kod**: läs `ARKITEKTUR-MERMAID.md` så du vet var saker bor.

## Filer du som Claude Code styrs av

| Fil | Vad den säger |
|---|---|
| `CLAUDE.md` | Den här filen — konstitutionen |
| `PRODUKT.md` | VARFÖR och VAD: vision, scope, vad som hör/inte hör hemma |
| `MERMAID-FAKTA.md` | Blueprint för Mermaid: syntax, fallgropar, rendering, parsing, best practices |
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
