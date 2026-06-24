import XCTest
import CoreGraphics
@testable import MermaidCanvas

/// v64: utgångssida på pil (fromSide) — round-trip + modellbeteende.
@MainActor
final class V64RoundTripTests: XCTestCase {

    private func stripStateJSON(_ markdown: String) -> String {
        guard let start = markdown.range(of: "<!-- mermaidcanvas-state"),
              let end = markdown.range(of: "\n-->", range: start.upperBound..<markdown.endIndex)
        else { return markdown }
        return String(markdown[..<start.lowerBound]) + String(markdown[end.upperBound...])
    }

    func testFromSide_RoundTripparBadaVagarna() {
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: 100, y: 100), label: "A")
        let b = ShapeNode(type: .rectangle, position: CGPoint(x: 300, y: 100), label: "B")
        let edge = EdgeConnection(from: a.id, to: b.id, fromSide: .bottom)
        let doc = CanvasDocument(title: "T", shapes: [a, b], edges: [edge],
                                 canvasSize: CGSize(width: 800, height: 800),
                                 specType: .general).content

        let viaJSON = MermaidParser.parse(doc)
        XCTAssertEqual(viaJSON.edges.first?.fromSide, .bottom, "state-JSON-vägen")

        let viaFallback = MermaidParser.parse(stripStateJSON(doc))
        XCTAssertEqual(viaFallback.edges.first?.fromSide, .bottom, "%% e0 fromSide-vägen")
    }

    func testFromSide_NilSkrivsInte() {
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: 100, y: 100), label: "A")
        let b = ShapeNode(type: .rectangle, position: CGPoint(x: 300, y: 100), label: "B")
        let edge = EdgeConnection(from: a.id, to: b.id)
        // Kolla mermaid-KROPPEN (det inbäddade AI-ramverket nämner ordet "fromSide" som doc).
        let mermaid = MermaidGenerator.generate(shapes: [a, b], edges: [edge],
                                                canvasSize: CGSize(width: 800, height: 800),
                                                specType: .general)
        XCTAssertFalse(mermaid.contains("fromSide"), "Automatisk sida → ingen meta i mermaid-kroppen")
        let doc = CanvasDocument(title: "T", shapes: [a, b], edges: [edge],
                                 canvasSize: CGSize(width: 800, height: 800),
                                 specType: .general).content
        XCTAssertNil(MermaidParser.parse(doc).edges.first?.fromSide)
    }

    func testSetEdgeFromSide_AndrarOchAterstaller() {
        let model = CanvasModel()
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: 100, y: 100), label: "A")
        let b = ShapeNode(type: .rectangle, position: CGPoint(x: 300, y: 100), label: "B")
        let edge = EdgeConnection(from: a.id, to: b.id)
        model.replaceAll(shapes: [a, b], edges: [edge])

        model.setEdgeFromSide(id: edge.id, side: .top)
        XCTAssertEqual(model.edges.first?.fromSide, .top)

        model.setEdgeFromSide(id: edge.id, side: nil)
        XCTAssertNil(model.edges.first?.fromSide, "nil = tillbaka till automatisk")
    }
}
