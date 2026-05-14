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
            let safeLabel = escape(label)
            switch shape.type {
            case .circle:
                lines.append("    \(nodeId)((\"\(safeLabel)\"))")
            }
        }
        return lines.joined(separator: "\n")
    }

    private static func escape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\"", with: "#quot;")
            .replacingOccurrences(of: "\n", with: "<br/>")
    }
}
