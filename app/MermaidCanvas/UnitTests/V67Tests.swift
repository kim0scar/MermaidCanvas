import XCTest
import CoreGraphics
@testable import MermaidCanvas

/// v67: Kims fynd efter v66-test — mitten-fix, iPhone-ram round-trip, n8n-paket.
@MainActor
final class V67Tests: XCTestCase {

    private func stripStateJSON(_ markdown: String) -> String {
        guard let start = markdown.range(of: "<!-- mermaidcanvas-state"),
              let end = markdown.range(of: "\n-->", range: start.upperBound..<markdown.endIndex)
        else { return markdown }
        return String(markdown[..<start.lowerBound]) + String(markdown[end.upperBound...])
    }

    // MARK: - Fynd 4: nya former byggs i mitten (inte topp-vänster)

    func testVisibleCenter_GlobalFrameZero_FallerTillbakaTillMitten() {
        let vp = CanvasViewportState()
        // Default: globalFrame = .zero (vyn ännu inte mätt) → ska INTE bli (0,0).
        XCTAssertEqual(vp.visibleCenterInCanvas, CGPoint(x: 2000, y: 2000),
                       "Innan layout → canvas-mitten, annars landar former i topp-vänstra hörnet")
    }

    func testVisibleCenter_MedGlobalFrame_RaknarNormalt() {
        let vp = CanvasViewportState()
        vp.globalFrame = CGRect(x: 0, y: 0, width: 400, height: 800)
        vp.contentOffset = CGSize(width: 1000, height: 1000)
        vp.zoomScale = 1.0
        // (1000 + 400/2, 1000 + 800/2) = (1200, 1400)
        XCTAssertEqual(vp.visibleCenterInCanvas, CGPoint(x: 1200, y: 1400))
    }

    // MARK: - Fynd 5: iPhone-ram round-trippar förlustfritt

    func testPhoneFrame_RoundTrip_StateJSON() {
        let p = ShapeNode(type: .phoneFrame, position: CGPoint(x: 500, y: 500), label: "Startskärm")
        let doc = CanvasDocument(title: "UI", shapes: [p], edges: [],
                                 canvasSize: CGSize(width: 4000, height: 4000),
                                 specType: .general).content
        let parsed = MermaidParser.parse(doc)
        XCTAssertEqual(parsed.shapes.first?.type, .phoneFrame, "state-JSON bevarar telefon-ramen")
        XCTAssertEqual(parsed.shapes.first?.label, "Startskärm")
    }

    func testPhoneFrame_RoundTrip_SjalvbarandeMermaid() {
        let p = ShapeNode(type: .phoneFrame, position: CGPoint(x: 500, y: 500), label: "Startskärm")
        let doc = CanvasDocument(title: "UI", shapes: [p], edges: [],
                                 canvasSize: CGSize(width: 4000, height: 4000),
                                 specType: .general).content
        XCTAssertTrue(doc.contains("shape-type: phoneFrame"), "Skriver %% shape-type för fallback-parsern")
        let parsed = MermaidParser.parse(stripStateJSON(doc))
        XCTAssertEqual(parsed.shapes.first?.type, .phoneFrame,
                       "Utan state-JSON återskapas typen via %% shape-type")
    }

    // MARK: - Fynd 1: n8n-paket

    func testN8nPaket_FinnsOchHarRattKategorier() {
        XCTAssertTrue(ShapePack.userToggleable.contains(.n8n), "n8n syns i paket-raden")
        XCTAssertEqual(ShapePack.n8n.categories,
                       [.input, .agent, .tool, .router, .memory, .output],
                       "n8n innehåller flödesnoderna")
        XCTAssertEqual(ShapePack.n8n.defaultCategory, .input)
    }
}
