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

/// v62: var etiketten står relativt pilen. Default = .below (som tidigare).
enum EdgeLabelPlacement: String, Codable, CaseIterable {
    case above
    case below
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
    /// v62: etikettens placering (ovanför/under pilen). Default = .below.
    var labelPlacement: EdgeLabelPlacement
    /// v63: pilens färg som hex "#rrggbb". nil = standard (mörk).
    var colorHex: String?

    init(id: UUID = UUID(),
         from: UUID,
         to: UUID,
         label: String = "",
         direction: EdgeDirection = .forward,
         style: EdgeStyle = .solid,
         waypoints: [EdgeWaypoint] = [],
         labelPlacement: EdgeLabelPlacement = .below,
         colorHex: String? = nil) {
        self.id = id
        self.from = from
        self.to = to
        self.label = label
        self.direction = direction
        self.style = style
        self.waypoints = waypoints
        self.labelPlacement = labelPlacement
        self.colorHex = colorHex
    }

    private enum CodingKeys: String, CodingKey {
        case id, from, to, label, direction, bidirectional, style, waypoints
        case labelPlacement  // v62
        case colorHex        // v63
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
        // v62: bakåtkompatibel default — gamla filer saknar fältet
        self.labelPlacement = try c.decodeIfPresent(EdgeLabelPlacement.self,
                                                    forKey: .labelPlacement) ?? .below
        self.colorHex = try c.decodeIfPresent(String.self, forKey: .colorHex)  // v63
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
        try c.encode(labelPlacement, forKey: .labelPlacement)
        try c.encodeIfPresent(colorHex, forKey: .colorHex)
    }
}
