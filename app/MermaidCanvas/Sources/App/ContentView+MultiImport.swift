import SwiftUI
import CoreGraphics

extension ContentView {
    /// v1.1 (Kims "Ev kunna importera flera filer"): importera flera mermaid-filer och lägg
    /// VAR OCH EN i en egen container sida vid sida — för att jämföra varianter. Lägger till
    /// på nuvarande canvas (ersätter inte). Navigering via canvasen + snabb-nav-knappen.
    func importFilesAsContainers(_ urls: [URL]) {
        guard !urls.isEmpty else { return }
        model.snapshotForUndo()
        var xCursor: CGFloat = 400
        let rowY: CGFloat = 900

        for url in urls {
            guard let content = fileManager.open(url: url) else { continue }
            let parsed = MermaidParser.parse(content)
            guard !parsed.shapes.isEmpty else { continue }

            let xs = parsed.shapes.map { $0.position.x }, ys = parsed.shapes.map { $0.position.y }
            let minX = xs.min() ?? 0, maxX = xs.max() ?? 0
            let minY = ys.min() ?? 0, maxY = ys.max() ?? 0
            let pad: CGFloat = 90
            let w = (maxX - minX) + pad * 2
            let h = (maxY - minY) + pad * 2 + 40   // +40 för container-headern
            let cx = xCursor + w / 2

            let title = parsed.title.isEmpty
                ? url.deletingPathExtension().lastPathComponent : parsed.title
            var container = ShapeNode(type: .container, position: CGPoint(x: cx, y: rowY), label: title)
            container.widthMultiplier  = w / ShapeGeometry.typeBaseWidth(for: .container)
            container.heightMultiplier = h / ShapeGeometry.typeBaseHeight(for: .container)

            // Förskjut filens innehåll så dess mitt hamnar i containern (strax under headern).
            let dx = cx - (minX + maxX) / 2
            let dy = (rowY + 20) - (minY + maxY) / 2
            let placed: [ShapeNode] = parsed.shapes.map { s in
                var c = s
                c.position = CGPoint(x: s.position.x + dx, y: s.position.y + dy)
                if c.childOfContainerId == nil { c.childOfContainerId = container.id }
                return c
            }

            model.shapes.append(container)
            model.shapes.append(contentsOf: placed)
            model.edges.append(contentsOf: parsed.edges)
            xCursor += w + 120
        }
        centerOnPoint = contentCenter(of: model.shapes)
    }
}
