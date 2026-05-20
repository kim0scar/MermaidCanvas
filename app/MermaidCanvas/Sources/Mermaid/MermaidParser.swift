import Foundation
import CoreGraphics

enum MermaidParser {
    struct ParsedCanvas {
        var title: String = ""
        var shapes: [ShapeNode] = []
        var edges: [EdgeConnection] = []
        var canvasSize: CGSize? = nil
        var specType: SpecType = .general
        var platform: Platform? = nil  // v27 — nil = härleds från specType vid replaceAll
        var activeShapePacks: Set<ShapePack>? = nil  // v27 — nil = härleds från specType
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
        if let p = frontmatter.platform {
            result.platform = p
        }
        if let packs = frontmatter.shapePacks {
            result.activeShapePacks = packs
        }
        return result
    }

    // MARK: - Frontmatter

    private struct Frontmatter {
        var title: String? = nil
        var specType: SpecType? = nil
        var platform: Platform? = nil
        var shapePacks: Set<ShapePack>? = nil
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
            case "platform":
                if let p = Platform(rawValue: value) { fm.platform = p }
            case "shape_packs":
                let packs = value.split(separator: ",")
                    .compactMap { ShapePack(rawValue: $0.trimmingCharacters(in: .whitespaces)) }
                if !packs.isEmpty { fm.shapePacks = Set(packs) }
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
            // v23: textstil + färg-paket (optional för bakåtkompatibilitet)
            let textStyleRaw = (node["textStyle"] as? String) ?? TextStyle.body.rawValue
            let textStyle = TextStyle(rawValue: textStyleRaw) ?? .body
            let colorPackId = node["colorPackId"] as? String
            // v35.1: separat bredd/höjd-skalning (optional för bakåtkompatibilitet)
            let widthMultiplierRaw = node["widthMultiplier"]
            let widthMultiplier: CGFloat? = widthMultiplierRaw.map {
                max(0.1, min(10.0, numberValue($0))) }
            let heightMultiplierRaw = node["heightMultiplier"]
            let heightMultiplier: CGFloat? = heightMultiplierRaw.map {
                max(0.1, min(10.0, numberValue($0))) }
            // v35.1: lineEnd för lösa linjer/pilar (relativ offset från position)
            var lineEnd: CGPoint? = nil
            if let leDict = node["lineEnd"] as? [String: Any],
               let lx = leDict["x"], let ly = leDict["y"] {
                lineEnd = CGPoint(x: numberValue(lx), y: numberValue(ly))
            }
            // v37: textjustering + punktlista
            let textAlignRaw = (node["textAlignment"] as? String) ?? TextAlignMode.center.rawValue
            let textAlignment = TextAlignMode(rawValue: textAlignRaw) ?? .center
            let hasBullets = (node["hasBullets"] as? Bool) ?? false
            let shape = ShapeNode(
                type: type,
                position: CGPoint(x: x, y: y),
                label: label,
                showLabel: showLabel,
                sizeMultiplier: max(0.3, min(3.0, size)),
                widthMultiplier: widthMultiplier,
                heightMultiplier: heightMultiplier,
                note: note,
                category: category,
                rotation: max(-360, min(360, rotation)),
                colorOverride: colorOverride,
                linkNumber: linkNumber,
                tableRows: tableRows,
                tableCols: tableCols,
                textStyle: textStyle,
                colorPackId: colorPackId,
                lineEnd: lineEnd,
                textAlignment: textAlignment,
                hasBullets: hasBullets
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
            // v37: läs direction (ny) med fallback till bidirectional: Bool (gammal data)
            let directionRaw = edge["direction"] as? String
            let bidi = (edge["bidirectional"] as? Bool) ?? false
            let direction: EdgeDirection
            if let dr = directionRaw, let d = EdgeDirection(rawValue: dr) {
                direction = d
            } else {
                direction = bidi ? .bidirectional : .forward
            }
            let styleRaw = (edge["style"] as? String) ?? EdgeStyle.solid.rawValue
            let style = EdgeStyle(rawValue: styleRaw) ?? .solid
            var waypoints: [EdgeWaypoint] = []
            if let wpArr = edge["waypoints"] as? [[String: Any]] {
                for wp in wpArr {
                    let wx = wp["x"].map { numberValue($0) } ?? 0
                    let wy = wp["y"].map { numberValue($0) } ?? 0
                    waypoints.append(EdgeWaypoint(x: Double(wx), y: Double(wy)))
                }
            }
            edgeList.append(EdgeConnection(from: fromId, to: toId, label: label,
                                            direction: direction, style: style,
                                            waypoints: waypoints))
        }

        // Parse collapsed-array (mermaidIds → UUIDs via idMap)
        var collapsedSet: Set<UUID> = []
        if let collapsedRaw = obj["collapsed"] as? [String] {
            for mid in collapsedRaw {
                if let uuid = idMap[mid] { collapsedSet.insert(uuid) }
            }
        }

        // v27: Platform + form-paketer från JSON (om finns)
        var parsedPlatform: Platform? = nil
        if let platRaw = obj["platform"] as? String,
           let p = Platform(rawValue: platRaw) {
            parsedPlatform = p
        }
        var parsedPacks: Set<ShapePack>? = nil
        if let packsArr = obj["shapePacks"] as? [String] {
            let packs = packsArr.compactMap { ShapePack(rawValue: $0) }
            if !packs.isEmpty { parsedPacks = Set(packs) }
        }

        var result = ParsedCanvas(shapes: shapes,
                                  edges: edgeList,
                                  canvasSize: parsedCanvasSize,
                                  collapsedIds: collapsedSet)
        result.platform = parsedPlatform
        result.activeShapePacks = parsedPacks
        return result
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

        // Former; valfritt :::klass-suffix. Ordning: circle/pill-tests före rektangel
        // så att ((..)) och ([..]) inte snappas upp av enkelparen-regeln.
        let patterns: [(String, ShapeType)] = [
            (#"(\w+)\(\(\s*\"([^\"]*?)\"\s*\)\)(?::::(\w+))?"#, .circle),      // ((".."))
            (#"(\w+)\(\[\s*\"([^\"]*?)\"\s*\]\)(?::::(\w+))?"#, .pill),         // ([".."])
            (#"(\w+)\(\s*\"([^\"]*?)\"\s*\)(?::::(\w+))?"#, .rectangle),        // ("..") v35.1
            (#"(\w+)\[\s*\"([^\"]*?)\"\s*\](?::::(\w+))?"#, .rectangle),        // [".."] bakåtkomp
            (#"(\w+)\{\s*\"([^\"]*?)\"\s*\}(?::::(\w+))?"#, .diamond)           // {".."}
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
        // v37: Matchar alla 8 pil-kombinationer:
        // --> <-- <--> --- -.-> <-.-> <-.- -.-
        // Längre/mer-specifika alternativ testas först för att undvika överlapp.
        let edgePattern = #"(\w+)\s*(<-+\.->|<-+->|-+\.->|-+->|<-+\.-+|<-+|-+\.-+|-{3,})\s*(?:\|\s*\"?([^\"|]*?)\"?\s*\|\s*)?(\w+)"#
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
                // Bestäm riktning baserat på prefix/suffix
                let direction: EdgeDirection
                let startsWithArrow = arrowStr.hasPrefix("<")
                let endsWithArrow   = arrowStr.hasSuffix(">")
                if startsWithArrow && endsWithArrow {
                    direction = .bidirectional
                } else if endsWithArrow {
                    direction = .forward
                } else if startsWithArrow {
                    direction = .backward
                } else {
                    direction = .none
                }
                let dashed = arrowStr.contains(".")
                edges.append(EdgeConnection(from: from, to: to, label: label,
                                             direction: direction,
                                             style: dashed ? .dashed : .solid))
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
            if let cat = ShapeCategory(rawValue: raw) { return migrateDeprecated(cat) }
        }
        if let underscore = mermaidId.firstIndex(of: "_") {
            let prefix = String(mermaidId[..<underscore])
            if let cat = ShapeCategory(rawValue: prefix) { return migrateDeprecated(cat) }
        }
        return .ui
    }

    /// v31: deprecated kategorier (Roadmap/Architecture-pack) migreras till `.note`.
    /// Inga former tappas — bara färg/kategori byts ut.
    /// `.input`/`.agent`/`.tool`/`.router`/`.memory`/`.output` behålls eftersom de återanvänds
    /// av Prompt-Process-pack (delar SpecType.flow).
    private static func migrateDeprecated(_ cat: ShapeCategory) -> ShapeCategory {
        switch cat {
        case .feat, .milestone, .blocker, .future,
             .folder, .file, .module, .service, .data:
            return .note
        default:
            return cat
        }
    }
}
