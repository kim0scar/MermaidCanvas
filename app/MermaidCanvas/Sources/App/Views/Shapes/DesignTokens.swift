import SwiftUI
import CoreGraphics

/// v50.4 Cykel 3 — Design Tokens.
///
/// **Syfte:** Central sanningskälla för ALLA visuella konstanter (corner radii,
/// storlekar, färger, stroke-widths). Förhindrar att två oberoende kod-paths
/// (toolbar-chip + canvas-rendering) divergerar tyst.
///
/// **v50.8:** Enad även **aspect ratio** (chip-ikoner härleds från canvas-formernas
/// bas-storlek via `Chip.iconSize(for:)`) och **alla hörn-radier som ratio**
/// (`Shape.cornerRadius(for:height:)`). Chip, canvas, gallery och selection läser nu
/// samma källa → de kan inte glida isär.
///
/// **Källa:** https://github.com/microsoft/fluentui-apple/wiki/Design-Tokens
enum DesignTokens {}

// MARK: - Skärm-konstant storlek (v66)

extension DesignTokens {
    /// v66: storlek/offset i canvas-punkter som ser LIKA stor ut på skärmen
    /// oavsett zoom (inom 0.5x–2.5x; utanför växer/krymper den mjukt så
    /// ikoner aldrig exploderar relativt formerna). Ersätter de spridda
    /// `max(a, b / canvasScale)`-uttrycken med EN princip.
    static func screenPt(_ base: CGFloat, scale: CGFloat) -> CGFloat {
        base / min(max(scale, 0.5), 2.5)
    }
}

// MARK: - Shape tokens

/// Form-rendering konstanter — används av BÅDE ToolbarView (chip) och
/// CanvasView (canvas-rendering) samt ComponentGallery.
extension DesignTokens {
    enum Shape {
        // Hörn-radie som RATIO av referens-dimension (höjd; square = min-sida).
        // v50.8: ALLA rundade former uttrycks som ratio så chip (liten) och canvas
        // (stor) får proportionellt identisk rundning. Canvas default-look bevaras:
        //   rektangel 80×0.10=8 · container 200×0.08=16 · diamant 80×0.10=8 · tabell 80×0.075=6
        static let diamondCornerRadiusRatio: CGFloat = 0.10   // v50.9: 0.075→0.10 (Kim: lite rundare)
        static let squareCornerRadiusRatio: CGFloat = 0.06    // G2d: skarp, liksidig — tydligt skild från rektangeln
        static let processArrowCornerRadiusRatio: CGFloat = 0.30   // v50.9: 0.18→0.30 (Kim: pilen för kantig)
        static let rectangleCornerRadiusRatio: CGFloat = 0.10     // G2d: svagt rundade hörn (var 0.175 → såg pill-lik ut)
        static let containerCornerRadiusRatio: CGFloat = 0.08
        static let tableCornerRadiusRatio: CGFloat = 0.075
        static let octagonCornerRadiusRatio: CGFloat = 0.08   // v51.1: rundning på oktagonens 8 hörn
        static let phoneFrameCornerRadiusRatio: CGFloat = 0.16   // v67: telefon-bezel (av min-sidan)
        static let triangleCornerRadiusRatio: CGFloat = 0.10   // v68: rundning på trekantens 3 hörn

        // Stroke-widths
        /// v50.5 F1: chip + canvas använder SAMMA stroke-width så de inte divergerar.
        static let chipStrokeWidth: CGFloat = 1.5
        /// Canvas-stroke (faktisk form på canvas).
        static let canvasStrokeWidth: CGFloat = 1.5

        /// Absolut hörn-radie (pt) för en form vid given höjd. ENDA källa — canvas,
        /// chip, gallery och selection läser härifrån. (Custom-path-former
        /// Square/Diamond/ProcessArrow räknar själva från sina `cornerRadiusRatio`,
        /// men returneras här också så värdet är konsekvent om det behövs.)
        static func cornerRadius(for type: ShapeType, height: CGFloat) -> CGFloat {
            switch type {
            case .rectangle:           return height * rectangleCornerRadiusRatio
            case .container:           return height * containerCornerRadiusRatio
            case .table:               return height * tableCornerRadiusRatio
            case .square:              return height * squareCornerRadiusRatio
            case .diamond:             return height * diamondCornerRadiusRatio
            case .processArrow:        return height * processArrowCornerRadiusRatio
            case .octagon:             return height * octagonCornerRadiusRatio
            case .phoneFrame:          return height * 0.072   // v67 (mest för exhaustivitet)
            case .triangle:            return height * triangleCornerRadiusRatio
            case .cylinder:            return height * 0.10   // v69 (mest för exhaustivitet — egen path)
            case .pill, .circle:       return height / 2
            case .line, .arrow, .link: return 0
            case .emoji:               return height * 0.16   // v1.0: naken glyf
            }
        }
    }
}

// MARK: - Selection tokens

/// Selection-ram-konstanter för markerade former.
extension DesignTokens {
    enum Selection {
        /// Returnerar cornerRadius för selection-ram baserat på shape-typ.
        /// Matchar formens egen rendering via Shape.cornerRadius (single source).
        static func cornerRadius(for shapeType: ShapeType,
                                 width: CGFloat,
                                 height: CGFloat) -> CGFloat {
            switch shapeType {
            case .pill, .circle:
                return min(width, height) / 2
            case .diamond, .processArrow, .octagon, .phoneFrame, .triangle, .cylinder, .line, .arrow, .link, .emoji:
                // egna geometrier — SelectionOutline ritar formen, ingen rect-radie
                return 0
            case .rectangle, .container, .table, .square:
                return Shape.cornerRadius(for: shapeType, height: height)
            }
        }

        static let strokeWidth: CGFloat = 2.0
        static let dashPattern: [CGFloat] = [6, 4]
    }
}

// MARK: - Badge tokens

/// Edge-badge-konstanter (minus + stub-plus).
extension DesignTokens {
    enum Badge {
        // Minus-badge (kollapsa utgående kant från markerad shape)
        static let minusSize: CGFloat = 28
        static let minusColor: Color = Color(.systemPurple)
        static let minusStrokeWidth: CGFloat = 2
        static let minusShadowRadius: CGFloat = 4

        // Plus-badge (expandera kollapsad kant)
        static let plusSize: CGFloat = 28
        static let plusColor: Color = Color(.systemIndigo)
        static let plusStrokeWidth: CGFloat = 2
    }
}

// MARK: - Chip tokens

/// Toolbar-chip-konstanter.
extension DesignTokens {
    enum Chip {
        /// Hela chip-knappens diameter (klickyta).
        static let frameSize: CGFloat = 44

        /// v50.8: chip-ikonens storlek HÄRLEDS från canvas-formens aspect ratio
        /// (`ShapeGeometry`). Bredd = höjd × (canvas-bredd / canvas-höjd). Garanterar
        /// att chip och canvas alltid har samma proportion — ingen hårdkodning som
        /// kan glida isär. `targetHeight` = ikon-höjd inuti chip-frame.
        static func iconSize(for type: ShapeType, targetHeight: CGFloat = 20) -> CGSize {
            let w = ShapeGeometry.typeBaseWidth(for: type)
            let h = ShapeGeometry.typeBaseHeight(for: type)
            let ratio = h > 0 ? w / h : 1
            return CGSize(width: targetHeight * ratio, height: targetHeight)
        }
    }
}
