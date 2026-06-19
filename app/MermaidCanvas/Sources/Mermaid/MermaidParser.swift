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
        /// v63: kollapsade GRENAR (EdgeConnection-id:n). Gamla filer med
        /// nod-kollaps migreras: alla nodens utgående kanter blir kollapsade.
        var collapsedEdgeIds: Set<UUID> = []
        /// v66: legend — kategori-rawValue → Kims betydelse-text.
        var legend: [String: String] = [:]
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
        // v66: legend — läs från state-JSON eller %% legend-rader (fallback)
        if result.legend.isEmpty {
            if let regex = try? NSRegularExpression(
                pattern: #"%%\s+legend\s+(\w+):\s+(.+)"#) {
                let ns = markdown as NSString
                for m in regex.matches(in: markdown,
                                       range: NSRange(location: 0, length: ns.length))
                    where m.numberOfRanges >= 3 {
                    let key = ns.substring(with: m.range(at: 1))
                    let text = ns.substring(with: m.range(at: 2))
                        .trimmingCharacters(in: .whitespaces)
                    result.legend[key] = text
                }
            }
        }
        // v66-migrering: linjer/pilar äger nu sin längd via lineEnd DIREKT
        // (ändpunkts-handtag). Gamla filer skalade lineEnd med multipliers vid
        // rendering — baka in dem så strecket ser likadant ut som förut.
        for i in result.shapes.indices {
            let s = result.shapes[i]
            guard s.type == .line || s.type == .arrow, let e = s.lineEnd,
                  s.effectiveWidth != 1 || s.effectiveHeight != 1 else { continue }
            result.shapes[i].lineEnd = CGPoint(x: e.x * s.effectiveWidth,
                                               y: e.y * s.effectiveHeight)
            result.shapes[i].sizeMultiplier = 1
            result.shapes[i].widthMultiplier = nil
            result.shapes[i].heightMultiplier = nil
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
            let strokeColorOverride = node["strokeColor"] as? String  // v62
            let linkNumber = node["linkNumber"] as? Int
            let skillNumber = node["skillNumber"] as? Int  // v74
            let tableRows = node["tableRows"] as? Int
            let tableCols = node["tableCols"] as? Int
            // v23: textstil + färg-paket (optional för bakåtkompatibilitet)
            let textStyleRaw = (node["textStyle"] as? String) ?? TextStyle.body.rawValue
            let textStyle = TextStyle(rawValue: textStyleRaw) ?? .body
            let colorPackId = node["colorPackId"] as? String
            // v35.1: separat bredd/höjd-skalning (optional för bakåtkompatibilitet)
            // F (Kims beslut: filen ÄR sanningen) — ingen tyst kapning, bara golv mot 0/negativ.
            let widthMultiplierRaw = node["widthMultiplier"]
            let widthMultiplier: CGFloat? = widthMultiplierRaw.map { max(0.01, numberValue($0)) }
            let heightMultiplierRaw = node["heightMultiplier"]
            let heightMultiplier: CGFloat? = heightMultiplierRaw.map { max(0.01, numberValue($0)) }
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
                sizeMultiplier: max(0.01, size),
                widthMultiplier: widthMultiplier,
                heightMultiplier: heightMultiplier,
                note: note,
                prompt: prompt,   // v60
                category: category,
                rotation: rotation,
                colorOverride: colorOverride,
                strokeColorOverride: strokeColorOverride,
                linkNumber: linkNumber,
                skillNumber: skillNumber,  // v74
                tableRows: tableRows,
                tableCols: tableCols,
                tableCells: tableCells,
                textStyle: textStyle,
                colorPackId: colorPackId,
                lineEnd: lineEnd,
                textAlignment: textAlignment,
                hasBullets: hasBullets,
                hasNumberedList: hasNumberedList,
                indentLevel: max(0, indentLevel)
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
        var collapsedEdgeSet: Set<UUID> = []
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
            // v62: etikett-placering (default .below för gamla filer)
            let placementRaw = (edge["labelPlacement"] as? String) ?? ""
            let labelPlacement = EdgeLabelPlacement(rawValue: placementRaw) ?? .below
            let connection = EdgeConnection(from: fromId, to: toId, label: label,
                                            direction: direction, style: style,
                                            waypoints: waypoints,
                                            labelPlacement: labelPlacement,
                                            colorHex: edge["color"] as? String,
                                            fromSide: (edge["fromSide"] as? String)
                                                .flatMap(EdgeSide.init))
            // v63: kollaps per gren — flagga på kant-dicten
            if (edge["collapsed"] as? Bool) == true {
                collapsedEdgeSet.insert(connection.id)
            }
            edgeList.append(connection)
        }

        // v63-migration: gamla filer har "collapsed": [nod-mermaidId] →
        // alla nodens utgående kanter blir kollapsade grenar.
        if let collapsedRaw = obj["collapsed"] as? [String] {
            for mid in collapsedRaw {
                guard let uuid = idMap[mid] else { continue }
                for e in edgeList where e.from == uuid {
                    collapsedEdgeSet.insert(e.id)
                }
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
                                  collapsedEdgeIds: collapsedEdgeSet)
        result.platform = parsedPlatform
        result.activeShapePacks = parsedPacks
        // v66: legend ur state-JSON
        if let lg = obj["legend"] as? [String: String] {
            result.legend = lg
        }
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
            (#"(\w+)\[\(\s*\"([^\"]*?)\"\s*\)\](?::::(\w+))?"#, .cylinder),     // [(".." )] v69 cylinder
            (#"(\w+)\(\s*\"([^\"]*?)\"\s*\)(?::::(\w+))?"#, .rectangle),        // ("..") v35.1
            (#"(\w+)\[\s*\"([^\"]*?)\"\s*\](?::::(\w+))?"#, .rectangle),        // [".."] bakåtkomp
            (#"(\w+)\{\s*\"([^\"]*?)\"\s*\}(?::::(\w+))?"#, .diamond),          // {".."}
            (#"(\w+)\(\(\s*([^\)\"]+?)\s*\)\)(?::::(\w+))?"#, .circle),         // ((..)) ocitat
            (#"(\w+)\(\[\s*([^\]\"]+?)\s*\]\)(?::::(\w+))?"#, .pill),           // ([..]) ocitat
            (#"(\w+)\[\(\s*([^\)\"]+?)\s*\)\](?::::(\w+))?"#, .cylinder),       // [(..)] ocitat cylinder v69
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
                // v74: kategori via id-prefix (skill_N5 → .skill) — tidigare hårdkodad .ui,
                // vilket tappade skill-identiteten i ren-mermaid-round-trip.
                let category = categoryFor(mermaidId: id,
                                           classSuffixRange: NSRange(location: NSNotFound, length: 0),
                                           ns: ns)
                nodes.append(ParsedNode(mermaidId: id, type: .container, label: label, category: category))
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

        // v62/v63: `%% e<index> nyckel: värde`-kommentarer (kant-index i emit-ordning)
        var edgePlacements: [Int: EdgeLabelPlacement] = [:]
        var edgeColors: [Int: String] = [:]
        var edgeFromSides: [Int: EdgeSide] = [:]
        var edgeWaypoints: [Int: [EdgeWaypoint]] = [:]   // F2: waypoints överlever ren mermaid
        var collapsedEdgeIndices: Set<Int> = []
        if let regex = try? NSRegularExpression(pattern: #"%%\s+e(\d+)\s+(\w+):\s+(\S+)"#) {
            for m in regex.matches(in: block, range: NSRange(location: 0, length: ns.length))
                where m.numberOfRanges >= 4 {
                guard let idx = Int(ns.substring(with: m.range(at: 1))) else { continue }
                let key = ns.substring(with: m.range(at: 2))
                let value = ns.substring(with: m.range(at: 3))
                switch key {
                case "labelPlacement":
                    if let p = EdgeLabelPlacement(rawValue: value) { edgePlacements[idx] = p }
                case "color":
                    edgeColors[idx] = value
                case "fromSide":
                    if let s = EdgeSide(rawValue: value) { edgeFromSides[idx] = s }
                case "collapsed":
                    if value == "true" { collapsedEdgeIndices.insert(idx) }
                case "waypoint":
                    // Flera "%% e<i> waypoint: x,y"-rader per kant — ackumuleras i ordning.
                    let parts = value.split(separator: ",")
                    if parts.count == 2, let wx = Double(parts[0]), let wy = Double(parts[1]) {
                        edgeWaypoints[idx, default: []].append(EdgeWaypoint(x: wx, y: wy))
                    }
                default:
                    break
                }
            }
        }

        // v61: Positioner. `%% pos:`-kommentar vinner; noder utan får lagrad
        // auto-layout som följer flowchart-riktningen (TD/LR/BT/RL) — inte cirkel.
        // v66: flow-filer (skill-kedjor) utan EXPLICIT riktning får LR —
        // horisontellt som n8n. Explicit "flowchart TD" respekteras alltid.
        var flowDirection = MermaidAutoLayout.direction(in: block)
        if flowDirection == .td, markdown.contains("spec_type: flow") {
            let hasExplicit = block
                .split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .first { $0.lowercased().hasPrefix("flowchart") || $0.lowercased().hasPrefix("graph") }
                .map { $0.split(separator: " ").count >= 2 } ?? false
            if !hasExplicit { flowDirection = .lr }
        }
        let autoPositions = MermaidAutoLayout.positions(
            nodeIds: nodes.map { $0.mermaidId },
            edges: rawEdges.map { (from: $0.from, to: $0.to) },
            direction: flowDirection)

        // v61.2: subgraph-medlemskap — noder deklarerade mellan `subgraph X` och `end`
        // är containerns barn. Utan detta ser edge-routingen containern som hinder
        // för barnens pilar (pilarna routas långt åt sidan).
        var membership: [String: String] = [:]   // nod-id → container-id
        var currentContainer: String? = nil
        for rawLine in block.split(separator: "\n", omittingEmptySubsequences: true) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            if line.hasPrefix("subgraph") {
                let rest = line.dropFirst("subgraph".count).trimmingCharacters(in: .whitespaces)
                let id = rest.prefix { $0.isLetter || $0.isNumber || $0 == "_" }
                currentContainer = id.isEmpty ? nil : String(id)
                continue
            }
            if line == "end" { currentContainer = nil; continue }
            guard let container = currentContainer, !line.hasPrefix("%%") else { continue }
            let nodeId = line.prefix { $0.isLetter || $0.isNumber || $0 == "_" }
            if !nodeId.isEmpty { membership[String(nodeId)] = container }
        }

        var idMap: [String: UUID] = [:]
        var legacyCollapsedShapeIds: Set<UUID> = []  // v63: migreras till grenar nedan
        var shapes: [ShapeNode] = nodes.map { n in
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
            // v67: explicit %% shape-type vinner över mermaid-kroppen (phoneFrame/table/link saknar egen syntax).
            let resolvedType = m?.shapeTypeRaw.flatMap { ShapeType(rawValue: $0) } ?? n.type
            let shape = ShapeNode(
                type: resolvedType,
                position: pos,
                label: label,
                showLabel: !(m?.hiddenLabel ?? false),
                sizeMultiplier: max(0.01, m?.size ?? 1.0),
                widthMultiplier: m?.width.map { max(0.01, $0) },
                heightMultiplier: m?.height.map { max(0.01, $0) },
                note: m?.note ?? "",
                prompt: m?.prompt ?? "",
                category: n.category,
                rotation: m?.rotation ?? 0,
                colorOverride: m?.color,
                strokeColorOverride: m?.stroke,
                linkNumber: m?.link,
                skillNumber: m?.skillNumber,  // v74
                tableRows: m?.tableRows,
                tableCols: m?.tableCols,
                tableCells: m?.tableCells,   // MB steg 6: celler överlever ren mermaid
                textStyle: m?.textStyleRaw.flatMap { TextStyle(rawValue: $0) } ?? .body,
                colorPackId: m?.packId,
                lineEnd: lineEnd,
                // F2: justering + listor + indrag överlever ren mermaid (via %%)
                textAlignment: m?.textAlignRaw.flatMap { TextAlignMode(rawValue: $0) } ?? .center,
                hasBullets: m?.hasBullets ?? false,
                hasNumberedList: m?.hasNumberedList ?? false,
                indentLevel: max(0, m?.indentLevel ?? 0)
            )
            if m?.collapsed == true { legacyCollapsedShapeIds.insert(shape.id) }
            idMap[n.mermaidId] = shape.id
            return shape
        }

        // v61.2: andra-pass — koppla barnen till sina containrar (idMap är nu komplett)
        for (i, n) in nodes.enumerated() {
            guard let containerMid = membership[n.mermaidId],
                  let parentUUID = idMap[containerMid],
                  parentUUID != shapes[i].id else { continue }
            shapes[i].childOfContainerId = parentUUID
        }

        var edges: [EdgeConnection] = []
        var collapsedEdges: Set<UUID> = []
        for (i, raw) in rawEdges.enumerated() {
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
            let connection = EdgeConnection(from: from, to: to, label: raw.label,
                                            direction: direction,
                                            style: dashed ? .dashed : .solid,
                                            waypoints: edgeWaypoints[i] ?? [],   // F2
                                            labelPlacement: edgePlacements[i] ?? .below,
                                            colorHex: edgeColors[i],
                                            fromSide: edgeFromSides[i])
            // v63: kollaps per gren (index = rå-kantens ordning, samma som i:t ovan)
            if collapsedEdgeIndices.contains(i) {
                collapsedEdges.insert(connection.id)
            }
            edges.append(connection)
        }

        // v63-migration: gamla `%% <nod> collapsed` → nodens alla utgående grenar.
        for e in edges where legacyCollapsedShapeIds.contains(e.from) {
            collapsedEdges.insert(e.id)
        }
        // G1: canvas-måtten ur den parseade %%-raden (round-trippar i REN mermaid).
        var parsedSize: CGSize? = nil
        if let r = try? NSRegularExpression(pattern: #"%%\s*canvas-size:\s*([0-9.]+)\s*,\s*([0-9.]+)"#),
           let m = r.firstMatch(in: block, range: NSRange(location: 0, length: ns.length)),
           m.numberOfRanges >= 3,
           let w = Double(ns.substring(with: m.range(at: 1))),
           let h = Double(ns.substring(with: m.range(at: 2))) {
            parsedSize = CGSize(width: w, height: h)
        }
        var result = ParsedCanvas(shapes: shapes, edges: edges, collapsedEdgeIds: collapsedEdges)
        result.canvasSize = parsedSize
        return result
    }

}
