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
        /// v50.5 F6: Hörn-radie som PROCENT av sida — chip OCH canvas får
        /// visuellt likvärdig rundning. Tidigare fixt 10pt → chip 22pt fick
        /// nästan cirkel-form (10/22 = 45%), canvas 80pt fick 10/80 = 12.5%.
        /// Med ratio: båda får ~12.5% av sidan.
        static let squareCornerRadiusRatio: CGFloat = 0.125
        /// Kvarstår för bakåtkompatibilitet — använd i selection-corner.
        static let squareCornerRadius: CGFloat = 10

        // ProcessArrow (pentagon)
        /// v50.5 F3: Hörn-radie för processArrow ANGES SOM PROCENT av rect-höjd
        /// så chip (liten) OCH canvas (stor) får visuellt likvärdig rundning.
        /// 0.18 = 18% av höjd. Chip 18pt → 3.24pt, canvas 80pt → 14.4pt
        /// — samma proportion mellan radie och form-storlek.
        static let processArrowCornerRadiusRatio: CGFloat = 0.18

        // Rectangle / Container / Table
        /// Standard rektangel-radie för alla rektangulära former.
        static let rectangleCornerRadius: CGFloat = 10

        // Stroke-widths
        /// v50.5 F1: chip + canvas använder SAMMA stroke-width så de inte
        /// divergerar. 1.5pt är en bra mellan-väg som ser ren ut på båda
        /// storlekar (26×20 chip och 120×80 canvas).
        static let chipStrokeWidth: CGFloat = 1.5
        /// Canvas-stroke (faktisk form på canvas).
        static let canvasStrokeWidth: CGFloat = 1.5
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

        /// v50.5 F2: explicit pill-chip-ikon med Capsule (tidigare användes
        /// SF Symbol "capsule" som inte matchade canvas-formens proportion).
        /// 30×16 = 1.875:1, samma ratio som canvas-pill (150×80).
        static let pillIconWidth: CGFloat = 30
        static let pillIconHeight: CGFloat = 16
    }
}
