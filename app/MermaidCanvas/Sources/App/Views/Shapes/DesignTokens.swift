import SwiftUI
import CoreGraphics

/// v50.4 Cykel 3 — Design Tokens.
///
/// **Syfte:** Central sanningskälla för ALLA visuella konstanter (corner radii,
/// storlekar, färger, stroke-widths). Förhindrar att två oberoende kod-paths
/// (toolbar-chip + canvas-rendering) divergerar tyst.
///
/// **Mönster:** chip OCH canvas läser från samma token. Ändra på ETT ställe
/// → båda uppdateras synkat.
///
/// **Källa:** https://github.com/microsoft/fluentui-apple/wiki/Design-Tokens
enum DesignTokens {}

// MARK: - Shape tokens

/// Form-rendering konstanter — används av BÅDE ToolbarView (chip) och
/// CanvasShapes/CanvasView (canvas-rendering).
extension DesignTokens {
    enum Shape {
        // Diamond (romb)
        /// Hörn-radie för diamant — samma för chip och canvas så de visuellt matchar.
        static let diamondCornerRadius: CGFloat = 6

        // Square (kvadrat)
        /// Hörn-radie för kvadrat — matchar mellan chip och canvas.
        static let squareCornerRadius: CGFloat = 10

        // ProcessArrow (pentagon)
        /// Hörn-radie för processArrow — gäller de fyra raka hörnen
        /// (spetsen hålls skarp). Skala automatiskt mot rect-höjd
        /// (se ProcessArrowShape.path för clamp-logik).
        static let processArrowCornerRadius: CGFloat = 8

        // Rectangle / Container / Table
        /// Standard rektangel-radie för alla rektangulära former.
        static let rectangleCornerRadius: CGFloat = 10

        // Stroke-widths
        /// Chip-stroke (toolbar).
        static let chipStrokeWidth: CGFloat = 1.3
        /// Canvas-stroke (faktisk form på canvas).
        static let canvasStrokeWidth: CGFloat = 2.0
    }
}

// MARK: - Selection tokens

/// Selection-ram-konstanter för markerade former.
extension DesignTokens {
    enum Selection {
        /// Returnerar cornerRadius för selection-ram baserat på shape-typ.
        /// Matchar formens egen rendering (rectangle r=10 → selection r=10).
        static func cornerRadius(for shapeType: ShapeType,
                                 width: CGFloat,
                                 height: CGFloat) -> CGFloat {
            switch shapeType {
            case .rectangle, .container, .table:
                return Shape.rectangleCornerRadius
            case .square:
                return Shape.squareCornerRadius
            case .pill, .circle:
                return min(width, height) / 2
            case .diamond, .processArrow, .line, .arrow, .link:
                return 0
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

/// Toolbar-chip-konstanter (storlek på chip-frame och chip-ikon-frame inuti).
extension DesignTokens {
    enum Chip {
        /// Hela chip-knappens diameter (klickyta).
        static let frameSize: CGFloat = 44

        /// Width × height för chip-ikonen INUTI chip-frame.
        /// Egentligen olika per form pga visual-weight balansering.
        static let diamondIconWidth: CGFloat = 26
        static let diamondIconHeight: CGFloat = 20

        static let squareIconSide: CGFloat = 22

        static let processArrowIconWidth: CGFloat = 26
        static let processArrowIconHeight: CGFloat = 18
    }
}
