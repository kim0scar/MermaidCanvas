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
        // v50.5 (v5) BUG1: matcha stäng-taggen som "\n-->" (egen rad) — INTE
        // första "-->". En nod/notis med texten "A --> B" skrev tidigare ett
        // rått "-->" inuti JSON-strängen, vilket trunkerade hela state-blocket
        // och tappade ALL fidelity (positioner, färger, notiser…) till
        // fallback-parsern. JSON escapar äkta radbrytningar som \n (2 tecken),
        // så "\n-->" kan bara vara vår egen avslutningsrad (CanvasDocument:46-48).
        guard let start = markdown.range(of: "<!-- mermaidcanvas-state"),
              let end = markdown.range(of: "\n-->", range: start.upperBound..<markdown.endIndex)
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
            let prompt = (node["prompt"] as? String) ?? ""   // v60
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
            // v46: numrerad lista, indrag, tabell-celler
            let hasNumberedList = (node["hasNumberedList"] as? Bool) ?? false
            let indentLevel = (node["indentLevel"] as? Int) ?? 0
            let tableCells = node["tableCells"] as? [[String]]
            let shape = ShapeNode(
                type: type,
                position: CGPoint(x: x, y: y),
                label: label,
                showLabel: showLabel,
                sizeMultiplier: max(0.3, min(3.0, size)),
                widthMultiplier: widthMultiplier,
                heightMultiplier: heightMultiplier,
                note: note,
                prompt: prompt,   // v60
                category: category,
                rotation: max(-360, min(360, rotation)),
                colorOverride: colorOverride,
                linkNumber: linkNumber,
                tableRows: tableRows,
                tableCols: tableCols,
                tableCells: tableCells,
                textStyle: textStyle,
                colorPackId: colorPackId,
                lineEnd: lineEnd,
                textAlignment: textAlignment,
                hasBullets: hasBullets,
                hasNumberedList: hasNumberedList,
                indentLevel: max(0, min(2, indentLevel))
            )
            idMap[mid] = shape.id
            shapes.append(shape)
        }

        // v47: andra-pass — sätt childOfContainerId nu när alla mermaidId → UUID-mappningar
        // är kända. Vi sparar mermaid-id:t som sträng i JSON och slår upp UUID:t här.
        for (idx, node) in nodes.enumerated() {
            guard let parentMid = node["childOfContainerId"] as? String,
                  let parentUUID = idMap[parentMid] else { continue }
            // Skydda mot data där noden refererar sig själv eller en icke-container
            guard idx < shapes.count else { continue }
            if shapes[idx].id != parentUUID {
                shapes[idx].childOfContainerId = parentUUID
            }
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

    private struct RawEdge {
        let from: String
        let arrow: String
        let label: String
        let to: String
    }

    private static func parseMermaid(_ markdown: String) -> ParsedCanvas {
        guard let start = markdown.range(of: "```mermaid"),
              let end = markdown.range(of: "```", range: start.upperBound..<markdown.endIndex)
        else { return ParsedCanvas() }
        let block = String(markdown[start.upperBound..<end.lowerBound])
        let ns = block as NSString

        // Former; valfritt :::klass-suffix. Ordning: circle/pill-tests före rektangel
        // så att ((..)) och ([..]) inte snappas upp av enkelparen-regeln.
        // v61: ocitate label-varianter — Claude skriver ofta A[Text] utan citattecken.
        // Citerade testas först (seen-mängden skyddar mot dubbel-parse).
        let patterns: [(String, ShapeType)] = [
            (#"(\w+)\(\(\s*\"([^\"]*?)\"\s*\)\)(?::::(\w+))?"#, .circle),      // ((".."))
            (#"(\w+)\(\[\s*\"([^\"]*?)\"\s*\]\)(?::::(\w+))?"#, .pill),         // ([".."])
            (#"(\w+)\(\s*\"([^\"]*?)\"\s*\)(?::::(\w+))?"#, .rectangle),        // ("..") v35.1
            (#"(\w+)\[\s*\"([^\"]*?)\"\s*\](?::::(\w+))?"#, .rectangle),        // [".."] bakåtkomp
            (#"(\w+)\{\s*\"([^\"]*?)\"\s*\}(?::::(\w+))?"#, .diamond),          // {".."}
            (#"(\w+)\(\(\s*([^\)\"]+?)\s*\)\)(?::::(\w+))?"#, .circle),         // ((..)) ocitat
            (#"(\w+)\(\[\s*([^\]\"]+?)\s*\]\)(?::::(\w+))?"#, .pill),           // ([..]) ocitat
            (#"(\w+)\(\s*([^\)\"]+?)\s*\)(?::::(\w+))?"#, .rectangle),          // (..) ocitat
            (#"(\w+)\[\s*([^\]\"]+?)\s*\](?::::(\w+))?"#, .rectangle),          // [..] ocitat
            (#"(\w+)\{\s*([^\}\"]+?)\s*\}(?::::(\w+))?"#, .diamond)             // {..} ocitat
        ]

        var seen = Set<String>()
        var nodes: [ParsedNode] = []

        // v44: Parsa subgraph-block FÖRST — varje subgraph blir en container-form.
        // (Före form-mönstren så `subgraph id[Label]` inte snappas som rektangel.)
        // v61: tre syntax-varianter — ["Label"], [Label] och bara `subgraph id`.
        let subgraphPatterns = [
            #"subgraph\s+(\w+)\s*\[\s*\"([^\"]*?)\"\s*\]"#,   // subgraph id ["Label"]
            #"subgraph\s+(\w+)\s*\[\s*([^\]\"]+?)\s*\]"#,     // subgraph id [Label]
            #"subgraph\s+(\w+)\s*$"#                           // subgraph id (label = id)
        ]
        for pattern in subgraphPatterns {
            guard let regex = try? NSRegularExpression(pattern: pattern,
                                                       options: [.anchorsMatchLines]) else { continue }
            let matches = regex.matches(in: block, range: NSRange(location: 0, length: ns.length))
            for m in matches where m.numberOfRanges >= 2 {
                let id = ns.substring(with: m.range(at: 1))
                // v46: hoppa över iphone/canvas-wrapper-subgraphs som inte är användarcontainrar
                guard !seen.contains(id), id != "iphone" else { continue }
                seen.insert(id)
                let label: String
                if m.numberOfRanges >= 3, m.range(at: 2).location != NSNotFound {
                    label = ns.substring(with: m.range(at: 2))
                        .replacingOccurrences(of: "#quot;", with: "\"")
                        .replacingOccurrences(of: "<br/>", with: "\n")
                } else {
                    label = id
                }
                nodes.append(ParsedNode(mermaidId: id, type: .container, label: label, category: .ui))
            }
        }

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

        // v61: Metadata-kommentarer (%% id pos/size/rot/color/prompt/…) — gör
        // mermaid-blocket självbärande utan state-JSON.
        let meta = MermaidMetaComments.parse(block)

        // Kanter som råa id-par — behövs FÖRE positioneringen (layouten följer kanterna).
        // v61: kanterna letas i ett AVSKALAT block där nod-kroppar ([..], (..), {..})
        // och %%-kommentarer tagits bort. Då hittas inline-deklarationer som
        // `a["X"] --> b["Y"]` (så Claude skriver mermaid) — inte bara nakna `a --> b`.
        // v37: Matchar alla 8 pil-kombinationer:
        // --> <-- <--> --- -.-> <-.-> <-.- -.-
        // Längre/mer-specifika alternativ testas först för att undvika överlapp.
        var rawEdges: [RawEdge] = []
        let strippedBlock = stripNodeBodies(block)
        let strippedNs = strippedBlock as NSString
        let edgePattern = #"(\w+)\s*(<-+\.->|<-+->|-+\.->|-+->|<-+\.-+|<-+|-+\.-+|-{3,})\s*(?:\|\s*\"?([^\"|]*?)\"?\s*\|\s*)?(\w+)"#
        if let regex = try? NSRegularExpression(pattern: edgePattern) {
            let matches = regex.matches(in: strippedBlock,
                                        range: NSRange(location: 0, length: strippedNs.length))
            for m in matches where m.numberOfRanges >= 5 {
                let label = m.range(at: 3).location != NSNotFound
                    ? strippedNs.substring(with: m.range(at: 3)) : ""
                rawEdges.append(RawEdge(from: strippedNs.substring(with: m.range(at: 1)),
                                        arrow: strippedNs.substring(with: m.range(at: 2)),
                                        label: label,
                                        to: strippedNs.substring(with: m.range(at: 4))))
            }
        }

        // v61: Nakna id:n utan deklaration (`a --> b` där b aldrig får [Label])
        // blir rektanglar med id:t som text — Claude skriver ofta så.
        for raw in rawEdges {
            for id in [raw.from, raw.to] where !seen.contains(id) {
                seen.insert(id)
                let category = categoryFor(mermaidId: id,
                                           classSuffixRange: NSRange(location: NSNotFound, length: 0),
                                           ns: ns)
                nodes.append(ParsedNode(mermaidId: id, type: .rectangle, label: id, category: category))
            }
        }

        // v61: Positioner. `%% pos:`-kommentar vinner; noder utan får lagrad
        // auto-layout som följer flowchart-riktningen (TD/LR/BT/RL) — inte cirkel.
        let flowDirection = MermaidAutoLayout.direction(in: block)
        let autoPositions = MermaidAutoLayout.positions(
            nodeIds: nodes.map { $0.mermaidId },
            edges: rawEdges.map { (from: $0.from, to: $0.to) },
            direction: flowDirection)

        var idMap: [String: UUID] = [:]
        var collapsedSet: Set<UUID> = []
        let shapes: [ShapeNode] = nodes.map { n in
            let m = meta[n.mermaidId]
            let pos = m?.position ?? autoPositions[n.mermaidId] ?? CGPoint(x: 200, y: 320)
            // line-end skrivs absolut av generatorn → tillbaka till relativ offset
            var lineEnd: CGPoint? = nil
            if let abs = m?.lineEndAbsolute {
                lineEnd = CGPoint(x: abs.x - pos.x, y: abs.y - pos.y)
            }
            // Dold etikett skrivs som " " i nod-syntaxen — återställ från %% name:
            let trimmedLabel = n.label.trimmingCharacters(in: .whitespaces)
            let label = trimmedLabel.isEmpty ? (m?.name ?? trimmedLabel) : n.label
            let shape = ShapeNode(
                type: n.type,
                position: pos,
                label: label,
                showLabel: !(m?.hiddenLabel ?? false),
                sizeMultiplier: max(0.3, min(3.0, m?.size ?? 1.0)),
                widthMultiplier: m?.width.map { max(0.1, min(10.0, $0)) },
                heightMultiplier: m?.height.map { max(0.1, min(10.0, $0)) },
                note: m?.note ?? "",
                prompt: m?.prompt ?? "",
                category: n.category,
                rotation: max(-360, min(360, m?.rotation ?? 0)),
                colorOverride: m?.color,
                linkNumber: m?.link,
                tableRows: m?.tableRows,
                tableCols: m?.tableCols,
                textStyle: m?.textStyleRaw.flatMap { TextStyle(rawValue: $0) } ?? .body,
                colorPackId: m?.packId,
                lineEnd: lineEnd
            )
            if m?.collapsed == true { collapsedSet.insert(shape.id) }
            idMap[n.mermaidId] = shape.id
            return shape
        }

        var edges: [EdgeConnection] = []
        for raw in rawEdges {
            guard let from = idMap[raw.from], let to = idMap[raw.to] else { continue }
            // Bestäm riktning baserat på prefix/suffix
            let direction: EdgeDirection
            let startsWithArrow = raw.arrow.hasPrefix("<")
            let endsWithArrow   = raw.arrow.hasSuffix(">")
            if startsWithArrow && endsWithArrow {
                direction = .bidirectional
            } else if endsWithArrow {
                direction = .forward
            } else if startsWithArrow {
                direction = .backward
            } else {
                direction = .none
            }
            let dashed = raw.arrow.contains(".")
            edges.append(EdgeConnection(from: from, to: to, label: raw.label,
                                         direction: direction,
                                         style: dashed ? .dashed : .solid))
        }

        return ParsedCanvas(shapes: shapes, edges: edges, collapsedIds: collapsedSet)
    }

    /// v61: Skala bort nod-kroppar och kommentarer inför kant-parsning.
    /// `a["Träffa (kanske) Bo"] --> b{Val}` → `a --> b`. Innersta klamrar
    /// tas bort först, upprepat tills inget ändras (strängen krymper varje varv).
    private static func stripNodeBodies(_ block: String) -> String {
        // %%-kommentarer bort (kan innehålla pil-tecken i notis/prompt-text)
        var s = block.split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("%%") }
            .joined(separator: "\n")
        let bracketPatterns = [#"\([^\(\)]*\)"#, #"\[[^\[\]]*\]"#, #"\{[^\{\}]*\}"#]
        var changed = true
        while changed {
            changed = false
            for pattern in bracketPatterns {
                guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
                let ns = s as NSString
                let next = regex.stringByReplacingMatches(
                    in: s, range: NSRange(location: 0, length: ns.length), withTemplate: "")
                if next != s {
                    s = next
                    changed = true
                }
            }
        }
        // :::kategori-suffix bort (annars blir "ui" i `a:::ui --> b` en fantomnod)
        s = replacing(#":::\w+"#, in: s, with: "")
        // Normalisera äldre pil-skrivsätt till |label|-formen som kant-regexen förstår:
        // `a -- text --> b` → `a -->|text| b`, `a -. text .-> b`, `a == text ==> b`
        s = replacing(#"--\s+([^-<>|\n]+?)\s+-->"#, in: s, with: "-->|$1|")
        s = replacing(#"-\.\s+([^-<>|\n]+?)\s+\.->"#, in: s, with: "-.->|$1|")
        s = replacing(#"==\s+([^=<>|\n]+?)\s+==>"#, in: s, with: "==>|$1|")
        // Tjocka pilar (==>) → vanliga pilar — appen har ingen tjock-stil
        s = replacing(#"<=+>"#, in: s, with: "<-->")
        s = replacing(#"=+>"#, in: s, with: "-->")
        return s
    }

    private static func replacing(_ pattern: String, in text: String, with template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let ns = text as NSString
        return regex.stringByReplacingMatches(
            in: text, range: NSRange(location: 0, length: ns.length), withTemplate: template)
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
