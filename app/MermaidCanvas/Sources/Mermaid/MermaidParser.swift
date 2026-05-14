import Foundation
import CoreGraphics

enum MermaidParser {
    /// Parsar en MermaidCanvas-markdown till en lista med ShapeNode.
    /// Letar först efter canvasState-JSON-kommentar (autoritativ för positioner).
    /// Annars: parsa mermaid-blocket och auto-positionera i en cirkel.
    static func parse(_ markdown: String) -> [ShapeNode] {
        if let fromState = parseStateJSON(markdown), !fromState.isEmpty {
            return fromState
        }
        let mermaidNodes = parseMermaid(markdown)
        return autoPosition(mermaidNodes)
    }

    private static func parseStateJSON(_ markdown: String) -> [ShapeNode]? {
        guard let start = markdown.range(of: "<!-- mermaidcanvas-state"),
              let end = markdown.range(of: "-->", range: start.upperBound..<markdown.endIndex)
        else { return nil }
        let jsonStr = String(markdown[start.upperBound..<end.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = jsonStr.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let nodes = obj["nodes"] as? [[String: Any]]
        else { return nil }

        return nodes.compactMap { node in
            guard let xAny = node["x"], let yAny = node["y"] else { return nil }
            let x = numberValue(xAny)
            let y = numberValue(yAny)
            let label = (node["label"] as? String) ?? "Form"
            let typeRaw = (node["type"] as? String) ?? ShapeType.circle.rawValue
            let type = ShapeType(rawValue: typeRaw) ?? .circle
            return ShapeNode(type: type, position: CGPoint(x: x, y: y), label: label)
        }
    }

    private static func numberValue(_ value: Any) -> CGFloat {
        if let i = value as? Int { return CGFloat(i) }
        if let d = value as? Double { return CGFloat(d) }
        if let s = value as? String, let d = Double(s) { return CGFloat(d) }
        return 0
    }

    private struct MermaidNode {
        let id: String
        let label: String
    }

    private static func parseMermaid(_ markdown: String) -> [MermaidNode] {
        guard let start = markdown.range(of: "```mermaid"),
              let end = markdown.range(of: "```", range: start.upperBound..<markdown.endIndex)
        else { return [] }
        let block = String(markdown[start.upperBound..<end.lowerBound])

        var result: [MermaidNode] = []
        let pattern = #"(\w+)\s*\(\(\s*\"([^\"]*?)\"\s*\)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let ns = block as NSString
        let matches = regex.matches(in: block, range: NSRange(location: 0, length: ns.length))
        for m in matches where m.numberOfRanges >= 3 {
            let id = ns.substring(with: m.range(at: 1))
            let label = ns.substring(with: m.range(at: 2))
                .replacingOccurrences(of: "#quot;", with: "\"")
                .replacingOccurrences(of: "<br/>", with: "\n")
            result.append(MermaidNode(id: id, label: label))
        }
        return result
    }

    private static func autoPosition(_ nodes: [MermaidNode]) -> [ShapeNode] {
        let count = nodes.count
        guard count > 0 else { return [] }
        let centerX: CGFloat = 200
        let centerY: CGFloat = 320
        if count == 1 {
            return [ShapeNode(type: .circle, position: CGPoint(x: centerX, y: centerY), label: nodes[0].label)]
        }
        let radius: CGFloat = 130
        return nodes.enumerated().map { i, node in
            let angle = (2.0 * .pi / Double(count)) * Double(i) - .pi / 2
            let x = centerX + radius * CGFloat(cos(angle))
            let y = centerY + radius * CGFloat(sin(angle))
            return ShapeNode(type: .circle, position: CGPoint(x: x, y: y), label: node.label)
        }
    }
}
