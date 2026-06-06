import XCTest
import CoreGraphics
import SwiftUI
@testable import MermaidCanvas

/// v62: round-trip för de nya fälten — etikett-placering (ovanför/under pilen)
/// och separat ram-färg. Båda vägarna: state-JSON OCH strippad mermaid (fallback).
final class V62RoundTripTests: XCTestCase {

    private func stripStateJSON(_ markdown: String) -> String {
        guard let start = markdown.range(of: "<!-- mermaidcanvas-state"),
              let end = markdown.range(of: "\n-->", range: start.upperBound..<markdown.endIndex)
        else { return markdown }
        return String(markdown[..<start.lowerBound]) + String(markdown[end.upperBound...])
    }

    private func makeDoc() -> String {
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: 100, y: 100), label: "A",
                          colorOverride: "#ff0000", strokeColorOverride: "#0000ff")
        let b = ShapeNode(type: .rectangle, position: CGPoint(x: 300, y: 100), label: "B",
                          strokeColorOverride: "#15803d")
        let edgeAbove = EdgeConnection(from: a.id, to: b.id, label: "ja",
                                       labelPlacement: .above)
        return CanvasDocument(title: "T", shapes: [a, b], edges: [edgeAbove],
                              canvasSize: CGSize(width: 800, height: 800),
                              specType: .general).content
    }

    func testStateJSON_RamFargOchPlaceringRoundTrippar() {
        let parsed = MermaidParser.parse(makeDoc())
        XCTAssertEqual(parsed.shapes.count, 2)
        let a = parsed.shapes.first { $0.label == "A" }
        XCTAssertEqual(a?.colorOverride, "#ff0000", "Fyllning ska round-trippa")
        XCTAssertEqual(a?.strokeColorOverride, "#0000ff", "Ram-färg ska round-trippa")
        let b = parsed.shapes.first { $0.label == "B" }
        XCTAssertNil(b?.colorOverride)
        XCTAssertEqual(b?.strokeColorOverride, "#15803d", "Ram UTAN fyllning ska round-trippa")
        XCTAssertEqual(parsed.edges.first?.labelPlacement, .above,
                       "Etikett-placering ska round-trippa via state-JSON")
    }

    func testFallback_RamFargOchPlaceringRoundTrippar() {
        let parsed = MermaidParser.parse(stripStateJSON(makeDoc()))
        XCTAssertEqual(parsed.shapes.count, 2)
        let a = parsed.shapes.first { $0.label == "A" }
        XCTAssertEqual(a?.colorOverride, "#ff0000")
        XCTAssertEqual(a?.strokeColorOverride, "#0000ff",
                       "%% stroke: ska läsas i fallback")
        XCTAssertEqual(parsed.edges.first?.labelPlacement, .above,
                       "%% e0 labelPlacement: ska läsas i fallback")
        XCTAssertEqual(parsed.edges.first?.label, "ja")
    }

    func testGamlaFiler_FarDefaults() {
        // Kant utan labelPlacement + nod utan stroke → defaults, ingen krasch
        let md = """
        # Gammal fil

        ```mermaid
        flowchart TD
            a["A"] -->|"x"| b["B"]
        ```
        """
        let parsed = MermaidParser.parse(md)
        XCTAssertEqual(parsed.edges.first?.labelPlacement, .below)
        XCTAssertNil(parsed.shapes.first?.strokeColorOverride)
    }

    func testMermaidExport_SeparatStrokeIStyleRad() {
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: 100, y: 100), label: "A",
                          colorOverride: "#ff0000", strokeColorOverride: "#0000ff")
        let code = MermaidGenerator.generate(shapes: [a], edges: [],
                                             canvasSize: CGSize(width: 800, height: 800),
                                             specType: .general)
        XCTAssertTrue(code.contains("fill:#ff0000"), "Fyllningen i style-raden")
        XCTAssertTrue(code.contains("stroke:#0000ff"), "Ramen separat i style-raden")
        XCTAssertTrue(code.contains("stroke: #0000ff"), "%% stroke-kommentaren")
    }

    func testHexHjalpare() {
        XCTAssertNotNil(Color(hexString: "#ff0000"))
        XCTAssertNotNil(Color(hexString: "15803d"))
        XCTAssertNil(Color(hexString: "rosa"))
        XCTAssertTrue(Color.isDarkHex("#111827"), "Mörk färg → ljus text")
        XCTAssertFalse(Color.isDarkHex("#ffe3d0"), "Ljus färg → mörk text")
    }
}
