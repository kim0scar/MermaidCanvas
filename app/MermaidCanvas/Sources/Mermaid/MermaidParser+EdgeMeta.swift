import Foundation

extension MermaidParser {
    /// v1.0+ Visio: dekoda ägt underflöde ur en state-JSON-nod (ShapeNodes egen Codable, byte-exakt).
    static func subCanvas(from node: [String: Any]) -> SubCanvas? {
        guard let subObj = node["subCanvas"],
              let data = try? JSONSerialization.data(withJSONObject: subObj),
              let decoded = try? JSONDecoder().decode(SubCanvas.self, from: data) else { return nil }
        return decoded
    }

    /// Parsade `%% e<index> …`-kant-metadata (per kant-index i emit-ordning).
    struct EdgeMeta {
        var placements: [Int: EdgeLabelPlacement] = [:]
        var colors: [Int: String] = [:]
        var fromSides: [Int: EdgeSide] = [:]
        var waypoints: [Int: [EdgeWaypoint]] = [:]   // F2: överlever ren mermaid
        var lineShapes: [Int: EdgeLineShape] = [:]   // v1.0: form på linjen
        var collapsedIndices: Set<Int> = []
    }

    /// v1.0 (R5-utbrytning): parsar `%% e<index> nyckel: värde`-kant-kommentarerna ur blocket.
    static func parseEdgeMeta(block: String, ns: NSString) -> EdgeMeta {
        var meta = EdgeMeta()
        guard let regex = try? NSRegularExpression(pattern: #"%%\s+e(\d+)\s+(\w+):\s+(\S+)"#)
        else { return meta }
        for m in regex.matches(in: block, range: NSRange(location: 0, length: ns.length))
            where m.numberOfRanges >= 4 {
            guard let idx = Int(ns.substring(with: m.range(at: 1))) else { continue }
            let key = ns.substring(with: m.range(at: 2))
            let value = ns.substring(with: m.range(at: 3))
            switch key {
            case "labelPlacement":
                if let p = EdgeLabelPlacement(rawValue: value) { meta.placements[idx] = p }
            case "color":
                meta.colors[idx] = value
            case "fromSide":
                if let s = EdgeSide(rawValue: value) { meta.fromSides[idx] = s }
            case "lineShape":
                if let ls = EdgeLineShape(rawValue: value) { meta.lineShapes[idx] = ls }
            case "collapsed":
                if value == "true" { meta.collapsedIndices.insert(idx) }
            case "waypoint":
                // Flera "%% e<i> waypoint: x,y"-rader per kant — ackumuleras i ordning.
                let parts = value.split(separator: ",")
                if parts.count == 2, let wx = Double(parts[0]), let wy = Double(parts[1]) {
                    meta.waypoints[idx, default: []].append(EdgeWaypoint(x: wx, y: wy))
                }
            default:
                break
            }
        }
        return meta
    }
}
