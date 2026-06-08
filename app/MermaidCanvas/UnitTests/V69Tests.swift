import XCTest
import CoreGraphics
@testable import MermaidCanvas

/// v69: process-kontroll-vokabulär (Grind/Bevis/Manual/Script) + cylinder-geometri.
/// Rådgivnings-fynd: en pålitlig skill-kedja behöver grind (≠ router), bevis, manuell-stopp.
@MainActor
final class V69Tests: XCTestCase {

    private func stripStateJSON(_ markdown: String) -> String {
        guard let start = markdown.range(of: "<!-- mermaidcanvas-state"),
              let end = markdown.range(of: "\n-->", range: start.upperBound..<markdown.endIndex)
        else { return markdown }
        return String(markdown[..<start.lowerBound]) + String(markdown[end.upperBound...])
    }

    // MARK: - Cylinder (native mermaid) round-trippar BÅDA vägarna

    func testCylinder_RoundTrip_StateJSON() {
        let c = ShapeNode(type: .cylinder, position: CGPoint(x: 500, y: 500),
                          label: "Bevis", category: .evidence)
        let doc = CanvasDocument(title: "Bevis", shapes: [c], edges: [],
                                 canvasSize: CGSize(width: 4000, height: 4000),
                                 specType: .general).content
        let parsed = MermaidParser.parse(doc)
        XCTAssertEqual(parsed.shapes.first?.type, .cylinder, "state-JSON bevarar cylindern")
        XCTAssertEqual(parsed.shapes.first?.category, .evidence)
    }

    func testCylinder_RoundTrip_NativeMermaid() {
        let c = ShapeNode(type: .cylinder, position: CGPoint(x: 500, y: 500), label: "Bevis")
        let doc = CanvasDocument(title: "Bevis", shapes: [c], edges: [],
                                 canvasSize: CGSize(width: 4000, height: 4000),
                                 specType: .general).content
        // Cylinder är NATIVE mermaid → behöver ingen %% shape-type, läses tillbaka via [(...)]
        XCTAssertFalse(doc.contains("shape-type: cylinder"),
                       "Cylinder ska INTE behöva %% shape-type (den är native mermaid)")
        let parsed = MermaidParser.parse(stripStateJSON(doc))
        XCTAssertEqual(parsed.shapes.first?.type, .cylinder,
                       "Utan state-JSON återskapas cylindern via native [(\"...\")]")
        XCTAssertEqual(parsed.shapes.first?.label, "Bevis")
    }

    // MARK: - n8n-paletten har den kompletta process-vokabulären

    func testN8nPaket_HarProcessKontrollNoder() {
        for c in [ShapeCategory.gate, .evidence, .manual, .script] {
            XCTAssertTrue(ShapePack.n8n.categories.contains(c),
                          "n8n-paletten saknar \(c.rawValue)")
        }
        // De gamla flödesnoderna finns kvar
        for c in [ShapeCategory.input, .skill, .subagent, .agent, .tool, .router, .memory, .prompt, .output] {
            XCTAssertTrue(ShapePack.n8n.categories.contains(c), "n8n saknar \(c.rawValue)")
        }
    }

    // MARK: - Nya kategorier hör till flow + har distinkta färger

    func testNyaKategorier_TillhorFlow() {
        for c in [ShapeCategory.gate, .evidence, .manual, .script] {
            XCTAssertEqual(c.specType, .flow, "\(c.rawValue) ska höra till flow")
        }
    }

    func testNyaKategorier_HarDistinktaStrokeFarger() {
        let strokes = [ShapeCategory.gate, .evidence, .manual, .script].map { $0.strokeColor }
        let unika = Set(strokes.map { $0.hex })
        XCTAssertEqual(unika.count, 4, "Grind/Bevis/Manual/Script ska ha 4 olika ram-färger")
    }

    // MARK: - Grind är semantiskt skild från Router (rådgivarens huvudpoäng)

    func testGrind_ArSkildFranRouter() {
        XCTAssertNotEqual(ShapeCategory.gate.displayName, ShapeCategory.router.displayName)
        XCTAssertNotEqual(ShapeCategory.gate.strokeColor.hex, ShapeCategory.router.strokeColor.hex,
                          "Grind och Router ska se olika ut")
    }
}
