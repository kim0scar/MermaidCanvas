import XCTest
import CoreGraphics
@testable import MermaidCanvas

/// v74: skill-nummer (kedje-ordning) + portabel skill-export (SkillFileComposer).
/// Verifierar att skill-nr round-trippar via BÅDE state-JSON och ren mermaid,
/// att skill-kategorin överlever ren-mermaid-fallback (parserfixen), och att
/// den portabla filen innehåller kontraktet utan att knäcka parsern.
@MainActor
final class V74SkillNrTests: XCTestCase {

    private func makeSkill() -> (containerId: UUID, shapes: [ShapeNode], edges: [EdgeConnection]) {
        let cId = UUID()
        let container = ShapeNode(id: cId, type: .container, position: CGPoint(x: 150, y: 100),
                                  label: "mfp-sortiment", category: .skill, skillNumber: 2)
        let s1 = ShapeNode(type: .rectangle, position: CGPoint(x: 100, y: 100), label: "Steg 1",
                           prompt: "Input: x. Uppgift: y. Output: z.",
                           category: .agent, childOfContainerId: cId)
        let s2 = ShapeNode(type: .rectangle, position: CGPoint(x: 200, y: 100), label: "Steg 2",
                           category: .agent, childOfContainerId: cId)
        let edges = [EdgeConnection(from: s1.id, to: s2.id, label: "", direction: .forward, style: .solid)]
        return (cId, [container, s1, s2], edges)
    }

    /// Tar bort state-JSON ur ett dokument → tvingar parsern till ren-mermaid-fallback.
    private func stripStateJSON(_ doc: String) -> String {
        guard let start = doc.range(of: "<!-- mermaidcanvas-state") else { return doc }
        return String(doc[..<start.lowerBound])
    }

    func testGenerator_SkriverSkillNrKommentarOchStateJSON() {
        let p = makeSkill()
        let mermaid = MermaidGenerator.generate(shapes: p.shapes, edges: p.edges, specType: .flow)
        XCTAssertTrue(mermaid.contains("skill-nr: 2"), "skill-nr-kommentaren ska skrivas")
        let state = MermaidGenerator.canvasStateJSON(
            shapes: p.shapes, edges: p.edges, canvasSize: CGSize(width: 4000, height: 4000),
            specType: .flow, platform: .blank, activeShapePacks: [.basic],
            collapsedEdgeIds: [], legend: [:])
        XCTAssertTrue(state.contains("\"skillNumber\""), "skillNumber ska finnas i state-JSON")
    }

    func testRoundTrip_ViaStateJSON_BehallerSkillNummer() {
        let p = makeSkill()
        let doc = CanvasDocument(title: "test", shapes: p.shapes, edges: p.edges,
                                 canvasSize: CGSize(width: 4000, height: 4000), specType: .flow).content
        let parsed = MermaidParser.parse(doc)
        let container = parsed.shapes.first { $0.type == .container }
        XCTAssertEqual(container?.skillNumber, 2, "skill-nr ska överleva state-JSON-round-trip")
        XCTAssertEqual(container?.category, .skill)
    }

    func testRoundTrip_RenMermaid_BehallerSkillNummerOchKategori() {
        let p = makeSkill()
        let doc = stripStateJSON(CanvasDocument(title: "test", shapes: p.shapes, edges: p.edges,
                                                canvasSize: CGSize(width: 4000, height: 4000),
                                                specType: .flow).content)
        let parsed = MermaidParser.parse(doc)
        let container = parsed.shapes.first { $0.type == .container }
        XCTAssertNotNil(container, "containern ska hittas i ren mermaid")
        XCTAssertEqual(container?.skillNumber, 2, "skill-nr ska överleva ren-mermaid-fallback")
        XCTAssertEqual(container?.category, .skill,
                       "skill-kategorin ska överleva ren-mermaid-fallback (v74-parserfixen)")
    }

    func testComposer_PortabelFil_KontraktFrontmatterOchRoundTrip() {
        let p = makeSkill()
        let content = SkillFileComposer.compose(
            skillName: "mfp-sortiment", skillNumber: 2,
            shapes: p.shapes, edges: p.edges,
            canvasSize: CGSize(width: 4000, height: 4000),
            platform: .blank, activeShapePacks: [.basic], legend: [:])
        XCTAssertTrue(content.contains("skill_nr: 2"), "frontmatter ska ha skill_nr")
        XCTAssertTrue(content.contains("skill_name: mfp-sortiment"))
        XCTAssertTrue(content.contains("contract_version: \(SkillExportContract.version)"))
        XCTAssertTrue(content.contains("# Skill 2 · mfp-sortiment"), "rubriken ska visa kedjenumret")
        XCTAssertTrue(content.contains(SkillExportContract.text), "kontraktet ska vara inbäddat ordagrant")
        let fences = content.components(separatedBy: "```").count - 1
        XCTAssertEqual(fences, 2, "exakt ETT mermaid-block (två staket)")
        let parsed = MermaidParser.parse(content)
        let container = parsed.shapes.first { $0.type == .container }
        XCTAssertEqual(container?.label, "mfp-sortiment", "filen ska parsas tillbaka till samma skill")
        XCTAssertEqual(container?.skillNumber, 2)
        XCTAssertEqual(parsed.shapes.filter { $0.childOfContainerId != nil }.count, 2)
    }

    func testKontraktstexten_FoljerFrysreglerna() {
        let text = SkillExportContract.text
        XCTAssertFalse(text.contains("```"), "kontraktet får inte innehålla kodstaket")
        XCTAssertFalse(text.contains("<!--"), "kontraktet får inte innehålla HTML-kommentar")
        for line in text.split(separator: "\n") {
            XCTAssertFalse(line.trimmingCharacters(in: .whitespaces).hasPrefix("%%"),
                           "ingen rad i kontraktet får börja med dubbla procenttecken")
        }
    }
}
