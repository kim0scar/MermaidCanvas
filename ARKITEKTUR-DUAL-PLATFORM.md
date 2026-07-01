# ARKITEKTUR — Dual-platform (iPhone + Mac), Milstolpe 1.1

*Skapad 2026-06-24. Hur appen blev BÅDE iOS och macOS med EN delad kodbas. Läs denna innan du rör plattforms-koden.*

## Modellen: en hjärna, två ansikten

```
            ┌─────────── DELAD HJÄRNA (Sources/) ───────────┐
            │  Mermaid/ · App/Models/ · App/Persistence/     │
            │  + nästan alla App/Views/ (canvas, toolbar…)   │
            └───────────────────┬────────────────────────────┘
                    ┌───────────┴───────────┐
              iOS-skal                  macOS-skal
        main.swift (UIApplicationMain   MermaidCanvasApp.swift
        + SceneDelegate, orient.lås)    (@main Window { ContentView() })
        ZoomableCanvas (UIScrollView)   ZoomableCanvasMac (NSScrollView)
```

**Två app-targets i `project.yml` som delar SAMMA `Sources/`-sökvägar** (INTE ett framework — arch-check är sökvägs-baserad, en flytt skulle spränga baseline + tvinga public-audit över ~120 filer). Plattforms-skillnader hanteras med `#if os(iOS)` / `#if os(macOS)` / `#if canImport(UIKit)` — inte separata kodbaser.

## Vad som är delat vs plattforms-specifikt

| Lager | Delat? | Not |
|---|---|---|
| `Sources/Mermaid/` · `App/Models/` · `App/Persistence/` | 100% delat | Foundation/CoreGraphics-rent (hjärnan) |
| `App/Views/` (canvas, toolbar, sheets, handtag) | ~95% delat | via shims + `#if`-vakter |
| App-entré | per plattform | iOS: `main.swift` (UIApplicationMain, orient.lås). macOS: `MermaidCanvasApp.swift` (`@main` `Window` — riktigt flyttbart/storleksbart/helskärms-fönster sedan 1.5.7; var `MenuBarExtra` t.o.m. 1.5.6). |
| Zoom/pan-canvas | per plattform, GEMENSAM SÖM | iOS `ZoomableCanvas` (UIScrollView) · macOS `ZoomableCanvasMac` (NSScrollView, flippad doc). Båda populerar SAMMA `CanvasViewportState` → resten av appen oförändrad. |

## Plattforms-shims (gör delade vyer cross-platform)
- **`ClaudeCode/Haptics.swift`** — iOS feedback, macOS no-op.
- **`ClaudeCode/Clipboard.swift`** — UIPasteboard / NSPasteboard.
- **`ClaudeCode/Color+Platform.swift`** — `Color.appBackground` m.fl. (iOS UIColor = oförändrat, macOS NSColor). Ersätter `Color(.systemBackground)` som är UIColor-bara.
- **`ClaudeCode/Color+Hex.swift`** — `.hex` har NSColor-gren (mermaid-färger på Mac).
- **`App/Views/PlatformModifiers.swift`** — `inlineNavTitle()` (iOS inline-nav, macOS no-op). Toolbar-placements `.navigationBarTrailing`/`.topBarTrailing` → `.primaryAction` (cross-platform).
- **`App/Views/Export/ActivityView.swift`** — iOS UIActivityViewController, macOS stub (NSSharingServicePicker = TODO Fas 6).
- **`App/Views/Export/CanvasImageExporter.swift`** — `.uiImage` (iOS) / `.nsImage`+NSBitmapImageRep (macOS).
- **`App/ContentView+Platform.swift`** — `isCompactHeight` (iOS size class, macOS = false → alltid topp-bar).

## Sömmen: `CanvasViewportState` (det som gör tvillingen möjlig)
Allt nedströms (chip-drop, handtag, selektion) läser BARA `CanvasViewportState` (`canvasPoint(forGlobal:)`, `visibleCenterInCanvas`, `isInsideCanvas`) — aldrig scroll-vyn direkt. macOS-tvillingen behöver bara populera samma tre fält:
- `zoomScale` = `NSScrollView.magnification`
- `contentOffset` = `clipView.bounds.origin × magnification` (matchar UIScrollViews skalade offset)
- `globalFrame` = scroll-vyns ram i fönster-koord (top-left-flippad)
Flippad `documentView` (`isFlipped = true`) så top-left-origin matchar iOS.

## Bygg & deploy (macOS)
- Target `MermaidCanvasMac`, scheme `MermaidCanvasMac`, bundle `com.kimlundqvist.mermaidcanvas.mac`.
- **Använd `scripts/deploy-mac.sh`** — bygger Release, installerar i `/Applications/Visuali2e.app`, och VERIFIERAR (version == AppVersion + appen lever + inga kraschloggar). Kör inte de råa kommandona för hand; scriptet är den självverifierande grinden (regel 4, 🟡).
- Under huven: `xcodebuild -scheme MermaidCanvasMac -configuration Release -destination 'platform=macOS' build`. **1.5.7:** `LSUIElement` borttagen → riktig fönster-app MED Dock-ikon + standard-menyrad (var menyrads-popup utan Dock-ikon t.o.m. 1.5.6). Canvas-bakgrunden ritas nu explicit (ljus/mörk) i `ZoomableCanvasMac` — var systemgrå förut.
- **Får aldrig hoppas över vid deploy** (`VERSIONSHANTERING.md` steg 2b) — annars halkar Mac-appen tyst efter iPhone (lärdomen 2026-06-28: var 1.0 vs iPhone 1.5.1).

## Hårt lärda läxor (rör inte detta utan att förstå)
- **macOS Info.plist MÅSTE ligga UTANFÖR `Sources/`** (`app/MermaidCanvas/Info-macOS.plist`). Låg den i `Sources/App` (delad sökväg) förorenade den iOS-targetens plist → iOS-test kunde inte launcha (`$(PRODUCT_BUNDLE_IDENTIFIER)` oresolvd).
- **`main.swift` utesluts från macOS-targeten** (`excludes:` i project.yml) — top-level `UIApplicationMain` krockar annars med macOS `@main`.
- **EN version** (AppVersion.version → MARKETING + CURRENT_PROJECT lika). Lägg ALDRIG per-target version-override (arch-check version-sync).
- iOS-beteendet ska vara BIT-FÖR-BIT oförändrat efter varje plattforms-ändring (204 unit-tester grön-grind).

## Status (1.1)
✅ Fas 1–4 + deploy: macOS-appen byggd, installerad, körande i menyraden, äkta zoom/pan. KVAR (polish): kom-ihåg-mappen, NSSharingServicePicker-delning, genvägar. KVAR (Kim): klick-verifiering av popup/känsla på Mac + iPhone-känsla-bock på 1.0.
