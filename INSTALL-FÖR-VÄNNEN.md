# Installera Visuali2e på din iPhone — guide för dig som testar

Hej! Du har fått ett ZIP-arkiv med en iOS-app som heter **Visuali2e** —
en visuell flödesschema-editor (känsla: Lucidchart) för iPhone. Den är
byggd för att tänka tillsammans med Claude Code via Mermaid-kod.

ZIP:en är **källkod** (inte en färdig app) — du bygger den på din egen Mac
med ditt eget Apple-ID. Den här filen är skriven så **Claude Code** kan
följa stegen åt dig. Versionsnumret står i ZIP-filens namn (`Visuali2e-vN.zip`)
och i `app/MermaidCanvas/Sources/App/AppVersion.swift`.

---

## Snabbstart (om du har Claude Code)

1. Packa upp ZIP-filen någonstans (`~/Downloads/Visuali2e/` t.ex.)
2. Anslut din iPhone till Macen (USB eller WiFi-pairing räcker)
3. Öppna terminalen, gå in i mappen, kör `claude` (eller `claude code`)
4. Säg till Claude exakt det här:

   > Installera Visuali2e på min iPhone. Följ stegen i `INSTALL-FÖR-VÄNNEN.md` exakt.

Claude tar hand om resten.

---

## Vad Claude ska göra (stegen i ordning)

**Förutsättningar att kolla:**

- Mac med Xcode 15+ installerat (`xcode-select -p` ska peka på en Xcode.app)
- `xcodegen` installerat (`brew install xcodegen` om saknas)
- En iPhone ansluten — verifiera med `xcrun devicectl list devices`
  → status ska vara `available (paired)`
- Ett Apple-ID inloggat i Xcode (Settings → Accounts) — gratis räcker,
  men ger **7 dagars** signering och **max 3** sideloadade appar samtidigt

**Steg 1 — Byt signering till ditt Apple-ID (ett kommando)**

Appen är signerad för Kims Apple-ID. Det måste bytas till ditt, annars vägrar
Xcode signera. Ett script sköter hela bytet (Team-ID + bundle-ID på alla ställen)
och regenererar Xcode-projektet i rätt ordning:

```bash
scripts/friend-setup.sh <DITT_TEAM_ID> com.<dittnamn>
# Ex:  scripts/friend-setup.sh ABCDE12345 com.bjorn
```

Ditt **Team ID** (10 tecken) hittas i Xcode: Settings → Accounts → välj ditt
Apple-ID → "Manage Certificates" → id:t syns i parentes efter namnet.
(Kör scriptet från repo-roten — mappen där `app/` ligger.)

**Steg 2 — Bygg för iPhone**

Hämta iPhone-ID först:
```bash
xcrun devicectl list devices | grep iPhone
```
(Identifier är 36-teckens UUID i andra kolumnen)

Bygg (byt `com.<dittnamn>` till samma prefix som i steg 1):
```bash
cd app/MermaidCanvas
xcodebuild -project MermaidCanvas.xcodeproj -scheme MermaidCanvas \
  -sdk iphoneos \
  -destination "platform=iOS,id=<IPHONE_UUID>" \
  -derivedDataPath DerivedData-device \
  -allowProvisioningUpdates build
```

Om Xcode säger "Failed to register bundle identifier" — då är ditt
Apple-ID redan på 3 sideloadade appar. Radera en gammal från hemskärmen först.

**Steg 3 — Installera + starta**

```bash
APP=$(pwd)/DerivedData-device/Build/Products/Debug-iphoneos/MermaidCanvas.app
xcrun devicectl device install app --device <IPHONE_UUID> "$APP"
xcrun devicectl device process launch --device <IPHONE_UUID> com.<dittnamn>.mermaidcanvas
```

**Steg 4 — Lita på utvecklaren på iPhonen**

Första gången säger iOS att utvecklaren inte är betrodd. På iPhonen:
*Inställningar → Allmänt → VPN och enhetshantering → välj Apple-ID-profilen → Lita på*

Sen funkar appen. (Den slutar starta efter 7 dagar på ett gratis-konto —
kör då steg 2–3 igen för att bygga om.)

---

## Vad du ska testa

1. **Rita former** — tryck "Former" i verktygsraden, lägg ut cirkel, rektangel,
   romb, pill, container m.fl. på canvasen.
2. **Flytta + markera** — dra former; testa multi-select (markerings-verktyget),
   dra flera som en grupp.
3. **Container** — skapa en container, dra in former, dra containern → barnen följer med.
4. **Pilar + etiketter** — dra en pil mellan två former; håll inne på pilen →
   redigera text, riktning, färg.
5. **Spara + öppna (viktigast)** — spara filen (du väljer plats i Filer-appen,
   ditt eget iCloud funkar), stäng och öppna igen → allt ska se EXAKT likadant ut.
6. **Mermaid-export** — meny → "Visa Mermaid-kod", kopiera och klistra i
   https://mermaid.live för att se att det renderas.

Skriv tillbaka till Kim vad som funkar och vad som inte funkar.

---

## Kontext (om Claude vill veta mer)

- Arkitekturen står i `CLAUDE.md`, `ARKITEKTUR-MERMAID.md`, `ARKITEKTUR-REGLER.md`,
  `ROADMAP.md` i samma mapp. Filerna sparas där DU väljer i Filer-appen — appen har
  ingen hårdkodad plats, så ditt eget iCloud funkar direkt.
- Signerings-bytet i steg 1 görs av `scripts/friend-setup.sh`.

Lycka till!
