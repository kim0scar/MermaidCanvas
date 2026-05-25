import XCTest
import SwiftUI
import SnapshotTesting
@testable import MermaidCanvas

/// v50.5 — Snapshot testing av isolerade UI-komponenter.
/// LÄSER ALLA värden från DesignTokens så testen automatiskt följer med
/// när vi ändrar tokens (samma mönster som chip/canvas-rendering).
///
/// Genererar baseline om saknas, jämför pixel-by-pixel annars.
final class SnapshotTests: XCTestCase {

    override class func setUp() {
        super.setUp()
        SnapshotTesting.diffTool = .ksdiff
    }

    // MARK: - Canvas-storlek former

    func test_diamond_shape() {
        let view = DiamondShape()
            .stroke(Color.black, lineWidth: DesignTokens.Shape.canvasStrokeWidth)
            .frame(width: 120, height: 80)
            .padding(20)
            .background(Color.white)
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 160, height: 120)), record: .missing)
    }

    func test_processarrow_shape() {
        let view = ProcessArrowShape()
            .stroke(Color.black, lineWidth: DesignTokens.Shape.canvasStrokeWidth)
            .frame(width: 120, height: 80)
            .padding(20)
            .background(Color.white)
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 160, height: 120)), record: .missing)
    }

    func test_square_shape() {
        let view = SquareShape()
            .stroke(Color.black, lineWidth: DesignTokens.Shape.canvasStrokeWidth)
            .frame(width: 80, height: 80)
            .padding(20)
            .background(Color.white)
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 120, height: 120)), record: .missing)
    }

    /// v50.5: pill (Capsule) — canvas-storlek 150×80.
    func test_pill_shape() {
        let view = Capsule(style: .continuous)
            .stroke(Color.black, lineWidth: DesignTokens.Shape.canvasStrokeWidth)
            .frame(width: 150, height: 80)
            .padding(20)
            .background(Color.white)
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 190, height: 120)), record: .missing)
    }

    // MARK: - Chip-rendering (läser tokens)

    func test_diamond_chip() {
        let view = DiamondShape(cornerRadius: DesignTokens.Shape.diamondCornerRadius)
            .stroke(Color.primary, lineWidth: DesignTokens.Shape.chipStrokeWidth)
            .frame(width: DesignTokens.Chip.diamondIconWidth,
                   height: DesignTokens.Chip.diamondIconHeight)
            .padding(10)
            .background(Color.white)
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 46, height: 40)), record: .missing)
    }

    func test_processarrow_chip() {
        let view = ProcessArrowShape()
            .stroke(Color.primary, lineWidth: DesignTokens.Shape.chipStrokeWidth)
            .frame(width: DesignTokens.Chip.processArrowIconWidth,
                   height: DesignTokens.Chip.processArrowIconHeight)
            .padding(10)
            .background(Color.white)
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 46, height: 38)), record: .missing)
    }

    func test_square_chip() {
        // v50.5: använder default cornerRadiusRatio
        let view = SquareShape()
            .stroke(Color.primary, lineWidth: DesignTokens.Shape.chipStrokeWidth)
            .frame(width: DesignTokens.Chip.squareIconSide,
                   height: DesignTokens.Chip.squareIconSide)
            .padding(10)
            .background(Color.white)
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 42, height: 42)), record: .missing)
    }

    /// v50.5: pill chip — explicit Capsule (matchar v50.5 ToolbarView-fix).
    func test_pill_chip() {
        let view = Capsule(style: .continuous)
            .stroke(Color.primary, lineWidth: DesignTokens.Shape.chipStrokeWidth)
            .frame(width: DesignTokens.Chip.pillIconWidth,
                   height: DesignTokens.Chip.pillIconHeight)
            .padding(10)
            .background(Color.white)
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 50, height: 36)), record: .missing)
    }

    // MARK: - Edge-badges

    func test_edge_collapse_minus_badge() {
        let view = EdgeStartCollapseBadge(
            position: CGPoint(x: 30, y: 30),
            canvasScale: 1.0,
            onTap: {}
        )
        .frame(width: 60, height: 60)
        .background(Color.white)
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 60, height: 60)), record: .missing)
    }

    func test_edge_stub_plus_badge() {
        let view = EdgeStubBadge(
            position: CGPoint(x: 30, y: 30),
            canvasScale: 1.0,
            onTap: {}
        )
        .frame(width: 60, height: 60)
        .background(Color.white)
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 60, height: 60)), record: .missing)
    }

    // MARK: - Side-by-side chip vs canvas (kärnan i F1/F2/F3)

    /// Hjälpare: chip + canvas av samma form sida vid sida.
    /// Använder tokens på BÅDA sidor → ändras tokens, ändras båda synkront.
    @ViewBuilder
    private func sideBySide<ChipView: View, CanvasView: View>(
        @ViewBuilder chip: () -> ChipView,
        @ViewBuilder canvas: () -> CanvasView
    ) -> some View {
        HStack(spacing: 30) {
            VStack(spacing: 4) {
                chip()
                Text("CHIP").font(.system(size: 8))
            }
            VStack(spacing: 4) {
                canvas()
                Text("CANVAS").font(.system(size: 8))
            }
        }
        .padding(20)
        .background(Color.white)
    }

    func test_diamond_chip_vs_canvas_side_by_side() {
        let view = sideBySide(
            chip: {
                DiamondShape(cornerRadius: DesignTokens.Shape.diamondCornerRadius)
                    .stroke(Color.primary, lineWidth: DesignTokens.Shape.chipStrokeWidth)
                    .frame(width: DesignTokens.Chip.diamondIconWidth,
                           height: DesignTokens.Chip.diamondIconHeight)
            },
            canvas: {
                DiamondShape()
                    .stroke(Color.primary, lineWidth: DesignTokens.Shape.canvasStrokeWidth)
                    .frame(width: 120, height: 80)
            }
        )
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 240, height: 140)), record: .missing)
    }

    func test_processarrow_chip_vs_canvas_side_by_side() {
        let view = sideBySide(
            chip: {
                ProcessArrowShape()
                    .stroke(Color.primary, lineWidth: DesignTokens.Shape.chipStrokeWidth)
                    .frame(width: DesignTokens.Chip.processArrowIconWidth,
                           height: DesignTokens.Chip.processArrowIconHeight)
            },
            canvas: {
                ProcessArrowShape()
                    .stroke(Color.primary, lineWidth: DesignTokens.Shape.canvasStrokeWidth)
                    .frame(width: 120, height: 80)
            }
        )
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 240, height: 140)), record: .missing)
    }

    func test_pill_chip_vs_canvas_side_by_side() {
        // v50.5: 280pt-bredd så canvas-pill (150pt) inte clippas.
        let view = sideBySide(
            chip: {
                Capsule(style: .continuous)
                    .stroke(Color.primary, lineWidth: DesignTokens.Shape.chipStrokeWidth)
                    .frame(width: DesignTokens.Chip.pillIconWidth,
                           height: DesignTokens.Chip.pillIconHeight)
            },
            canvas: {
                Capsule(style: .continuous)
                    .stroke(Color.primary, lineWidth: DesignTokens.Shape.canvasStrokeWidth)
                    .frame(width: 150, height: 80)
            }
        )
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 280, height: 140)), record: .missing)
    }

    func test_square_chip_vs_canvas_side_by_side() {
        let view = sideBySide(
            chip: {
                SquareShape()
                    .stroke(Color.primary, lineWidth: DesignTokens.Shape.chipStrokeWidth)
                    .frame(width: DesignTokens.Chip.squareIconSide,
                           height: DesignTokens.Chip.squareIconSide)
            },
            canvas: {
                SquareShape()
                    .stroke(Color.primary, lineWidth: DesignTokens.Shape.canvasStrokeWidth)
                    .frame(width: 80, height: 80)
            }
        )
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 200, height: 140)), record: .missing)
    }


    // MARK: - Hela Component Gallery (global konsistens)

    func test_component_gallery_full() {
        let view = NavigationStack { ComponentGallery() }
        assertSnapshot(
            of: view,
            as: .image(layout: .device(config: .iPhone13Pro)),
            record: .missing
        )
    }
}
