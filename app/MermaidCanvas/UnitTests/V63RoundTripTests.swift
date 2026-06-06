import XCTest
import CoreGraphics
@testable import MermaidCanvas

/// v63: round-trip + beteende för Kims sex fynd —
/// pilfärg, kollaps PER GREN (inkl. migration av gamla nod-kollapsade filer).
@MainActor
final class V63RoundTripTests: XCTestCase {

    private func stripStateJSON(_ markdown: String) -> String {
        guard let start = markdown.range(of: "<!-- mermaidcanvas-state"),
              let end = markdown.range(of: "\n-->", range: start.upperBound..<markdown.endIndex)
        else { return markdown }
        return String(markdown[..<start.lowerBound]) + String(markdown[end.upperBound...])
    }

    // MARK: - Pilfärg

    func testPilFarg_RoundTripparBadaVagarna() {
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: 100, y: 100), label: "A")
        let b = ShapeNode(type: .rectangle, position: CGPoint(x: 300, y: 100), label: "B")
        let edge = EdgeConnection(from: a.id, to: b.id, label: "x", colorHex: "#b91c1c")
        let doc = CanvasDocument(title: "T", shapes: [a, b], edges: [edge],
                                 canvasSize: CGSize(width: 800, height: 800),
                                 specType: .general).content

        let viaJSON = MermaidParser.parse(doc)
        XCTAssertEqual(viaJSON.edges.first?.colorHex, "#b91c1c", "state-JSON-vägen")

        let viaFallback = MermaidParser.parse(stripStateJSON(doc))
        XCTAssertEqual(viaFallback.edges.first?.colorHex, "#b91c1c", "%% e0 color-vägen")
    }

    // MARK: - Kollaps per gren

    /// Diamant med två grenar: kollapsa EN gren → bara den grenens mål döljs.
    func testKollaps_BaraEnGren() {
        let model = CanvasModel()
        let router = ShapeNode(type: .diamond, position: CGPoint(x: 200, y: 100), label: "Val")
        let left   = ShapeNode(type: .rectangle, position: CGPoint(x: 100, y: 300), label: "Vänster")
        let right  = ShapeNode(type: .rectangle, position: CGPoint(x: 300, y: 300), label: "Höger")
        let leftEdge  = EdgeConnection(from: router.id, to: left.id, label: "ja")
        let rightEdge = EdgeConnection(from: router.id, to: right.id, label: "nej")
        model.replaceAll(shapes: [router, left, right], edges: [leftEdge, rightEdge])

        model.toggleCollapseEdge(leftEdge.id)

        XCTAssertTrue(model.hiddenShapeIds.contains(left.id), "Vänster gren döljs")
        XCTAssertFalse(model.hiddenShapeIds.contains(right.id),
                       "HÖGER GREN SKA VARA KVAR — Kims huvudfynd")
        XCTAssertFalse(model.hiddenShapeIds.contains(router.id))

        model.toggleCollapseEdge(leftEdge.id)
        XCTAssertTrue(model.hiddenShapeIds.isEmpty, "Expandera återställer")
    }

    /// Kollaps tar med grenens EFTERFÖLJARE (nedströms), inte bara första noden.
    func testKollaps_TarMedEfterfoljare() {
        let model = CanvasModel()
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: 100, y: 100), label: "A")
        let b = ShapeNode(type: .rectangle, position: CGPoint(x: 100, y: 250), label: "B")
        let c = ShapeNode(type: .rectangle, position: CGPoint(x: 100, y: 400), label: "C")
        let ab = EdgeConnection(from: a.id, to: b.id)
        let bc = EdgeConnection(from: b.id, to: c.id)
        model.replaceAll(shapes: [a, b, c], edges: [ab, bc])

        model.toggleCollapseEdge(ab.id)
        XCTAssertEqual(model.hiddenShapeIds, [b.id, c.id], "B och C döljs, A kvar")
    }

    func testKollaps_RoundTripparPerGren() {
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: 100, y: 100), label: "A")
        let b = ShapeNode(type: .rectangle, position: CGPoint(x: 100, y: 300), label: "B")
        let c = ShapeNode(type: .rectangle, position: CGPoint(x: 300, y: 300), label: "C")
        let ab = EdgeConnection(from: a.id, to: b.id)
        let ac = EdgeConnection(from: a.id, to: c.id)
        let doc = CanvasDocument(title: "T", shapes: [a, b, c], edges: [ab, ac],
                                 canvasSize: CGSize(width: 800, height: 800),
                                 specType: .general,
                                 collapsedEdgeIds: [ab.id]).content

        // state-JSON-vägen
        let viaJSON = MermaidParser.parse(doc)
        XCTAssertEqual(viaJSON.collapsedEdgeIds.count, 1)
        let collapsedJSON = viaJSON.edges.first { viaJSON.collapsedEdgeIds.contains($0.id) }
        let bJSON = viaJSON.shapes.first { $0.label == "B" }
        XCTAssertEqual(collapsedJSON?.to, bJSON?.id, "Rätt gren (A→B) är kollapsad")

        // fallback-vägen
        let viaFallback = MermaidParser.parse(stripStateJSON(doc))
        XCTAssertEqual(viaFallback.collapsedEdgeIds.count, 1)
        let collapsedFB = viaFallback.edges.first { viaFallback.collapsedEdgeIds.contains($0.id) }
        let bFB = viaFallback.shapes.first { $0.label == "B" }
        XCTAssertEqual(collapsedFB?.to, bFB?.id)
    }

    /// Gamla filer (v62 och äldre): "collapsed": [nod-id] i state-JSON →
    /// alla nodens utgående grenar kollapsas. (Demo-filen på Kims iPhone har
    /// exakt detta format med router_N4.)
    func testKollaps_MigrationAvGammalNodKollaps() {
        let md = """
        # Gammal fil

        ```mermaid
        flowchart TD
            r{"Val"} --> x["X"]
            r --> y["Y"]
        ```

        <!-- mermaidcanvas-state
        {
          "canvas": { "width": 800, "height": 800, "shapeBaseWidth": 120, "shapeBaseHeight": 80, "unit": "pt" },
          "nodes": [
            { "id": "r", "x": 200, "y": 100, "label": "Val", "type": "diamond", "category": "router" },
            { "id": "x", "x": 100, "y": 300, "label": "X", "type": "rectangle", "category": "ui" },
            { "id": "y", "x": 300, "y": 300, "label": "Y", "type": "rectangle", "category": "ui" }
          ],
          "edges": [
            { "from": "r", "to": "x", "label": "", "direction": "forward", "style": "solid" },
            { "from": "r", "to": "y", "label": "", "direction": "forward", "style": "solid" }
          ],
          "collapsed": ["r"]
        }
        -->
        """
        let parsed = MermaidParser.parse(md)
        XCTAssertEqual(parsed.collapsedEdgeIds.count, 2,
                       "Gammal nod-kollaps → BÅDA utgående grenarna kollapsade")
    }

    /// Gammalt fallback-format: `%% <nod> collapsed` (utan kolon) migreras också.
    func testKollaps_MigrationAvGammalFallbackKommentar() {
        let md = """
        # Gammal fil

        ```mermaid
        flowchart TD
            r{"Val"} --> x["X"]
            r --> y["Y"]
            %% r collapsed
        ```
        """
        let parsed = MermaidParser.parse(md)
        XCTAssertEqual(parsed.collapsedEdgeIds.count, 2,
                       "%% r collapsed → båda utgående grenarna")
    }
}
