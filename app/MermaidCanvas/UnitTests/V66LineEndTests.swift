import XCTest
import CoreGraphics
@testable import MermaidCanvas

/// v66: strecket äger sin längd via lineEnd (ändpunkts-handtag) —
/// round-trip + migrering av gamla multiplier-skalade linjer.
final class V66LineEndTests: XCTestCase {

    func testLineEnd_RoundTrippar() {
        var line = ShapeNode(type: .line, position: CGPoint(x: 200, y: 200), label: "")
        line.lineEnd = CGPoint(x: 180, y: -60)
        let doc = CanvasDocument(title: "T", shapes: [line], edges: [],
                                 canvasSize: CGSize(width: 800, height: 800),
                                 specType: .general).content
        let parsed = MermaidParser.parse(doc)
        let p = parsed.shapes.first { $0.type == .line }
        XCTAssertEqual(p?.lineEnd?.x ?? 0, 180, accuracy: 1.0)
        XCTAssertEqual(p?.lineEnd?.y ?? 0, -60, accuracy: 1.0)
    }

    /// Gamla filer: linje med widthMultiplier 2.0 skalades vid RENDERING.
    /// Nu bakas multipliern in i lineEnd vid inläsning → ser likadan ut.
    func testMigrering_MultiplierBakasInILineEnd() {
        var line = ShapeNode(type: .line, position: CGPoint(x: 200, y: 200), label: "")
        line.lineEnd = CGPoint(x: 60, y: 0)
        line.widthMultiplier = 2.0
        line.heightMultiplier = 1.0
        let doc = CanvasDocument(title: "T", shapes: [line], edges: [],
                                 canvasSize: CGSize(width: 800, height: 800),
                                 specType: .general).content
        let parsed = MermaidParser.parse(doc)
        guard let p = parsed.shapes.first(where: { $0.type == .line }) else {
            return XCTFail("Linjen saknas")
        }
        XCTAssertEqual(p.lineEnd?.x ?? 0, 120, accuracy: 1.0, "60 × 2.0 inbakat")
        XCTAssertEqual(p.effectiveWidth, 1, "Multipliers nollställda efter migrering")
        XCTAssertEqual(p.effectiveHeight, 1)
    }

    /// Bboxen följer lineEnd-spannet — ett utdraget streck clippas inte.
    func testBboxValexerMedLineEnd() {
        var line = ShapeNode(type: .line, position: CGPoint(x: 200, y: 200), label: "")
        line.lineEnd = CGPoint(x: 250, y: 90)
        XCTAssertGreaterThanOrEqual(ShapeGeometry.width(for: line), 500,
                                    "Frame ska rymma ändpunkten (|x|·2)")
        XCTAssertGreaterThanOrEqual(ShapeGeometry.height(for: line), 180)
    }
}
