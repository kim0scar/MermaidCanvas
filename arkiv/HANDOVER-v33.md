# HANDOVER: v33-räddning + UI-komplettering

**Datum:** 2026-05-19
**Status:** Canvas-fix klar och deployad. UI-komplettering pågår.
**Mål (sätt via `/goal`):** Återställ v33 till "Apple-nivå" med ALLT UI. Iterera tills perfekt.

## Sammanhang (läs detta först)

Kim hade en v33 på sin iPhone som "fungerade perfekt med allt UI". v33-arbetet committades aldrig till git — bara en droppad stash + 2 testfiler räddades. Resten finns BARA i Claude-sessionsloggen som tool_use-events.

Vi har återställt:
- ✅ **Canvas-fixen** (objekt landar där fingret släpps, pan/zoom funkar) — via A10 (transformEffect) + synkron dragController-synk
- ✅ **A3** (Mermaid live)
- ✅ **A4** (Preview-knapp bort)
- ✅ **V33-testfiler** (V33SensorTests + V33AutoLoopTests)
- ✅ **AppVersion = v33**
- ✅ **V33SensorTests gröna i simulator**
- ✅ **Deployad till iPhone**

Vi har INTE återställt:
- ❌ **Större UI-redesign från v33** (Kim säger "allt UI saknas")

## Problem som behöver lösas i nästa session

### 1. iPhone visar "v32" trots v33-deploy
Kim öppnade appen efter min deploy och såg "v32" i status-baren. Två möjliga orsaker:
- Han kollade FÖRE installationen tog effekt (möjligt)
- App-bundle är inte uppdaterad korrekt

**Verifiera:** `xcrun devicectl device info apps --device F271CF8E-4260-5501-9E86-1C765EA1A38E | grep -A2 mermaidcanvas` — output visade "1.0 1" inte versionsnamn. Be Kim öppna appen igen, eller force-reinstall.

### 2. Saknade UI-ändringar från v33-sessionen

En Explore-agent har börjat mappa förlorade UI-ändringar från sessionsloggen `/Users/kim/.claude/projects/-Users-kim-2e-Mermaid-Code/a696e37d-cd10-46e1-8ad6-53d453fef5e6.jsonl` (33MB).

**Hittills identifierat (preliminärt — verifiera mot kod):**

| Fil | Förlorad ändring |
|---|---|
| `ToolbarView.swift` | `case packs` borttaget från SecondaryToolbarRow; `packsSecondary`/`packChip`/`packToggle`-funktioner borttagna; shapesSecondary omdesignad från VStack 2 rader → ScrollView 1 rad; padding 14pt → 10pt; diagnostik-string för test borttagen |
| `ContentView.swift` | Preview-sheet integration; Note-popup-sheet möjligen borttagen |
| `CanvasModel.swift` | Möjlig borttagning av `toggleShapePack`, `activeShapePacks` |
| `ShapeNode.swift` | 6 Write + 8 Edit — formmodell-ändringar (okänt vad) |
| `EditShapeSheet.swift` | 4 Write-events — dialog-omdesign |
| `LägenMenu.swift` | 3 Write-events — meny-struktur |
| `MinimapView.swift` | 2 Write-events |
| `NewCanvasSheet.swift` | 2 Write-events |
| `PlatformRulesSheet.swift` | 3 Write-events |
| `SelectionHandles.swift` | 2 Write-events |
| `ColorPack.swift` | 1 Write — färgpaletter ändrade? |

**OBS:** Explore-agentens första analys är preliminär. Andra agenter behöver djupare extraktion av varje filändring för konkret kod att applicera.

### 3. Detta är osäkert: vill vi BEHÅLLA packs-funktionen?

v33 verkar ha TAGIT BORT shape-packs-toggles (förenkling). Men v31-koden har dem inbakade. Fråga: var det medvetet i v33? Eller är det testkod-städning? Verifiera med Kim INNAN du tar bort packs — han kanske använder dem.

## Konkret nästa-steg-lista

### Steg 1: Verifiera iPhone-versionen
```bash
# Be Kim öppna appen och titta på status-baren
# Om det fortfarande säger v32: force-reinstall
xcrun devicectl device uninstall app --device F271CF8E-4260-5501-9E86-1C765EA1A38E com.kimlundqvist.mermaidcanvas
xcrun devicectl device install app --device F271CF8E-4260-5501-9E86-1C765EA1A38E \
  "/Users/kim/2e Mermaid Code/.claude/worktrees/pedantic-noyce-9467c0/app/MermaidCanvas/DerivedData/Build/Products/Debug-iphoneos/MermaidCanvas.app"
xcrun devicectl device process launch --device F271CF8E-4260-5501-9E86-1C765EA1A38E com.kimlundqvist.mermaidcanvas
```

### Steg 2: Djupextrahera EXAKTA kodändringar per fil
Spawna en NY Explore-agent för VARJE fil i listan ovan, för att hämta exakt sista versionen av tool_use Edit/Write-anropet. Sökmönster i jsonl:

```bash
grep -o '"file_path":"[^"]*ToolbarView[^"]*"[^}]*"new_string":"[^"]*"' \
  /Users/kim/.claude/projects/-Users-kim-2e-Mermaid-Code/a696e37d-cd10-46e1-8ad6-53d453fef5e6.jsonl | tail -5
```

Alternativ: använd `jq` för att parsera tool_use-events strukturerat.

### Steg 3: Implementera per fil
Applicera ändringarna inkrementellt. Commit + push efter varje fil som kompilerar (Regel 12).

### Steg 4: Iterera med simulator-tester
Efter varje fil: kör `xcodebuild test -only-testing:MermaidCanvasUITests/V33SensorTests` i simulatorn. Visa Kim screenshot av sim:n. Be om PASS/FAIL.

**Använd skill `ios-sim-validation`** för strukturerad orkestrering (det är vad den är till för).

### Steg 5: När allt UI är på plats → ny iPhone-deploy
Build → uninstall → install → launch.

### Steg 6: Kim verifierar på iPhone
Tvåspårigt PASS (sim + device) innan vi anser klart. Använd skill `ui-verifiering-ios`.

### Steg 7: Sista commit
"v33 komplett: alla A1-A10 + UI-redesign återställd."

## Filer som matters

| Fil | Roll |
|---|---|
| [CLAUDE.md](CLAUDE.md) | Konstitutionen, Regel 12 om auto-commit |
| [AppVersion.swift](app/MermaidCanvas/Sources/App/AppVersion.swift) | "v33" — bumpa INTE om ej feature-shippad |
| [CanvasView.swift](app/MermaidCanvas/Sources/App/Views/CanvasView.swift) | A10 transformEffect, synkron dragController-synk — KLAR |
| [ToolbarView.swift](app/MermaidCanvas/Sources/App/Views/ToolbarView.swift) | HUVUDSAKLIG UI-FÖRLUST — packs bort, shapes-row redesign |
| [ContentView.swift](app/MermaidCanvas/Sources/App/ContentView.swift) | Preview-sheet redan applicerad från stash |
| Sessionslogg | `/Users/kim/.claude/projects/-Users-kim-2e-Mermaid-Code/a696e37d-cd10-46e1-8ad6-53d453fef5e6.jsonl` — guldgruvan |
| Räddade testfiler | `~/v33-rescue/` |
| Stash-tag | `git tag rescued-v32-stash` (commit 80c6d577) |

## Senaste 4 commits på main

```
41d648b fix: kopiera EndToEndTests + LayoutOverflowTests från huvudtree
6e7da16 v33: städning (Preview bort, Mermaid live) + V33-tester + bump AppVersion
1053c3b v33 canvas-fix: transformEffect + synkron dragController-synk
ed4b7ee Regel 12: auto-commit + push efter varje fungerande fix
```

## Tasks (status vid handover)

```
#1  ✅ Säkra v33-data (tag + backup)
#2  ✅ Granska stash per fil
#3  ✅ Extrahera A1-A10-spec
#4  ✅ Reimplementera root-cause-fix + A10
#5  ✅ Bumpa AppVersion till v33
#6  ✅ V33SensorTests gröna i sim
#7  🔄 Iterera tills v33 är komplett + allt UI på Apple-nivå
#8  ⏳ Merge → main + push (delvis: push:ats kontinuerligt)
#9  ✅ A2/A7/A8 verifierat finns i v31
#10 ✅ A1/A3/A4/A6 städning klar
#11 🔄 Verifiera varför iPhone visar v32
#12 🔄 Djupextrahera ALLA UI-ändringar från v33-sessionen
```

## Hur du börjar nästa session

1. Läs CLAUDE.md (konstitutionen)
2. Läs denna fil
3. Läs senaste plan: `~/.claude/plans/kan-du-kolla-p-compiled-jellyfish.md`
4. Kör `git log --oneline -5` för att se var vi står
5. Fortsätt från **Steg 1: Verifiera iPhone-versionen** ovan
6. Goal-hooken är aktiv — den blockerar Stop tills v33 är "Apple-nivå". Du måste iterera klart.
