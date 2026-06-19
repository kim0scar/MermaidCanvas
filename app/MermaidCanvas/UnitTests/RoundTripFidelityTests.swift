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

    // MARK: - A1.4b UX-110: mermaid-subgraph-medlemskap följer childOfContainerId (inte position)

    /// UX-110 (rotfixad v73): en nod som bara LIGGER på containern, utan
    /// childOfContainerId, får ALDRIG bli subgraph-medlem i det genererade mermaid-
    /// blocket — annars säger mermaid och state-JSON olika saker (round-trip-
    /// protokollbrott; Claude som läser mermaid:en ser en annan struktur än appen).
    /// Vi inspekterar subgraph-blocket direkt: det ska innehålla EXAKT det explicita barnet.
    func test_ux110_mermaidMembershipFollowsChildOf() throws {
        var box = ShapeNode(type: .container, position: CGPoint(x: 500, y: 500), label: "Grupp")
        box.widthMultiplier = 3.0; box.heightMultiplier = 2.0   // stora bounds → stray hamnar geometriskt "inuti"
        let child = ShapeNode(type: .circle, position: CGPoint(x: 460, y: 500),
                              label: "BARN", childOfContainerId: box.id)
        let stray = ShapeNode(type: .circle, position: CGPoint(x: 540, y: 500), label: "STRAY")
        let mermaid = MermaidGenerator.generate(shapes: [box, child, stray], edges: [], specType: .general)
        let lines = mermaid.components(separatedBy: "\n")

        // Hitta varje nods mermaid-id via dess etikett-rad (t.ex. `ui_N1(("BARN")):::ui`).
        func nodeId(_ label: String) -> String? {
            lines.first { $0.contains("\"\(label)\"") && $0.contains("((") }?
                .trimmingCharacters(in: .whitespaces).components(separatedBy: "(").first
        }
        guard let barnId = nodeId("BARN"), let strayId = nodeId("STRAY") else {
            return XCTFail("hittar inte nod-id i mermaid")
        }
        // Subgraph-blocket: medlemmarna står mellan `subgraph …` och `end`.
        guard let sgIdx = lines.firstIndex(where: { $0.contains("subgraph") }),
              let endRel = lines[(sgIdx + 1)...].firstIndex(where: {
                  $0.trimmingCharacters(in: .whitespaces) == "end" }) else {
            return XCTFail("hittar inget subgraph-block")
        }
        let members = lines[(sgIdx + 1)..<endRel]
            .map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        XCTAssertEqual(members, [barnId],
                       "subgraph ska ha EXAKT det explicita barnet som medlem (UX-110)")
        XCTAssertFalse(members.contains(strayId),
                       "STRAY ligger på containern men är inte barn — får inte stå i subgraph (UX-110)")
    }

    // MARK: - A1.4c MB steg 6: tabell/länk överlever REN mermaid (utan state-JSON)

    /// Tabellen ska behålla sin typ OCH sina celler även när bara mermaid-texten finns
    /// (Claude→Kim-riktningen). Utan fixen blir den en rektangel och cellerna tappas.
    func test_fallback_tablePreservesTypeAndCells() throws {
        var t = ShapeNode(type: .table, position: CGPoint(x: 400, y: 400), label: "Tab",
                          tableRows: 2, tableCols: 2)
        t.tableCells = [["a", "b"], ["c", "d"]]
        let mermaid = MermaidGenerator.generate(shapes: [t], edges: [], specType: .general)
        let parsed = MermaidParser.parse("```mermaid\n\(mermaid)\n```")  // ren mermaid (fence, ingen state-JSON)
        let p = parsed.shapes.first { $0.label == "Tab" }
        XCTAssertEqual(p?.type, .table, "tabell-typ ska överleva ren mermaid")
        XCTAssertEqual(p?.tableCells, [["a", "b"], ["c", "d"]], "tabellceller ska överleva ren mermaid")
    }

    /// Jump-länken ska behålla typen `.link` i ren mermaid — annars hittar `partnerLink`
    /// inte partnern (kräver `.type == .link`) och förflyttningen dör.
    func test_fallback_linkPreservesType() throws {
        var l = ShapeNode(type: .link, position: CGPoint(x: 300, y: 300), label: "Hopp")
        l.linkNumber = 1
        let mermaid = MermaidGenerator.generate(shapes: [l], edges: [], specType: .general)
        let parsed = MermaidParser.parse("```mermaid\n\(mermaid)\n```")  // ren mermaid (fence, ingen state-JSON)
        let p = parsed.shapes.first { $0.label == "Hopp" }
        XCTAssertEqual(p?.type, .link, "länk-typ ska överleva ren mermaid (annars dör jump)")
        XCTAssertEqual(p?.linkNumber, 1, "länk-nummer ska överleva")
    }

    /// En kollapsad gren ska förbli kollapsad även i ren mermaid (Claude→Kim).
    func test_fallback_collapsedBranchSurvives() throws {
        let a = ShapeNode(type: .circle, position: CGPoint(x: 200, y: 300), label: "A")
        let b = ShapeNode(type: .rectangle, position: CGPoint(x: 500, y: 300), label: "B")
        let e = EdgeConnection(from: a.id, to: b.id)
        let mermaid = MermaidGenerator.generate(shapes: [a, b], edges: [e],
                                                specType: .general, collapsedEdgeIds: [e.id])
        let parsed = MermaidParser.parse("```mermaid\n\(mermaid)\n```")
        XCTAssertEqual(parsed.collapsedEdgeIds.count, 1, "kollapsad gren ska överleva ren mermaid")
        let collapsed = parsed.edges.first { parsed.collapsedEdgeIds.contains($0.id) }
        XCTAssertEqual(parsed.shapes.first { $0.id == collapsed?.from }?.label, "A")
        XCTAssertEqual(parsed.shapes.first { $0.id == collapsed?.to }?.label, "B")
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

    // MARK: - F1: icke-heltalsposition round-trippar EXAKT via state-JSON (Kims kopiera→klistra)

    /// Före F1 avrundades position till heltal i state-JSON (321,7 → 322). Garantin
    /// "rita → kopiera → radera → klistra → exakt samma, noll avvikelse" kräver full precision.
    func test_nonIntegerPosition_exactRoundTrip() throws {
        let s = ShapeNode(type: .rectangle, position: CGPoint(x: 321.7, y: 88.42), label: "Sub")
        let parsed = roundTrip([s], [])
        let p = parsed.shapes.first
        XCTAssertEqual(p?.position.x ?? 0, 321.7, accuracy: 0.0001, "x ska round-trippa exakt (ingen Int-avrundning)")
        XCTAssertEqual(p?.position.y ?? 0, 88.42, accuracy: 0.0001, "y ska round-trippa exakt")
    }

    // MARK: - F2: VARJE formtyp behåller sin IDENTITET i REN mermaid (utan state-JSON)

    /// Lager 2 (andra som läser min mermaid): ingen formtyp får degradera tyst till rektangel
    /// när bara mermaid-kroppen finns. Före F2 tappade square/processArrow/octagon/line/arrow
    /// sin identitet här (saknade %% shape-type → blev rektanglar).
    func test_fallback_everyShapeType_identitySurvives() throws {
        for (i, t) in ShapeType.allCases.enumerated() {
            var s = ShapeNode(type: t, position: CGPoint(x: 300 + i * 60, y: 300), label: "T\(i)")
            if t == .table { s.tableRows = 2; s.tableCols = 2 }
            if t == .line || t == .arrow { s.lineEnd = CGPoint(x: 60, y: 0) }
            let mermaid = MermaidGenerator.generate(shapes: [s], edges: [], specType: .general)
            let parsed = MermaidParser.parse("```mermaid\n\(mermaid)\n```")  // ingen state-JSON
            let p = parsed.shapes.first { $0.label == "T\(i)" }
            XCTAssertEqual(p?.type, t, "formtyp \(t) ska överleva ren mermaid (inte degradera till rektangel)")
        }
    }

    // MARK: - F2: justering + listor + indrag överlever REN mermaid

    /// Före F2 fanns dessa bara som CSS/state-JSON → tappades tyst i ren-mermaid-fallbacken.
    func test_fallback_textFormattingSurvives() throws {
        var s = ShapeNode(type: .rectangle, position: CGPoint(x: 400, y: 400), label: "Fmt")
        s.textAlignment = .trailing
        s.hasBullets = true
        s.hasNumberedList = true
        s.indentLevel = 2
        let mermaid = MermaidGenerator.generate(shapes: [s], edges: [], specType: .general)
        let parsed = MermaidParser.parse("```mermaid\n\(mermaid)\n```")
        let p = parsed.shapes.first { $0.label == "Fmt" }
        XCTAssertEqual(p?.textAlignment, .trailing, "justering ska överleva ren mermaid")
        XCTAssertEqual(p?.hasBullets, true, "punktlista ska överleva ren mermaid")
        XCTAssertEqual(p?.hasNumberedList, true, "numrerad lista ska överleva ren mermaid")
        XCTAssertEqual(p?.indentLevel, 2, "indrag ska överleva ren mermaid")
    }

    // MARK: - F2 (steg 8 2g): container-anteckning + prompt överlever REN mermaid

    /// Luckan: noderna skrev %% note, containrarna gjorde inte → skill-containerns
    /// anteckning tappades i ren mermaid. Nu skriver + läser vi den.
    func test_fallback_containerNoteSurvives() throws {
        var box = ShapeNode(type: .container, position: CGPoint(x: 500, y: 500), label: "Skill")
        box.note = "skissanteckning"
        box.prompt = "container-prompt"
        let child = ShapeNode(type: .rectangle, position: CGPoint(x: 480, y: 520),
                              label: "Barn", childOfContainerId: box.id)
        let mermaid = MermaidGenerator.generate(shapes: [box, child], edges: [], specType: .general)
        let parsed = MermaidParser.parse("```mermaid\n\(mermaid)\n```")
        let p = parsed.shapes.first { $0.label == "Skill" }
        XCTAssertEqual(p?.note, "skissanteckning", "container-anteckning ska överleva ren mermaid")
        XCTAssertEqual(p?.prompt, "container-prompt", "container-prompt ska överleva ren mermaid")
    }

    // MARK: - F2: edge-waypoints överlever REN mermaid (fallbacken kastade dem förr)

    func test_fallback_edgeWaypointsSurvive() throws {
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: 200, y: 300), label: "A")
        let b = ShapeNode(type: .rectangle, position: CGPoint(x: 700, y: 300), label: "B")
        var e = EdgeConnection(from: a.id, to: b.id, label: "väg")
        e.waypoints = [EdgeWaypoint(x: 400, y: 360), EdgeWaypoint(x: 550, y: 240)]
        let mermaid = MermaidGenerator.generate(shapes: [a, b], edges: [e], specType: .general)
        let parsed = MermaidParser.parse("```mermaid\n\(mermaid)\n```")
        XCTAssertEqual(parsed.edges.first?.waypoints.count, 2, "waypoints ska överleva ren mermaid")
        XCTAssertEqual(parsed.edges.first?.waypoints.first?.x ?? 0, 400, accuracy: 0.5)
        XCTAssertEqual(parsed.edges.first?.waypoints.first?.y ?? 0, 360, accuracy: 0.5)
    }

    // MARK: - F7: filen ÄR sanningen — parsern kapar inte tyst (Kims beslut)

    /// Före F7 kapade parsern tyst: storlek→3×, bredd/höjd→10×, rotation→±360, indrag→2.
    /// Appen tillåter större (grupp-resize, indrag-knappen) → tyst krympning vid round-trip.
    /// Nu round-trippar extremvärden EXAKT via state-JSON.
    func test_noSilentClamp_extremeValues_roundTrip() throws {
        var s = ShapeNode(type: .rectangle, position: CGPoint(x: 400, y: 400), label: "Stor")
        s.sizeMultiplier = 5.0
        s.widthMultiplier = 12.0
        s.heightMultiplier = 8.5
        s.rotation = 400
        s.indentLevel = 3
        let parsed = roundTrip([s], [])
        let p = parsed.shapes.first
        XCTAssertEqual(p?.sizeMultiplier ?? 0, 5.0, accuracy: 0.0001, "storlek får inte kapas till 3×")
        XCTAssertEqual(p?.widthMultiplier ?? 0, 12.0, accuracy: 0.0001, "bredd får inte kapas till 10×")
        XCTAssertEqual(p?.heightMultiplier ?? 0, 8.5, accuracy: 0.0001)
        XCTAssertEqual(p?.rotation ?? 0, 400, accuracy: 0.0001, "rotation får inte kapas till 360")
        XCTAssertEqual(p?.indentLevel, 3, "indrag 3 får inte kapas till 2")
    }

    // MARK: - F7: container bär ALLA style-fält i ren mermaid (inte bara note/prompt)

    /// Före F7 tappade en färgad/roterad/stor/stylad skill-container allt det i ren mermaid
    /// (nod-loopen hoppar över containrar → de %%-raderna skrevs aldrig).
    func test_fallback_containerStyleFieldsSurvive() throws {
        var box = ShapeNode(type: .container, position: CGPoint(x: 500, y: 500), label: "Skill")
        box.colorOverride = "#ff8800"
        box.strokeColorOverride = "#003366"
        box.colorPackId = "blå"
        box.textStyle = .r1
        box.textAlignment = .trailing
        box.hasBullets = true
        box.hasNumberedList = true
        box.indentLevel = 1
        box.rotation = 15
        box.sizeMultiplier = 1.4
        box.showLabel = false
        let child = ShapeNode(type: .rectangle, position: CGPoint(x: 480, y: 520),
                              label: "Barn", childOfContainerId: box.id)
        let mermaid = MermaidGenerator.generate(shapes: [box, child], edges: [], specType: .general)
        let parsed = MermaidParser.parse("```mermaid\n\(mermaid)\n```")  // ren mermaid, ingen state-JSON
        let p = parsed.shapes.first { $0.label == "Skill" }
        XCTAssertEqual(p?.colorOverride, "#ff8800", "container-färg ska överleva ren mermaid")
        XCTAssertEqual(p?.strokeColorOverride, "#003366")
        XCTAssertEqual(p?.colorPackId, "blå")
        XCTAssertEqual(p?.textStyle, .r1)
        XCTAssertEqual(p?.textAlignment, .trailing)
        XCTAssertEqual(p?.hasBullets, true)
        XCTAssertEqual(p?.hasNumberedList, true)
        XCTAssertEqual(p?.showLabel, false, "hidden-label ska överleva ren mermaid")
        XCTAssertEqual(p?.indentLevel, 1)
        XCTAssertEqual(p?.rotation ?? 0, 15, accuracy: 0.5, "rot avrundas till heltal i %%")
        XCTAssertEqual(p?.sizeMultiplier ?? 0, 1.4, accuracy: 0.05, "size skrivs med 1 decimal i %%")
    }
}
