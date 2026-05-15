import Foundation
import CoreGraphics

enum MermaidParser {
    struct ParsedCanvas {
        var title: String = ""
        var shapes: [ShapeNode] = []
        var edges: [EdgeConnection] = []
        var canvasSize: CGSize? = nil
        var specType: SpecType = .ui
        var collapsedIds: Set<UUID> = []
    }

    static func parse(_ markdown: String) -> ParsedCanvas {
        let frontmatter = parseFrontmatter(markdown)
        let title = frontmatter.title ?? parseTitle(markdown)
        var result: ParsedCanvas
        if let fromState = parseStateJSON(markdown) {
            result = fromState
        } else {
            result = parseMermaid(markdown)
        }
        result.title = title
        if let st = frontmatter.specType {
            result.specType = st
        }
        return result
    }

    // MARK: - Frontmatter

    private struct Frontmatter {
        var title: String? = nil
        var specType: SpecType? = nil
    }

    private static func parseFrontmatter(_ markdown: String) -> Frontmatter {
        let trimmed = markdown.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("---") else { return Frontmatter() }
        let afterStart = trimmed.dropFirst(3)
        guard let endRange = afterStart.range(of: "\n---") else { return Frontmatter() }
        let yaml = String(afterStart[..<endRange.lowerBound])
        var fm = Frontmatter()
        for line in yaml.split(separator: "\n") {
            let parts = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            guard parts.count == 2 else { continue }
            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let value = parts[1].trimmingCharacters(in: .whitespaces)
            switch key {
            case "title": fm.title = value
            case "spec_type":
                if let st = SpecType(rawValue: value) { fm.specType = st }
            default: break
            }
        }
        return fm
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
        var parsedCanvasSize: CGSize? = nil
        if let canvas = obj["canvas"] as? [String: Any] {
            let w = canvas["width"].map { numberValue($0) } ?? 0
            let h = canvas["height"].map { numberValue($0) } ?? 0
            if w > 0 && h > 0 {
                parsedCanvasSize = CGSize(width: w, height: h)
            }
        }

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
            let showLabel = (node["showLabel"] as? Bool) ?? true
            let sizeRaw = node["size"]
            let size = sizeRaw.map { numberValue($0) } ?? 1.0
            let note = (node["note"] as? String) ?? ""
            let categoryRaw = (node["category"] as? String) ?? ShapeCategory.ui.rawValue
            let category = ShapeCategory(rawValue: categoryRaw) ?? .ui
            let rotationRaw = node["rotation"]
            let rotation = rotationRaw.map { numberValue($0) } ?? 0
            let colorOverride = node["color"] as? String
            let linkNumber = node["linkNumber"] as? Int
            let tableRows = node["tableRows"] as? Int
            let tableCols = node["tableCols"] as? Int
            let shape = ShapeNode(
                type: type,
                position: CGPoint(x: x, y: y),
                label: label,
                showLabel: showLabel,
                sizeMultiplier: max(0.3, min(3.0, size)),
                note: note,
                category: category,
                rotation: max(-360, min(360, rotation)),
                colorOverride: colorOverride,
                linkNumber: linkNumber,
                tableRows: tableRows,
                tableCols: tableCols
            )
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
            var waypoints: [EdgeWaypoint] = []
            if let wpArr = edge["waypoints"] as? [[String: Any]] {
                for wp in wpArr {
                    let wx = wp["x"].map { numberValue($0) } ?? 0
                    let wy = wp["y"].map { numberValue($0) } ?? 0
                    waypoints.append(EdgeWaypoint(x: Double(wx), y: Double(wy)))
                }
            }
            edgeList.append(EdgeConnection(from: fromId, to: toId, label: label, bidirectional: bidi, waypoints: waypoints))
        }

        // Parse collapsed-array (mermaidIds → UUIDs via idMap)
        var collapsedSet: Set<UUID> = []
        if let collapsedRaw = obj["collapsed"] as? [String] {
            for mid in collapsedRaw {
                if let uuid = idMap[mid] { collapsedSet.insert(uuid) }
            }
        }

        return ParsedCanvas(shapes: shapes,
                            edges: edgeList,
                            canvasSize: parsedCanvasSize,
                            collapsedIds: collapsedSet)
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
        let category: ShapeCategory
    }

    private static func parseMermaid(_ markdown: String) -> ParsedCanvas {
        guard let start = markdown.range(of: "```mermaid"),
              let end = markdown.range(of: "```", range: start.upperBound..<markdown.endIndex)
        else { return ParsedCanvas() }
        let block = String(markdown[start.upperBound..<end.lowerBound])
        let ns = block as NSString

        // Tre former; valfritt :::klass-suffix
        let patterns: [(String, ShapeType)] = [
            (#"(\w+)\(\(\s*\"([^\"]*?)\"\s*\)\)(?::::(\w+))?"#, .circle),
            (#"(\w+)\[\s*\"([^\"]*?)\"\s*\](?::::(\w+))?"#, .rectangle),
            (#"(\w+)\{\s*\"([^\"]*?)\"\s*\}(?::::(\w+))?"#, .diamond)
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
                let category = categoryFor(mermaidId: id, classSuffixRange: m.range(at: 3), ns: ns)
                nodes.append(ParsedNode(mermaidId: id, type: type, label: label, category: category))
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
            let shape = ShapeNode(type: n.type,
                                  position: CGPoint(x: centerX, y: centerY),
                                  label: n.label,
                                  category: n.category)
            return [PositionedNode(mermaidId: n.mermaidId, shape: shape)]
        }
        let radius: CGFloat = 140
        return nodes.enumerated().map { i, n in
            let angle = (2.0 * .pi / Double(count)) * Double(i) - .pi / 2
            let x = centerX + radius * CGFloat(cos(angle))
            let y = centerY + radius * CGFloat(sin(angle))
            let shape = ShapeNode(type: n.type,
                                  position: CGPoint(x: x, y: y),
                                  label: n.label,
                                  category: n.category)
            return PositionedNode(mermaidId: n.mermaidId, shape: shape)
        }
    }

    /// Kategori i fallback-läge: först :::klass-suffix, annars prefix i id (ui_xxx), annars .ui.
    private static func categoryFor(mermaidId: String, classSuffixRange: NSRange, ns: NSString) -> ShapeCategory {
        if classSuffixRange.location != NSNotFound {
            let raw = ns.substring(with: classSuffixRange)
            if let cat = ShapeCategory(rawValue: raw) { return cat }
        }
        if let underscore = mermaidId.firstIndex(of: "_") {
            let prefix = String(mermaidId[..<underscore])
            if let cat = ShapeCategory(rawValue: prefix) { return cat }
        }
        return .ui
    }
}
