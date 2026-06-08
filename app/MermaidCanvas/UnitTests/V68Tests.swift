import XCTest
import CoreGraphics
@testable import MermaidCanvas

/// v68: Kims 6 fynd efter v67 — trekant, +10% canvas, komplett n8n, iPhone-mått.
@MainActor
final class V68Tests: XCTestCase {

    private func stripStateJSON(_ markdown: String) -> String {
        guard let start = markdown.range(of: "<!-- mermaidcanvas-state"),
              let end = markdown.range(of: "\n-->", range: start.upperBound..<markdown.endIndex)
        else { return markdown }
        return String(markdown[..<start.lowerBound]) + String(markdown[end.upperBound...])
    }

    // MARK: - Fynd 2: trekant round-trippar förlustfritt

    func testTriangle_RoundTrip_StateJSON() {
        let t = ShapeNode(type: .triangle, position: CGPoint(x: 300, y: 300), label: "Tri")
        let doc = CanvasDocument(title: "T", shapes: [t], edges: [],
                                 canvasSize: CGSize(width: 2000, height: 2000),
                                 specType: .general).content
        XCTAssertEqual(MermaidParser.parse(doc).shapes.first?.type, .triangle)
    }

    func testTriangle_RoundTrip_SjalvbarandeMermaid() {
        let t = ShapeNode(type: .triangle, position: CGPoint(x: 300, y: 300), label: "Tri")
        let doc = CanvasDocument(title: "T", shapes: [t], edges: [],
                                 canvasSize: CGSize(width: 2000, height: 2000),
                                 specType: .general).content
        XCTAssertTrue(doc.contains("shape-type: triangle"), "Skriver %% shape-type för fallback")
        XCTAssertEqual(MermaidParser.parse(stripStateJSON(doc)).shapes.first?.type, .triangle,
                       "Utan state-JSON återskapas trekanten via %% shape-type")
    }

    func testTriangle_MermaidAlltidGiltig() {
        // Trekanten får ALDRIG krascha mermaid (Kims krav) → rektangel-kropp i blocket.
        let t = ShapeNode(type: .triangle, position: CGPoint(x: 300, y: 300), label: "Tri")
        let mermaid = MermaidGenerator.generate(shapes: [t], edges: [],
                                                canvasSize: CGSize(width: 2000, height: 2000),
                                                specType: .general)
        XCTAssertTrue(mermaid.contains("[\"Tri\"]"), "Giltig rektangel-kropp i mermaid-blocket")
        XCTAssertTrue(mermaid.contains("flowchart"))
    }

    // MARK: - Fynd 5: former 10% större på canvas (chips opåverkade)

    func testCanvasShapes_TioProcentStorre() {
        let r = ShapeNode(type: .rectangle, position: .zero, label: "")
        // bas 120×80 × 1.10
        XCTAssertEqual(ShapeGeometry.width(for: r), 132, accuracy: 0.01)
        XCTAssertEqual(ShapeGeometry.height(for: r), 88, accuracy: 0.01)
        // chips läser typeBaseWidth direkt → OPÅVERKADE
        XCTAssertEqual(ShapeGeometry.typeBaseWidth(for: .rectangle), 120, accuracy: 0.01)
    }

    func testLinjeBboxOpaverkadAvBoost() {
        // Lösa linjer styrs av lineEnd och ska INTE skalas med 1.10.
        let line = ShapeNode(type: .line, position: .zero, label: "", lineEnd: CGPoint(x: 100, y: 0))
        XCTAssertEqual(ShapeGeometry.width(for: line), 224, accuracy: 0.01) // 100*2+24
    }

    // MARK: - Fynd 1: iPhone 16 Pro-mått korrekta

    func testPhoneFrame_16ProProportion() {
        let ratio = ShapeGeometry.typeBaseWidth(for: .phoneFrame)
                  / ShapeGeometry.typeBaseHeight(for: .phoneFrame)
        // iPhone 16 Pro: 402×874 = 0.460
        XCTAssertEqual(ratio, 0.460, accuracy: 0.003)
    }

    // MARK: - Fynd 6: komplett n8n-palett

    func testN8nPaket_KomplettSkillKedja() {
        let cats = ShapePack.n8n.categories
        for c in [ShapeCategory.input, .skill, .subagent, .agent, .tool, .router, .memory, .prompt, .output] {
            XCTAssertTrue(cats.contains(c), "n8n saknar \(c.rawValue)")
        }
    }
}
