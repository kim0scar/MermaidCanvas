import XCTest
import SwiftUI
import SnapshotTesting
@testable import MermaidCanvas

/// v50.4 Cykel 1 — Snapshot testing av isolerade UI-komponenter.
/// Första körningen genererar referensbilder i `__Snapshots__/SnapshotTests/`.
/// Senare körningar jämför pixel-by-pixel och failar vid diff.
///
/// Syfte: fånga visuella regressioner automatiskt mellan iterationer
/// (t.ex. att chip-ikonen ändras eller att en badge får fel storlek).
final class SnapshotTests: XCTestCase {

    override class func setUp() {
        super.setUp()
        // v50.4: global record-mode .missing → skapa baseline om saknas,
        // annars jämför pixel-by-pixel. Sätts via SnapshotTestingConfiguration
        // som påverkar alla efterföljande assertSnapshot-calls i bundlen.
        SnapshotTesting.diffTool = .ksdiff
    }

    // MARK: - Shape-rendering (canvas-storlek)

    func test_diamond_shape() {
        let view = DiamondShape()
            .stroke(Color.black, lineWidth: 2)
            .frame(width: 120, height: 80)
            .padding(20)
            .background(Color.white)
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 160, height: 120)), record: .missing)
    }

    func test_processarrow_shape() {
        let view = ProcessArrowShape()
            .stroke(Color.black, lineWidth: 2)
            .frame(width: 120, height: 80)
            .padding(20)
            .background(Color.white)
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 160, height: 120)), record: .missing)
    }

    func test_square_shape() {
        let view = SquareShape()
            .stroke(Color.black, lineWidth: 2)
            .frame(width: 80, height: 80)
            .padding(20)
            .background(Color.white)
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 120, height: 120)), record: .missing)
    }

    // MARK: - Chip-rendering (toolbar-storlek)

    func test_diamond_chip() {
        let view = DiamondShape(cornerRadius: 3)
            .stroke(Color.primary, lineWidth: 1.3)
            .frame(width: 26, height: 20)
            .padding(10)
            .background(Color.white)
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 46, height: 40)), record: .missing)
    }

    func test_processarrow_chip() {
        let view = ProcessArrowShape()
            .stroke(Color.primary, lineWidth: 1.3)
            .frame(width: 26, height: 18)
            .padding(10)
            .background(Color.white)
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 46, height: 38)), record: .missing)
    }

    func test_square_chip() {
        let view = SquareShape(cornerRadius: 6)
            .stroke(Color.primary, lineWidth: 1.3)
            .frame(width: 22, height: 22)
            .padding(10)
            .background(Color.white)
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 42, height: 42)), record: .missing)
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

    // MARK: - Side-by-side chip vs canvas (kritiskt för v50.4 R-felet)

    func test_diamond_chip_vs_canvas_side_by_side() {
        let view = HStack(spacing: 30) {
            // Chip
            VStack(spacing: 4) {
                DiamondShape(cornerRadius: 3)
                    .stroke(Color.primary, lineWidth: 1.3)
                    .frame(width: 26, height: 20)
                Text("CHIP").font(.system(size: 8))
            }
            // Canvas
            VStack(spacing: 4) {
                DiamondShape()
                    .stroke(Color.primary, lineWidth: 2)
                    .frame(width: 120, height: 80)
                Text("CANVAS").font(.system(size: 8))
            }
        }
        .padding(20)
        .background(Color.white)
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 240, height: 140)), record: .missing)
    }

    // MARK: - v50.4 Cykel 2 — Hela Component Gallery (global konsistens)

    func test_component_gallery_full() {
        // En enda snapshot av hela Gallery-vyn → fångar global visuell
        // konsistens mellan alla former, badges, edges. Om en form ändras
        // i isolation men gör sviten visuellt inkonsekvent → upptäcks här.
        let view = NavigationStack {
            ComponentGallery()
        }
        assertSnapshot(
            of: view,
            as: .image(layout: .device(config: .iPhone13Pro)),
            record: .missing
        )
    }

    func test_processarrow_chip_vs_canvas_side_by_side() {
        let view = HStack(spacing: 30) {
            VStack(spacing: 4) {
                ProcessArrowShape()
                    .stroke(Color.primary, lineWidth: 1.3)
                    .frame(width: 26, height: 18)
                Text("CHIP").font(.system(size: 8))
            }
            VStack(spacing: 4) {
                ProcessArrowShape()
                    .stroke(Color.primary, lineWidth: 2)
                    .frame(width: 120, height: 80)
                Text("CANVAS").font(.system(size: 8))
            }
        }
        .padding(20)
        .background(Color.white)
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 240, height: 140)), record: .missing)
    }
}
