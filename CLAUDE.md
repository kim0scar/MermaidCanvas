# CLAUDE.md — Konstitutionen för MermaidCanvas

Detta är styrdokumentet för Claude Code i det här projektet. Kort med flit. När du som Claude Code öppnar projektet — läs den här filen först.

---

## Vid ny session eller efter /compact — läs i den här ordningen

Detta är minimum för att fortsätta arbeta:

1. **`CLAUDE.md`** (denna fil) — alla regler + var allt är
2. **`app/MermaidCanvas/Sources/AppVersion.swift`** — nuvarande version-nummer (single source of truth)
3. **`ARKITEKTUR-MERMAID.md`** — exakt vad nuvarande version har för funktioner + filöversikt
4. **`~/.claude/plans/vi-ska-bygga-en-magical-knuth.md`** — vad som är gjort + nästa steg
5. **`ROADMAP.md`** — versioner + roadmap framåt
6. **Memory:** `~/.claude/projects/-Users-kim-2e-Mermaid-Code/memory/MEMORY.md` (laddas automatiskt)
7. **Git-loggen:** `git log --oneline -10` för senaste 10 commits

Om något verkar saknas, fråga Kim: "Är allt sparat enligt CLAUDE.md sanningskälla?"

---

## Var allt finns sparat (sanningskälla)

Den här tabellen är **alltid aktuell**. Uppdatera den så fort en ny sparplats tillkommer.

| Vad | Var | Synkat till |
|---|---|---|
| **Projektkod + styrdokument** | `/Users/kim/2e Mermaid Code/` | git (lokalt) + GitHub |
| **Metodfil: visuellt språk** | `METOD-VISUELL-DIALOG.md` (portabel — ska finnas med i alla projekt) | git |
| **Metoder (arbetssätt)** | `Metoder/` — CLI-parallell bug-jakt + AI-användartest (idb) | git |
| **GitHub-repo (privat)** | https://github.com/kim0scar/MermaidCanvas | molnbackup, `kim0scar`-kontot |
| **App-källkod (Swift)** | `app/MermaidCanvas/Sources/` (Models, Views, Mermaid, Persistence) | git |
| **Xcode-projekt** | `app/MermaidCanvas/MermaidCanvas.xcodeproj/` (regenereras från `project.yml` via `xcodegen`) | git |
| **Build-artefakter** | `app/MermaidCanvas/DerivedData/` — *.gitignored*, regenereras vid build | endast lokalt |
| **Aktuell arkitektur** | `ARKITEKTUR-MERMAID.md` (senaste version) | git |
| **Swift-modul-tabell** | `ARKITEKTUR-SWIFT.md` (filtabell + modul-roller) | git |
| **Roadmap + version-spårning** | `ROADMAP.md` (versioner + plan framåt) | git |
| **Tidigare arkitektur-versioner** | `arkiv/ARKITEKTUR-MERMAID-vN.md` (en per deploy) | git |
| **Appen på iPhone** | bundle-ID `com.kimlundqvist.mermaidcanvas`, Team `SFXR8MV6MP`, device F271CF8E-4260-5501-9E86-1C765EA1A38E | enbart på iPhone tills nästa deploy från Mac |
| **Kims canvas-filer (i drift)** | `~/Library/Mobile Documents/com~apple~CloudDocs/00000. Claude Code/1. Mermaid/` | iCloud Drive — syns på både iPhone och Mac |
| **Memory (för framtida sessioner)** | `~/.claude/projects/-Users-kim-2e-Mermaid-Code/memory/` | endast lokalt på Macen |
| **Plan-fil (aktuell roadmap)** | `~/.claude/plans/vi-ska-bygga-en-magical-knuth.md` | endast lokalt på Macen |
| **Versionssnapshot per deploy** | `arkiv/ARKITEKTUR-MERMAID-vN.md` | git |

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

Användarens canvas-filer ligger i:
`~/Library/Mobile Documents/com~apple~CloudDocs/00000. Claude Code/1. Mermaid/`

## Regler för Claude Code (icke förhandlingsbara)

1. **Var-allt-finns-sparat-tabellen ovan är sanningskällan.** När en ny sparplats tillkommer (ny mapp, nytt moln, nytt verktyg) — uppdatera tabellen i samma commit. Det är denna fil som svarar på "är allt sparat?".
2. **Vid scope-tvivel — läs `PRODUKT.md` först.** Den definierar vad som hör/inte hör hemma i appen.
3. **Vid Mermaid-tvivel — läs `MERMAID-FAKTA.md`.** Den är blueprinten för hur Mermaid faktiskt fungerar. Gissa aldrig syntax.
4. **Versionshantering**: följ alltid `VERSIONSHANTERING.md`. Hoppa inte över steg.
5. **Modulär kod**: små filer, en sak per fil. Hellre fler filer än en stor. Inga monolitfiler — även om det blir mer kod totalt.
   **Single source of truth för versionsnummer**: `app/MermaidCanvas/Sources/AppVersion.swift`. Bumpa endast där. Aldrig hårdkoda versionsnummer någon annanstans.
   **Versionen ska synas i appen** (status-baren). Vid varje deploy: uppdatera `AppVersion.current` *innan* build.
6. **Arkitektur som sanning**: efter varje deploy ska `ARKITEKTUR-MERMAID.md` uppdateras så att diagrammet alltid speglar nuvarande kod.
7. **iOS-deploy**: följ `Start för ios appar Kim.md` för Team ID, signing och devicectl-flödet. Allt står där.
8. **Språk**: svenska i kod-kommentarer (få sådana) och commit-meddelanden. Korta meningar.
9. **Frågestil**: Kim är inte utvecklare. Gör rimliga antaganden, fråga bara vid riktiga vägval. Inget utvecklarjargong i svar.
10. **Innan du ändrar kod**: läs `BLUEPRINT.md` (fil-index + modul-ansvar) och `ARKITEKTUR-MERMAID.md` (diagram). Om din ändring avviker från BLUEPRINT.md:s modul-gränser — motivera det för Kim innan du fortsätter.
11. **Visuell dialog är delat språk — två lager**: när du läser eller skriver canvas-filer, följ `METOD-VISUELL-DIALOG.md` strikt. Protokollet har **två lager** som måste hållas isär: *Fidelity* (positioner, storlekar, canvas-mått — så du ser exakt det Kim ritat) och *Semantik* (kategori per nod — så du vet vad varje form *betyder*). App-lagret (zoom, multiselect, undo, etc.) är en tredje sak som aldrig får blandas in i filen. Förlustfri round-trip + korrekt semantik är icke förhandlingsbar — utan båda fungerar inte hela syftet med appen.
12. **Auto-commit + push efter varje fungerande fix.** Så fort en ändring är klar och kompilerar (eller verifierat funkar i sim/iPhone): commit:a och push:a direkt — utan att Kim ber om det. Kim ska aldrig behöva oroa sig för att jobb försvinner. Versionsbumpning sker fortfarande bara vid milstolpe (regel 4), men *själva sparandet* är automatiskt mellan versioner. Innan `/clear`: verifiera att `git status` är clean och att `origin/main` är synkat — säg till Kim om något saknas.

## Filer du som Claude Code styrs av

| Fil | Vad den säger |
|---|---|
| `CLAUDE.md` | Den här filen — konstitutionen |
| `PRODUKT.md` | VARFÖR och VAD: vision, scope, vad som hör/inte hör hemma |
| `MERMAID-FAKTA.md` | Blueprint för Mermaid: syntax, fallgropar, rendering, parsing, best practices |
| `METOD-VISUELL-DIALOG.md` | Protokoll för delat visuellt språk Kim ↔ Claude Code. Portabel — gäller alla projekt med visuell yta. |
| `N8N-FLODE-KONTRAKT.md` | Hur ett ritat flöde (`spec_type: flow`) blir n8n-workflow eller skill — entydigt, utan gissningar |
| `VERSIONSHANTERING.md` | Exakt checklista vid varje deploy / ny version |
| `ARKITEKTUR-MERMAID.md` | Aktuell arkitektur: mermaid-diagram + fil-tabell |
| `BLUEPRINT.md` | **Komplett fil-index** + modul-ansvar + skalbarhetsprinciper + v39 feature-kluster |
| `ARKITEKTUR-SWIFT.md` | Swift-modul-tabell (äldre, BLUEPRINT.md är nu primär) |
| `ROADMAP.md` | Versioner + roadmap framåt |
| `Start för ios appar Kim.md` | iPhone-deploy: signing, build, devicectl |
| `arkiv/ARKITEKTUR-MERMAID-vN.md` | Historik över hur appen sett ut tidigare |
| `~/.claude/plans/vi-ska-bygga-en-magical-knuth.md` | MVP-roadmap + nuvarande etapp |

## Användarens profil (kort)

Kim har dyslexi / ADHD / 2e-profil. Tänker visuellt och rumsligt. Föredrar bilder framför ord.
När du svarar Kim:
- Korta meningar
- Inga onödiga ord
- Visa hellre än förklara
- Svenska
