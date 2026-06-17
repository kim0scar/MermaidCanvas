import XCTest
import CoreGraphics
@testable import MermaidCanvas

/// MA spår A — A1: DJUP round-trip-fidelity.
///
/// Skillnad mot RoundTripTests (som plockar enstaka fält med 1pt-tolerans): här
/// jämförs HELA varje form/kant fält-för-fält efter round-trip — bara id ignoreras
/// (parsern skapar nya UUID:n). Heltalskoordinater används så state-JSON:ens
/// Int-avrundning ger EXAKT round-trip. En enda fält-glidning failar testet och
/// pekar ut exakt vilket fält som tappades.
final class RoundTripFidelityTests: XCTestCase {

    // MARK: - pipeline + djupjämförelse

    private func roundTrip(_ shapes: [ShapeNode], _ edges: [EdgeConnection],
                           platform: Platform = .blank,
                           packs: Set<ShapePack> = [.basic],
                           collapsed: Set<UUID> = []) -> MermaidParser.ParsedCanvas {
        let doc = CanvasDocument(
            title: "Fidelity", shapes: shapes, edges: edges,
            canvasSize: CGSize(width: 4000, height: 4000),
            specType: .general, platform: platform,
            activeShapePacks: packs, collapsedEdgeIds: collapsed)
        return MermaidParser.parse(doc.content)
    }

    /// Encodar en form till en dict, tar bort id och normaliserar childOf → index.
    private func canon(_ shapes: [ShapeNode]) throws -> [NSDictionary] {
        let idx = Dictionary(uniqueKeysWithValues: shapes.enumerated().map { ($0.element.id, $0.offset) })
        let enc = JSONEncoder()
        return try shapes.map { s in
            var d = try JSONSerialization.jsonObject(with: enc.encode(s)) as! [String: Any]
            d.removeValue(forKey: "id")
            if let cid = s.childOfContainerId, let i = idx[cid] { d["childOfContainerId"] = i }
            else { d.removeValue(forKey: "childOfContainerId") }
            return d as NSDictionary
        }
    }

    private func canon(_ edges: [EdgeConnection], in shapes: [ShapeNode]) throws -> [NSDictionary] {
        let idx = Dictionary(uniqueKeysWithValues: shapes.enumerated().map { ($0.element.id, $0.offset) })
        let enc = JSONEncoder()
        return try edges.map { e in
            var d = try JSONSerialization.jsonObject(with: enc.encode(e)) as! [String: Any]
            d.removeValue(forKey: "id")
            if let f = idx[e.from] { d["from"] = f }
            if let t = idx[e.to] { d["to"] = t }
            return d as NSDictionary
        }
    }

    /// Jämför form-för-form och rapporterar exakt vilka nycklar som skiljer.
    private func assertShapesEqual(_ original: [ShapeNode], _ parsed: [ShapeNode],
                                   _ msg: String, file: StaticString = #filePath, line: UInt = #line) throws {
        XCTAssertEqual(parsed.count, original.count, "\(msg): antal former", file: file, line: line)
        let a = try canon(original), b = try canon(parsed)
        for i in 0..<min(a.count, b.count) where a[i] != b[i] {
            let ad = a[i] as! [String: Any], bd = b[i] as! [String: Any]
            let keys = Set(ad.keys).union(bd.keys).sorted()
            let diffs = keys.compactMap { k -> String? in
                let x = ad[k], y = bd[k]
                if "\(x ?? "nil")" == "\(y ?? "nil")" { return nil }
                return "\(k): original=\(x ?? "saknas") → parsed=\(y ?? "saknas")"
            }
            XCTFail("\(msg): form #\(i) skiljer:\n  " + diffs.joined(separator: "\n  "), file: file, line: line)
        }
    }

    // MARK: - A1.1 varje formtyp, typ + universella fält

    func test_everyShapeType_preserved() throws {
        var shapes: [ShapeNode] = []
        for (i, t) in ShapeType.allCases.enumerated() {
            var s = ShapeNode(type: t, position: CGPoint(x: 200 + i * 160, y: 300),
                              label: "L\(i)", note: "n\(i)", prompt: "p\(i)")
            s.textStyle = .r2
            s.textAlignment = .leading
            if t == .line || t == .arrow { s.lineEnd = CGPoint(x: 60, y: 40) }
            if t == .table { s.tableRows = 2; s.tableCols = 2 }  // parsern defaultar annars till 3×3
            shapes.append(s)
        }
        let parsed = roundTrip(shapes, [])
        try assertShapesEqual(shapes, parsed.shapes, "varje formtyp")
    }

    // MARK: - A1.2 en form med ALLA rika fält

    func test_richRectangle_allFields() throws {
        var s = ShapeNode(type: .rectangle, position: CGPoint(x: 500, y: 600), label: "Rik")
        s.note = "anteckning"; s.prompt = "en prompt"; s.rotation = 30
        s.colorOverride = "#ff8800"; s.strokeColorOverride = "#003366"
        s.colorPackId = "blue"; s.textStyle = .r1; s.textAlignment = .trailing
        s.hasBullets = true; s.indentLevel = 2
        s.sizeMultiplier = 1.5; s.widthMultiplier = 2.0; s.heightMultiplier = 1.25
        let parsed = roundTrip([s], [])
        try assertShapesEqual([s], parsed.shapes, "rik rektangel")
    }

    // MARK: - A1.3 kanter, alla varianter

    func test_edges_allVariants() throws {
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: 200, y: 200), label: "A")
        let b = ShapeNode(type: .rectangle, position: CGPoint(x: 600, y: 200), label: "B")
        var edges: [EdgeConnection] = []
        for dir in EdgeDirection.allCases {
            for style in EdgeStyle.allCases {
                var e = EdgeConnection(from: a.id, to: b.id, label: "\(dir)-\(style)",
                                       direction: dir, style: style)
                e.colorHex = "#abcdef"
                e.fromSide = .bottom
                e.labelPlacement = .above
                e.waypoints = [EdgeWaypoint(x: 400, y: 260)]
                edges.append(e)
            }
        }
        let parsed = roundTrip([a, b], edges)
        XCTAssertEqual(parsed.edges.count, edges.count, "alla kant-varianter bevaras")
        let ca = try canon(edges, in: [a, b]), cb = try canon(parsed.edges, in: parsed.shapes)
        for i in 0..<min(ca.count, cb.count) {
            XCTAssertEqual(ca[i], cb[i], "kant #\(i) (\(edges[i].label)) skiljer")
        }
    }

    // MARK: - A1.4 container + barn-länk

    func test_containerChildLinkage() throws {
        var box = ShapeNode(type: .container, position: CGPoint(x: 500, y: 500), label: "Grupp")
        box.widthMultiplier = 2.4; box.heightMultiplier = 1.6
        let c1 = ShapeNode(type: .circle, position: CGPoint(x: 380, y: 500), childOfContainerId: box.id)
        let c2 = ShapeNode(type: .circle, position: CGPoint(x: 620, y: 500), childOfContainerId: box.id)
        let shapes = [box, c1, c2]
        let parsed = roundTrip(shapes, [])
        try assertShapesEqual(shapes, parsed.shapes, "container-barn-länk")
    }

    // MARK: - A1.5 tabell med celler

    func test_tableCells() throws {
        var t = ShapeNode(type: .table, position: CGPoint(x: 400, y: 400), label: "Tab",
                          tableRows: 2, tableCols: 3)
        t.tableCells = [["a", "b", "c"], ["d", "e", "f"]]
        let parsed = roundTrip([t], [])
        try assertShapesEqual([t], parsed.shapes, "tabellceller")
    }

    // MARK: - A1.6 idempotens (parse→generate×2 byte-identisk)

    func test_idempotent() throws {
        let a = ShapeNode(type: .diamond, position: CGPoint(x: 300, y: 300), label: "Beslut")
        let b = ShapeNode(type: .pill, position: CGPoint(x: 600, y: 300), label: "Pill")
        let e = EdgeConnection(from: a.id, to: b.id, label: "ja", direction: .bidirectional, style: .dashed)
        func generate(_ shapes: [ShapeNode], _ edges: [EdgeConnection]) -> String {
            CanvasDocument(title: "Idem", shapes: shapes, edges: edges,
                           canvasSize: CGSize(width: 4000, height: 4000),
                           specType: .general, platform: .blank,
                           activeShapePacks: [.basic], collapsedEdgeIds: []).content
        }
        let md1 = generate([a, b], [e])
        let p1 = MermaidParser.parse(md1)
        let md2 = generate(p1.shapes, p1.edges)
        let p2 = MermaidParser.parse(md2)
        let md3 = generate(p2.shapes, p2.edges)
        XCTAssertEqual(md2, md3, "andra och tredje genereringen ska vara byte-identiska (stabil serialisering)")
    }
}
