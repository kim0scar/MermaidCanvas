import XCTest
import CoreGraphics
@testable import MermaidCanvas

/// Steg 7 — Mermaid-konformitetsgrind.
///
/// Detta test GENERERAR appens faktiska mermaid-output för hela form-vokabulären och
/// skriver ut varje block som en base64-rad (`@@@MMD64:<namn>:<base64>`).
/// `scripts/extract-mermaid-fixtures.sh` fångar utskriften → `scripts/mermaid-fixtures/*.mmd`,
/// och `scripts/mermaid-conformance.mjs` validerar varje fixtur mot RIKTIG mermaid (mermaid.parse).
///
/// Syftet: bevisa att det appen ritar blir giltig mermaid som renderar "exakt som på canvasen".
/// De interna round-trip-testerna bevisar bara att appen läser sin egen text — inte att riktig
/// mermaid accepterar den. Den här grinden täpper den luckan.
///
/// Regenerera fixtures vid generator-ändring:  ./scripts/extract-mermaid-fixtures.sh
final class MermaidConformanceCorpusTests: XCTestCase {

    private func node(_ type: ShapeType, _ label: String, _ cat: ShapeCategory,
                      x: CGFloat, y: CGFloat,
                      prompt: String = "", note: String = "",
                      linkNumber: Int? = nil, skillNumber: Int? = nil,
                      tableRows: Int? = nil, tableCols: Int? = nil,
                      tableCells: [[String]]? = nil,
                      childOf: UUID? = nil) -> ShapeNode {
        ShapeNode(type: type, position: CGPoint(x: x, y: y), label: label,
                  note: note, prompt: prompt, category: cat,
                  linkNumber: linkNumber, skillNumber: skillNumber,
                  tableRows: tableRows, tableCols: tableCols, tableCells: tableCells,
                  childOfContainerId: childOf)
    }

    /// En base64-rad per fixtur — robust mot att xcodebuild-loggen interfolierar rader.
    /// `scripts/extract-mermaid-fixtures.sh` grep:ar dessa och avkodar till .mmd.
    private func dump(_ name: String, _ mermaid: String) {
        let b64 = Data(mermaid.utf8).base64EncodedString()
        print("@@@MMD64:\(name):\(b64)")
    }

    /// Fixtur 1: hela form-vokabulären + alla kant-varianter + container m. barn,
    /// tabell m. celler, jump-länk, samt en etikett med specialtecken (escaping).
    func test_corpus_allShapes() {
        let container = node(.container, "Skill 1", .skill, x: 400, y: 400,
                             prompt: "Kör (research) → spara #fil; klar", note: "min egen anteckning",
                             skillNumber: 1)
        let child1 = node(.rectangle, "Subagent", .subagent, x: 360, y: 380, childOf: container.id)
        let child2 = node(.pill, "Output", .output, x: 440, y: 420, childOf: container.id)

        let shapes: [ShapeNode] = [
            node(.circle,       "Cirkel",        .ui,     x: 50,  y: 50),
            node(.rectangle,    "Rektangel",     .ui,     x: 200, y: 50),
            node(.diamond,      "Beslut?",       .router, x: 350, y: 50),
            node(.pill,         "Pill",          .input,  x: 500, y: 50),
            node(.square,       "Kvadrat",       .ui,     x: 50,  y: 150),
            node(.processArrow, "Process",       .ui,     x: 200, y: 150),
            node(.octagon,      "Stopp",         .manual, x: 350, y: 150),
            node(.triangle,     "Triangel",      .ui,     x: 500, y: 150),
            node(.cylinder,     "Databas",       .evidence, x: 50, y: 250),
            node(.phoneFrame,   "iPhone 16 Pro", .ui,     x: 200, y: 250),
            node(.link,         "Hoppa",         .ui,     x: 350, y: 250, linkNumber: 1),
            node(.table,        "Tabell",        .ui,     x: 500, y: 250,
                 tableRows: 2, tableCols: 2, tableCells: [["a", "b"], ["c", "d"]]),
            node(.line,         "Linje",         .ui,     x: 50,  y: 350),
            node(.arrow,        "Pil",           .ui,     x: 200, y: 350),
            // Specialtecken i etikett → tvingar escaping-vägen i generatorn:
            node(.rectangle,    "Tricky (a) \"b\" #c; åäö 🎯", .ui, x: 350, y: 350),
            container, child1, child2,
        ]

        let ids = shapes.map { $0.id }
        let edges: [EdgeConnection] = [
            EdgeConnection(from: ids[0], to: ids[2], label: "ja",  direction: .forward,       style: .solid, lineShape: .straight),
            EdgeConnection(from: ids[2], to: ids[3], label: "nej", direction: .forward,       style: .dashed, lineShape: .orthogonal),
            EdgeConnection(from: ids[1], to: ids[0], label: "",    direction: .backward,      style: .solid),
            EdgeConnection(from: ids[4], to: ids[5], label: "",    direction: .bidirectional, style: .solid),
            EdgeConnection(from: ids[6], to: ids[7], label: "",    direction: .none,          style: .solid),
        ]

        let mermaid = MermaidGenerator.generate(shapes: shapes, edges: edges,
                                                canvasSize: .zero, specType: .general)
        XCTAssertFalse(mermaid.isEmpty)
        XCTAssertTrue(mermaid.contains("flowchart"))
        dump("all-shapes", mermaid)
    }

    /// Fixtur 2: UI-läge → iPhone-subgraph-wrappern runt noderna.
    func test_corpus_uiFrame() {
        let shapes: [ShapeNode] = [
            node(.rectangle, "Knapp",   .ui,      x: 100, y: 200),
            node(.rectangle, "Rubrik",  .ui,      x: 100, y: 100),
            node(.rectangle, "Lista",   .zone,    x: 100, y: 300),
        ]
        let edges = [EdgeConnection(from: shapes[1].id, to: shapes[0].id)]
        let mermaid = MermaidGenerator.generate(shapes: shapes, edges: edges,
                                                canvasSize: CGSize(width: 393, height: 852),
                                                specType: .ui)
        XCTAssertFalse(mermaid.isEmpty)
        dump("ui-frame", mermaid)
    }

    /// Fixtur 3 (steg 8 / F): Skill-flöde-vokabulären — skill-container med ALLA byggstenar
    /// (input, subagent, tool, MCP, plugin, MD-fil, Excel-fil, output) + prompt + anteckning.
    /// Bevisar att de nya kategorierna och container-metadatan parsar i RIKTIG mermaid.
    func test_corpus_skillFlow() {
        let skill = node(.container, "Skill 2", .skill, x: 400, y: 400,
                         prompt: "Läs källa → sammanställ → spara", note: "skiss för bollande",
                         skillNumber: 2)
        let inp  = node(.pill,      "Input",    .input,        x: 200, y: 380, childOf: skill.id)
        let sub  = node(.rectangle, "Subagent", .subagent,     x: 320, y: 380, childOf: skill.id)
        let tool = node(.rectangle, "Tool",     .tool,         x: 440, y: 380, childOf: skill.id)
        let mcp  = node(.rectangle, "MCP",      .mcp,          x: 320, y: 440, childOf: skill.id)
        let plug = node(.rectangle, "Plugin",   .plugin,       x: 440, y: 440, childOf: skill.id)
        let md   = node(.rectangle, "data.md",  .fileMarkdown, x: 200, y: 440, childOf: skill.id)
        let xls  = node(.rectangle, "ark.xlsx", .fileExcel,    x: 560, y: 440, childOf: skill.id)
        let out  = node(.pill,      "Output",   .output,       x: 560, y: 380, childOf: skill.id)
        let shapes = [skill, inp, sub, tool, mcp, plug, md, xls, out]
        let ids = shapes.map { $0.id }
        let edges: [EdgeConnection] = [
            EdgeConnection(from: ids[1], to: ids[2], direction: .forward, style: .solid),
            EdgeConnection(from: ids[2], to: ids[3], direction: .forward, style: .solid),
            EdgeConnection(from: ids[2], to: ids[8], direction: .forward, style: .solid),
        ]
        let mermaid = MermaidGenerator.generate(shapes: shapes, edges: edges,
                                                canvasSize: .zero, specType: .general)
        XCTAssertFalse(mermaid.isEmpty)
        XCTAssertTrue(mermaid.contains("flowchart"))
        dump("skill-flow", mermaid)
    }
}
