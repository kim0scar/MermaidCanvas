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

struct EdgeConnection: Identifiable, Codable {
    let id: UUID
    var from: UUID
    var to: UUID
    var label: String
    var bidirectional: Bool
    /// v27: hel eller streckad linje. Default = .solid.
    var style: EdgeStyle
    /// v19: valfri mid-punkt för L-formad path. Tom = rak linje.
    /// Lucidchart-style: en draggable midpoint.
    var waypoints: [EdgeWaypoint]

    init(id: UUID = UUID(),
         from: UUID,
         to: UUID,
         label: String = "",
         bidirectional: Bool = false,
         style: EdgeStyle = .solid,
         waypoints: [EdgeWaypoint] = []) {
        self.id = id
        self.from = from
        self.to = to
        self.label = label
        self.bidirectional = bidirectional
        self.style = style
        self.waypoints = waypoints
    }

    private enum CodingKeys: String, CodingKey {
        case id, from, to, label, bidirectional, style, waypoints
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decode(UUID.self, forKey: .id)
        self.from = try c.decode(UUID.self, forKey: .from)
        self.to = try c.decode(UUID.self, forKey: .to)
        self.label = try c.decode(String.self, forKey: .label)
        self.bidirectional = try c.decode(Bool.self, forKey: .bidirectional)
        self.style = try c.decodeIfPresent(EdgeStyle.self, forKey: .style) ?? .solid
        self.waypoints = try c.decode([EdgeWaypoint].self, forKey: .waypoints)
    }
}
