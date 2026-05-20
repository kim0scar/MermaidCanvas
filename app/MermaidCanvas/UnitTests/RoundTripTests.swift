import XCTest
import CoreGraphics
@testable import MermaidCanvas

/// v29: round-trip-test för alla 6 form-typer.
/// Verifierar att skapad form → MermaidGenerator → MermaidParser ger
/// IDENTISK state (typ, position, label, sizeMultiplier).
/// Detta är "mermaid-koden = exakt vad jag ser"-kontrollen som Kim begärt.
final class RoundTripTests: XCTestCase {

    func testRoundTrip_AllSixShapeTypes() throws {
        // v44: .text borttagen — pill ersätter slot
        let originalShapes: [ShapeNode] = [
            ShapeNode(type: .circle,    position: CGPoint(x: 100, y: 100), label: "Cirkel"),
            ShapeNode(type: .rectangle, position: CGPoint(x: 200, y: 150), label: "Rektangel"),
            ShapeNode(type: .diamond,   position: CGPoint(x: 300, y: 200), label: "Diamant"),
            ShapeNode(type: .pill,      position: CGPoint(x: 400, y: 250), label: "Pill"),
            ShapeNode(type: .table,     position: CGPoint(x: 500, y: 300), label: "Tabell",
                      tableRows: 3, tableCols: 4),
            ShapeNode(type: .link,      position: CGPoint(x: 600, y: 350), label: "Link",
                      linkNumber: 1)
        ]

        // 2. Generera mermaid via CanvasDocument (full pipeline inkl sidecar-JSON)
        let doc = CanvasDocument(
            title: "RoundTripTest",
            shapes: originalShapes,
            edges: [],
            canvasSize: CGSize(width: 800, height: 800),
            specType: .general,
            platform: .blank,
            activeShapePacks: [.basic],
            collapsedIds: []
        )
        let markdown = doc.content

        // 3. Parsa tillbaka
        let parsed = MermaidParser.parse(markdown)

        // 4. Verifiera antal
        XCTAssertEqual(parsed.shapes.count, originalShapes.count,
                       "Antal former ska bevaras genom round-trip")

        // 5. Verifiera typer (samma ordning)
        for (i, orig) in originalShapes.enumerated() {
            guard i < parsed.shapes.count else { break }
            let p = parsed.shapes[i]
            XCTAssertEqual(p.type, orig.type, "Form #\(i): typ ska bevaras")
        }

        // 6. Verifiera positioner — tillåt 1pt tolerans (Int-konvertering i mermaid-kommentar)
        for (i, orig) in originalShapes.enumerated() {
            guard i < parsed.shapes.count else { break }
            let p = parsed.shapes[i]
            XCTAssertEqual(p.position.x, orig.position.x, accuracy: 1.0,
                           "Form #\(i) (\(orig.type.rawValue)): position.x ska bevaras")
            XCTAssertEqual(p.position.y, orig.position.y, accuracy: 1.0,
                           "Form #\(i) (\(orig.type.rawValue)): position.y ska bevaras")
        }

        // 7. Verifiera labels (text-form har specialhantering — kan vara tomt om showLabel=false)
        for (i, orig) in originalShapes.enumerated() where orig.showLabel {
            guard i < parsed.shapes.count else { break }
            let p = parsed.shapes[i]
            XCTAssertEqual(p.label, orig.label,
                           "Form #\(i) (\(orig.type.rawValue)): label ska bevaras")
        }

        // 8. Tabell-rader/-kolumner
        let parsedTable = parsed.shapes.first { $0.type == .table }
        XCTAssertNotNil(parsedTable, "Tabell ska finnas i parsed output")
        if let t = parsedTable {
            XCTAssertEqual(t.tableRows, 3, "Tabell-rader ska bevaras")
            XCTAssertEqual(t.tableCols, 4, "Tabell-kolumner ska bevaras")
        }

        // 9. Link-nummer
        let parsedLink = parsed.shapes.first { $0.type == .link }
        XCTAssertNotNil(parsedLink, "Länk ska finnas i parsed output")
        if let l = parsedLink {
            XCTAssertEqual(l.linkNumber, 1, "Länk-nummer ska bevaras")
        }
    }

    func testRoundTrip_EdgesWithStyles() throws {
        let s1 = ShapeNode(type: .circle, position: CGPoint(x: 100, y: 100), label: "A")
        let s2 = ShapeNode(type: .circle, position: CGPoint(x: 300, y: 100), label: "B")
        let edges = [
            EdgeConnection(from: s1.id, to: s2.id, direction: .forward,      style: .solid),
            EdgeConnection(from: s2.id, to: s1.id, direction: .bidirectional, style: .dashed)
        ]

        let doc = CanvasDocument(
            title: "EdgeTest",
            shapes: [s1, s2],
            edges: edges,
            canvasSize: CGSize(width: 800, height: 800),
            specType: .general,
            platform: .blank,
            activeShapePacks: [.basic],
            collapsedIds: []
        )
        let parsed = MermaidParser.parse(doc.content)

        XCTAssertEqual(parsed.edges.count, 2, "Båda kanterna ska bevaras")
        XCTAssertTrue(parsed.edges.contains { $0.style == .solid },
                      "Solid edge-style ska bevaras")
        XCTAssertTrue(parsed.edges.contains { $0.style == .dashed },
                      "Dashed edge-style ska bevaras")
        XCTAssertTrue(parsed.edges.contains { $0.direction == .bidirectional },
                      "Bidirectional edge ska bevaras")
    }

    func testRoundTrip_PlatformAndShapePacks() throws {
        let s = ShapeNode(type: .rectangle, position: CGPoint(x: 200, y: 200), label: "Tile")
        let doc = CanvasDocument(
            title: "PackTest",
            shapes: [s],
            edges: [],
            canvasSize: CGSize(width: 800, height: 800),
            specType: .architecture,
            platform: .blank,
            activeShapePacks: [.basic, .architecture, .roadmap],
            collapsedIds: []
        )
        let parsed = MermaidParser.parse(doc.content)
        XCTAssertEqual(parsed.platform, .blank, "Platform ska bevaras")
        let packs = parsed.activeShapePacks ?? []
        XCTAssertTrue(packs.contains(.architecture),
                      "Arkitektur-pack ska bevaras")
        XCTAssertTrue(packs.contains(.roadmap),
                      "Roadmap-pack ska bevaras")
    }
}
