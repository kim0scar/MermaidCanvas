import CoreGraphics

/// Steg G — form-genomgångens scenario + en utbruten builder (R5-ratchet: håller
/// UITestScenarios.swift under filstorleks-taket). Registreras i huvudfilens scenario-dict.
extension UITestScenarios {

    static func place01TightHorizontal(_ model: CanvasModel, _ c: CGPoint) {
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: c.x - 120, y: c.y))
        let b = ShapeNode(type: .rectangle, position: CGPoint(x: c.x + 120, y: c.y))
        model.shapes.append(contentsOf: [a, b])
        model.addEdge(from: a.id, to: b.id)
    }

    /// Alla 12 placerbara basfigurer i ett 3×4-rutnät (notis = popup, ej form).
    /// Verktyg för form-genomgången — Kim ser alla på en gång och pekar på vad som ska ändras.
    static func place36AllBaseShapes(_ model: CanvasModel, _ c: CGPoint) {
        let cols: [CGFloat] = [-120, 0, 120]
        let rows: [CGFloat] = [-225, -75, 75, 225]
        func pos(_ col: Int, _ row: Int) -> CGPoint {
            CGPoint(x: c.x + cols[col], y: c.y + rows[row])
        }
        var shapes: [ShapeNode] = [
            ShapeNode(type: .circle,       position: pos(0, 0), label: "Cirkel"),
            ShapeNode(type: .pill,         position: pos(1, 0), label: "Pill"),
            ShapeNode(type: .rectangle,    position: pos(2, 0), label: "Rektangel"),
            ShapeNode(type: .square,       position: pos(0, 1), label: "Kvadrat"),
            ShapeNode(type: .diamond,      position: pos(1, 1), label: "Romb"),
            ShapeNode(type: .processArrow, position: pos(2, 1), label: "Process"),
            ShapeNode(type: .octagon,      position: pos(0, 2), label: "Oktagon"),
            ShapeNode(type: .triangle,     position: pos(1, 2), label: "Triangel"),
            ShapeNode(type: .container,    position: pos(2, 2), label: "Container"),
        ]
        var table = ShapeNode(type: .table, position: pos(0, 3), label: "Tabell")
        table.tableRows = 2; table.tableCols = 2
        shapes.append(table)
        var link = ShapeNode(type: .link, position: pos(1, 3), label: "Länk")
        link.linkNumber = 1
        shapes.append(link)
        var line = ShapeNode(type: .line, position: pos(2, 3), label: "Linje")
        line.lineEnd = CGPoint(x: 70, y: 0)
        shapes.append(line)
        model.shapes.append(contentsOf: shapes)
    }
}
