import XCTest
import CoreGraphics
@testable import MermaidCanvas

/// v35: validerar mermaid-export för alla 9 shape-typer + svåra labels
/// (åäö, emoji, mellanslag, citationstecken) + edges-med-labels + round-trip.
///
/// Detta är "trygghetsnätet" som garanterar att Kims canvas-filer ALDRIG
/// genererar ogiltig mermaid när en form innehåller åäö eller emoji.
final class V35MermaidValidationTests: XCTestCase {

    // MARK: - 1. Alla 9 shape-typer → korrekt mermaid-syntax

    func testGenerator_AllNineShapeTypes_ProducesValidSyntax() throws {
        let shapes: [ShapeNode] = [
            ShapeNode(type: .circle,    position: CGPoint(x: 100, y: 100), label: "Cirkel"),
            ShapeNode(type: .rectangle, position: CGPoint(x: 200, y: 100), label: "Rektangel"),
            ShapeNode(type: .diamond,   position: CGPoint(x: 300, y: 100), label: "Diamant"),
            ShapeNode(type: .pill,      position: CGPoint(x: 400, y: 100), label: "Pill"),
            ShapeNode(type: .text,      position: CGPoint(x: 500, y: 100), label: "Text"),
            ShapeNode(type: .table,     position: CGPoint(x: 600, y: 100), label: "Tabell",
                      tableRows: 3, tableCols: 4),
            ShapeNode(type: .link,      position: CGPoint(x: 700, y: 100), label: "Länk",
                      linkNumber: 1),
            ShapeNode(type: .line,      position: CGPoint(x: 800, y: 100), label: "Linje",
                      lineEnd: CGPoint(x: 50, y: 50)),
            ShapeNode(type: .arrow,     position: CGPoint(x: 900, y: 100), label: "Pil",
                      lineEnd: CGPoint(x: 50, y: 50))
        ]
        XCTAssertEqual(shapes.count, 9, "Testet ska täcka alla 9 ShapeType-fall")
        // Sanity check: alla ShapeType-fall ska finnas representerade
        let coveredTypes = Set(shapes.map { $0.type })
        XCTAssertEqual(coveredTypes.count, ShapeType.allCases.count,
                       "Testet ska täcka alla ShapeType-fall i enumet")

        let mermaid = MermaidGenerator.generate(
            shapes: shapes,
            edges: [],
            canvasSize: CGSize(width: 1200, height: 600),
            specType: .general
        )

        // Mermaid-block ska börja med flowchart-direktiv
        XCTAssertTrue(mermaid.hasPrefix("flowchart TD"),
                      "Mermaid-output ska starta med 'flowchart TD'")

        // Varje form-typ har ett specifikt syntax-mönster i mermaid-grammatiken.
        // Vi vet att labels är giltiga unika strängar — så vi söker efter dem
        // omslutna av rätt avgränsare.
        let circleSyntax = "((\"Cirkel\"))"
        let rectSyntax = "[\"Rektangel\"]"
        let diamondSyntax = "{\"Diamant\"}"
        let pillSyntax = "([\"Pill\"])"
        let tableSyntax = "[\"Tabell\"]"
        // text/link/line/arrow renderas också med [...] resp ((...))
        let textSyntax = "[\"Text\"]"
        let linkSyntax = "((\"Länk\"))"
        let lineSyntax = "[\"Linje\"]"
        let arrowSyntax = "[\"Pil\"]"

        XCTAssertTrue(mermaid.contains(circleSyntax), "Cirkel-syntax saknas: '\(circleSyntax)'")
        XCTAssertTrue(mermaid.contains(rectSyntax), "Rektangel-syntax saknas: '\(rectSyntax)'")
        XCTAssertTrue(mermaid.contains(diamondSyntax), "Diamant-syntax saknas: '\(diamondSyntax)'")
        XCTAssertTrue(mermaid.contains(pillSyntax), "Pill-syntax saknas: '\(pillSyntax)'")
        XCTAssertTrue(mermaid.contains(textSyntax), "Text-syntax saknas: '\(textSyntax)'")
        XCTAssertTrue(mermaid.contains(tableSyntax), "Tabell-syntax saknas: '\(tableSyntax)'")
        XCTAssertTrue(mermaid.contains(linkSyntax), "Länk-syntax saknas: '\(linkSyntax)'")
        XCTAssertTrue(mermaid.contains(lineSyntax), "Line-syntax saknas: '\(lineSyntax)'")
        XCTAssertTrue(mermaid.contains(arrowSyntax), "Arrow-syntax saknas: '\(arrowSyntax)'")

        // Tabell-metadata ska finnas som mermaid-kommentar
        XCTAssertTrue(mermaid.contains("table: 3×4"),
                      "Tabell-rader/-kolumner ska sparas som mermaid-kommentar")

        // Link-nummer ska finnas som mermaid-kommentar
        XCTAssertTrue(mermaid.contains("link: 1"),
                      "Link-nummer ska sparas som mermaid-kommentar")

        // Varje shape ska ha en position-kommentar
        let posLines = mermaid.split(separator: "\n").filter { $0.contains("pos:") }
        XCTAssertEqual(posLines.count, 9,
                       "Alla 9 former ska ha 'pos:'-kommentar (en per form)")
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
                           bidirectional: false, style: .solid),
            EdgeConnection(from: s2.id, to: s3.id, label: "skickar till",
                           bidirectional: true, style: .dashed),
            EdgeConnection(from: s1.id, to: s3.id, label: "",
                           bidirectional: false, style: .solid)
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
        XCTAssertTrue(parsed.edges.contains { $0.bidirectional },
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
                           bidirectional: false, style: .solid),
            EdgeConnection(from: b.id, to: c.id, label: "sedan",
                           bidirectional: false, style: .dashed),
            EdgeConnection(from: c.id, to: a.id, label: "tillbaka 🔄",
                           bidirectional: true, style: .solid)
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
                           label: "", bidirectional: false, style: .solid)
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

    /// Verifierar att text-shapes får transparent fill/stroke i Mermaid
    /// (inte kategori-fyllning som skulle täcka texten).
    func testGenerator_TextShape_HasTransparentStyle() throws {
        let shapes: [ShapeNode] = [
            ShapeNode(type: .text, position: CGPoint(x: 200, y: 200), label: "Rubrik")
        ]
        let code = MermaidGenerator.generate(
            shapes: shapes,
            edges: [],
            canvasSize: CGSize(width: 800, height: 600),
            specType: .general
        )

        XCTAssertTrue(code.contains("fill:transparent") && code.contains("stroke:transparent"),
                      "Text-shape ska ha transparent fill + stroke:\n\(code)")
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
}
