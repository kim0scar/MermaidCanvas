# CLAUDE.md — Konstitutionen för MermaidCanvas

Detta är styrdokumentet för Claude Code i det här projektet. Kort med flit. När du som Claude Code öppnar projektet — läs den här filen först.

---

## Vid ny session eller efter /compact — läs i den här ordningen

Detta är minimum för att fortsätta arbeta:

1. **`CLAUDE.md`** (denna fil) — alla regler + var allt är
2. **`ARKITEKTUR-OMBYGGNAD.md`** — 🔨 AKTIVT UPPDRAG (MA): hela arkitektur-ombyggnaden — uppdrag, fynd, gjort, KVAR + per-steg-recept. Läs denna för att återuppta efter `/clear`. Gäller tills MA (steg 17) är klart.
3. **`PROJEKTPLAN.md`** — LAGEN: aktivt steg + klart-kriterium + idébank (regel 13)
4. **`app/MermaidCanvas/Sources/App/AppVersion.swift`** — nuvarande version-nummer (single source of truth)
5. **`arkiv/HANDOVER-vN.md`** (senaste, t.ex. v73) — beslutslogg: vägval + varför + nuläge
6. **`ARKITEKTUR-MERMAID.md`** — exakt vad nuvarande version har för funktioner + filöversikt
7. **`ROADMAP.md`** — version-historik (bakåt) + **kommande funktioner & idéer** (framåt, post-bas) — men inget byggs ur roadmappen utan att först bli ett PROJEKTPLAN-steg (metod + plan styr)
8. **Memory:** `~/.claude/projects/-Users-kim-2e-Mermaid-Code/memory/MEMORY.md` (laddas automatiskt)
9. **Git-loggen:** `git log --oneline -10` för senaste 10 commits

Om något verkar saknas, fråga Kim: "Är allt sparat enligt CLAUDE.md sanningskälla?"

---

## Var allt finns sparat (sanningskälla)

Den här tabellen är **alltid aktuell**. Uppdatera den så fort en ny sparplats tillkommer.

| Vad | Var | Synkat till |
|---|---|---|
| **Projektkod + styrdokument** | `/Users/kim/2e Mermaid Code/` | git (lokalt) + GitHub |
| **Projektplan (LAGEN: steg + milstolpar + idébank)** | `PROJEKTPLAN.md` (regel 13) | git |
| **Projektplan: ritad vy (för appen)** | iCloud-Mermaid-mappen: `projektplan.md` — VY, regenereras av Claude vid status-ändring | iCloud Drive |
| **Projektplan-metoden (portabel, för nya projekt)** | `~/.claude/templates/projektplan-metod/` (README + MALL + REGEL + INTERVJU) | ZIP: iCloud `00000. Claude Code/projektplan-metod-v1.zip` |
| **Metodfil: visuellt språk** | `METOD-VISUELL-DIALOG.md` (portabel — ska finnas med i alla projekt) | git |
| **Metoder (arbetssätt)** | `Metoder/` — CLI-parallell bug-jakt + AI-användartest (idb) | git |
| **GitHub-repo (privat)** | https://github.com/kim0scar/MermaidCanvas | molnbackup, `kim0scar`-kontot |
| **App-källkod (Swift)** | `app/MermaidCanvas/Sources/` (Models, Views, Mermaid, Persistence) | git |
| **Xcode-projekt** | `app/MermaidCanvas/MermaidCanvas.xcodeproj/` (regenereras från `project.yml` via `xcodegen`) | git |
| **Build-artefakter** | `app/MermaidCanvas/DerivedData/` — *.gitignored*, regenereras vid build | endast lokalt |
| **Aktuell arkitektur** | `ARKITEKTUR-MERMAID.md` (senaste version) | git |
| **Swift-modul-tabell** | `ARKITEKTUR-SWIFT.md` (filtabell + modul-roller) | git |
| **Version-historik + kommande funktioner** | `ROADMAP.md` (bakåt: vad varje version innehöll · framåt: kommande funktioner & idéer post-bas — men byggs bara efter att de blivit ett PROJEKTPLAN-steg) | git |
| **Tidigare arkitektur-versioner** | `arkiv/ARKITEKTUR-MERMAID-vN.md` (en per deploy) | git |
| **Appen på iPhone** | bundle-ID `com.kimlundqvist.mermaidcanvas`, Team `SFXR8MV6MP`, device F271CF8E-4260-5501-9E86-1C765EA1A38E | enbart på iPhone tills nästa deploy från Mac |
| **Appen på Mac (menyrad)** | `/Applications/Visuali2e.app` — bundle `com.kimlundqvist.mermaidcanvas.mac`, Team `SFXR8MV6MP`. Menyrads-app (LSUIElement), DELAR all kod med iPhone-appen (target `MermaidCanvasMac`). Bygg: `xcodebuild -scheme MermaidCanvasMac -configuration Release -destination 'platform=macOS'`. Arkitektur: `ARKITEKTUR-DUAL-PLATFORM.md` | lokalt på Macen (Release i /Applications) |
| **Kims canvas-filer (i drift)** | `~/Library/Mobile Documents/com~apple~CloudDocs/00000. Claude Code/1. Mermaid/` | iCloud Drive — syns på både iPhone och Mac |
| **Versions-ZIPar (rollback utan git)** | `~/Library/Mobile Documents/com~apple~CloudDocs/00000. Claude Code/Visuali2e-versioner/Visuali2e-vN.zip` — en ZIP per version-tagg, skapas vid varje deploy (`git archive`) | iCloud Drive (syns på iPhone + Mac) |
| **Version-taggar (rollback med git)** | `git tag` — varje deploy taggas `vN` | GitHub (pushas med `git push origin --tags`) |
| **Dela appen med testaren Björn** | Skill `~/.claude/skills/visuali2e-bjorn/SKILL.md` ("dela med Björn") → käll-ZIP (HEAD) i iCloud-mappen `Versioner till Björn/Visuali2e-vN.zip` (samlas per version); Kim skickar manuellt. Vän-guide: `INSTALL-FÖR-VÄNNEN.md` + `scripts/friend-setup.sh` (byter Team-ID/bundle) — följer med i varje ZIP | iCloud (ZIP) + lokalt (skill) |
| **Skill: flode (kör skill-kedjor / dirigent)** | `~/.claude/skills/flode/SKILL.md` | endast lokalt på Macen |
| **MFP-pipeline: skills** | `~/.claude/skills/mfp-site-intelligence/SKILL.md` (Skill 1 v2: 4-vägs discovery + gap-analys + konsensus) + `~/.claude/skills/mfp-sortiment/SKILL.md` (Skill 2: E1/E2-par per sida) — körs via `flode` | endast lokalt på Macen |
| **MFP-pipeline: ritade flöden** | iCloud-Mermaid-mappen: `mfp-pipeline.md` (helheten, 4 skill-containrar) + `mfp-site-intelligence.md` (Skill 1 v2; v1 i `mfp-site-intelligence-v1-arkiv.md`) + `mfp-sortiment.md` (Skill 2) | iCloud Drive |
| **MFP-pipeline: körresultat** | iCloud-Mermaid-mappen: `mfp-site-intelligence/official_source_map.md` + `evidence/` (Skill 1 körd mot Canon) | iCloud Drive |
| **Memory (för framtida sessioner)** | `~/.claude/projects/-Users-kim-2e-Mermaid-Code/memory/` | endast lokalt på Macen |
| **Plan-fil (UTGÅNGEN — pekar på PROJEKTPLAN.md)** | `~/.claude/plans/vi-ska-bygga-en-magical-knuth.md` | endast lokalt på Macen |
| **Beslutslogg / handover (per save)** | `arkiv/HANDOVER-vN.md` (senaste = v72: vägval + varför + nuläge) | git |
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
3. **Vid Mermaid-tvivel — läs `MERMAID-FAKTA.md` (skrivskyddad facit-bibel).** Den är den enda sanningskällan för vad Mermaid KAN och INTE kan. Gissa aldrig syntax. Filen är `chmod 444` — lås bara upp den vid avsiktlig facit-revision (med nytt datum).

   **Noll-avvikelse-garantin (icke förhandlingsbar — kärnan i hela appen):** det Kim ser på canvasen ska bli EXAKT det andra får ur hans mermaid, och Kim ska kunna *rita → kopiera mermaid → radera → klistra in → få exakt samma, noll avvikelse*. Gäller Kim OCH andra. Tre krav:
   - **(a) Allt valideras mot RIKTIG mermaid INNAN det byggs vidare.** Bygg aldrig mermaid-genererande kod som inte är validerad: `node scripts/mermaid-conformance.mjs` (officiella `mermaid.parse`) måste vara grön. Ändrar du hur former/kanter skrivs — regenerera fixtures (`./scripts/extract-mermaid-fixtures.sh`) och se att grinden är grön.
   - **(b) App-bara funktioner måste ändå exporteras, röra sig med filen OCH kunna förstås av en läsare/AI — aldrig tyst.** Ribban i två delar: (1) **round-trippa** (överleva export) och (2) **avslöjas ärligt** i det inbäddade AI-ramverket (`AppCapabilities.frameworkText`) + facit-menyn. Bärare i prioritetsordning: **native mermaid** > **`%%`-metadata** (så en läsare i ren mermaid faktiskt ser fältet) > **state-JSON-only** — det sista BARA när mermaid genuint inte kan representera saken (t.ex. nod-text-fetstil), och då MÅSTE det flaggas "bara i state-blocket". **En hel STRUKTUR (ett nästlat underflöde, en grupp) får ALDRIG vara state-JSON-only** — den bärs som native `subgraph` så den syns i ren mermaid (lärdomen från underflöden, PARKERADE 2026-06-28 just för att de bröt detta). Detta är samma ribba som regel 15(a) ("bärare = `%%`-nyckel/native/state-JSON — aldrig enbart app-state"): state-JSON-i-filen är en giltig bärare, men en osynlig hel-struktur är det inte. Bygg aldrig en ren app-funktion utan att först lösa hur den överlever export OCH avslöjas.
   - **(c) Round-trip är maskinellt tvingad, inte en åsikt.** `RoundTripFidelityTests` (state-JSON = bokstavligt noll avvikelse; ren mermaid = identitet/semantik överlever) + round-trip-grind i pre-commit blockerar avvikelse. Mjuka aldrig upp ett round-trip-test.

   **Två-lager-modellen (säg det rakt ut):** appen är *inte* ren Mermaid. Mermaid är TRANSPORTEN (portabel, AI-läsbar kropp); appen är RENDERAREN med ett eget tilläggslager (`%%`-metadata + state-JSON = "MermaidCanvas Extended"). Egna former (phoneFrame, tabell, oktagon…) renderas i ren mermaid som närmaste native-form — Mermaids gräns, inte en bugg; identiteten bärs av `%% shape-type`. (Detalj: MERMAID-FAKTA.md sektion K + L. **Komplett fält-spec — varje app-only-fält + dess bärare: `EXTENDED-FORMAT.md`.**)

   **Bygg som Apple:** appen byggs lika robust och enhetlig som om Apple själva byggt den — inga lösa trådar, inga tysta degraderingar.

   **Metodiskt genom alla former:** form-vokabulären gås igenom form-för-form (inte stickprov); varje form bevisas round-trippa innan nästa.
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
13. **`PROJEKTPLAN.md` är lagen.** Inget byggs som inte står som steg där — gäller även "små" fixar och resonemang som leder till bygge.
    - **Sessionsstart/efter compact:** läs PROJEKTPLAN.md, säg läget på 3 rader: "Läget: X av Y klara. Pågår: steg N — ... Klart när: ... Kör vi?"
    - **Före nytt steg:** citera klart-kriteriet + verifiera att Kräver-steget är ✅. **WIP = 1**: max ett steg ⏳. Jobbigt steg → krymp det ("minsta biten som går att visa"), hoppa aldrig.
    - **Efter steg:** kör kriteriet bokstavligt. Maskinellt verifierbart → bocka + visa bevis. Kräver Kims ögon (iPhone) → bara Kim säger "klart". Uppdatera progressbar ("X% → Y%") + committa planen.
    - **Ny idé (Kims eller din):** EN rad i 💡 Idébanken direkt, svara kort: "Snygg. Sparad som 💡#N — vi är på steg X." Ingen diskussion, bygg inget. Idébanken töms bara vid milstolpe-slut, med Kim.
    - **Meta-spärr:** idéer om att förbättra planen/metoden själv parkeras likadant — metoden är fryst tills milstolpen är klar.
    - **Avvikelse/ändring av steg:** revideringsrad i planen FÖRE arbetet (datum · vad · varför). Klart-kriterier mjukas aldrig upp utan revideringsrad.
    - **Tak:** planen ≤ 100 rader, 1 mening per steg. I vardagen är bara tre saker skrivbara: status, idérad, krympt steg.
    - **Ritad vy:** iCloud-Mermaid `projektplan.md` är en VY av planen (status i etiketterna) — regenerera den vid varje status-ändring. Textfilen är alltid lagen.

14. **Arkitektur tvingas maskinellt — se `ARKITEKTUR-REGLER.md`.** `scripts/arch-check.py` måste vara grön innan commit (körs av `scripts/hooks/pre-commit`). Lagren pekar bara nedåt (View → Model → Mermaid/Persistence); Mermaid rör aldrig UI, Model ritar aldrig, jättefiler får bara krympa (ratchet i `scripts/arch-baseline.json`), version synkas AppVersion ↔ project.yml ↔ Info.plist. Round-trip-testerna är deploy-grind. **Mermaid-konformitetsgrinden** (`scripts/mermaid-conformance.mjs`, officiella mermaid.parse) körs också av pre-commit och vid deploy — appens genererade mermaid måste parsa i riktig mermaid. Bryt aldrig en regel utan att först motivera för Kim.

15. **De tre fönstren mot appen hålls ALLTID aktuella — maskinellt, inte på minnet (icke förhandlingsbart).** Tre saker beskriver "vad appen kan" för en utomstående och får ALDRIG bli inaktuella eller motsäga varandra: **(1) round-trippen** (export↔import av mermaid — Kim ritar→kopierar→raderar→klistrar→exakt samma; en vän öppnar i mermaid.live), **(2) AI-ramverket** (`AppCapabilities.frameworkText()` — copy-paste-texten en främmande AI får för att förstå filen), **(3) facit-menyn "Mermaid vs app"** i appen (Kims människo-facit). **Enda sanningskällan för alla tre är `AppCapabilities.swift`** — menyn och ramverket GENERERAS ur den, kan aldrig handredigeras isär. EXTENDED-FORMAT.md är den uttömmande fält-/bärar-specen (regeln listar aldrig fält själv — pekar dit).
    **Definition av klart (VARJE ny form/funktion/fix — alla fem gröna, annars inte klart):** (a) **bärare** i mermaid (`%%`-nyckel/native/state-JSON) — aldrig enbart app-state (regel 3b); (b) **`AppCapabilities`-rad** — ny form tvingas av uttömmande `shape(_:)`-switchen (kompilerar ej annars), ny funktions-nyckel läggs i `allCarrierKeys` + `features`; (c) **EXTENDED-FORMAT.md** uppdaterad i samma commit; (d) **round-trip-test** grönt (`RoundTripFidelityTests` + `StateJSONSymmetryTests`); (e) **facit-täckning grön** — `AppCapabilitiesCoverageTests` kräver BIJEKTION generator↔facit (ingen odokumenterad `%%`-nyckel, ingen fantom-nyckel) + att menyn/ramverket täcker varje form. **Gaten är lagen, inte din vilja** (pre-commit + deploy, regel 14). Är a–e röd/saknad → commit:a inte; täta först. Mjuka aldrig upp ett av dessa test — ska standarden ändras: revideringsrad (regel 13) FÖRST.

## Filer du som Claude Code styrs av

| Fil | Vad den säger |
|---|---|
| `CLAUDE.md` | Den här filen — konstitutionen |
| `PROJEKTPLAN.md` | **LAGEN** — vad som byggs, i vilken ordning, med klart-kriterier (regel 13) |
| `ARKITEKTUR-OMBYGGNAD.md` | 🔨 **AKTIVT UPPDRAG (MA)** — arkitektur-ombyggnadens uppdrag, fynd, gjort + KVAR + per-steg-recept. Återupptagnings-dokument efter `/clear`. |
| `PRODUKT.md` | VARFÖR och VAD: vision, scope, vad som hör/inte hör hemma |
| `MERMAID-FAKTA.md` | Blueprint för Mermaid: syntax, fallgropar, rendering, parsing, best practices |
| `EXTENDED-FORMAT.md` | **Komplett spec för det app-egna lagret** ("MermaidCanvas Extended"): varje app-only-fält → `%%`-nyckel + state-JSON-nyckel + om det överlever ren mermaid + reserverade nycklar |
| `METOD-VISUELL-DIALOG.md` | Protokoll för delat visuellt språk Kim ↔ Claude Code. Portabel — gäller alla projekt med visuell yta. |
| `N8N-FLODE-KONTRAKT.md` | Hur ett ritat flöde (`spec_type: flow`) blir n8n-workflow — entydigt, utan gissningar |
| `SKILL-KEDJA-KONTRAKT.md` | Hur ett ritat flöde blir en KEDJA av Claude Code-skills (container=skill, memory-nod=överlämnings-fil). Körs via skillen `flode`. |
| `VERSIONSHANTERING.md` | Exakt checklista vid varje deploy / ny version |
| `ARKITEKTUR-MERMAID.md` | Aktuell arkitektur: mermaid-diagram + fil-tabell |
| `BLUEPRINT.md` | **Komplett fil-index** + modul-ansvar + skalbarhetsprinciper + v39 feature-kluster |
| `ARKITEKTUR-REGLER.md` | **Maskinellt tvingade** arkitekturregler (lager, filstorlek, version) — `scripts/arch-check.py` blockerar brott (regel 14) |
| `ARKITEKTUR-SWIFT.md` | Swift-modul-tabell (äldre, BLUEPRINT.md är nu primär) |
| `ROADMAP.md` | Version-historik (bakåt) + kommande funktioner & idéer (framåt, post-bas); byggs bara via PROJEKTPLAN-steg |
| `Start för ios appar Kim.md` | iPhone-deploy: signing, build, devicectl |
| `arkiv/ARKITEKTUR-MERMAID-vN.md` | Historik över hur appen sett ut tidigare |

## Användarens profil (kort)

Kim har dyslexi / ADHD / 2e-profil. Tänker visuellt och rumsligt. Föredrar bilder framför ord.
När du svarar Kim:
- Korta meningar
- Inga onödiga ord
- Visa hellre än förklara
- Svenska
