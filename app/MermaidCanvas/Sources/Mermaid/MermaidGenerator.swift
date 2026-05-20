import Foundation

// v43: Routing runt obstacles görs visuellt i appen (EdgeRouting.swift) — Mermaid sköter
// sin egen layout via "curve: basis"-direktivet (init-raden i generate(...)). Vi behöver
// alltså INTE serialisera waypoints eller routing-info per kant; appens routing är endast
// renderings-overlay och påverkar inte filens innehåll.
enum MermaidGenerator {
    static func generate(shapes: [ShapeNode],
                         edges: [EdgeConnection],
                         canvasSize: CGSize = .zero,
                         specType: SpecType = .ui,
                         collapsedIds: Set<UUID> = []) -> String {
        guard !shapes.isEmpty else {
            // v32: bara header — inget diagnostiskt "Tom canvas"-meddelande som kan tolkas som fel.
            return "%%{init: {\"flowchart\": {\"curve\": \"basis\"}}}%%\nflowchart TD\n"
        }
        // v38: curve:basis ger mjuka bezier-kurvor i Mermaid Live (speglar in-app-utseendet).
        var lines: [String] = [
            "%%{init: {\"flowchart\": {\"curve\": \"basis\"}}}%%",
            "flowchart TD"
        ]
        let mermaidIds = makeMermaidIds(for: shapes)

        // Per-mode "ram"-wrapper. UI-läge får iPhone-subgraph; övriga utan wrapper.
        let needsFrame = (specType == .ui)
        let indent = needsFrame ? "        " : "    "

        if needsFrame {
            let w = canvasSize.width > 0 ? Int(canvasSize.width.rounded()) : 393
            let h = canvasSize.height > 0 ? Int(canvasSize.height.rounded()) : 852
            lines.append("    subgraph iphone[\"iPhone \(w)×\(h)\"]")
            lines.append("        direction TB")
        }

        // Nodes
        for shape in shapes {
            let id = mermaidIds[shape.id]!
            let label = shape.showLabel ? (shape.label.isEmpty ? " " : shape.label) : " "
            let safe = escape(label)
            let body = shapeBody(for: shape.type, label: safe)
            lines.append("\(indent)\(id)\(body):::\(shape.category.rawValue)")
            // Synliga metadata-kommentarer för Claude och människor:
            if !shape.note.isEmpty {
                lines.append("\(indent)%% \(id) note: \(oneLine(shape.note))")
            }
            if abs(shape.sizeMultiplier - 1.0) > 0.01 {
                lines.append("\(indent)%% \(id) size: \(String(format: "%.1f", shape.sizeMultiplier))")
            }
            if abs(shape.rotation) > 0.5 {
                lines.append("\(indent)%% \(id) rot: \(Int(shape.rotation.rounded()))°")
            }
            if !shape.showLabel {
                lines.append("\(indent)%% \(id) hidden-label")
            }
            if let color = shape.colorOverride {
                lines.append("\(indent)%% \(id) color: \(color)")
            }
            // v35.1: separat bredd/höjd om de avviker från sizeMultiplier
            if let w = shape.widthMultiplier {
                lines.append("\(indent)%% \(id) width: \(String(format: "%.2f", w))")
            }
            if let h = shape.heightMultiplier {
                lines.append("\(indent)%% \(id) height: \(String(format: "%.2f", h))")
            }
            // v35.1: absolut slutposition för lösa linjer/pilar — synligt för Claude
            if let end = shape.lineEnd {
                let absX = Int((shape.position.x + end.x).rounded())
                let absY = Int((shape.position.y + end.y).rounded())
                lines.append("\(indent)%% \(id) line-end: \(absX),\(absY)")
            }
            if let link = shape.linkNumber {
                lines.append("\(indent)%% \(id) link: \(link)")
            }
            if shape.type == .table {
                let r = shape.tableRows ?? 3
                let c = shape.tableCols ?? 3
                lines.append("\(indent)%% \(id) table: \(r)×\(c)")
            }
            if collapsedIds.contains(shape.id) {
                lines.append("\(indent)%% \(id) collapsed")
            }
            // v23: textstil + färg-paket
            if shape.textStyle != .body {
                lines.append("\(indent)%% \(id) style: \(shape.textStyle.rawValue)")
            }
            if let packId = shape.colorPackId {
                lines.append("\(indent)%% \(id) pack: \(packId)")
            }
            lines.append("\(indent)%% \(id) pos: \(Int(shape.position.x.rounded())),\(Int(shape.position.y.rounded()))")
        }

        // v35.1: Layout-hints för ouppkopplade former — osynliga ~~~-länkar
        // som tvingar Mermaid att rendera i rätt kolumner/rader baserat på position.
        let hints = layoutHints(shapes: shapes, edges: edges, mermaidIds: mermaidIds, indent: indent)
        for hint in hints { lines.append(hint) }

        // v35.1: Unified style-taggar per nod — storlek + färg + text-transparens.
        // En enda `style id ...`-rad per nod kombinerar alla CSS-egenskaper.
        for shape in shapes {
            guard let id = mermaidIds[shape.id] else { continue }
            var styleProps: [String] = []

            // Font-size: textStyle.fontSize × sizeMultiplier-genomsnitt.
            // body×1.0 = 14px = Mermaids default → hoppa över för att hålla koden ren.
            let visSize = Double((shape.effectiveWidth + shape.effectiveHeight) / 2.0)
            let baseFontPt: Double
            switch shape.textStyle {
            case .r1:   baseFontPt = 20
            case .r2:   baseFontPt = 17
            case .r3:   baseFontPt = 14
            case .body: baseFontPt = 14   // matchar Mermaids default
            }
            let scaledFont = max(8, Int((baseFontPt * visSize).rounded()))
            if abs(scaledFont - 14) > 1 {
                styleProps.append("font-size:\(scaledFont)px")
            }
            // Padding skalas bara med form-storlek (inte textstil)
            if abs(visSize - 1.0) > 0.01 {
                let padding = max(2, Int((8.0 * visSize).rounded()))
                styleProps.append("padding:\(padding)px")
            }
            // Font-weight: r1=bold, r2=600(semibold), r3=500(medium)
            switch shape.textStyle {
            case .r1:   styleProps.append("font-weight:bold")
            case .r2:   styleProps.append("font-weight:600")
            case .r3:   styleProps.append("font-weight:500")
            case .body: break
            }

            // Färg: colorOverride → colorPack → text-transparens (i prioritetsordning).
            // colorOverride och colorPack emitteras som inline style → slår alltid igenom
            // mot classDef:s vita fyllning.
            if let color = shape.colorOverride, !color.isEmpty {
                styleProps.append("fill:\(color)")
                styleProps.append("stroke:\(color)")
            } else if let packId = shape.colorPackId, packId != "none",
                      let hex = colorPackHex(packId) {
                // v35.1: ColorPack-färger → inline style så de syns i Mermaid-export.
                styleProps.append("fill:\(hex.fill)")
                styleProps.append("stroke:\(hex.stroke)")
                styleProps.append("color:\(hex.text)")
            } else if shape.type == .text {
                // Text-shapes ska vara transparenta — classDef textOnly är definierad
                // men appliceras aldrig automatiskt; inline style tar prioritet.
                styleProps.append("fill:transparent")
                styleProps.append("stroke:transparent")
            }

            guard !styleProps.isEmpty else { continue }
            lines.append("\(indent)style \(id) \(styleProps.joined(separator: ","))")
        }

        // Edges
        for (i, edge) in edges.enumerated() {
            guard let from = mermaidIds[edge.from], let to = mermaidIds[edge.to] else { continue }
            // v37: linje-stil × riktning — 8 kombinationer
            let arrow: String
            switch (edge.direction, edge.style) {
            case (.forward,       .solid):  arrow = "-->"
            case (.forward,       .dashed): arrow = "-.->"
            case (.backward,      .solid):  arrow = "<--"
            case (.backward,      .dashed): arrow = "<-.-"
            case (.bidirectional, .solid):  arrow = "<-->"
            case (.bidirectional, .dashed): arrow = "<-.->"
            case (.none,          .solid):  arrow = "---"
            case (.none,          .dashed): arrow = "-.-"
            }
            if edge.label.isEmpty {
                lines.append("\(indent)\(from) \(arrow) \(to)")
            } else {
                lines.append("\(indent)\(from) \(arrow)|\"\(escape(edge.label))\"| \(to)")
            }
            // Waypoints som synliga kommentarer
            for wp in edge.waypoints {
                lines.append("\(indent)%% e\(i) waypoint: \(Int(wp.x.rounded())),\(Int(wp.y.rounded()))")
            }
        }

        if needsFrame {
            lines.append("    end")
        }

        // classDef per använd kategori + text-class + frame-class.
        let used = Set(shapes.map { $0.category })
        lines.append("")
        for cat in ShapeCategory.allCases where used.contains(cat) {
            lines.append("    classDef \(cat.rawValue) \(cat.mermaidClassDef);")
        }
        // Transparent klass för text-shapes så de inte ärver fyllning.
        if shapes.contains(where: { $0.type == .text }) {
            lines.append("    classDef textOnly fill:transparent,stroke:transparent,color:#111827;")
        }
        if needsFrame {
            lines.append("    classDef iphone fill:#f8fafc,stroke:#0f172a,stroke-width:2px,color:#0f172a;")
            lines.append("    class iphone iphone;")
        }

        return lines.joined(separator: "\n")
    }

    static func canvasStateJSON(shapes: [ShapeNode],
                                edges: [EdgeConnection],
                                canvasSize: CGSize,
                                specType: SpecType = .ui,
                                platform: Platform = .blank,
                                activeShapePacks: Set<ShapePack> = [.basic],
                                collapsedIds: Set<UUID> = []) -> String {
        let mermaidIds = makeMermaidIds(for: shapes)
        let nodes: [[String: Any]] = shapes.map { shape in
            var n: [String: Any] = [
                "id": mermaidIds[shape.id]!,
                "x": Int(shape.position.x.rounded()),
                "y": Int(shape.position.y.rounded()),
                "label": shape.label,
                "type": shape.type.rawValue,
                "category": shape.category.rawValue,
                "showLabel": shape.showLabel,
                "size": Double(shape.sizeMultiplier),
                "rotation": Double(shape.rotation),
                "note": shape.note
            ]
            if let color = shape.colorOverride { n["color"] = color }
            if let link = shape.linkNumber { n["linkNumber"] = link }
            if shape.type == .table {
                n["tableRows"] = shape.tableRows ?? 3
                n["tableCols"] = shape.tableCols ?? 3
            }
            // v23: textstil + färg-paket
            if shape.textStyle != .body {
                n["textStyle"] = shape.textStyle.rawValue
            }
            if let packId = shape.colorPackId {
                n["colorPackId"] = packId
            }
            // v35.1: separat bredd/höjd-skalning
            if let w = shape.widthMultiplier  { n["widthMultiplier"]  = Double(w) }
            if let h = shape.heightMultiplier { n["heightMultiplier"] = Double(h) }
            // v35.1: endpoint för lösa linjer/pilar (relativ offset från position)
            if let end = shape.lineEnd {
                n["lineEnd"] = ["x": Double(end.x), "y": Double(end.y)]
            }
            // v37: textjustering + punktlista (sparas bara om ej default)
            if shape.textAlignment != .center {
                n["textAlignment"] = shape.textAlignment.rawValue
            }
            if shape.hasBullets {
                n["hasBullets"] = true
            }
            return n
        }
        let edgeArr: [[String: Any]] = edges.compactMap { edge in
            guard let f = mermaidIds[edge.from], let t = mermaidIds[edge.to] else { return nil }
            var e: [String: Any] = [
                "from": f,
                "to": t,
                "label": edge.label,
                "direction": edge.direction.rawValue,
                "style": edge.style.rawValue
            ]
            if !edge.waypoints.isEmpty {
                e["waypoints"] = edge.waypoints.map { ["x": $0.x, "y": $0.y] }
            }
            return e
        }
        let collapsedMermaidIds = collapsedIds.compactMap { mermaidIds[$0] }

        // iPhone-frame inom canvasen — så Claude exakt kan översätta
        // canvas-position till iPhone-screen-position.
        let iphoneRect = iPhoneFrameMath.frame(in: canvasSize)
        let iphone: [String: Any] = [
            "x": Int(iphoneRect.origin.x.rounded()),
            "y": Int(iphoneRect.origin.y.rounded()),
            "width": Int(iphoneRect.width.rounded()),
            "height": Int(iphoneRect.height.rounded()),
            "designWidth": Int(iPhoneFrameMath.designSize.width),
            "designHeight": Int(iPhoneFrameMath.designSize.height)
        ]

        let canvas: [String: Any] = [
            "width": Int(canvasSize.width.rounded()),
            "height": Int(canvasSize.height.rounded()),
            "shapeBaseWidth": 120,
            "shapeBaseHeight": 80,
            "unit": "pt",
            "iphoneFrame": iphone
        ]
        let packsArr = ShapePack.allCases
            .filter { activeShapePacks.contains($0) }
            .map { $0.rawValue }
        var dict: [String: Any] = [
            "canvas": canvas,
            "specType": specType.rawValue,
            "platform": platform.rawValue,
            "shapePacks": packsArr,
            "nodes": nodes,
            "edges": edgeArr
        ]
        if !collapsedMermaidIds.isEmpty {
            dict["collapsed"] = collapsedMermaidIds
        }
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted]),
              let str = String(data: data, encoding: .utf8) else { return "{}" }
        return str
    }

    // MARK: - Privata helpers

    // MARK: - Layout hints (v35.1)

    /// Genererar osynliga `~~~`-länkar för att hjälpa Mermaid att rendera
    /// ouppkopplade former i samma rumsliga arrangemang som på canvas.
    ///
    /// Algoritm:
    /// 1. Sortera shapes efter X → gruppera i kolumner (gap > 80pt = ny kolumn)
    /// 2. Inom varje kolumn, sortera efter Y
    /// 3. Lägg till `A ~~~ B` mellan konsekutiva shapes i samma kolumn
    ///
    /// Hoppas över om det finns kanter — kanterna definierar redan strukturen.
    private static func layoutHints(shapes: [ShapeNode],
                                     edges: [EdgeConnection],
                                     mermaidIds: [UUID: String],
                                     indent: String) -> [String] {
        guard shapes.count >= 2, edges.isEmpty else { return [] }

        let sortedByX = shapes.sorted { $0.position.x < $1.position.x }

        // Dela upp i kolumner: X-gap > 80pt = ny kolumn
        let threshold: CGFloat = 80
        var columns: [[ShapeNode]] = []
        var current: [ShapeNode] = [sortedByX[0]]
        for i in 1..<sortedByX.count {
            let gap = sortedByX[i].position.x - sortedByX[i - 1].position.x
            if gap > threshold {
                columns.append(current)
                current = [sortedByX[i]]
            } else {
                current.append(sortedByX[i])
            }
        }
        columns.append(current)

        // Generera ~~~ per kolumn (top → bottom)
        var hints: [String] = []
        for column in columns where column.count >= 2 {
            let col = column.sorted { $0.position.y < $1.position.y }
            for i in 0..<col.count - 1 {
                guard let a = mermaidIds[col[i].id],
                      let b = mermaidIds[col[i + 1].id] else { continue }
                hints.append("\(indent)\(a) ~~~ \(b)")
            }
        }
        return hints
    }

    private static func makeMermaidIds(for shapes: [ShapeNode]) -> [UUID: String] {
        var ids: [UUID: String] = [:]
        for (i, s) in shapes.enumerated() {
            ids[s.id] = "\(s.category.idPrefix)_N\(i)"
        }
        return ids
    }

    private static func shapeBody(for type: ShapeType, label: String) -> String {
        switch type {
        case .circle:       return "((\"\(label)\"))"
        case .rectangle:    return "(\"\(label)\")"  // v35.1: rundade hörn matchar RoundedRectangle i appen
        case .diamond:      return "{\"\(label)\"}"
        case .text:         return "[\"\(label)\"]"
        case .table:        return "[\"\(label)\"]"
        case .link:         return "((\"\(label)\"))"
        // v31:
        case .pill:         return "([\"\(label)\"])"  // mermaid stadium-shape
        case .line:         return "[\"\(label)\"]"    // lös linje — endpoints i %% line-kommentar
        case .arrow:        return "[\"\(label)\"]"    // lös pil — som line + arrow-flagga
        // v35.1: nya grundformer
        case .square:       return "(\"\(label)\")"    // kvadrat — Mermaid visar som rundad rektangel
        case .processArrow: return "[\"\(label)\"]"    // processpil — Mermaid saknar pentagon-form; rektangel
        }
    }

    private static func escape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "\"", with: "#quot;")
            .replacingOccurrences(of: "\n", with: "<br/>")
    }

    private static func oneLine(_ text: String) -> String {
        text.replacingOccurrences(of: "\n", with: " ⏎ ")
            .replacingOccurrences(of: "%%", with: "%-%")
    }

    /// v35.1: Hex-färger för ColorPack per id — speglar ColorPack.swift exakt.
    /// MermaidGenerator importerar bara Foundation (inte SwiftUI) så vi slår upp
    /// värdena direkt istället för att anropa ColorPack.fillColor.hex.
    private static func colorPackHex(_ id: String) -> (fill: String, stroke: String, text: String)? {
        switch id {
        case "persika": return ("#ffe3d0", "#e5a57a", "#7a3f1a")
        case "rosa":    return ("#ffe5ec", "#ff8fa3", "#8b2a3e")
        case "blå":     return ("#e0f0ff", "#7fb8e5", "#1a4a7a")
        case "grön":    return ("#d9f5e0", "#7cc196", "#1f5733")
        case "gul":     return ("#fff4d6", "#e0b85c", "#6b4a1a")
        case "lila":    return ("#ecdfff", "#b89ce0", "#4a2d7a")
        default:        return nil
        }
    }
}
