import Foundation

enum MermaidGenerator {
    static func generate(shapes: [ShapeNode],
                         edges: [EdgeConnection],
                         canvasSize: CGSize = .zero,
                         specType: SpecType = .ui,
                         collapsedIds: Set<UUID> = []) -> String {
        guard !shapes.isEmpty else {
            return "flowchart TD\n    Tom[\"Tom canvas — lägg till en form\"]"
        }
        var lines: [String] = ["flowchart TD"]
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

        // Edges
        for (i, edge) in edges.enumerated() {
            guard let from = mermaidIds[edge.from], let to = mermaidIds[edge.to] else { continue }
            // v27: linje-stil + riktning round-trip
            let arrow: String
            switch (edge.style, edge.bidirectional) {
            case (.solid, false):  arrow = "-->"
            case (.solid, true):   arrow = "<-->"
            case (.dashed, false): arrow = "-.->"
            case (.dashed, true):  arrow = "<-.->"
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
            return n
        }
        let edgeArr: [[String: Any]] = edges.compactMap { edge in
            guard let f = mermaidIds[edge.from], let t = mermaidIds[edge.to] else { return nil }
            var e: [String: Any] = [
                "from": f,
                "to": t,
                "label": edge.label,
                "bidirectional": edge.bidirectional,
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

    private static func makeMermaidIds(for shapes: [ShapeNode]) -> [UUID: String] {
        var ids: [UUID: String] = [:]
        for (i, s) in shapes.enumerated() {
            ids[s.id] = "\(s.category.idPrefix)_N\(i)"
        }
        return ids
    }

    private static func shapeBody(for type: ShapeType, label: String) -> String {
        switch type {
        case .circle:    return "((\"\(label)\"))"
        case .rectangle: return "[\"\(label)\"]"
        case .diamond:   return "{\"\(label)\"}"
        case .text:      return "[\"\(label)\"]"
        case .table:     return "[\"\(label)\"]"   // tabell-data skrivs som %% kommentar
        case .link:      return "((\"\(label)\"))" // länk-nummer skrivs som %% kommentar
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
}
