import Foundation

enum MermaidGenerator {
    static func generate(from shapes: [ShapeNode]) -> String {
        guard !shapes.isEmpty else {
            return "flowchart TD\n    Tom[\"Tom canvas — lägg till en form\"]"
        }
        var lines: [String] = ["flowchart TD"]
        for (index, shape) in shapes.enumerated() {
            let nodeId = "N\(index)"
            let label = shape.label.isEmpty ? "Form \(index + 1)" : shape.label
            let safe = escape(label)
            switch shape.type {
            case .circle:
                lines.append("    \(nodeId)((\"\(safe)\"))")
            }
        }
        return lines.joined(separator: "\n")
    }

    static func canvasStateJSON(from shapes: [ShapeNode]) -> String {
        let positions: [[String: Any]] = shapes.enumerated().map { index, shape in
            [
                "id": "N\(index)",
                "x": Int(shape.position.x.rounded()),
                "y": Int(shape.position.y.rounded()),
                "label": shape.label,
                "type": shape.type.rawValue
            ]
        }
        let dict: [String: Any] = ["nodes": positions]
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted]),
              let str = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return str
    }

    private static func escape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\"", with: "#quot;")
            .replacingOccurrences(of: "\n", with: "<br/>")
    }
}
