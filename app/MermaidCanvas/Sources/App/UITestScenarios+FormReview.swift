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

    /// Steg 8 (2d): fil-former med dokument-glyf — MD + Excel + subagent.
    static func place37SkillFlowFiles(_ model: CanvasModel, _ c: CGPoint) {
        let sub = ShapeNode(type: .rectangle, position: CGPoint(x: c.x, y: c.y - 90),
                            label: "Subagent", category: .subagent)
        let md  = ShapeNode(type: .rectangle, position: CGPoint(x: c.x - 110, y: c.y + 70),
                            label: "data.md", category: .fileMarkdown)
        let xls = ShapeNode(type: .rectangle, position: CGPoint(x: c.x + 110, y: c.y + 70),
                            label: "ark.xlsx", category: .fileExcel)
        model.shapes.append(contentsOf: [sub, md, xls])
        model.addEdge(from: sub.id, to: md.id)
        model.addEdge(from: sub.id, to: xls.id)
    }

    /// Steg 9: phoneFrame med modellnamn (visas utanpå) + markerad (visar handtagen:
    /// bara proportionell resize + rotation, ingen fri resize).
    static func place38PhoneFrame(_ model: CanvasModel, _ c: CGPoint) {
        let phone = ShapeNode(type: .phoneFrame, position: c, label: "iPhone 16 Pro")
        model.shapes.append(phone)
        model.selectedShapeId = phone.id
    }

    /// Fundament-verifiering: alla basfigurer MED text + distinkta kategori-färger.
    /// Används för att jämföra app-rendering mot mermaid-rendering (app == mermaid).
    static func place39VerifyAll(_ model: CanvasModel, _ c: CGPoint) {
        let cols: [CGFloat] = [-135, 0, 135]
        let rows: [CGFloat] = [-235, -78, 78, 235]
        func pos(_ col: Int, _ row: Int) -> CGPoint { CGPoint(x: c.x + cols[col], y: c.y + rows[row]) }
        var shapes: [ShapeNode] = [
            ShapeNode(type: .circle,       position: pos(0, 0), label: "Start",   category: .input),
            ShapeNode(type: .pill,         position: pos(1, 0), label: "Pill",    category: .ui),
            ShapeNode(type: .rectangle,    position: pos(2, 0), label: "Ruta",    category: .feat),
            ShapeNode(type: .square,       position: pos(0, 1), label: "Kvadrat", category: .zone),
            ShapeNode(type: .diamond,      position: pos(1, 1), label: "Beslut?", category: .router),
            ShapeNode(type: .processArrow, position: pos(2, 1), label: "Steg",    category: .script),
            ShapeNode(type: .octagon,      position: pos(0, 2), label: "Stopp",   category: .manual),
            ShapeNode(type: .triangle,     position: pos(1, 2), label: "Tri",     category: .gate),
            ShapeNode(type: .cylinder,     position: pos(2, 2), label: "DB",      category: .evidence),
        ]
        var table = ShapeNode(type: .table, position: pos(0, 3), label: "Tabell", category: .ui)
        table.tableRows = 2; table.tableCols = 2; table.tableCells = [["a", "b"], ["c", "d"]]
        shapes.append(table)
        var link = ShapeNode(type: .link, position: pos(1, 3), label: "Hopp", category: .ui)
        link.linkNumber = 1
        shapes.append(link)
        var line = ShapeNode(type: .line, position: pos(2, 3), label: "", category: .overlay)
        line.lineEnd = CGPoint(x: 70, y: 0)
        shapes.append(line)
        model.shapes.append(contentsOf: shapes)
        model.addEdge(from: shapes[0].id, to: shapes[4].id)
    }
}
