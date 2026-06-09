import XCTest
import CoreGraphics
@testable import MermaidCanvas

/// v70: skill-containrar — spara EN container (en skill) som egen fil. Verifierar att
/// delmängden (container + barn + kant-memory) plockas ut rätt och round-trippar.
@MainActor
final class V70Tests: XCTestCase {

    /// Pipeline: container A (a1,a2) → memory m1 (handoff) → container B (b1), + fri nod x.
    private func makePipeline() -> (a: UUID, b: UUID, shapes: [ShapeNode], edges: [EdgeConnection]) {
        let aId = UUID(); let bId = UUID()
        let containerA = ShapeNode(id: aId, type: .container, position: CGPoint(x: 150, y: 100),
                                   label: "skill-a", category: .skill)
        let a1 = ShapeNode(type: .rectangle, position: CGPoint(x: 100, y: 100), label: "A1",
                           category: .agent, childOfContainerId: aId)
        let a2 = ShapeNode(type: .rectangle, position: CGPoint(x: 200, y: 100), label: "A2",
                           category: .agent, childOfContainerId: aId)
        let m1 = ShapeNode(type: .cylinder, position: CGPoint(x: 400, y: 100), label: "handoff.md",
                           category: .memory)
        let containerB = ShapeNode(id: bId, type: .container, position: CGPoint(x: 600, y: 100),
                                   label: "skill-b", category: .skill)
        let b1 = ShapeNode(type: .rectangle, position: CGPoint(x: 600, y: 100), label: "B1",
                           category: .agent, childOfContainerId: bId)
        let x = ShapeNode(type: .circle, position: CGPoint(x: 900, y: 900), label: "Fri", category: .input)
        let shapes = [containerA, a1, a2, m1, containerB, b1, x]
        let edges = [
            EdgeConnection(from: a2.id, to: m1.id, label: "skriver", direction: .forward, style: .solid),
            EdgeConnection(from: m1.id, to: b1.id, label: "läser", direction: .forward, style: .solid)
        ]
        return (aId, bId, shapes, edges)
    }

    func testContainerSubset_TarMedBarnOchKantMemory_ExkluderarResten() {
        let p = makePipeline()
        let subset = MermaidGenerator.containerSubset(containerId: p.a, shapes: p.shapes, edges: p.edges)
        let ids = Set(subset.shapes.map { $0.id })
        XCTAssertTrue(ids.contains(p.a), "containern ska vara med")
        XCTAssertEqual(subset.shapes.filter { $0.childOfContainerId == p.a }.count, 2, "båda barnen med")
        XCTAssertTrue(subset.shapes.contains { $0.category == .memory }, "kant-memory (handoff) ska följa med")
        XCTAssertFalse(ids.contains(p.b), "andra containern ska INTE vara med")
        XCTAssertFalse(subset.shapes.contains { $0.label == "B1" }, "andra skillens barn ska INTE vara med")
        XCTAssertFalse(subset.shapes.contains { $0.label == "Fri" }, "fri nod utanför ska INTE vara med")
    }

    func testSkillSubset_RoundTrippar_SomEgenFil() {
        let p = makePipeline()
        let subset = MermaidGenerator.containerSubset(containerId: p.a, shapes: p.shapes, edges: p.edges)
        let doc = CanvasDocument(title: "skill-a", shapes: subset.shapes, edges: subset.edges,
                                 canvasSize: CGSize(width: 4000, height: 4000), specType: .flow).content
        let parsed = MermaidParser.parse(doc)
        XCTAssertTrue(parsed.shapes.contains { $0.type == .container && $0.label == "skill-a" },
                      "skill-containern ska finnas i den sparade filen")
        XCTAssertEqual(parsed.shapes.filter { $0.childOfContainerId != nil }.count, 2,
                       "barnen behåller container-kopplingen i den egna filen")
        XCTAssertTrue(parsed.shapes.contains { $0.category == .memory && $0.label == "handoff.md" },
                      "handoff-filen (memory) ska följa med")
        XCTAssertFalse(parsed.shapes.contains { $0.label == "B1" || $0.label == "Fri" },
                       "noder utanför skillen ska INTE vara med")
    }

    func testSanitizeFileName() {
        XCTAssertEqual(CanvasFileManager.sanitizeFileName("mfp/site:intelligence"), "mfp-site-intelligence")
        XCTAssertEqual(CanvasFileManager.sanitizeFileName("   "), "skill")
        XCTAssertEqual(CanvasFileManager.sanitizeFileName("Bra namn"), "Bra namn")
    }
}
