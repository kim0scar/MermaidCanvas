import Foundation
import CoreGraphics

enum MermaidParser {
    struct ParsedCanvas {
        var title: String = ""
        var shapes: [ShapeNode] = []
        var edges: [EdgeConnection] = []
    }

    static func parse(_ markdown: String) -> ParsedCanvas {
        let title = parseTitle(markdown)
        var result: ParsedCanvas
        if let fromState = parseStateJSON(markdown) {
            result = fromState
        } else {
            result = parseMermaid(markdown)
        }
        result.title = title
        return result
    }

    private static func parseTitle(_ markdown: String) -> String {
        for line in markdown.split(separator: "\n", omittingEmptySubsequences: true) {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("# ") {
                let title = String(trimmed.dropFirst(2)).trimmingCharacters(in: .whitespaces)
                if title == "Canvas — MermaidCanvas" { return "" }
                return title
            }
            if trimmed.hasPrefix("```") { break }
        }
        return ""
    }

    // MARK: - State-JSON (autoritativ)

    private static func parseStateJSON(_ markdown: String) -> ParsedCanvas? {
        guard let start = markdown.range(of: "<!-- mermaidcanvas-state"),
              let end = markdown.range(of: "-->", range: start.upperBound..<markdown.endIndex)
        else { return nil }
        let jsonStr = String(markdown[start.upperBound..<end.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = jsonStr.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }

        let nodes = (obj["nodes"] as? [[String: Any]]) ?? []
        let edges = (obj["edges"] as? [[String: Any]]) ?? []

        var idMap: [String: UUID] = [:]
        var shapes: [ShapeNode] = []
        for node in nodes {
            guard let mid = node["id"] as? String,
                  let xAny = node["x"], let yAny = node["y"]
            else { continue }
            let x = numberValue(xAny)
            let y = numberValue(yAny)
            let label = (node["label"] as? String) ?? "Form"
            let typeRaw = (node["type"] as? String) ?? ShapeType.circle.rawValue
            let type = ShapeType(rawValue: typeRaw) ?? .circle
            let shape = ShapeNode(type: type, position: CGPoint(x: x, y: y), label: label)
            idMap[mid] = shape.id
            shapes.append(shape)
        }

        var edgeList: [EdgeConnection] = []
        for edge in edges {
            guard let fromMid = edge["from"] as? String,
                  let toMid = edge["to"] as? String,
                  let fromId = idMap[fromMid],
                  let toId = idMap[toMid]
            else { continue }
            let label = (edge["label"] as? String) ?? ""
            let bidi = (edge["bidirectional"] as? Bool) ?? false
            edgeList.append(EdgeConnection(from: fromId, to: toId, label: label, bidirectional: bidi))
        }

        return ParsedCanvas(shapes: shapes, edges: edgeList)
    }

    private static func numberValue(_ value: Any) -> CGFloat {
        if let i = value as? Int { return CGFloat(i) }
        if let d = value as? Double { return CGFloat(d) }
        if let s = value as? String, let d = Double(s) { return CGFloat(d) }
        return 0
    }

    // MARK: - Mermaid-blocket (fallback)

    private struct ParsedNode {
        let mermaidId: String
        let type: ShapeType
        let label: String
    }

    private static func parseMermaid(_ markdown: String) -> ParsedCanvas {
        guard let start = markdown.range(of: "```mermaid"),
              let end = markdown.range(of: "```", range: start.upperBound..<markdown.endIndex)
        else { return ParsedCanvas() }
        let block = String(markdown[start.upperBound..<end.lowerBound])
        let ns = block as NSString

        let patterns: [(String, ShapeType)] = [
            (#"(\w+)\(\(\s*\"([^\"]*?)\"\s*\)\)"#, .circle),
            (#"(\w+)\[\s*\"([^\"]*?)\"\s*\]"#, .rectangle),
            (#"(\w+)\{\s*\"([^\"]*?)\"\s*\}"#, .diamond)
        ]

        var seen = Set<String>()
        var nodes: [ParsedNode] = []
        for (pattern, type) in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let matches = regex.matches(in: block, range: NSRange(location: 0, length: ns.length))
            for m in matches where m.numberOfRanges >= 3 {
                let id = ns.substring(with: m.range(at: 1))
                guard !seen.contains(id) else { continue }
                seen.insert(id)
                let label = ns.substring(with: m.range(at: 2))
                    .replacingOccurrences(of: "#quot;", with: "\"")
                    .replacingOccurrences(of: "<br/>", with: "\n")
                nodes.append(ParsedNode(mermaidId: id, type: type, label: label))
            }
        }

        let positioned = autoPosition(nodes)
        var idMap: [String: UUID] = [:]
        let shapes: [ShapeNode] = positioned.map { entry in
            idMap[entry.mermaidId] = entry.shape.id
            return entry.shape
        }

        var edges: [EdgeConnection] = []
        // Matchar A --> B, A <--> B, samt med ev. label: A -->|"x"| B
        let edgePattern = #"(\w+)\s*(<-+->|-+->)\s*(?:\|\s*\"?([^\"|]*?)\"?\s*\|\s*)?(\w+)"#
        if let regex = try? NSRegularExpression(pattern: edgePattern) {
            let matches = regex.matches(in: block, range: NSRange(location: 0, length: ns.length))
            for m in matches where m.numberOfRanges >= 5 {
                let fromMid = ns.substring(with: m.range(at: 1))
                let arrowStr = ns.substring(with: m.range(at: 2))
                let toMid = ns.substring(with: m.range(at: 4))
                let label: String
                if m.range(at: 3).location != NSNotFound {
                    label = ns.substring(with: m.range(at: 3))
                } else {
                    label = ""
                }
                guard let from = idMap[fromMid], let to = idMap[toMid] else { continue }
                let bidi = arrowStr.hasPrefix("<")
                edges.append(EdgeConnection(from: from, to: to, label: label, bidirectional: bidi))
            }
        }

        return ParsedCanvas(shapes: shapes, edges: edges)
    }

    private struct PositionedNode {
        let mermaidId: String
        let shape: ShapeNode
    }

    private static func autoPosition(_ nodes: [ParsedNode]) -> [PositionedNode] {
        let count = nodes.count
        guard count > 0 else { return [] }
        let centerX: CGFloat = 200
        let centerY: CGFloat = 320
        if count == 1 {
            let n = nodes[0]
            let shape = ShapeNode(type: n.type, position: CGPoint(x: centerX, y: centerY), label: n.label)
            return [PositionedNode(mermaidId: n.mermaidId, shape: shape)]
        }
        let radius: CGFloat = 140
        return nodes.enumerated().map { i, n in
            let angle = (2.0 * .pi / Double(count)) * Double(i) - .pi / 2
            let x = centerX + radius * CGFloat(cos(angle))
            let y = centerY + radius * CGFloat(sin(angle))
            let shape = ShapeNode(type: n.type, position: CGPoint(x: x, y: y), label: n.label)
            return PositionedNode(mermaidId: n.mermaidId, shape: shape)
        }
    }
}
