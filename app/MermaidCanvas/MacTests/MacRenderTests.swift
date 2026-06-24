import XCTest
import CoreGraphics
@testable import MermaidCanvasMac

/// 1.1 genomgång (2026-06-24): BEVISAR att Mac-canvasen RENDERAR.
/// Kör den DELADE render-vägen (ImageRenderer → pixlar via CanvasImageExporters NSImage-gren)
/// på macOS. Om formerna ritas till en giltig PNG på Mac, då renderar canvasen — det är exakt
/// samma SwiftUI-vyer som menyrads-popupen visar. Stänger "renderar Mac-canvasen?"-frågan maskinellt.
@MainActor
final class MacRenderTests: XCTestCase {

    func test_canvasRendersToPNGOnMacOS() {
        let m = CanvasModel()
        m.addShape(.rectangle, at: CGPoint(x: 400, y: 400))
        m.addShape(.circle, at: CGPoint(x: 700, y: 420))
        m.addShape(.diamond, at: CGPoint(x: 550, y: 650))

        let out = CanvasImageExporter.renderImage(model: m, jpeg: false)
        XCTAssertNotNil(out, "macOS-rendering ska ge en PNG (NSImage-grenen i CanvasImageExporter)")
        XCTAssertEqual(out?.ext, "png")
        XCTAssertGreaterThan(out?.data.count ?? 0, 1000,
                             "PNG ska ha verkligt innehåll = formerna faktiskt ritade på macOS")
    }

    func test_canvasParsesAndRendersRealFileOnMacOS() {
        // Hela kedjan på macOS: parsa en MermaidCanvas-fil → modell → rendera.
        let md = """
        ```mermaid
        flowchart TD
            n1(("Start"))
            n2{"OK?"}
            n1 --> n2
        ```
        """
        let parsed = MermaidParser.parse(md)
        XCTAssertGreaterThanOrEqual(parsed.shapes.count, 2, "parsern (delad) funkar på macOS")
        let m = CanvasModel()
        m.replaceAll(shapes: parsed.shapes, edges: parsed.edges, title: "T",
                     specType: parsed.specType, platform: parsed.platform,
                     activeShapePacks: parsed.activeShapePacks,
                     collapsedEdgeIds: parsed.collapsedEdgeIds, legend: parsed.legend)
        let out = CanvasImageExporter.renderImage(model: m, jpeg: false)
        XCTAssertNotNil(out, "parsad fil ska renderas på macOS")
    }
}
