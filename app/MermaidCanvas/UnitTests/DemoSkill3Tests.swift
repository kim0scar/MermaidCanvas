import XCTest
import CoreGraphics
@testable import MermaidCanvas

/// Steg 11 (vokabulärsbeviset): demo-skill-3-subagents.md — verifierar att den
/// FAKTISKA filen i Kims iCloud parsas rätt av appen: subagent som egen kategori,
/// alla noder i containern, skill-nr 3, LR-layout, prompts intakta.
/// Hoppar över om filen saknas (annan maskin).
final class DemoSkill3Tests: XCTestCase {

    private let sokvag = "/Users/kim/Library/Mobile Documents/com~apple~CloudDocs/00000. Claude Code/1. Mermaid/demo-skill-3-subagents.md"

    func testDemoSkill3_ParsasRattAvAppen() throws {
        guard let md = try? String(contentsOfFile: sokvag, encoding: .utf8) else {
            throw XCTSkip("demo-skill-3-subagents.md finns inte på den här maskinen")
        }
        let p = MermaidParser.parse(md)

        // Containern: skill-kategori + skill-nr 3
        let container = p.shapes.first { $0.type == .container }
        XCTAssertNotNil(container, "skill-containern ska finnas")
        XCTAssertEqual(container?.category, .skill)
        XCTAssertEqual(container?.skillNumber, 3, "skill-nr 3 ska round-trippa")

        // Subagent = EGEN kategori, två stycken
        let subagents = p.shapes.filter { $0.category == .subagent }
        XCTAssertEqual(subagents.count, 2, "S1 + S2 ska vara subagent-noder")
        for s in subagents {
            XCTAssertTrue(s.prompt.contains("Tool capability:"), "tool-metadata i prompten")
            XCTAssertTrue(s.prompt.contains("Forbidden:"), "forbidden i prompten")
        }

        // ALLA noder bor i containern (Kims krav: containern fångar allt)
        let children = p.shapes.filter { $0.childOfContainerId == container?.id }
        XCTAssertEqual(children.count, 12, "alla 12 noder ska vara barn i containern")

        // Nodtyperna finns: gate, manual (octagon), memory x4 (inkl. run_manifest), agent, script, input, output
        XCTAssertEqual(p.shapes.filter { $0.category == .memory }.count, 4)
        XCTAssertTrue(p.shapes.contains { $0.category == .gate })
        XCTAssertTrue(p.shapes.contains { $0.category == .manual && $0.type == .octagon })
        XCTAssertTrue(p.shapes.contains { $0.category == .agent })

        // LR: huvudlinjen växer i x
        func pos(_ label: String) -> CGPoint? { p.shapes.first { $0.label == label }?.position }
        guard let input = pos("Input: ämne"),
              let gap = pos("Gap-agent: jämför filerna"),
              let output = pos("Visa aktiv output") else {
            return XCTFail("huvudlinjens noder saknas")
        }
        XCTAssertLessThan(input.x, gap.x)
        XCTAssertLessThan(gap.x, output.x)

        // Kanterna: 14 st, inkl. pass/fail från grinden + manifest-noden
        XCTAssertEqual(p.edges.count, 14)

        // Revisionshygien (steg 12): manifest-nod + run-mapps-sökvägar i prompterna
        let manifest = p.shapes.first { $0.label == "run_manifest.md" }
        XCTAssertNotNil(manifest, "run_manifest.md ska vara egen memory-nod")
        XCTAssertEqual(manifest?.category, .memory)
        XCTAssertTrue(manifest?.prompt.contains("aktiv outputfil") ?? false)
        for s in subagents {
            XCTAssertTrue(s.prompt.contains("runs/<run_id>/"), "subagent-output ska ligga i run-mappen")
        }
    }
}
