# Start för iOS-appar — Kim

> **För Claude / framtida sessioner:** Den här filen är Kims fullständiga playbook från "tomt projekt" till "appen kör på iPhone över WiFi" — funkar för både native Xcode-appar och Godot 4-projekt. Bevisad fungerande 2026-05-10 med Echowake (Godot 4.6.2 → iPhone 16 Pro via WiFi). Alla fallgropar längst ner. Verifiera kort med kommandona i slutet om något känns osäkert; annars kör.

---

## 🤖 AI-bootstrap — gör detta FÖRST i ett nytt projekt

När Kim hänvisar dig till denna fil i en ny projektmapp är ditt första steg (innan något annat):

1. **Skapa `.claude/settings.local.json`** i den aktuella projektmappen med iOS-deploy-allowlistan från avsnittet "Claude Code-permissions" nedan. Detta görs *innan* du försöker köra något deploy-kommando — då slipper Kim klicka "tillåt" en enda gång under sessionen.
2. **Läs hela detta dokument** så du har Team ID, device-ID, bundle ID-konvention och fallgropar i huvudet.
3. **Verifiera miljön** med kommandona under "Steg 0" — tar 2 sekunder, bekräftar att Godot/Xcode/cert/iPhone fortfarande är på plats.
4. **Bekräfta för Kim på 1 rad:** "✅ Setup klar, redo att deploya till iPhone". Sedan jobbar du autonomt — Kim ska bara skriva *vad* appen ska göra, aldrig godkänna *hur* den byggs.

Det är hela mandatet. Kim klickar inget. Inga frågor om filer-på-disk, inga "tillåt detta kommando", inga Xcode-knappar. Allt körs via Bash från Claude.

---

## TL;DR — Allt är redan installerat

Apple ID (**gratis Individual — INTE paid Developer Program**), signing cert, parat device, alla SDK:er och Godot iOS-templates finns. Claude Code är konfigurerad så hela deploy-flödet körs utan permission-prompts. Workflow är 100% scriptbar — ingen kabel behövs.

---

## Hårdvara

| | |
|---|---|
| Dator | MacBook Pro M1, 8 GB RAM, **Apple Silicon (arm64)** |
| macOS | 26.4.1 (build 25E253) |
| Telefon | **iPhone 16 Pro** ("Kims iPhone"), parat & available över WiFi |
| iPhone — devicectl-ID (UUID) | `F271CF8E-4260-5501-9E86-1C765EA1A38E` |
| iPhone — xcodebuild-ID (ECID) | `00008140-0009446C1EC0801C` |

> ⚠️ De två iPhone-ID:n är **olika format för samma telefon**. Devicectl använder UUID, xcodebuild använder ECID. Både behövs i ett deploy-flöde.

> 8 GB RAM räcker bra för 2D-spel och native appar. Tyngre 3D-projekt kan bli trångt — flagga om ambitionen blir hög.

---

## Toolchain

| Verktyg | Version | Plats |
|---|---|---|
| Xcode | **26.4.1** (Build 17E202) | `/Applications/Xcode.app` |
| `xcode-select -p` | | `/Applications/Xcode.app/Contents/Developer` |
| Godot | **4.6.2.stable** (officiell) | `/Applications/Godot.app` |
| Godot iOS export templates | 4.6.2.stable | `~/Library/Application Support/Godot/export_templates/4.6.2.stable/` |

---

## Claude Code-permissions — så slipper Kim klicka "tillåt"

Hela detta deploy-flöde körs av Claude utan att Kim behöver godkänna varje kommando. Det fungerar tack vare två lager:

### Globalt (alla sessioner överallt)

`~/.claude/settings.json`:
```json
{
  "skipAutoPermissionPrompt": true,
  "permissions": { "defaultMode": "auto" }
}
```

`defaultMode: "auto"` sätter Claude i tillåtande läge från start. `skipAutoPermissionPrompt: true` hoppar över startdialogen som annars frågar om man vill aktivera det. **Redan satt — rör inte.**

### Per projekt (skapa direkt vid projektstart)

Skapa `<projektmapp>/.claude/settings.local.json` med iOS-deploy-allowlistan **innan** Claude börjar — då slipper Kim klicka "tillåt" första gången varje kommando råkar ut för promten:

```json
{
  "permissions": {
    "allow": [
      "Bash(mkdir -p builds/ios)",
      "Bash(mkdir -p build/ios)",
      "Bash(/Applications/Godot.app/Contents/MacOS/Godot --headless *)",
      "Bash(godot --headless *)",
      "Bash(xcodebuild *)",
      "Bash(xcrun devicectl *)",
      "Bash(xcrun xctrace *)",
      "Bash(xcrun simctl *)",
      "Bash(security find-identity *)",
      "Bash(security find-certificate *)",
      "Bash(security cms *)",
      "Bash(qlmanage -t *)",
      "Bash(sips *)",
      "Bash(chmod +x *deploy*.sh)",
      "Bash(bash *deploy*.sh)",
      "Bash(git add *)",
      "Bash(git commit *)",
      "Bash(git push *)",
      "Bash(gh repo *)",
      "Bash(gh auth *)"
    ]
  }
}
```

> 🔑 **Insikt:** Det är **projektmappens** `.claude/settings.local.json` som styr promptarna, inte global config. En tom mapp = ny session frågar om allt. Förfyll listan så är Claude direkt produktiv. RYMDSPEL-mappen har en längre ackumulerad lista som referens: `/Users/kim/RYMDSPEL/.claude/settings.local.json`.

---

## Apple-signing — KRITISKT

| | |
|---|---|
| Apple-konto | kim.lundqvist@gmail.com |
| Kontotyp | **Free Apple ID (Individual)** — 7-dagars provisioning profile TTL, ingen TestFlight |
| **Team ID** | **`SFXR8MV6MP`** ← använd detta |
| Signing identity (cert) | `Apple Development: kim.lundqvist@gmail.com (JQ5BQY5VNU)` |
| Cert fingerprint (SHA-1) | `11DDA959AE6B2B9BB5AC14874CD771219989597C` |
| Provisioning profiles | `~/Library/Developer/Xcode/UserData/Provisioning Profiles/` (Xcode 26-läget — INTE den gamla `~/Library/MobileDevice/...`-mappen) |

> 🚨 **Fallgrop:** `(JQ5BQY5VNU)` på slutet av cert-namnet är **cert-CN-suffix**, INTE Team ID. Att förväxla dessa ger felet *"No Account for Team JQ5BQY5VNU"*. Kims faktiska Team ID är `SFXR8MV6MP`, läst ur cert-OU=.

**Verifiera Team ID rätt (kör om osäker):**
```bash
security find-certificate -c "Apple Development: kim.lundqvist@gmail.com" -p \
  | openssl x509 -text -noout | grep Subject
# Subject: UID=..., CN=Apple Development: kim.lundqvist@gmail.com (JQ5BQY5VNU), OU=SFXR8MV6MP, O=Kim Lundqvist, C=US
#                                                                                ↑ Team ID är OU= , inte (...)
```

**Andra hint:** existerande provisioning profiles avslöjar Team ID:
```bash
for f in ~/Library/Developer/Xcode/UserData/Provisioning\ Profiles/*.mobileprovision; do
  /usr/bin/security cms -D -i "$f" 2>/dev/null | grep -A1 TeamIdentifier | grep string
done
# → <string>SFXR8MV6MP</string>
```

---

## End-to-end playbook

### Steg 0: Kontrollera miljön (en sekund)

```bash
/Applications/Godot.app/Contents/MacOS/Godot --version  # → 4.6.2.stable.official.*
xcodebuild -version                                     # → Xcode 26.4.1
security find-identity -v -p codesigning                # → 1 valid identity (Apple Development)
xcrun devicectl list devices                            # → Kims iPhone "available (paired)"
```

Om något inte stämmer: stop och felsök innan vi kör.

---

### Steg 1A — Bygga native Xcode-app (snabbväg)

1. **Xcode → File → New → Project** → välj t.ex. *App* under *iOS* → fyll i:
   - Product Name: appnamnet
   - Team: `Kim Lundqvist (SFXR8MV6MP)`
   - Organization Identifier: `com.kimlundqvist`
   - Interface: SwiftUI eller Storyboard
2. **Echowake-target → Signing & Capabilities** → bocka **Automatically manage signing** (om det inte redan är ifyllt). Team ska vara *Kim Lundqvist (SFXR8MV6MP)*.
3. Plugga in iPhone, eller välj den från **device-väljaren längst upp** (WiFi-paired iPhone visas där också).
4. **Cmd+R**. Klart.

→ hoppa till **Steg 4 (WiFi-deploy)** om du vill köra utan Xcode GUI-knappen.

---

### Steg 1B — Bygga Godot 4-projekt

#### Projektets `project.godot` måste ha:
```ini
[application]
config/name="<AppNamn>"
run/main_scene="res://scenes/Main.tscn"
config/features=PackedStringArray("4.4", "Mobile")
config/icon="res://icon.svg"

[display]
window/size/viewport_width=1080
window/size/viewport_height=1920
window/handheld/orientation="portrait"
window/stretch/mode="canvas_items"
window/stretch/aspect="expand"

[rendering]
renderer/rendering_method="mobile"
renderer/rendering_method.mobile="mobile"
textures/vram_compression/import_etc2_astc=true   ; ⚠️ KRÄVS av iOS-export, annars failar utan tydligt felmeddelande
environment/defaults/default_clear_color=Color(0.012, 0.014, 0.04, 1)
```

#### Skapa `export_presets.cfg` direkt (slipper Godot-GUI):
Använd mallen i `/Users/kim/RYMDSPEL - SECOND/Echowake/export_presets.cfg` som referens. Ändra:
- `name` (presetets namn, t.ex. `"iOS"`)
- `export_path="builds/ios/<AppNamn>.xcodeproj"`
- `application/bundle_identifier="com.kimlundqvist.<appnamn>"`
- `application/app_store_team_id="SFXR8MV6MP"`
- `application/targeted_device_family=0` ← **0 = iPhone**, inte 1. Godots mappning är förvirrande:
  - `=0` → pbxproj `TARGETED_DEVICE_FAMILY="1"` (iPhone) ✓
  - `=1` → pbxproj `TARGETED_DEVICE_FAMILY="2"` (iPad) ❌ buggigt
  - `=2` → pbxproj `TARGETED_DEVICE_FAMILY="1,2"` (universal)
- `application/export_project_only=true` ← **lättar validering**, Godot dumpar bara Xcode-projektet utan att försöka signera. Sign sker i nästa steg.
- `application/min_ios_version="14.0"` (Metal-renderer kräver iOS 14+)

#### Exportera:
```bash
cd "/Users/kim/PROJEKTMAPP"
mkdir -p builds/ios
/Applications/Godot.app/Contents/MacOS/Godot --headless --export-debug "iOS" "builds/ios/<AppNamn>.xcodeproj"
```

Godot skapar:
- `builds/ios/<AppNamn>.xcodeproj/`
- `builds/ios/<AppNamn>/` (källfiler — `dummy.cpp`, plist, storyboard, Images.xcassets)
- `builds/ios/<AppNamn>.xcframework/` + `MoltenVK.xcframework/`
- `builds/ios/<AppNamn>.pck` (resurspaketet)

---

### Steg 2 — Bygg för iPhone arm64

```bash
cd "/Users/kim/PROJEKTMAPP/builds/ios"
xcodebuild -project <AppNamn>.xcodeproj \
  -scheme <AppNamn> \
  -configuration Debug \
  -sdk iphoneos \
  -destination "platform=iOS,id=00008140-0009446C1EC0801C" \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=SFXR8MV6MP \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration \
  -derivedDataPath ./DerivedData \
  build
```

Vad de magiska flaggorna gör:
- `CODE_SIGN_STYLE=Automatic` + `DEVELOPMENT_TEAM=SFXR8MV6MP`: override pbxproj manual signing (Godot defaultar till Manual).
- `-allowProvisioningUpdates`: låter xcodebuild kontakta Apple-servern och hämta/skapa development provisioning profile.
- `-allowProvisioningDeviceRegistration`: tillåter att registrera enheten på developer-portalen om den inte redan är där.

→ Build artifact: `./DerivedData/Build/Products/Debug-iphoneos/<AppNamn>.app`

---

### Steg 3 — Installera på iPhone över WiFi (devicectl-tunnel)

```bash
APP="./DerivedData/Build/Products/Debug-iphoneos/<AppNamn>.app"
xcrun devicectl device install app  --device F271CF8E-4260-5501-9E86-1C765EA1A38E "$APP"
xcrun devicectl device process launch --device F271CF8E-4260-5501-9E86-1C765EA1A38E com.kimlundqvist.<appnamn>
```

Det varnar `Failed to load provisioning paramter list ... No provider was found.` men fortsätter — **det är godartat**, inte ett fel. Sista raden är vad som räknas:
- Install: `App installed: bundleID: com.kimlundqvist.<appnamn>`
- Launch: `Launched application with com.kimlundqvist.<appnamn> bundle identifier.`

---

## Återanvändbart deploy-skript

Färdig version finns i `/Users/kim/RYMDSPEL - SECOND/Echowake/deploy_iphone.sh`. Mall:

```bash
#!/usr/bin/env bash
set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/builds/ios"
APP_NAME="<AppNamn>"
BUNDLE_ID="com.kimlundqvist.<appnamn>"
TEAM_ID="SFXR8MV6MP"
DEVICE_ID="00008140-0009446C1EC0801C"             # iPhone 16 Pro xcodebuild-ID
DEVICECTL_ID="F271CF8E-4260-5501-9E86-1C765EA1A38E" # iPhone 16 Pro devicectl-ID

mkdir -p "$BUILD_DIR"
/Applications/Godot.app/Contents/MacOS/Godot --headless --path "$PROJECT_DIR" \
  --export-debug "iOS" "builds/ios/${APP_NAME}.xcodeproj"

cd "$BUILD_DIR"
xcodebuild -project ${APP_NAME}.xcodeproj -scheme ${APP_NAME} -configuration Debug -sdk iphoneos \
  -destination "platform=iOS,id=$DEVICE_ID" \
  CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM="$TEAM_ID" \
  -allowProvisioningUpdates -allowProvisioningDeviceRegistration \
  -derivedDataPath ./DerivedData \
  build

APP="$BUILD_DIR/DerivedData/Build/Products/Debug-iphoneos/${APP_NAME}.app"
xcrun devicectl device install app --device "$DEVICECTL_ID" "$APP"
xcrun devicectl device process launch --device "$DEVICECTL_ID" "$BUNDLE_ID"
```

Kör efter ändringar i Godot-projektet — re-exporterar, bygger, installerar, startar appen i ett svep.

---

## Fallgropar / lärdomar (Echowake 2026-05-10)

### 🚨 Free Apple ID = 7 dagars provisioning profile TTL
Free Individual-kontot ger `TimeToLive: 7` på varje genererad provisioning profile (paid Developer Program ger `365`). Konsekvens: appen på iPhone slutar starta efter 7 dagar tills den re-installeras med ny build. **Lösning:** kör `deploy_iphone.sh` minst en gång per vecka, eller köp $99/år Developer Program om det börjar störa. TestFlight kräver paid-kontot. Verifiera TTL med:
```bash
for f in ~/Library/Developer/Xcode/UserData/Provisioning\ Profiles/*.mobileprovision; do
  security cms -D -i "$f" 2>/dev/null | grep -A1 TimeToLive | grep integer
done
# → <integer>7</integer>  = free  |  <integer>365</integer> = paid
```

### 🚨 Team ID ≠ cert-CN-suffix
Cert-strängen "Apple Development: kim.lundqvist@gmail.com (JQ5BQY5VNU)" — `(JQ5BQY5VNU)` är **inte** Team ID, det är cert-CN-suffix. Riktiga Team ID `SFXR8MV6MP` finns i `OU=`-fältet. Verifieringskommando i avsnittet ovan.

### 🚨 Godot 4.6.2 templates funkar INTE i iPhone-simulatorn på M1
Officiella iOS-templates har **bara** `arm64` device-slice + `x86_64` simulator-slice — **ingen `arm64` simulator-slice**. På Apple Silicon Mac med Xcode 26 (som har slopat x86_64 simulator-runtime) blir simulator-vägen död. **Hoppa över simulatorn, deploya direkt till iPhone**. Verifierat med `lipo -info` på `~/Library/Application Support/Godot/export_templates/4.6.2.stable/ios.zip`.

### 🚨 Godot's `targeted_device_family=1` blir TARGETED_DEVICE_FAMILY="2" (iPad!)
Buggig mappning i Godot. Använd `=0` för iPhone-only, `=2` för universal. Symptom: bygget säger *"Kims iPhone doesn't match any of <AppNamn>.app's targeted device families"*.

### 🚨 ETC2/ASTC-flagga krävs annars failar export validation TYST
Lägg `rendering/textures/vram_compression/import_etc2_astc=true` i `project.godot`. Utan den ger Godot bara *"Cannot export project with preset iOS due to configuration errors"* utan att säga vad.

### 🚨 Godots iOS-export defaultar till Manual signing
Pbxproj kommer med `CODE_SIGN_STYLE = "Manual"` och `PROVISIONING_PROFILE_SPECIFIER = ""`. Override via xcodebuild-flaggor (visat i Steg 2). Annars: *"No profiles for ... were found"*.

### 🚨 Re-export medan Xcode har projektet öppet
Xcode visar dialog **"Use Version on Disk" / "Keep Xcode Version"** — välj alltid **Use Version on Disk** så Xcode tar versionen Godot just exporterade.

### 🚨 `devicectl` skriker "No provider was found"
Förvirrande textsträng som skrivs ut även när allt fungerar. Den är godartad. Verifiera istället att sista loggraden säger `App installed:` resp `Launched application with ...`.

### 🚨 Två olika iPhone-ID:n
- xcodebuild använder ECID-format: `00008140-0009446C1EC0801C`
- devicectl använder UUID-format: `F271CF8E-4260-5501-9E86-1C765EA1A38E`
- Båda pekar på samma telefon. Hämta dem med `xcrun xctrace list devices` resp `xcrun devicectl list devices`.

### ⚠️ Första gången på en ny app
iPhone kan visa *"Untrusted Developer"*. Kim öppnar Inställningar → Allmänt → VPN och enhetshantering → trustar developer-profilen. Behövs bara första gången per dev-cert.

### ⚠️ Provisioning profiles flyttades i Xcode 26
Gamla guider pekar på `~/Library/MobileDevice/Provisioning Profiles/` — det finns inte längre. Nya platsen: `~/Library/Developer/Xcode/UserData/Provisioning Profiles/`. När Xcode auto-skapar en profile via `-allowProvisioningUpdates` hamnar den där.

---

## Verifieringskommandon (kör om något känns osäkert)

```bash
# Godot
/Applications/Godot.app/Contents/MacOS/Godot --version              # → 4.6.2.stable.*

# Xcode
xcodebuild -version                                                  # → Xcode 26.4.1
xcode-select -p                                                      # → /Applications/Xcode.app/...

# Cert
security find-identity -v -p codesigning                             # → 1 valid (Apple Development)

# Team ID (extrahera från cert)
security find-certificate -c "Apple Development: kim.lundqvist@gmail.com" -p \
  | openssl x509 -text -noout | grep Subject | grep -oE 'OU=[A-Z0-9]+'

# iPhone WiFi-tillgänglig?
xcrun devicectl list devices                                         # → "Kims iPhone" available (paired)

# xcodebuild-ID för iPhone
xcrun xctrace list devices 2>&1 | grep -v Simulator | grep iPhone

# Godot-templates installerade?
ls ~/Library/Application\ Support/Godot/export_templates/

# Existerande provisioning profiles
ls ~/Library/Developer/Xcode/UserData/Provisioning\ Profiles/
```

---

## Preferenser

- **Språk:** Kim föredrar svenska i kommunikation.
- **Projektmapp-konvention:** versaler/svenska namn, t.ex. `/Users/kim/RYMDSPEL - SECOND/`.
- Auto-mode tål att Claude bara börjar koda — fråga inte i onödan, gör rimliga antaganden.

---

*Senast verifierad end-to-end: 2026-05-10 med Echowake (Godot 4.6.2 → iPhone 16 Pro WiFi-deploy). Om det är >6 månader sedan, kör verifieringskommandona ovan innan du litar på versionerna.*
