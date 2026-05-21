# Installera Visuali2e på din iPhone — guide för dig som testar

Hej! Du har fått ett ZIP-arkiv med en iOS-app som heter **Visuali2e** —
en visuell flödesschema-editor (känsla: Lucidchart) för iPhone. Den är
byggd för att Kim ska tänka tillsammans med Claude Code via Mermaid-kod.

Den här filen är skriven så **Claude Code** kan följa stegen åt dig.

---

## Snabbstart (om du har Claude Code)

1. Packa upp ZIP-filen någonstans (`~/Downloads/Visuali2e-v46/` t.ex.)
2. Anslut din iPhone till Macen (USB eller WiFi-pairing räcker)
3. Öppna terminalen, gå in i mappen, kör `claude` (eller `claude code`)
4. Säg till Claude exakt det här:

   > Installera Visuali2e v46 på min iPhone. Följ stegen i `INSTALL-FÖR-VÄNNEN.md` exakt.

Claude tar hand om resten.

---

## Vad Claude ska göra (stegen i ordning)

**Förutsättningar att kolla:**

- Mac med Xcode 15+ installerat (`xcode-select -p` ska peka på en Xcode.app)
- `xcodegen` installerat (`brew install xcodegen` om saknas)
- En iPhone ansluten — verifiera med `xcrun devicectl list devices`
  → status ska vara `available (paired)`
- Ett Apple-ID inloggat i Xcode (Settings → Accounts) — gratis räcker,
  men ger 7 dagars signering och max 3 sideloadade appar samtidigt

**Steg 1 — Byt Team ID till vännens Apple-ID**

I `app/MermaidCanvas/project.yml` står:
```
DEVELOPMENT_TEAM: SFXR8MV6MP
```
Det är Kims Team ID. Det MÅSTE bytas till vännens egna, annars vägrar
Xcode signera. Vännens Team ID hittas så här:
```
xcrun security find-identity -v -p codesigning | head -5
```
Eller via Xcode: Settings → Accounts → välj Apple-ID → "Manage Certificates"
→ team-id syns i parentes efter namnet (10-tecken-sträng).

Byt **alla tre förekomster** av `SFXR8MV6MP` i `project.yml`:
```bash
sed -i '' 's/SFXR8MV6MP/<NYTT_TEAM_ID>/g' app/MermaidCanvas/project.yml
```

**Steg 2 — Byt bundle identifier**

Kims bundle-prefix `com.kimlundqvist` måste också bytas (annars krockar
signeringen mot en redan registrerad bundle). Använd vännens domän
eller initialer:
```bash
sed -i '' 's/com.kimlundqvist/com.<vännens-namn>/g' app/MermaidCanvas/project.yml
```

**Steg 3 — Regenerera Xcode-projektet**

```bash
cd app/MermaidCanvas && xcodegen generate
```

**Steg 4 — Bygg för iPhone**

Hämta iPhone-ID först:
```bash
xcrun devicectl list devices | grep iPhone
```
(Identifier är 36-teckens UUID i andra kolumnen)

Bygg:
```bash
cd app/MermaidCanvas
xcodebuild -project MermaidCanvas.xcodeproj -scheme MermaidCanvas \
  -sdk iphoneos \
  -destination "platform=iOS,id=<IPHONE_UUID>" \
  -derivedDataPath DerivedData-device \
  -allowProvisioningUpdates build
```

Om Xcode säger "Failed to register bundle identifier" — då är vännens
Apple-ID redan på 3 sideloadade appar. Be vännen radera en gammal från
hemskärmen först.

**Steg 5 — Installera + starta**

```bash
APP=$(pwd)/DerivedData-device/Build/Products/Debug-iphoneos/MermaidCanvas.app
xcrun devicectl device install app --device <IPHONE_UUID> "$APP"
xcrun devicectl device process launch --device <IPHONE_UUID> com.<vännens-namn>.mermaidcanvas
```

**Steg 6 — Lita på utvecklaren på iPhonen**

Första gången säger iOS att utvecklaren inte är betrodd. På iPhonen:
*Inställningar → Allmänt → VPN och enhetshantering → välj Apple-ID-profilen → Lita på*

Sen funkar appen.

---

## Vad du ska testa

Visuali2e v46 är "alpha→beta"-version. Kims test-fokus:

1. **Drag former** från toolbar till canvas (cirkel, rektangel, romb, etc.)
2. **Multi-select**: tryck markerings-verktyget (streckad rektangel-ikon),
   dra över flera former, drag dem som en grupp
3. **Container-form**: skapa en container, dra in andra former i den,
   dra containern → barnen ska följa med
4. **Text-justering**: välj en form, öppna textstyles (AA-ikonen),
   testa L/C/R-knapparna (nya i v46)
5. **Numrerad lista + indrag**: skriv flera rader i en form, slå på
   numrering + indrag, **spara filen**, öppna igen — listan ska överleva
   (det var den största bug Kim hittade i v45)
6. **Kant-etiketter**: skapa en pil mellan två former, höger-klicka pilen
   → "Lägg till etikett", skriv text
7. **Mermaid-export**: meny → "Visa Mermaid-kod" — kopiera och testa i
   https://mermaid.live för att se att det renderas

Skriv tillbaka till Kim vad som funkar och vad som inte funkar.

---

## Kontext (om Claude vill veta mer)

- Hela arkitekturen står i `CLAUDE.md`, `ARKITEKTUR-MERMAID.md`,
  `ROADMAP.md` i samma mapp.
- Kims canvas-filer ligger normalt i iCloud Drive
  `00000. Claude Code/1. Mermaid/` — men för testning är det enklare
  att skapa nya i appen.
- App-ikonens script ligger i `scripts/generate_app_icon.py`.

Lycka till!
