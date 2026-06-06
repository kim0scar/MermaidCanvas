import XCTest
import CoreGraphics
@testable import MermaidCanvas

/// v66: legend round-trip + "Kopiera som skill" (container-export).
final class V66LegendSkillTests: XCTestCase {

    private func stripStateJSON(_ markdown: String) -> String {
        guard let start = markdown.range(of: "<!-- mermaidcanvas-state"),
              let end = markdown.range(of: "\n-->", range: start.upperBound..<markdown.endIndex)
        else { return markdown }
        return String(markdown[..<start.lowerBound]) + String(markdown[end.upperBound...])
    }

    // MARK: - Legend

    func testLegend_RoundTripparBadaVagarna() {
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: 100, y: 100),
                          label: "A", category: .agent)
        let legend = ["agent": "Ett subagent-steg", "memory": "Överlämnings-fil"]
        let doc = CanvasDocument(title: "T", shapes: [a], edges: [],
                                 canvasSize: CGSize(width: 800, height: 800),
                                 specType: .flow, legend: legend).content

        XCTAssertTrue(doc.contains("%% legend agent: Ett subagent-steg"),
                      "Läsbar legend-rad i mermaid-blocket")

        let viaJSON = MermaidParser.parse(doc)
        XCTAssertEqual(viaJSON.legend["agent"], "Ett subagent-steg")
        XCTAssertEqual(viaJSON.legend["memory"], "Överlämnings-fil")

        let viaFallback = MermaidParser.parse(stripStateJSON(doc))
        XCTAssertEqual(viaFallback.legend["agent"], "Ett subagent-steg", "%% legend-vägen")
    }

    // MARK: - Kopiera som skill

    /// Två containrar med varsitt barn + en memory-nod mellan dem.
    /// Export av container 1 ska ge: containern + barnet + memory-noden —
    /// INTE container 2 eller dess barn.
    func testGenerateForContainer_BaraDenSkillen() {
        var c1 = ShapeNode(type: .container, position: CGPoint(x: 200, y: 200), label: "skill-ett")
        c1.widthMultiplier = 1.0
        var c2 = ShapeNode(type: .container, position: CGPoint(x: 700, y: 200), label: "skill-två")
        c2.widthMultiplier = 1.0
        var barn1 = ShapeNode(type: .rectangle, position: CGPoint(x: 200, y: 210),
                              label: "Steg ett", category: .agent)
        barn1.childOfContainerId = c1.id
        barn1.prompt = "Gör steg ett"
        var barn2 = ShapeNode(type: .rectangle, position: CGPoint(x: 700, y: 210),
                              label: "Steg två", category: .agent)
        barn2.childOfContainerId = c2.id
        let memory = ShapeNode(type: .rectangle, position: CGPoint(x: 450, y: 210),
                               label: "handoff.md", category: .memory)
        let e1 = EdgeConnection(from: barn1.id, to: memory.id, label: "skriver")
        let e2 = EdgeConnection(from: memory.id, to: barn2.id, label: "läser")

        let mermaid = MermaidGenerator.generateForContainer(
            containerId: c1.id,
            shapes: [c1, c2, barn1, barn2, memory],
            edges: [e1, e2])

        XCTAssertTrue(mermaid.contains("skill-ett"), "Containern med")
        XCTAssertTrue(mermaid.contains("Steg ett"), "Barnet med")
        XCTAssertTrue(mermaid.contains("handoff.md"), "Memory-noden i kanten med")
        XCTAssertTrue(mermaid.contains("skriver"), "Kanten till memory med")
        XCTAssertFalse(mermaid.contains("skill-två"), "ANDRA skillen ska INTE med")
        XCTAssertFalse(mermaid.contains("Steg två"), "Andra skillens barn ska INTE med")
        XCTAssertTrue(mermaid.contains("prompt: Gör steg ett"), "Prompten följer med")

        // Exporten är självbärande mermaid → parsern ger tillbaka delmängden
        let parsed = MermaidParser.parse("```mermaid\n\(mermaid)\n```")
        XCTAssertEqual(parsed.shapes.count, 3, "container + barn + memory")
        XCTAssertEqual(parsed.edges.count, 1, "bara kanten barn→memory")
    }
}
