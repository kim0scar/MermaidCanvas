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

struct EdgeConnection: Identifiable, Codable {
    let id: UUID
    var from: UUID
    var to: UUID
    var label: String
    var bidirectional: Bool
    /// v19: valfri mid-punkt för L-formad path. Tom = rak linje.
    /// Lucidchart-style: en draggable midpoint.
    var waypoints: [EdgeWaypoint]

    init(id: UUID = UUID(),
         from: UUID,
         to: UUID,
         label: String = "",
         bidirectional: Bool = false,
         waypoints: [EdgeWaypoint] = []) {
        self.id = id
        self.from = from
        self.to = to
        self.label = label
        self.bidirectional = bidirectional
        self.waypoints = waypoints
    }
}
