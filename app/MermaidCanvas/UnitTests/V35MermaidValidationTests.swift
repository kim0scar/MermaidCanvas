import XCTest
import CoreGraphics
@testable import MermaidCanvas

/// v35: validerar mermaid-export för alla 9 shape-typer + svåra labels
/// (åäö, emoji, mellanslag, citationstecken) + edges-med-labels + round-trip.
///
/// Detta är "trygghetsnätet" som garanterar att Kims canvas-filer ALDRIG
/// genererar ogiltig mermaid när en form innehåller åäö eller emoji.
final class V35MermaidValidationTests: XCTestCase {

    // MARK: - 1. Alla shape-typer → korrekt mermaid-syntax (v36.1: 11 typer, chevron+triangel borttagna)

    func testGenerator_AllNineShapeTypes_ProducesValidSyntax() throws {
        // v44: .text borttagen, .container tillagd
        let shapes: [ShapeNode] = [
            ShapeNode(type: .circle,       position: CGPoint(x: 100, y: 100), label: "Cirkel"),
            ShapeNode(type: .rectangle,    position: CGPoint(x: 200, y: 100), label: "Rektangel"),
            ShapeNode(type: .diamond,      position: CGPoint(x: 300, y: 100), label: "Diamant"),
            ShapeNode(type: .pill,         position: CGPoint(x: 400, y: 100), label: "Pill"),
            ShapeNode(type: .table,        position: CGPoint(x: 600, y: 100), label: "Tabell",
                      tableRows: 3, tableCols: 4),
            ShapeNode(type: .link,         position: CGPoint(x: 700, y: 100), label: "Länk",
                      linkNumber: 1),
            ShapeNode(type: .line,         position: CGPoint(x: 800, y: 100), label: "Linje",
                      lineEnd: CGPoint(x: 50, y: 50)),
            ShapeNode(type: .arrow,        position: CGPoint(x: 900, y: 100), label: "Pil",
                      lineEnd: CGPoint(x: 50, y: 50)),
            // v35.1/v36 grundformer (triangle och chevron borttagna — fungerar ej i Mermaid)
            ShapeNode(type: .square,       position: CGPoint(x: 1000, y: 100), label: "Fyrkant"),
            ShapeNode(type: .processArrow, position: CGPoint(x: 1100, y: 100), label: "Processpil"),
            // v44 — container (subgraph i Mermaid)
            ShapeNode(type: .container,    position: CGPoint(x: 1200, y: 100), label: "Container"),
            // v51.1 — åttahörning (Mermaid-fallback = rundad rektangel; round-trip via state-JSON)
            ShapeNode(type: .octagon,      position: CGPoint(x: 1300, y: 100), label: "Åttahörning")
        ]
        XCTAssertEqual(shapes.count, ShapeType.allCases.count, "Testet ska täcka alla ShapeType-fall")
        // Sanity check: alla ShapeType-fall ska finnas representerade
        let coveredTypes = Set(shapes.map { $0.type })
        XCTAssertEqual(coveredTypes.count, ShapeType.allCases.count,
                       "Testet ska täcka alla \(ShapeType.allCases.count) ShapeType-fall i enumet")

        let mermaid = MermaidGenerator.generate(
            shapes: shapes,
            edges: [],
            canvasSize: CGSize(width: 1200, height: 600),
            specType: .general
        )

        // v38: output börjar med init-direktiv för kurvor, sedan flowchart TD
        XCTAssertTrue(mermaid.contains("flowchart TD"),
                      "Mermaid-output ska innehålla 'flowchart TD'")

        // Varje form-typ har ett specifikt syntax-mönster i mermaid-grammatiken.
        // Vi vet att labels är giltiga unika strängar — så vi söker efter dem
        // omslutna av rätt avgränsare.
        let circleSyntax = "((\"Cirkel\"))"
        let rectSyntax = "(\"Rektangel\")"  // v35.1: rundade hörn
        let diamondSyntax = "{\"Diamant\"}"
        let pillSyntax = "([\"Pill\"])"
        let tableSyntax = "[\"Tabell\"]"
        let linkSyntax = "((\"Länk\"))"
        let lineSyntax = "[\"Linje\"]"
        let arrowSyntax = "[\"Pil\"]"

        XCTAssertTrue(mermaid.contains(circleSyntax), "Cirkel-syntax saknas: '\(circleSyntax)'")
        XCTAssertTrue(mermaid.contains(rectSyntax), "Rektangel-syntax saknas: '\(rectSyntax)'")
        XCTAssertTrue(mermaid.contains(diamondSyntax), "Diamant-syntax saknas: '\(diamondSyntax)'")
        XCTAssertTrue(mermaid.contains(pillSyntax), "Pill-syntax saknas: '\(pillSyntax)'")
        XCTAssertTrue(mermaid.contains(tableSyntax), "Tabell-syntax saknas: '\(tableSyntax)'")
        XCTAssertTrue(mermaid.contains(linkSyntax), "Länk-syntax saknas: '\(linkSyntax)'")
        XCTAssertTrue(mermaid.contains(lineSyntax), "Line-syntax saknas: '\(lineSyntax)'")
        XCTAssertTrue(mermaid.contains(arrowSyntax), "Arrow-syntax saknas: '\(arrowSyntax)'")
        // v35.1/v36.1: grundformer — renderas med [...] i Mermaid. Triangel+Chevron borttagna.
        XCTAssertTrue(mermaid.contains("\"Fyrkant\""), "Fyrkant-label saknas i output")
        XCTAssertTrue(mermaid.contains("\"Processpil\""), "Processpil-label saknas i output")
        // v44: container renderas som subgraph
        XCTAssertTrue(mermaid.contains("\"Container\""), "Container-label saknas i output")
        // v51.1: åttahörning
        XCTAssertTrue(mermaid.contains("\"Åttahörning\""), "Åttahörning-label saknas i output")

        // Tabell-metadata ska finnas som mermaid-kommentar
        XCTAssertTrue(mermaid.contains("table: 3×4"),
                      "Tabell-rader/-kolumner ska sparas som mermaid-kommentar")

        // Link-nummer ska finnas som mermaid-kommentar
        XCTAssertTrue(mermaid.contains("link: 1"),
                      "Link-nummer ska sparas som mermaid-kommentar")

        // Varje shape ska ha en position-kommentar
        let posLines = mermaid.split(separator: "\n").filter { $0.contains("pos:") }
        XCTAssertEqual(posLines.count, ShapeType.allCases.count,
                       "Alla \(ShapeType.allCases.count) former ska ha 'pos:'-kommentar (en per form)")
    }

    // MARK: - 2. Svåra labels: åäö + emoji + mellanslag + citationstecken

    func testGenerator_LabelsWithSwedishChars_RoundTripsCleanly() throws {
        let labels = [
            "åäö ÅÄÖ",
            "Hejsan",
            "Skärm för köp",
            "ÄPPLE & PÄRON",
        ]
        var shapes: [ShapeNode] = []
        for (i, label) in labels.enumerated() {
            shapes.append(ShapeNode(type: .rectangle,
                                    position: CGPoint(x: 100 + CGFloat(i) * 150, y: 200),
                                    label: label))
        }
        let doc = CanvasDocument(
            title: "Åäö-test",
            shapes: shapes,
            edges: [],
            canvasSize: CGSize(width: 800, height: 600),
            specType: .general,
            platform: .blank,
            activeShapePacks: [.basic],
            collapsedIds: []
        )
        let parsed = MermaidParser.parse(doc.content)
        XCTAssertEqual(parsed.shapes.count, labels.count,
                       "Alla shapes med åäö-labels ska bevaras")
        for (i, expected) in labels.enumerated() {
            XCTAssertEqual(parsed.shapes[i].label, expected,
                           "Label #\(i): åäö ska bevaras exakt — fick '\(parsed.shapes[i].label)'")
        }
    }

    func testGenerator_LabelsWithEmoji_RoundTripsCleanly() throws {
        let emojiLabels = [
            "Start ▶️",
            "Klar ✅",
            "Hej 🎉 där",
            "🔵 cirkel"
        ]
        var shapes: [ShapeNode] = []
        for (i, label) in emojiLabels.enumerated() {
            shapes.append(ShapeNode(type: .circle,
                                    position: CGPoint(x: 100 + CGFloat(i) * 150, y: 200),
                                    label: label))
        }
        let doc = CanvasDocument(
            title: "Emoji-test",
            shapes: shapes,
            edges: [],
            canvasSize: CGSize(width: 800, height: 600),
            specType: .general,
            platform: .blank,
            activeShapePacks: [.basic],
            collapsedIds: []
        )
        let parsed = MermaidParser.parse(doc.content)
        XCTAssertEqual(parsed.shapes.count, emojiLabels.count,
                       "Alla shapes med emoji-labels ska bevaras")
        for (i, expected) in emojiLabels.enumerated() {
            XCTAssertEqual(parsed.shapes[i].label, expected,
                           "Label #\(i): emoji ska bevaras exakt — fick '\(parsed.shapes[i].label)'")
        }
    }

    func testGenerator_LabelsWithQuotesAndSpaces_DoesNotBreakSyntax() throws {
        // Citationstecken är det farliga fallet — mermaid använder " som
        // avgränsare. MermaidGenerator escapar dem till #quot;
        let trickyLabels = [
            #"En "citerad" text"#,
            "Flera   mellanslag",
            "Tab\tinuti",
            "Slash / och pipe |",
        ]
        var shapes: [ShapeNode] = []
        for (i, label) in trickyLabels.enumerated() {
            shapes.append(ShapeNode(type: .rectangle,
                                    position: CGPoint(x: 100 + CGFloat(i) * 150, y: 200),
                                    label: label))
        }
        let doc = CanvasDocument(
            title: "Tricky-test",
            shapes: shapes,
            edges: [],
            canvasSize: CGSize(width: 800, height: 600),
            specType: .general,
            platform: .blank,
            activeShapePacks: [.basic],
            collapsedIds: []
        )
        let parsed = MermaidParser.parse(doc.content)
        XCTAssertEqual(parsed.shapes.count, trickyLabels.count,
                       "Alla shapes med svåra tecken ska bevaras")

        // Citationstecken specifikt: ska komma tillbaka oförändrade efter round-trip
        XCTAssertEqual(parsed.shapes[0].label, trickyLabels[0],
                       "Citationstecken ska bevaras genom round-trip via #quot;-escape")

        // Mermaid-blocket ska INTE innehålla råa nakna citationstecken
        // i positioner som skulle bryta mermaid-grammatiken
        guard let start = doc.content.range(of: "```mermaid"),
              let end = doc.content.range(of: "```",
                                          range: start.upperBound..<doc.content.endIndex)
        else {
            XCTFail("Mermaid-block saknas i dokumentet")
            return
        }
        let mermaidBlock = String(doc.content[start.upperBound..<end.lowerBound])
        // Inom label-strängarna ska " vara escapade till #quot;
        XCTAssertTrue(mermaidBlock.contains("#quot;"),
                      "Citationstecken ska escapas till #quot; i mermaid-block")
    }

    // MARK: - 3. Edges med labels → korrekt format

    func testGenerator_EdgesWithLabels_ProduceValidSyntax() throws {
        let s1 = ShapeNode(type: .circle, position: CGPoint(x: 100, y: 100), label: "A")
        let s2 = ShapeNode(type: .circle, position: CGPoint(x: 300, y: 100), label: "B")
        let s3 = ShapeNode(type: .circle, position: CGPoint(x: 500, y: 100), label: "C")

        let edges = [
            EdgeConnection(from: s1.id, to: s2.id, label: "godkänner",
                           direction: .forward, style: .solid),
            EdgeConnection(from: s2.id, to: s3.id, label: "skickar till",
                           direction: .bidirectional, style: .dashed),
            EdgeConnection(from: s1.id, to: s3.id, label: "",
                           direction: .forward, style: .solid)
        ]
        let doc = CanvasDocument(
            title: "Edge-label-test",
            shapes: [s1, s2, s3],
            edges: edges,
            canvasSize: CGSize(width: 800, height: 600),
            specType: .general,
            platform: .blank,
            activeShapePacks: [.basic],
            collapsedIds: []
        )

        // Mermaid-block ska innehålla en pipe-omsluten label på minst en edge
        XCTAssertTrue(doc.content.contains(#"|"godkänner"|"#),
                      "Edge-label med åäö ska finnas i mermaid med pipe-syntax")
        XCTAssertTrue(doc.content.contains(#"|"skickar till"|"#),
                      "Edge-label med mellanslag ska finnas i mermaid med pipe-syntax")

        // Round-trip via parser
        let parsed = MermaidParser.parse(doc.content)
        XCTAssertEqual(parsed.edges.count, edges.count,
                       "Alla edges ska bevaras genom round-trip")

        // Hitta varje edge och verifiera labels
        let labels = parsed.edges.map { $0.label }
        XCTAssertTrue(labels.contains("godkänner"),
                      "Edge-label 'godkänner' ska bevaras")
        XCTAssertTrue(labels.contains("skickar till"),
                      "Edge-label 'skickar till' ska bevaras")
        XCTAssertTrue(labels.contains(""),
                      "Edge utan label ska behålla tom string")

        // Styles ska bevaras
        XCTAssertTrue(parsed.edges.contains { $0.style == .solid },
                      "Solid edge-style ska bevaras")
        XCTAssertTrue(parsed.edges.contains { $0.style == .dashed },
                      "Dashed edge-style ska bevaras")
        XCTAssertTrue(parsed.edges.contains { $0.direction == .bidirectional },
                      "Bidirectional edge ska bevaras")
    }

    // MARK: - 4. Round-trip: position, label, category, colorPackId

    func testRoundTrip_PreservesAllShapeMetadata() throws {
        // En noggrann blandning av former med olika metadata
        let shapes: [ShapeNode] = [
            ShapeNode(type: .circle,
                      position: CGPoint(x: 123, y: 456),
                      label: "Kärnform",
                      showLabel: true,
                      category: .ui,
                      colorPackId: "blue_ocean"),
            ShapeNode(type: .rectangle,
                      position: CGPoint(x: 234, y: 567),
                      label: "Mittruta",
                      category: .note,
                      colorPackId: "sage_pastel"),
            ShapeNode(type: .diamond,
                      position: CGPoint(x: 345, y: 678),
                      label: "Beslut",
                      category: .zone,
                      colorPackId: nil),
            ShapeNode(type: .pill,
                      position: CGPoint(x: 456, y: 789),
                      label: "Status",
                      category: .overlay,
                      colorPackId: "sunset")
        ]

        let doc = CanvasDocument(
            title: "RoundTrip-meta",
            shapes: shapes,
            edges: [],
            canvasSize: CGSize(width: 1000, height: 1000),
            specType: .general,
            platform: .blank,
            activeShapePacks: [.basic, .ui],
            collapsedIds: []
        )

        let parsed = MermaidParser.parse(doc.content)
        XCTAssertEqual(parsed.shapes.count, shapes.count,
                       "Antalet shapes ska bevaras")

        for (i, original) in shapes.enumerated() {
            guard i < parsed.shapes.count else {
                XCTFail("Saknar parsed shape #\(i)")
                continue
            }
            let p = parsed.shapes[i]

            // Position (1pt tolerans pga Int-konvertering i mermaid-kommentar)
            XCTAssertEqual(p.position.x, original.position.x, accuracy: 1.0,
                           "Form #\(i) (\(original.type.rawValue)): position.x ska bevaras")
            XCTAssertEqual(p.position.y, original.position.y, accuracy: 1.0,
                           "Form #\(i) (\(original.type.rawValue)): position.y ska bevaras")

            // Label
            XCTAssertEqual(p.label, original.label,
                           "Form #\(i): label ska bevaras")

            // Type
            XCTAssertEqual(p.type, original.type,
                           "Form #\(i): type ska bevaras")

            // Category
            XCTAssertEqual(p.category, original.category,
                           "Form #\(i): category ska bevaras")

            // colorPackId (nil ska förbli nil)
            XCTAssertEqual(p.colorPackId, original.colorPackId,
                           "Form #\(i): colorPackId ska bevaras (även när nil)")
        }
    }

    func testRoundTrip_PreservesEdgeLabelsAndStyles_FullCycle() throws {
        let a = ShapeNode(type: .circle, position: CGPoint(x: 100, y: 100), label: "A")
        let b = ShapeNode(type: .rectangle, position: CGPoint(x: 300, y: 100), label: "B")
        let c = ShapeNode(type: .diamond, position: CGPoint(x: 500, y: 100), label: "C")

        let edges = [
            EdgeConnection(from: a.id, to: b.id, label: "först",
                           direction: .forward, style: .solid),
            EdgeConnection(from: b.id, to: c.id, label: "sedan",
                           direction: .forward, style: .dashed),
            EdgeConnection(from: c.id, to: a.id, label: "tillbaka 🔄",
                           direction: .bidirectional, style: .solid)
        ]

        // Cycle 1
        let doc1 = CanvasDocument(
            title: "Full-cycle",
            shapes: [a, b, c],
            edges: edges,
            canvasSize: CGSize(width: 800, height: 600),
            specType: .general,
            platform: .blank,
            activeShapePacks: [.basic],
            collapsedIds: []
        )
        let parsed1 = MermaidParser.parse(doc1.content)

        // Cycle 2 — regenerera från parsed
        let doc2 = CanvasDocument(
            title: "Full-cycle",
            shapes: parsed1.shapes,
            edges: parsed1.edges,
            canvasSize: parsed1.canvasSize ?? CGSize(width: 800, height: 600),
            specType: parsed1.specType,
            platform: parsed1.platform ?? .blank,
            activeShapePacks: parsed1.activeShapePacks ?? [.basic],
            collapsedIds: parsed1.collapsedIds
        )
        let parsed2 = MermaidParser.parse(doc2.content)

        // Antal shapes och edges ska överleva två cykler
        XCTAssertEqual(parsed2.shapes.count, 3,
                       "Tre shapes ska finnas efter två round-trip-cykler")
        XCTAssertEqual(parsed2.edges.count, 3,
                       "Tre edges ska finnas efter två round-trip-cykler")

        // Edge-labels ska överleva båda cyklerna (inkl emoji)
        let labels2 = Set(parsed2.edges.map { $0.label })
        XCTAssertTrue(labels2.contains("först"), "Edge-label 'först' ska överleva två cykler")
        XCTAssertTrue(labels2.contains("sedan"), "Edge-label 'sedan' ska överleva två cykler")
        XCTAssertTrue(labels2.contains("tillbaka 🔄"),
                      "Edge-label med emoji ska överleva två cykler")
    }

    // MARK: - 8. Layout hints (v35.1)

    /// Verifierar att osynliga ~~~-layout-hints genereras för ouppkopplade former
    /// i ett 2×2-mönster (Kims rapporterade use-case).
    func testGenerator_LayoutHints_TwoColumnGrid() throws {
        // 4 former i 2×2-arrangemang — exakt som Kims V35 1.md-fil
        // Kolumn 1 (x≈1950): circle (y=1775), rect (y=1922)
        // Kolumn 2 (x≈2060): rect (y=1835), diamond (y=1932)
        let shapes: [ShapeNode] = [
            ShapeNode(type: .circle,    position: CGPoint(x: 1963, y: 1775), label: ""),
            ShapeNode(type: .rectangle, position: CGPoint(x: 2058, y: 1835), label: ""),
            ShapeNode(type: .rectangle, position: CGPoint(x: 1934, y: 1922), label: ""),
            ShapeNode(type: .diamond,   position: CGPoint(x: 2061, y: 1932), label: "")
        ]
        let code = MermaidGenerator.generate(
            shapes: shapes,
            edges: [],
            canvasSize: CGSize(width: 3000, height: 3000),
            specType: .general
        )

        // Ska innehålla ~~~-hints
        XCTAssertTrue(code.contains("~~~"),
                      "Genererad kod ska innehålla ~~~-hints för 2×2-layouten:\n\(code)")

        // Ska innehålla exakt 2 ~~~-hintar (en per kolumn, en länk per kolumn)
        let hintCount = code.components(separatedBy: "~~~").count - 1
        XCTAssertEqual(hintCount, 2,
                       "2×2-grid ska ge exakt 2 ~~~-hintar (en per kolumn), fick \(hintCount):\n\(code)")

        // Kolumn 1: circle (N0) ovanför rect (N2) → ui_N0 ~~~ ui_N2
        // Kolumn 2: rect (N1) ovanför diamond (N3) → ui_N1 ~~~ ui_N3
        // (ordning baseras på shapes-index, kategori="ui")
        XCTAssertTrue(code.contains("ui_N0 ~~~ ui_N2"),
                      "Kolumn 1: circle ska vara ovanför rect (ui_N0 ~~~ ui_N2):\n\(code)")
        XCTAssertTrue(code.contains("ui_N1 ~~~ ui_N3"),
                      "Kolumn 2: rect ska vara ovanför diamond (ui_N1 ~~~ ui_N3):\n\(code)")
    }

    /// Verifierar att ~~~-hints INTE genereras när det finns kanter —
    /// kanterna definierar redan strukturen.
    func testGenerator_LayoutHints_SkippedWhenEdgesExist() throws {
        let shapes: [ShapeNode] = [
            ShapeNode(type: .circle,    position: CGPoint(x: 100, y: 100), label: "A"),
            ShapeNode(type: .rectangle, position: CGPoint(x: 300, y: 400), label: "B")
        ]
        let edges = [
            EdgeConnection(from: shapes[0].id, to: shapes[1].id,
                           label: "", direction: .forward, style: .solid)
        ]
        let code = MermaidGenerator.generate(
            shapes: shapes,
            edges: edges,
            canvasSize: CGSize(width: 800, height: 600),
            specType: .general
        )

        XCTAssertFalse(code.contains("~~~"),
                       "Ska INTE innehålla ~~~-hints när kanter finns:\n\(code)")
    }

    /// Verifierar att colorOverride genererar en Mermaid style-tag med fill-färg
    /// (inte bara en %%-kommentar) — så färgen syns i alla Mermaid-renderare.
    func testGenerator_ColorOverride_ProducesStyleTag() throws {
        let shapes: [ShapeNode] = [
            ShapeNode(type: .circle,    position: CGPoint(x: 100, y: 200),
                      label: "Röd",  colorOverride: "#FF5500"),
            ShapeNode(type: .rectangle, position: CGPoint(x: 300, y: 200),
                      label: "Normal") // ingen colorOverride
        ]
        let code = MermaidGenerator.generate(
            shapes: shapes,
            edges: [],
            canvasSize: CGSize(width: 800, height: 600),
            specType: .general
        )

        // Röd nod ska ha fill-style
        XCTAssertTrue(code.contains("style ui_N0") && code.contains("fill:#FF5500"),
                      "colorOverride ska generera fill-style:\n\(code)")
        // Normal nod ska INTE ha style-tag (ingen size, ingen color)
        XCTAssertFalse(code.contains("style ui_N1"),
                       "Nod utan colorOverride/size ska inte ha style-tag:\n\(code)")
    }

    /// v44: .text-formen är borttagen — alla former kan ha label.
    /// Testet hålls kvar som no-op markör så test-räkning är stabil; verifierar
    /// bara att ShapeType.text inte längre finns i enumet.
    func testGenerator_TextShape_RemovedInV44() throws {
        let allRaw = ShapeType.allCases.map { $0.rawValue }
        XCTAssertFalse(allRaw.contains("text"),
                       ".text ska inte längre vara en giltig ShapeType i v44 (\(allRaw))")
    }

    /// Verifierar att lineEnd för lösa linjer/pilar round-trippar via JSON-state.
    func testRoundTrip_LineEnd_Preserved() throws {
        let startPos = CGPoint(x: 500, y: 600)
        let endOffset = CGPoint(x: 150, y: -80)
        let shape = ShapeNode(
            type: .arrow,
            position: startPos,
            label: "Fri pil",
            lineEnd: endOffset
        )
        let doc = CanvasDocument(
            title: "LineEnd-test",
            shapes: [shape],
            edges: [],
            canvasSize: CGSize(width: 1000, height: 1000),
            specType: .general,
            platform: .blank,
            activeShapePacks: [.basic],
            collapsedIds: []
        )
        let parsed = MermaidParser.parse(doc.content)

        XCTAssertEqual(parsed.shapes.count, 1, "En shape ska finnas efter round-trip")
        let restored = try XCTUnwrap(parsed.shapes.first)
        XCTAssertNotNil(restored.lineEnd, "lineEnd ska bevaras efter round-trip")
        let le = try XCTUnwrap(restored.lineEnd)
        XCTAssertEqual(le.x, endOffset.x, accuracy: 1.0, "lineEnd.x ska stämma")
        XCTAssertEqual(le.y, endOffset.y, accuracy: 1.0, "lineEnd.y ska stämma")

        // Mermaid-koden ska också ha ett line-end-kommentar (absolutposition)
        XCTAssertTrue(doc.content.contains("line-end:"),
                      "Mermaid-kod ska innehålla %% line-end-kommentar:\n\(doc.content)")
    }

    /// Verifierar att widthMultiplier + heightMultiplier round-trippar via JSON-state.
    /// v46: numrering + indrag + tabell-celler ska round-trippa.
    func testRoundTrip_v46Fields_Preserved() throws {
        let listShape = ShapeNode(
            type: .rectangle,
            position: CGPoint(x: 100, y: 100),
            label: "Punkt 1\nPunkt 2\nPunkt 3",
            hasNumberedList: true,
            indentLevel: 2
        )
        let tableShape = ShapeNode(
            type: .table,
            position: CGPoint(x: 400, y: 100),
            label: "Tabell",
            tableRows: 2,
            tableCols: 2,
            tableCells: [["A", "B"], ["C", "D"]]
        )
        let doc = CanvasDocument(
            title: "v46-fields",
            shapes: [listShape, tableShape],
            edges: [],
            canvasSize: CGSize(width: 1000, height: 1000),
            specType: .general,
            platform: .blank,
            activeShapePacks: [.basic],
            collapsedIds: []
        )
        let parsed = MermaidParser.parse(doc.content)
        XCTAssertEqual(parsed.shapes.count, 2)
        let restoredList  = try XCTUnwrap(parsed.shapes.first { $0.type == .rectangle })
        let restoredTable = try XCTUnwrap(parsed.shapes.first { $0.type == .table })
        XCTAssertTrue(restoredList.hasNumberedList, "hasNumberedList ska bevaras")
        XCTAssertEqual(restoredList.indentLevel, 2, "indentLevel ska bevaras")
        XCTAssertEqual(restoredTable.tableCells?.count, 2, "tableCells rader ska bevaras")
        XCTAssertEqual(restoredTable.tableCells?[0], ["A", "B"], "tableCells första raden")
        XCTAssertEqual(restoredTable.tableCells?[1], ["C", "D"], "tableCells andra raden")
    }

    func testRoundTrip_WidthHeightMultiplier_Preserved() throws {
        let shape = ShapeNode(
            type: .rectangle,
            position: CGPoint(x: 300, y: 300),
            label: "Bred ruta",
            sizeMultiplier: 1.0,
            widthMultiplier: 2.5,
            heightMultiplier: 0.6
        )
        let doc = CanvasDocument(
            title: "WidthHeight-test",
            shapes: [shape],
            edges: [],
            canvasSize: CGSize(width: 1000, height: 1000),
            specType: .general,
            platform: .blank,
            activeShapePacks: [.basic],
            collapsedIds: []
        )
        let parsed = MermaidParser.parse(doc.content)

        XCTAssertEqual(parsed.shapes.count, 1)
        let restored = try XCTUnwrap(parsed.shapes.first)
        XCTAssertNotNil(restored.widthMultiplier,  "widthMultiplier ska bevaras")
        XCTAssertNotNil(restored.heightMultiplier, "heightMultiplier ska bevaras")
        XCTAssertEqual(Double(restored.widthMultiplier  ?? 0), 2.5, accuracy: 0.01)
        XCTAssertEqual(Double(restored.heightMultiplier ?? 0), 0.6, accuracy: 0.01)
    }

    /// Verifierar att storleks-variation genererar Mermaid style-taggar
    /// med skalad font-size så att noder ser relativt stora/små ut.
    func testGenerator_SizeVariation_ProducesStyleTags() throws {
        let shapes: [ShapeNode] = [
            ShapeNode(type: .circle,    position: CGPoint(x: 100, y: 200),
                      label: "Liten",  sizeMultiplier: 0.5),
            ShapeNode(type: .rectangle, position: CGPoint(x: 300, y: 200),
                      label: "Normal", sizeMultiplier: 1.0),   // ingen style-tag
            ShapeNode(type: .diamond,   position: CGPoint(x: 500, y: 200),
                      label: "Stor",   sizeMultiplier: 2.0)
        ]
        let code = MermaidGenerator.generate(
            shapes: shapes,
            edges: [],
            canvasSize: CGSize(width: 800, height: 600),
            specType: .general
        )

        // Liten nod (0.5) ska ha style-tag med liten font (min 8px)
        XCTAssertTrue(code.contains("style ui_N0 font-size:8px"),
                      "Liten nod (0.5×) ska ha style-tag:\n\(code)")

        // Normal nod (1.0) ska INTE ha style-tag
        XCTAssertFalse(code.contains("style ui_N1"),
                       "Normal nod (1.0×) ska inte ha style-tag:\n\(code)")

        // Stor nod (2.0) ska ha style-tag med stor font
        XCTAssertTrue(code.contains("style ui_N2 font-size:28px"),
                      "Stor nod (2.0×) ska ha style-tag:\n\(code)")
    }

    /// Verifierar att shapes i en enda kolumn (alla ungefär samma X)
    /// får en vertikal kedja av ~~~-hintar.
    func testGenerator_LayoutHints_SingleColumnChain() throws {
        let shapes: [ShapeNode] = [
            ShapeNode(type: .circle,    position: CGPoint(x: 500, y: 100), label: "Top"),
            ShapeNode(type: .rectangle, position: CGPoint(x: 510, y: 300), label: "Mid"),
            ShapeNode(type: .diamond,   position: CGPoint(x: 495, y: 500), label: "Bot")
        ]
        let code = MermaidGenerator.generate(
            shapes: shapes,
            edges: [],
            canvasSize: CGSize(width: 800, height: 600),
            specType: .general
        )

        // En kolumn med 3 shapes → 2 ~~~-hintar (top→mid, mid→bot)
        let hintCount = code.components(separatedBy: "~~~").count - 1
        XCTAssertEqual(hintCount, 2,
                       "3 shapes i en kolumn ska ge 2 ~~~-hintar, fick \(hintCount):\n\(code)")

        // Vertikal ordning: top (y=100) → mid (y=300) → bot (y=500)
        // shapes-index: circle=N0, rect=N1, diamond=N2
        XCTAssertTrue(code.contains("ui_N0 ~~~ ui_N1"),
                      "Top → Mid:\n\(code)")
        XCTAssertTrue(code.contains("ui_N1 ~~~ ui_N2"),
                      "Mid → Bot:\n\(code)")
    }

    /// Verifierar att colorPackId → inline style fill:X i Mermaid-export,
    /// så att pastellfärgerna syns i alla Mermaid-renderare och inte döljs
    /// av classDef:s vita fyllning.
    func testGenerator_ColorPack_ProducesStyleFill() throws {
        let shapes: [ShapeNode] = [
            ShapeNode(type: .diamond, position: CGPoint(x: 100, y: 200),
                      label: "Lila",  colorPackId: "lila"),
            ShapeNode(type: .diamond, position: CGPoint(x: 300, y: 200),
                      label: "Rosa",  colorPackId: "rosa"),
            ShapeNode(type: .circle,  position: CGPoint(x: 500, y: 200),
                      label: "Ingen") // ingen pack
        ]
        let code = MermaidGenerator.generate(
            shapes: shapes, edges: [],
            canvasSize: CGSize(width: 800, height: 600), specType: .general
        )

        // Lila pack → fill:#ecdfff
        XCTAssertTrue(code.contains("fill:#ecdfff"),
                      "Lila colorPack ska ge fill:#ecdfff:\n\(code)")
        // Rosa pack → fill:#ffe5ec
        XCTAssertTrue(code.contains("fill:#ffe5ec"),
                      "Rosa colorPack ska ge fill:#ffe5ec:\n\(code)")
        // Ingen pack → ingen style-tag för den noden (N2 har ingen size/color)
        XCTAssertFalse(code.contains("style ui_N2"),
                       "Nod utan pack ska inte ha style-tag:\n\(code)")
    }

    /// Verifierar att rectangle exporteras med rundade hörn (("label"))
    /// och att fallback-parsern känner igen formatet tillbaka som rectangle.
    func testGenerator_Rectangle_RoundedCornerSyntax() throws {
        let shape = ShapeNode(type: .rectangle, position: CGPoint(x: 200, y: 200), label: "Hej")
        let code = MermaidGenerator.generate(
            shapes: [shape], edges: [],
            canvasSize: CGSize(width: 600, height: 400), specType: .general
        )

        XCTAssertTrue(code.contains("(\"Hej\")"),
                      "Rectangle ska exporteras med rundade hörn (\"Hej\"):\n\(code)")

        // Fallback-parsern ska läsa tillbaka ("Hej") som rectangle.
        // parseMermaid kräver ```mermaid```-wrapper — generatorn ger bara raw-kod,
        // så vi lindar in den manuellt för att testa fallback-stigen.
        let wrapped = "```mermaid\n\(code)\n```"
        let parsed = MermaidParser.parse(wrapped)
        XCTAssertEqual(parsed.shapes.count, 1, "Parsern ska hitta 1 shape:\n\(wrapped)")
        XCTAssertEqual(parsed.shapes.first?.type, .rectangle,
                       "Parsern ska identifiera formen som rectangle:\n\(wrapped)")
    }

    // MARK: - v47: textAlignment som CSS i mermaid-export

    /// v47: textAlignment .leading och .trailing ska resultera i CSS
    /// `text-align:left` resp `text-align:right` i style-raden. .center är default
    /// och hoppas över.
    func testGenerator_TextAlignment_ProducesCSS() throws {
        let leftShape = ShapeNode(type: .rectangle,
                                  position: CGPoint(x: 100, y: 100),
                                  label: "vänster",
                                  textAlignment: .leading)
        let centerShape = ShapeNode(type: .rectangle,
                                    position: CGPoint(x: 300, y: 100),
                                    label: "mitt",
                                    textAlignment: .center)
        let rightShape = ShapeNode(type: .rectangle,
                                   position: CGPoint(x: 500, y: 100),
                                   label: "höger",
                                   textAlignment: .trailing)
        let code = MermaidGenerator.generate(
            shapes: [leftShape, centerShape, rightShape],
            edges: [],
            canvasSize: CGSize(width: 600, height: 400),
            specType: .general
        )
        // Räkna förekomster — bara leading + trailing ska ge text-align-rader.
        let leftCount  = code.components(separatedBy: "text-align:left").count - 1
        let rightCount = code.components(separatedBy: "text-align:right").count - 1
        let centerCount = code.components(separatedBy: "text-align:center").count - 1

        XCTAssertEqual(leftCount, 1, "leading-form ska ge en text-align:left-rad:\n\(code)")
        XCTAssertEqual(rightCount, 1, "trailing-form ska ge en text-align:right-rad:\n\(code)")
        XCTAssertEqual(centerCount, 0, "center är default och ska inte producera CSS:\n\(code)")
    }

    /// v47: container-child explicit-koppling — `childOfContainerId` round-trippar
    /// via canvasStateJSON som mermaid-id-sträng.
    func testRoundTrip_ChildOfContainer_Preserved() throws {
        let containerId = UUID()
        let container = ShapeNode(id: containerId, type: .container,
                                  position: CGPoint(x: 300, y: 300),
                                  label: "Grupp")
        let child = ShapeNode(type: .rectangle,
                              position: CGPoint(x: 300, y: 300),
                              label: "Barn",
                              childOfContainerId: containerId)
        let orphan = ShapeNode(type: .circle,
                               position: CGPoint(x: 800, y: 800),
                               label: "Fri")
        let doc = CanvasDocument(
            title: "v47-childOfContainer",
            shapes: [container, child, orphan], edges: [],
            canvasSize: CGSize(width: 1200, height: 1200),
            specType: .general, platform: .blank,
            activeShapePacks: [.basic], collapsedIds: []
        )
        XCTAssertTrue(doc.content.contains("\"childOfContainerId\""),
                      "Dokumentet ska innehålla childOfContainerId-nyckel.")
        let parsed = MermaidParser.parse(doc.content)
        XCTAssertEqual(parsed.shapes.count, 3, "Round-trip ska bevara 3 noder")
        let parsedContainer = parsed.shapes.first(where: { $0.type == .container })
        let parsedChild     = parsed.shapes.first(where: { $0.label == "Barn" })
        let parsedOrphan    = parsed.shapes.first(where: { $0.label == "Fri" })
        XCTAssertNotNil(parsedContainer)
        XCTAssertNotNil(parsedChild)
        XCTAssertNotNil(parsedOrphan)
        XCTAssertEqual(parsedChild?.childOfContainerId, parsedContainer?.id,
                       "Barnet ska peka på containerns UUID efter round-trip")
        XCTAssertNil(parsedOrphan?.childOfContainerId,
                     "Fri form ska ha childOfContainerId = nil")
    }

    /// v47: textAlignment round-trippar via canvasStateJSON oavsett vad
    /// styleStmts gör (de är bara för Mermaid Live-rendering).
    func testRoundTrip_TextAlignment_Preserved() throws {
        let original = ShapeNode(type: .rectangle,
                                 position: CGPoint(x: 200, y: 200),
                                 label: "Skev text",
                                 textAlignment: .trailing)
        let doc = CanvasDocument(
            title: "v47-textAlignment",
            shapes: [original], edges: [],
            canvasSize: CGSize(width: 600, height: 400),
            specType: .general, platform: .blank,
            activeShapePacks: [.basic], collapsedIds: []
        )
        let parsed = MermaidParser.parse(doc.content)
        XCTAssertEqual(parsed.shapes.count, 1, "Round-trip ska bevara 1 form")
        XCTAssertEqual(parsed.shapes.first?.textAlignment, .trailing,
                       "textAlignment .trailing ska bevaras genom round-trip")
    }
}
