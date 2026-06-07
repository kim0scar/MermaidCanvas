import SwiftUI

/// v50.5 v4 F10: streckad markeringsram som följer formens egen geometri.
/// Används av BÅDE SelectionHandles (enkelmarkering) och multi-selection
/// (marker-mode) — så båda ser likadana ut.
///
/// Tidigare: SelectionHandles hade switch internt, multi-select använde
/// rätt-och-slätt `Rectangle()`. Det gav rektangulär bbox runt circle,
/// diamond, pill — vilket Kim klagade på.
struct SelectionOutline: View {
    let shapeType: ShapeType
    /// Frame-storlek (width/height i canvas-koordinater).
    let width: CGFloat
    let height: CGFloat
    /// Stroke-bredd för det streckade linjet.
    let strokeWidth: CGFloat
    /// Canvas-skala — påverkar dash-pattern så det ser likadant ut vid alla zoom.
    let canvasScale: CGFloat

    private var dashStyle: StrokeStyle {
        StrokeStyle(lineWidth: strokeWidth,
                    dash: [6 / canvasScale, 4 / canvasScale])
    }

    var body: some View {
        Group {
            switch shapeType {
            case .diamond:
                DiamondShape().stroke(Color.accentColor, style: dashStyle)
            case .processArrow:
                ProcessArrowShape().stroke(Color.accentColor, style: dashStyle)
            case .octagon:
                OctagonShape().stroke(Color.accentColor, style: dashStyle)
            case .phoneFrame:
                PhoneFrameShape().stroke(Color.accentColor, style: dashStyle)
            case .circle:
                Circle().stroke(Color.accentColor, style: dashStyle)
            case .pill:
                Capsule(style: .continuous).stroke(Color.accentColor, style: dashStyle)
            case .square:
                SquareShape().stroke(Color.accentColor, style: dashStyle)
            case .rectangle, .container, .table:
                RoundedRectangle(
                    cornerRadius: DesignTokens.Selection.cornerRadius(
                        for: shapeType, width: width, height: height
                    ),
                    style: .continuous
                ).stroke(Color.accentColor, style: dashStyle)
            case .line, .arrow, .link:
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.accentColor, style: dashStyle)
            }
        }
        .frame(width: width, height: height)
    }
}
