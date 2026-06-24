# VERSIONSHANTERING.md

Exakt checklista som Claude Code följer **vid varje deploy** till iPhone. En deploy = en ny version.

## Vad är en version?

En version skapas varje gång appen byggs och installeras på iPhone. **Inte** vid varje liten kod-iteration under pågående arbete.

**EN enda version — aldrig två** (Kims order 2026-06-24). Versionsnummer: `1.0`, `1.1`, `1.2`, … Samma nummer används BÅDE i appen (det Kim ser), i bundle-versionen (MARKETING_VERSION + CURRENT_PROJECT_VERSION — lika), i git-taggen (`v1.0`) och i ZIP-namnet. Inget separat bygg-räknar-nummer.

## Checklista vid varje deploy

Kör i ordning. Hoppa inte över steg.

### 1. Kontrollera att git är rent

```bash
cd "/Users/kim/2e Mermaid Code"
git status
```

Allt ska vara stagat eller commitat innan deploy startar.

### 1b. Bumpa versionsnumret (EN enda)

Öppna `app/MermaidCanvas/Sources/App/AppVersion.swift`.
Höj `AppVersion.version` till nästa nummer (t.ex. `1.0` → `1.1`). **Detta är enda stället versionsnumret bor.**
Uppdatera `project.yml` så `MARKETING_VERSION` OCH `CURRENT_PROJECT_VERSION` = SAMMA nummer (`scripts/arch-check.py` blockerar annars).

Statusen i appen visar denna sträng. Om den inte uppdateras vet inte Kim om han kör nya eller gamla bygget.

### 1c. Kör grindarna (måste vara gröna)

```bash
cd "/Users/kim/2e Mermaid Code"
python3 scripts/arch-check.py                 # arkitektur (lager/filstorlek/version)
node scripts/mermaid-conformance.mjs          # appens mermaid PARSAR i riktig mermaid + lint mot kända render-glapp
node scripts/mermaid-render-check.mjs         # RENDER-grind (💡#8) — headless Chrome renderar fixturerna; parse räcker inte (`<--` parsar men kraschar render). BLOCKERANDE.
# Round-trip-grinden (STEG F) — BLOCKERANDE: noll avvikelse. Får aldrig hoppa över vid deploy.
xcodebuild test -project app/MermaidCanvas/MermaidCanvas.xcodeproj -scheme MermaidCanvas \
  -destination 'platform=iOS Simulator,id=<iPhone-sim-UDID>' \
  -only-testing:MermaidCanvasUnitTests/RoundTripFidelityTests \
  -only-testing:MermaidCanvasUnitTests/StateJSONSymmetryTests
```

- Ändrat hur former/kanter skrivs i `MermaidGenerator`? Regenerera först: `./scripts/extract-mermaid-fixtures.sh` (kör korpus-testet + validerar).
- Round-trip-grinden är BLOCKERANDE (Kims noll-avvikelse-garanti) + körs även av pre-commit när `Sources/Mermaid/` eller modellerna ändras. Mjuka aldrig upp ett round-trip-test.
- Render-grinden (`mermaid-render-check.mjs`) kräver Google Chrome (renderar fixturerna på riktigt). Parse-grinden + lint i pre-commit fångar den KÄNDA klassen (`<--`); render-grinden vid deploy fångar ALLT riktig mermaid kraschar på (💡#8, steg H-fyndet). Kraschar någon fixtur → generera om/fixa generatorn, deploya inte.
- Kör dessutom HELA testsviten via Xcode/xcodebuild innan deploy.
- Saknas `node_modules`? Kör `npm install` en gång (committat `package.json` pinnar mermaid + jsdom).

### 2. Bygg och deploya till iPhone

Följ `Start för ios appar Kim.md` (Steg 1A → Steg 2 → Steg 3 för native Swift, eller motsvarande för Godot).
Verifiera att appen faktiskt **startar** på iPhone innan du går vidare.

### 3. Arkivera föregående arkitektur

Innan du skriver om `ARKITEKTUR-MERMAID.md`: ta en kopia av den **föregående** versionen och lägg den i `arkiv/`. Föregående version är den som var live *innan* denna deploy — alltså `vN-1`.

```bash
# Exempel om du just bumpat till v13: ARKITEKTUR-MERMAID.md beskrev v12 → snapshot:
cp ARKITEKTUR-MERMAID.md "arkiv/ARKITEKTUR-MERMAID-v12.md"
```

Detta säkerställer att varje deployad version har en frusen snapshot i `arkiv/`.

### 4. Skapa ny ARKITEKTUR-MERMAID.md

Spegla nuvarande kod. Två obligatoriska delar:
1. Ett `mermaid graph TD`-diagram över appens komponenter och flöden.
2. En tabell: `Komponent | Fil | Ansvar`.

Lägg datum + versionsnummer överst.

### 5. Commit

```bash
git add -A
git commit -m "vN: <vad ändrades på svenska>"
```

Exempel: `git commit -m "v3: la till stöd för att rita pilar mellan former"`

### 6. Pusha till GitHub + tagga + ZIP

```bash
git push
# Taggen = v + versionen (t.ex. v1.0). EN version, samma nummer överallt.
git tag v1.0 && git push origin v1.0
# ZIP till iCloud så Kim själv kan backa version utan git:
git archive --format=zip \
  -o "/Users/kim/Library/Mobile Documents/com~apple~CloudDocs/00000. Claude Code/Visuali2e-versioner/Visuali2e-1.0.zip" v1.0
```

Varje version finns då på TRE sätt: git-historik, GitHub-tagg och separat ZIP i iCloud.

**Rollback utan git (Kims väg):** öppna `Visuali2e-versioner/` i iCloud → packa upp
önskad `Visuali2e-X.Y.zip` → be Claude Code bygga+deploya från den mappen.
**Rollback med git:** `git checkout v1.0` (eller `git revert`).

### 7. Rapportera till Kim

Säg exakt: **"Version vN deployad och pushad."**
Plus en mening om vad som ändrades.

## Rollback om något gick sönder

Om appen kraschar eller funktionalitet försvann i nyss deployade version:

```bash
git revert HEAD
# Bygg om och deploya föregående version enligt Start för ios appar Kim.md
```

Spegla rollbacken: skapa en ny `ARKITEKTUR-MERMAID.md` som matchar den återställda koden, och döp om den trasiga i arkivet till `ARKITEKTUR-MERMAID-vN-trasig.md` så historiken behålls.
