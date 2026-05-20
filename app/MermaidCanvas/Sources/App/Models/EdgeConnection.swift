import Foundation
import CoreGraphics

struct EdgeWaypoint: Codable, Hashable {
    var x: Double
    var y: Double

    init(_ p: CGPoint) {
        self.x = Double(p.x)
        self.y = Double(p.y)
    }

    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    var point: CGPoint { CGPoint(x: x, y: y) }
}

/// v27: linje-stil för en pil.
enum EdgeStyle: String, Codable, CaseIterable {
    case solid
    case dashed
}

/// v37: pilriktning — ersätter bidirectional: Bool med 4 val.
enum EdgeDirection: String, Codable, CaseIterable {
    case forward        // → (standard)
    case backward       // ←
    case bidirectional  // ↔
    case none           // — (inget pilhuvud)
}

struct EdgeConnection: Identifiable, Codable {
    let id: UUID
    var from: UUID
    var to: UUID
    var label: String
    /// v37: pilriktning — ersätter bidirectional: Bool.
    var direction: EdgeDirection
    /// v27: hel eller streckad linje. Default = .solid.
    var style: EdgeStyle
    /// v19: valfri mid-punkt för L-formad path. Tom = rak linje.
    var waypoints: [EdgeWaypoint]

    init(id: UUID = UUID(),
         from: UUID,
         to: UUID,
         label: String = "",
         direction: EdgeDirection = .forward,
         style: EdgeStyle = .solid,
         waypoints: [EdgeWaypoint] = []) {
        self.id = id
        self.from = from
        self.to = to
        self.label = label
        self.direction = direction
        self.style = style
        self.waypoints = waypoints
    }

    private enum CodingKeys: String, CodingKey {
        case id, from, to, label, direction, bidirectional, style, waypoints
    }

    /// Migration: läser direction (v37) med fallback till bidirectional: Bool (v36 och äldre).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.from = try c.decode(UUID.self, forKey: .from)
        self.to = try c.decode(UUID.self, forKey: .to)
        self.label = try c.decode(String.self, forKey: .label)
        if let dir = try? c.decode(EdgeDirection.self, forKey: .direction) {
            self.direction = dir
        } else {
            let bidi = (try? c.decode(Bool.self, forKey: .bidirectional)) ?? false
            self.direction = bidi ? .bidirectional : .forward
        }
        self.style = try c.decodeIfPresent(EdgeStyle.self, forKey: .style) ?? .solid
        self.waypoints = (try? c.decode([EdgeWaypoint].self, forKey: .waypoints)) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(from, forKey: .from)
        try c.encode(to, forKey: .to)
        try c.encode(label, forKey: .label)
        try c.encode(direction, forKey: .direction)
        try c.encode(style, forKey: .style)
        try c.encode(waypoints, forKey: .waypoints)
    }
}
