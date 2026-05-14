import Foundation

enum MermaidGenerator {
    static func generate(shapes: [ShapeNode], edges: [EdgeConnection]) -> String {
        guard !shapes.isEmpty else {
            return "flowchart TD\n    Tom[\"Tom canvas — lägg till en form\"]"
        }
        var lines: [String] = ["flowchart TD"]
        let mermaidIds: [UUID: String] = Dictionary(
            uniqueKeysWithValues: shapes.enumerated().map { ($1.id, "N\($0)") }
        )
        for shape in shapes {
            let id = mermaidIds[shape.id]!
            let label = shape.showLabel ? (shape.label.isEmpty ? " " : shape.label) : " "
            let safe = escape(label)
            let line: String
            switch shape.type {
            case .circle:    line = "    \(id)((\"\(safe)\"))"
            case .rectangle: line = "    \(id)[\"\(safe)\"]"
            case .diamond:   line = "    \(id){\"\(safe)\"}"
            }
            lines.append(line)
        }
        for edge in edges {
            guard let from = mermaidIds[edge.from], let to = mermaidIds[edge.to] else { continue }
            let arrow = edge.bidirectional ? "<-->" : "-->"
            if edge.label.isEmpty {
                lines.append("    \(from) \(arrow) \(to)")
            } else {
                lines.append("    \(from) \(arrow)|\"\(escape(edge.label))\"| \(to)")
            }
        }
        return lines.joined(separator: "\n")
    }

    static func canvasStateJSON(shapes: [ShapeNode], edges: [EdgeConnection], canvasSize: CGSize) -> String {
        let mermaidIds: [UUID: String] = Dictionary(
            uniqueKeysWithValues: shapes.enumerated().map { ($1.id, "N\($0)") }
        )
        let nodes: [[String: Any]] = shapes.map { shape in
            [
                "id": mermaidIds[shape.id]!,
                "x": Int(shape.position.x.rounded()),
                "y": Int(shape.position.y.rounded()),
                "label": shape.label,
                "type": shape.type.rawValue,
                "showLabel": shape.showLabel,
                "size": Double(shape.sizeMultiplier),
                "note": shape.note
            ]
        }
        let edgeArr: [[String: Any]] = edges.compactMap { edge in
            guard let f = mermaidIds[edge.from], let t = mermaidIds[edge.to] else { return nil }
            return [
                "from": f,
                "to": t,
                "label": edge.label,
                "bidirectional": edge.bidirectional
            ]
        }
        let canvas: [String: Any] = [
            "width": Int(canvasSize.width.rounded()),
            "height": Int(canvasSize.height.rounded()),
            "shapeBaseWidth": 120,
            "shapeBaseHeight": 80,
            "unit": "pt"
        ]
        let dict: [String: Any] = ["canvas": canvas, "nodes": nodes, "edges": edgeArr]
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted]),
              let str = String(data: data, encoding: .utf8) else { return "{}" }
        return str
    }

    private static func escape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\"", with: "#quot;")
            .replacingOccurrences(of: "\n", with: "<br/>")
    }
}
