import XCTest
import CoreGraphics
@testable import MermaidCanvas

/// v61: Regressionstester för fallback-parsern (mermaid-block UTAN state-JSON).
/// Två kärnkrav från GAP-ANALYS-v61:
/// 1. Rå mermaid från Claude får lagrad layout (TD/LR/BT/RL) — inte cirkel.
/// 2. Mermaid-blocket är självbärande: %%-kommentarerna round-trippar
///    positioner, storlek, rotation, färg, prompt m.m.
final class V61FallbackParserTests: XCTestCase {

    // MARK: - Hjälpare

    /// Tar bort state-JSON-blocket så fallback-parsern tvingas ta över.
    private func stripStateJSON(_ markdown: String) -> String {
        guard let start = markdown.range(of: "<!-- mermaidcanvas-state"),
              let end = markdown.range(of: "\n-->", range: start.upperBound..<markdown.endIndex)
        else { return markdown }
        return String(markdown[..<start.lowerBound]) + String(markdown[end.upperBound...])
    }

    private func rawMermaid(_ body: String) -> String {
        """
        # Test

        ```mermaid
        \(body)
        ```
        """
    }

    // MARK: - 1. Lagrad auto-layout (Claude → Kim)

    func testRawMermaid_TD_GerVertikalKedja() {
        let md = rawMermaid("""
        flowchart TD
            a["Start"] --> b["Mitten"]
            b --> c["Slut"]
        """)
        let parsed = MermaidParser.parse(md)
        XCTAssertEqual(parsed.shapes.count, 3)
        let a = parsed.shapes[0], b = parsed.shapes[1], c = parsed.shapes[2]
        // TD: y växer per nivå, x konstant (en nod per nivå)
        XCTAssertLessThan(a.position.y, b.position.y, "TD: a ska ligga ovanför b")
        XCTAssertLessThan(b.position.y, c.position.y, "TD: b ska ligga ovanför c")
        XCTAssertEqual(a.position.x, b.position.x, accuracy: 1, "TD: rak kedja = samma x")
        XCTAssertEqual(b.position.x, c.position.x, accuracy: 1)
    }

    func testRawMermaid_LR_GerHorisontellKedja() {
        let md = rawMermaid("""
        flowchart LR
            a["Ett"] --> b["Två"]
            b --> c["Tre"]
        """)
        let parsed = MermaidParser.parse(md)
        XCTAssertEqual(parsed.shapes.count, 3)
        let a = parsed.shapes[0], b = parsed.shapes[1], c = parsed.shapes[2]
        XCTAssertLessThan(a.position.x, b.position.x, "LR: a ska ligga vänster om b")
        XCTAssertLessThan(b.position.x, c.position.x)
        XCTAssertEqual(a.position.y, b.position.y, accuracy: 1, "LR: rak kedja = samma y")
    }

    func testRawMermaid_Forgrening_SyskonPaSammaNiva() {
        let md = rawMermaid("""
        flowchart TD
            rot["Rot"] --> v["Vänster"]
            rot --> h["Höger"]
        """)
        let parsed = MermaidParser.parse(md)
        XCTAssertEqual(parsed.shapes.count, 3)
        let rot = parsed.shapes[0], v = parsed.shapes[1], h = parsed.shapes[2]
        XCTAssertLessThan(rot.position.y, v.position.y, "Rot ska ligga ovanför barnen")
        XCTAssertEqual(v.position.y, h.position.y, accuracy: 1, "Syskon på samma nivå")
        XCTAssertNotEqual(v.position.x, h.position.x, "Syskon får inte överlappa")
    }

    func testRawMermaid_Cykel_KraschaInte() {
        let md = rawMermaid("""
        flowchart TD
            a["A"] --> b["B"]
            b --> a
        """)
        let parsed = MermaidParser.parse(md)
        XCTAssertEqual(parsed.shapes.count, 2, "Cykel ska parsas utan hängning/krasch")
        XCTAssertEqual(parsed.edges.count, 2)
    }

    func testRawMermaid_BT_OmvandRiktning() {
        let md = rawMermaid("""
        flowchart BT
            a["Start"] --> b["Slut"]
        """)
        let parsed = MermaidParser.parse(md)
        let a = parsed.shapes[0], b = parsed.shapes[1]
        XCTAssertGreaterThan(a.position.y, b.position.y, "BT: flödet går nedifrån och upp")
    }

    // MARK: - 1b. Claude-typisk syntax (ocitat, nakna id:n, tjocka pilar)

    func testRawMermaid_OcitatLabel() {
        let md = rawMermaid("""
        flowchart TD
            login[Logga in] --> home{Är inloggad?}
        """)
        let parsed = MermaidParser.parse(md)
        XCTAssertEqual(parsed.shapes.count, 2)
        XCTAssertEqual(parsed.shapes.first { $0.type == .rectangle }?.label, "Logga in")
        XCTAssertEqual(parsed.shapes.first { $0.type == .diamond }?.label, "Är inloggad?")
        XCTAssertEqual(parsed.edges.count, 1)
    }

    func testRawMermaid_NaknaIdBlirNoder() {
        let md = rawMermaid("""
        flowchart TD
            Start --> Slut
        """)
        let parsed = MermaidParser.parse(md)
        XCTAssertEqual(parsed.shapes.count, 2, "Nakna id:n ska bli noder")
        XCTAssertEqual(parsed.shapes[0].label, "Start", "Id:t blir text")
        XCTAssertEqual(parsed.edges.count, 1)
    }

    func testRawMermaid_TjockPilOchInlineEtikett() {
        let md = rawMermaid("""
        flowchart TD
            a[Auth] ==> b[Home]
            b -- tap --> c[Inställningar]
        """)
        let parsed = MermaidParser.parse(md)
        XCTAssertEqual(parsed.shapes.count, 3)
        XCTAssertEqual(parsed.edges.count, 2, "==> och `-- text -->` ska bli kanter")
        let labeled = parsed.edges.first { !$0.label.isEmpty }
        XCTAssertEqual(labeled?.label, "tap", "Inline-etiketten ska bevaras")
    }

    func testRawMermaid_KategoriFranClassSuffix() {
        let md = rawMermaid("""
        flowchart LR
            input_N0[Webhook]:::input --> agent_N1[Tolka]:::agent
        """)
        let parsed = MermaidParser.parse(md)
        XCTAssertEqual(parsed.shapes.count, 2)
        XCTAssertEqual(parsed.shapes[0].category, .input)
        XCTAssertEqual(parsed.shapes[1].category, .agent)
        XCTAssertEqual(parsed.edges.count, 1, ":::suffix får inte skapa fantomnoder")
    }

    // MARK: - 2. Självbärande mermaid-block (%%-kommentarer)

    func testFallback_PositionerLasesFranPosKommentarer() {
        let shapes = [
            ShapeNode(type: .circle,    position: CGPoint(x: 111, y: 222), label: "Cirkel"),
            ShapeNode(type: .rectangle, position: CGPoint(x: 333, y: 444), label: "Rektangel")
        ]
        let doc = CanvasDocument(title: "T", shapes: shapes, edges: [],
                                 canvasSize: CGSize(width: 800, height: 800),
                                 specType: .general)
        let parsed = MermaidParser.parse(stripStateJSON(doc.content))
        XCTAssertEqual(parsed.shapes.count, 2)
        XCTAssertEqual(parsed.shapes[0].position.x, 111, accuracy: 1,
                       "Position ska läsas från %% pos: — INTE auto-layout")
        XCTAssertEqual(parsed.shapes[0].position.y, 222, accuracy: 1)
        XCTAssertEqual(parsed.shapes[1].position.x, 333, accuracy: 1)
        XCTAssertEqual(parsed.shapes[1].position.y, 444, accuracy: 1)
    }

    func testFallback_MetadataRoundTrippar() {
        var shape = ShapeNode(type: .rectangle,
                              position: CGPoint(x: 100, y: 100),
                              label: "Stylad",
                              sizeMultiplier: 1.5,
                              note: "En anteckning\npå två rader",
                              prompt: "Hämta data\nfrån API:t",
                              rotation: 45,
                              colorOverride: "#ff0000",
                              textStyle: .r1,
                              colorPackId: "rosa")
        shape.widthMultiplier = 2.0
        shape.heightMultiplier = 0.5
        let doc = CanvasDocument(title: "T", shapes: [shape], edges: [],
                                 canvasSize: CGSize(width: 800, height: 800),
                                 specType: .general)
        let parsed = MermaidParser.parse(stripStateJSON(doc.content))
        XCTAssertEqual(parsed.shapes.count, 1)
        let p = parsed.shapes[0]
        XCTAssertEqual(p.sizeMultiplier, 1.5, accuracy: 0.05)
        XCTAssertEqual(p.rotation, 45, accuracy: 1)
        XCTAssertEqual(p.colorOverride, "#ff0000")
        XCTAssertEqual(p.note, "En anteckning\npå två rader", "Note ska round-trippa inkl radbrytning")
        XCTAssertEqual(p.prompt, "Hämta data\nfrån API:t", "Prompt (n8n) ska round-trippa inkl radbrytning")
        XCTAssertEqual(p.textStyle, .r1)
        XCTAssertEqual(p.colorPackId, "rosa")
        XCTAssertEqual(p.widthMultiplier ?? 0, 2.0, accuracy: 0.05)
        XCTAssertEqual(p.heightMultiplier ?? 0, 0.5, accuracy: 0.05)
    }

    func testFallback_DoldEtikettAterstallsFranName() {
        let shape = ShapeNode(type: .circle, position: CGPoint(x: 50, y: 60),
                              label: "Hemlig text", showLabel: false)
        let doc = CanvasDocument(title: "T", shapes: [shape], edges: [],
                                 canvasSize: CGSize(width: 800, height: 800),
                                 specType: .general)
        let parsed = MermaidParser.parse(stripStateJSON(doc.content))
        XCTAssertEqual(parsed.shapes.count, 1)
        XCTAssertFalse(parsed.shapes[0].showLabel, "hidden-label ska ge showLabel=false")
        XCTAssertEqual(parsed.shapes[0].label, "Hemlig text",
                       "Label ska återställas från %% name: trots dold etikett")
    }

    func testFallback_CollapsedLases() {
        let a = ShapeNode(type: .circle, position: CGPoint(x: 50, y: 60), label: "A")
        let b = ShapeNode(type: .circle, position: CGPoint(x: 250, y: 60), label: "B")
        let doc = CanvasDocument(title: "T", shapes: [a, b],
                                 edges: [EdgeConnection(from: a.id, to: b.id)],
                                 canvasSize: CGSize(width: 800, height: 800),
                                 specType: .general,
                                 collapsedIds: [a.id])
        let parsed = MermaidParser.parse(stripStateJSON(doc.content))
        XCTAssertEqual(parsed.collapsedIds.count, 1, "%% collapsed ska läsas i fallback")
        let parsedA = parsed.shapes.first { $0.label == "A" }
        XCTAssertEqual(parsed.collapsedIds.first, parsedA?.id)
    }

    func testFallback_TabellOchLank() {
        let shapes = [
            ShapeNode(type: .table, position: CGPoint(x: 50, y: 60), label: "Tabell",
                      tableRows: 2, tableCols: 5),
            ShapeNode(type: .link, position: CGPoint(x: 250, y: 60), label: "Länk",
                      linkNumber: 3)
        ]
        let doc = CanvasDocument(title: "T", shapes: shapes, edges: [],
                                 canvasSize: CGSize(width: 800, height: 800),
                                 specType: .general)
        let parsed = MermaidParser.parse(stripStateJSON(doc.content))
        let table = parsed.shapes.first { $0.tableRows != nil }
        XCTAssertEqual(table?.tableRows, 2)
        XCTAssertEqual(table?.tableCols, 5)
        let link = parsed.shapes.first { $0.linkNumber != nil }
        XCTAssertEqual(link?.linkNumber, 3)
    }

    func testFallback_LineEndBlirRelativ() {
        let line = ShapeNode(type: .line, position: CGPoint(x: 100, y: 100),
                             label: "", lineEnd: CGPoint(x: 80, y: 40))
        let doc = CanvasDocument(title: "T", shapes: [line], edges: [],
                                 canvasSize: CGSize(width: 800, height: 800),
                                 specType: .general)
        let parsed = MermaidParser.parse(stripStateJSON(doc.content))
        XCTAssertEqual(parsed.shapes.count, 1)
        let end = parsed.shapes[0].lineEnd
        XCTAssertNotNil(end, "line-end ska läsas i fallback")
        XCTAssertEqual(end?.x ?? 0, 80, accuracy: 1, "Absolut line-end ska bli relativ igen")
        XCTAssertEqual(end?.y ?? 0, 40, accuracy: 1)
    }
}
