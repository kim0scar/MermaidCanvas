import SwiftUI
import UIKit

/// Steg H: renderar RITADE ytan (former + kanter) till en PNG via ImageRenderer.
/// Beskär till ritningens bounding-box + marginal — INTE hela 3000×3000-canvasen.
/// Använder ExportCanvasView = samma render-väg som canvasen → bilden matchar
/// alltid det Kim ser (fundamentet för fidelity-jämförelsen mot mermaid).
@MainActor
enum CanvasImageExporter {
    /// Marginal (canvas-punkter) runt ritningen i bilden.
    static let padding: CGFloat = 56

    /// PNG-data för den ritade ytan (bakåtkomp-alias).
    static func renderPNG(model: CanvasModel, scale: CGFloat = 3) -> Data? {
        renderImage(model: model, jpeg: false, scale: scale)?.data
    }

    /// Bild-data + filändelse för den ritade ytan. jpeg=true → JPG (Kims val), annars PNG.
    static func renderImage(model: CanvasModel, jpeg: Bool, scale: CGFloat = 3) -> (data: Data, ext: String)? {
        let visible = model.shapes.filter { !model.hiddenShapeIds.contains($0.id) }
        guard !visible.isEmpty else { return nil }
        let box = boundingBox(shapes: visible, edges: model.edges)

        let content = ExportCanvasView(
            shapes: model.shapes,
            edges: model.edges,
            hiddenShapeIds: model.hiddenShapeIds,
            collapsedEdgeIds: model.collapsedEdgeIds,
            contentSize: model.contentSize
        )
        // Skjut ritningen så bbox-hörnet hamnar i (0,0), beskär till bbox-storlek.
        .offset(x: -box.minX, y: -box.minY)
        .frame(width: box.width, height: box.height, alignment: .topLeading)
        .clipped()
        .background(Color.white)

        let renderer = ImageRenderer(content: content)
        renderer.scale = scale
        renderer.isOpaque = true
        guard let img = renderer.uiImage else { return nil }
        if jpeg {
            guard let d = img.jpegData(compressionQuality: 0.9) else { return nil }
            return (d, "jpg")
        }
        guard let d = img.pngData() else { return nil }
        return (d, "png")
    }

    /// Bounding-box runt former (+ ev. waypoints) i canvas-koordinater, med marginal.
    static func boundingBox(shapes: [ShapeNode], edges: [EdgeConnection]) -> CGRect {
        var minX = CGFloat.greatestFiniteMagnitude
        var minY = CGFloat.greatestFiniteMagnitude
        var maxX = -CGFloat.greatestFiniteMagnitude
        var maxY = -CGFloat.greatestFiniteMagnitude
        for s in shapes {
            let hw = ShapeGeometry.width(for: s) / 2
            let hh = ShapeGeometry.height(for: s) / 2
            minX = min(minX, s.position.x - hw); maxX = max(maxX, s.position.x + hw)
            minY = min(minY, s.position.y - hh); maxY = max(maxY, s.position.y + hh)
        }
        let ids = Set(shapes.map { $0.id })
        for e in edges where ids.contains(e.from) && ids.contains(e.to) {
            for wp in e.waypoints {
                minX = min(minX, wp.point.x); maxX = max(maxX, wp.point.x)
                minY = min(minY, wp.point.y); maxY = max(maxY, wp.point.y)
            }
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
            .insetBy(dx: -padding, dy: -padding)
    }
}
