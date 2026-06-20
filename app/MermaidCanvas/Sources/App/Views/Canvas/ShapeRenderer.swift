import SwiftUI

/// Renderar en forms bakgrund + ram + (pending-)markering per ShapeType.
/// Bruten ur ShapeView (MA spår A steg 5) så ShapeView blir en tunnare koordinator —
/// detta är de tre stora switcharna som arkitektur-granskningen pekade ut.
/// Ren vy: tar färdiga färger + titel som indata, äger ingen state.
struct ShapeRenderer: View {
    let shape: ShapeNode
    let fill: Color
    let stroke: Color
    let containerTitle: String
    let isPendingFrom: Bool

    var body: some View {
        ZStack {
            background
            strokeLayer
            fileGlyph
            highlight
        }
    }

    /// Steg 8 (2d): fil-kategorier (MD/Excel) ritas som rektangel men får en
    /// igenkännings-glyf i övre vänstra hörnet så Kim ser vad de är.
    @ViewBuilder
    private var fileGlyph: some View {
        if let symbol = shape.category.fileGlyphSymbol {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(stroke.opacity(0.7))
                .padding(7)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private var background: some View {
        switch shape.type {
        case .circle:
            Circle()
                .fill(fill)
                .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
        case .rectangle:
            RoundedRectangle(cornerRadius: DesignTokens.Shape.cornerRadius(for: .rectangle, height: ShapeGeometry.height(for: shape)), style: .continuous)
                .fill(fill)
                .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
        case .diamond:
            DiamondShape()
                .fill(fill)
                .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
        case .pill:
            Capsule(style: .continuous)
                .fill(fill)
                .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
        case .container:
            // v60: container i Lucidchart-stil — solid header-rad med titel + ljus kropp
            // + tunn solid ram. Titeln bor i headern (ej flytande tab).
            VStack(spacing: 0) {
                HStack(spacing: 5) {
                    Spacer(minLength: 10)   // v76: titel centrerad (fönster-stil) — syns även mitt i breda containrar
                    // v70: skill-markör — visar att containern är en skill-gräns.
                    if shape.category == .skill {
                        Image(systemName: "hexagon.fill")
                            .font(.system(size: 9 * min(shape.sizeMultiplier, 1.4)))
                            .foregroundStyle(Color.white.opacity(0.85))
                    }
                    Text(containerTitle)
                        .font(.system(size: 13 * min(shape.sizeMultiplier, 1.4), weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .minimumScaleFactor(0.85)
                    Spacer(minLength: 10)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 28)
                .background(shape.category.strokeColor)
                Rectangle().fill(fill.opacity(0.04))
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Shape.cornerRadius(for: .container, height: ShapeGeometry.height(for: shape)), style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Shape.cornerRadius(for: .container, height: ShapeGeometry.height(for: shape)), style: .continuous)
                    // v74: skill-containrar får tydligare ram än vanliga grupper.
                    .stroke(shape.category.strokeColor.opacity(shape.category == .skill ? 0.8 : 0.6),
                            lineWidth: shape.category == .skill ? 2 : 1.5)
            )
        case .table:
            TableShapeBackground(rows: shape.tableRows ?? 3,
                                 cols: shape.tableCols ?? 3,
                                 cells: shape.tableCells ?? [],
                                 fill: fill,
                                 stroke: stroke)
        case .link:
            // G2b: länk-bubblan bär kategori-färgen (fyllning + ram) som övriga former.
            JumpLinkShapeBackground(number: shape.linkNumber ?? 0, fill: fill, stroke: stroke)
        case .square:
            SquareShape()
                .fill(fill)
                .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
        case .processArrow:
            ProcessArrowShape()
                .fill(fill)
                .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
        case .octagon:
            OctagonShape()
                .fill(fill)
                .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
        case .phoneFrame:
            // v67/v68: mörk bezel + ljus skärm + dynamic island.
            // Steg 9: modellnamnet ritas UTANPÅ ramen (ShapeView), inte som caption
            // inuti — skärmytan hålls helt fri för UI-bygge.
            PhoneFrameBackground(bezel: stroke, screen: fill, caption: "")
        case .triangle:
            TriangleShape()
                .fill(fill)
                .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
        case .cylinder:
            CylinderShape()
                .fill(fill)
                .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
        case .line, .arrow, .emoji:   // v1.0: emoji = naken glyf (ingen ruta)
            EmptyView()
        }
    }

    @ViewBuilder
    private var strokeLayer: some View {
        switch shape.type {
        case .circle:
            Circle().stroke(stroke, lineWidth: DesignTokens.Shape.canvasStrokeWidth)
        case .rectangle:
            RoundedRectangle(cornerRadius: DesignTokens.Shape.cornerRadius(for: .rectangle, height: ShapeGeometry.height(for: shape)), style: .continuous).stroke(stroke, lineWidth: DesignTokens.Shape.canvasStrokeWidth)
        case .diamond:
            DiamondShape().stroke(stroke, lineWidth: DesignTokens.Shape.canvasStrokeWidth)
        case .pill:
            Capsule(style: .continuous).stroke(stroke, lineWidth: DesignTokens.Shape.canvasStrokeWidth)
        case .square:
            SquareShape().stroke(stroke, lineWidth: DesignTokens.Shape.canvasStrokeWidth)
        case .processArrow:
            ProcessArrowShape().stroke(stroke, lineWidth: DesignTokens.Shape.canvasStrokeWidth)
        case .octagon:
            OctagonShape().stroke(stroke, lineWidth: DesignTokens.Shape.canvasStrokeWidth)
        case .triangle:
            TriangleShape().stroke(stroke, lineWidth: DesignTokens.Shape.canvasStrokeWidth)
        case .cylinder:
            CylinderShape().stroke(stroke, lineWidth: DesignTokens.Shape.canvasStrokeWidth)
        case .container:
            // v44: container — ram redan ritad i background
            EmptyView()
        case .phoneFrame:
            // v67: bezeln ÄR ramen (ritad i background)
            EmptyView()
        case .table, .link, .line, .arrow, .emoji:
            EmptyView()
        }
    }

    @ViewBuilder
    private var highlight: some View {
        if isPendingFrom {
            switch shape.type {
            case .circle:
                Circle().stroke(Color.accentColor, lineWidth: 3.5)
            case .rectangle, .table:
                RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.accentColor, lineWidth: 3.5)
            case .diamond:
                DiamondShape().stroke(Color.accentColor, lineWidth: 3.5)
            case .pill:
                Capsule(style: .continuous).stroke(Color.accentColor, lineWidth: 3.5)
            case .square:
                SquareShape().stroke(Color.accentColor, lineWidth: 3.5)
            case .processArrow:
                ProcessArrowShape().stroke(Color.accentColor, lineWidth: 3.5)
            case .octagon:
                OctagonShape().stroke(Color.accentColor, lineWidth: 3.5)
            case .phoneFrame:
                PhoneFrameShape().stroke(Color.accentColor, lineWidth: 3.5)
            case .triangle:
                TriangleShape().stroke(Color.accentColor, lineWidth: 3.5)
            case .cylinder:
                CylinderShape().stroke(Color.accentColor, lineWidth: 3.5)
            case .container:
                RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.accentColor, lineWidth: 3.5)
            case .link:
                Circle().stroke(Color.accentColor, lineWidth: 3.5)
            case .emoji:
                RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.accentColor, lineWidth: 3.5)
            case .line, .arrow:
                EmptyView()
            }
        }
    }
}
