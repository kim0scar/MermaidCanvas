# iOS SwiftUI — Plattform-regler (v31)

Detta är en stub-regelfil. Plattformen `iOSSwiftUI` är skapad i v31 men reglerna fylls på i kommande version.

## Vad plattformen innebär

Native iOS-app byggd med SwiftUI. Canvas-export ska speglar:
- Views och deras hierarki
- @State / @Binding / @ObservedObject / @StateObject — observerbar state
- NavigationStack / Sheet / FullScreenCover — navigationsflöden
- TabView / NavigationSplitView — toppnivå-struktur

## Tillåtna kategorier (kommer)

| Form | Kategori | Mermaid classDef |
|---|---|---|
| Rektangel | `view` | `fill:#3b82f6, stroke:#1e40af, color:#fff` |
| Pill | `viewModifier` | `fill:#a78bfa, stroke:#7c3aed, color:#fff` |
| Diamant | `binding` | `fill:#f59e0b, stroke:#b45309, color:#fff` |
| Linje | `dataflow` | tunn pil |

(Kategori-cases ska läggas till i `ShapeCategory.swift` när reglerna är fastställda.)

## Saknas än

- Konkreta form↔SwiftUI-mappningar
- Sidecar-format för Claude Code
- Exempel-canvas + förväntad mermaid-output

Fyll på allt eftersom du börjar designa iOS-appar i MermaidCanvas.
