import XCTest
import CoreGraphics
@testable import MermaidCanvas

/// v71: legend som alltid-närvarande översättare — auto-fylls från de formtyper som
/// används, manuell rad vinner. Gör varje skill-flödes mermaid självförklarande för Claude.
@MainActor
final class V71Tests: XCTestCase {

    private func flowShapes() -> [ShapeNode] {
        [
            ShapeNode(type: .pill,      position: CGPoint(x: 100, y: 100), label: "In",    category: .input),
            ShapeNode(type: .rectangle, position: CGPoint(x: 100, y: 200), label: "Agent", category: .agent),
            ShapeNode(type: .diamond,   position: CGPoint(x: 100, y: 300), label: "Grind", category: .gate),
            ShapeNode(type: .cylinder,  position: CGPoint(x: 100, y: 400), label: "fil.md", category: .memory)
        ]
    }

    func testAutoLegend_FyllsFranAnvandaKategorier_UtanManuell() {
        let code = MermaidGenerator.generate(shapes: flowShapes(), edges: [],
                                             canvasSize: CGSize(width: 800, height: 800), specType: .flow)
        // En legend-rad per använd formtyp ska ALLTID finnas (ingen manuell legend angiven).
        XCTAssertTrue(code.contains("%% legend input:"), "legend för input saknas:\n\(code)")
        XCTAssertTrue(code.contains("%% legend agent:"), "legend för agent saknas")
        XCTAssertTrue(code.contains("%% legend gate:"), "legend för gate (Grind) saknas")
        XCTAssertTrue(code.contains("%% legend memory:"), "legend för memory saknas")
        // Default-texten = kategorins pickerHint.
        XCTAssertTrue(code.contains("Ingångspunkt"), "input-legend ska ha pickerHint-text")
        XCTAssertTrue(code.contains("kvalitetskontroll"), "gate-legend ska förklara grind ≠ router")
    }

    func testAutoLegend_ManuellOverrideVinner() {
        let shapes = [ShapeNode(type: .rectangle, position: CGPoint(x: 100, y: 100), label: "A", category: .agent)]
        let code = MermaidGenerator.generate(shapes: shapes, edges: [],
                                             canvasSize: CGSize(width: 800, height: 800),
                                             specType: .flow, legend: ["agent": "Min egen text"])
        XCTAssertTrue(code.contains("%% legend agent: Min egen text"), "manuell override ska vinna:\n\(code)")
        XCTAssertFalse(code.contains("AI-agent eller processlogik"), "default ska INTE användas när override finns")
    }

    func testLegend_ManuellaBevaras_DefaultsPollarInteState() {
        let shapes = [
            ShapeNode(type: .rectangle, position: CGPoint(x: 100, y: 100), label: "A", category: .agent),
            ShapeNode(type: .pill,      position: CGPoint(x: 100, y: 200), label: "In", category: .input)
        ]
        let doc = CanvasDocument(title: "L", shapes: shapes, edges: [],
                                 canvasSize: CGSize(width: 800, height: 800),
                                 specType: .flow, legend: ["agent": "Min text"]).content
        let parsed = MermaidParser.parse(doc)
        XCTAssertEqual(parsed.legend["agent"], "Min text", "manuell legend ska bevaras via state-JSON")
        XCTAssertNil(parsed.legend["input"], "auto-default ska INTE lagras som manuell legend i state")
    }
}
