# HANDOVER — MermaidCanvas (Visuali2e)

*Senast uppdaterad: 2026-05-30 · Version: v50.6 · Branch: `main`*

Det här dokumentet låter vem som helst (människa eller Claude Code CLI) ta över
projektet med glasklarhet om var allt finns. Läs detta + `CLAUDE.md` först.

---

## 1. Var allt ligger på datorn

**Projektets huvudmapp (jobba HÄR):**
```
/Users/kim/2e Mermaid Code
```
- Detta är git-repots rot, branch `main`. ALLT arbete ligger nu i `main`
  (mergat 2026-05-30) och är pushat till GitHub.
- GitHub: https://github.com/kim0scar/MermaidCanvas (privat, konto `kim0scar`).

> **Not om worktrees:** under `.claude/worktrees/` finns tillfälliga
> arbetskopior från tidigare sessioner. IGNORERA dem — `main` i huvudmappen är
> sanningen. De kan rensas med `git worktree prune`.

## 2. Appens nuläge (v50.6)

- SwiftUI iPhone-app, visuell flödesschema-editor. Persistas som Mermaid-markdown.
- Versionsnummer: **single source of truth** = `app/MermaidCanvas/Sources/App/AppVersion.swift`.
- v50.6 = 6 buggfixar + 2 regressionstester + två nya utvecklingsverktyg (se nedan).
- Senaste deploy: iPhone 16 Pro (device-id i `CLAUDE.md`).

## 3. Styrdokument (läs i denna ordning)

1. `CLAUDE.md` — konstitutionen: alla regler + sparplats-tabell (sanningskälla).
2. `app/MermaidCanvas/Sources/App/AppVersion.swift` — aktuellt versionsnummer.
3. `ROADMAP.md` — versioner + v50.6-changelog + vad som återstår.
4. `BLUEPRINT.md` — fil-index + modul-ansvar.
5. `ARKITEKTUR-MERMAID.md` — arkitekturdiagram (OBS: speglar v39, se doku-skuld nedan).
6. `UX_PERSONA_AUDIT.md` — 14 UX-fynd från användartestet (nästa-att-fixa).

## 4. Utvecklingsverktyg (byggda denna session)

Två återanvändbara metoder, dokumenterade i `Metoder/` och kopierade som
körbara skills i `verktyg-skills/`:

| Metod-doc | Skill (kopia i repo) | Original-plats |
|---|---|---|
| `Metoder/METOD-CLI-PARALLELL.md` | `verktyg-skills/cli-parallell-arbetare/` | `~/.claude/skills/cli-parallell-arbetare/` |
| `Metoder/METOD-ANVANDARTEST-UI.md` | `verktyg-skills/ux-personas-test/` | `~/.claude/skills/ux-personas-test/` |

- **cli-parallell-arbetare** — kör Code CLI som parallell read-only bug-jägare.
- **ux-personas-test** — AI-personas driver appen i simulatorn via `idb` och hittar UX-fel.

> **OBS — skillen är AKTIV från `~/.claude/skills/`, inte från repo-kopian.**
> `verktyg-skills/` är en *läsbar kopia för handover*. Vill du att skillsen ska
> fungera på en NY dator: kopiera dem därifrån till `~/.claude/skills/`.

### idb-setup (krävs för ux-personas-test)
- `brew install facebook/fb/idb-companion`
- Python-klient i venv med **Python 3.13** (kraschar på 3.14): `~/.idb-venv`,
  `pip install fb-idb`.
- Wrappern `verktyg-skills/ux-personas-test/bin/idb` sätter PATH automatiskt.

## 5. Vad som återstår (från UX-audit + backlog)

**Blockerande UX-buggar (fixa först):**
- Andra form går inte att lägga till (ser ut som inget händer).
- Dubbeltap öppnar ingen textredigering.
- VoiceOver läser tekniska symbolnamn.

**Stör men blockerar inte:** former staplas osynligt · ingen markeringsfeedback ·
träffytor <44pt · ingen onboarding · pil-skapande svårhittat.

**Teknisk skuld:**
- `ARKITEKTUR-MERMAID.md` speglar v39 — koden är v50.6. Behöver omskrivning.
- Backlog: konvertera flaky V48-tester till launch-arg-bas; byt app-ikon-task.

## 6. Hur man tar över — snabbstart

```bash
cd "/Users/kim/2e Mermaid Code"
git status                  # ska vara rent på main
git log --oneline -5        # se senaste arbetet
# Bygg + deploy: följ "Start för ios appar Kim.md"
# UX-test: säg t.ex. "testa appen som en nybörjare" (kräver idb, se §4)
```

## 7. Verifiera att allt är sparat
```bash
git status            # rent
git status -sb        # "up to date with origin/main"
git log --oneline -1  # 859179c docs: Metoder/ …
```
