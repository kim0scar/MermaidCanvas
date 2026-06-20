import Foundation
import CoreGraphics

/// v1.0+ Visio "hoppa in": en form kan ÄGA ett helt underflöde (en nästlad canvas en nivå
/// djupare). Skiljer sig från kollaps (döljer på samma yta) och container (visar barn inline)
/// — här NAVIGERAR man in i formen. Inline-ägt: underflödet bor i formen själv (ingen
/// korsreferens) → round-trippar med formen och påverkar inte befintliga ritningars round-trip.
/// Multi-nivå faller ut naturligt: en form i ett underflöde kan ha ett eget `subCanvas`.
struct SubCanvas: Codable, Equatable {
    var shapes: [ShapeNode]
    var edges: [EdgeConnection]
    var canvasWidth: Double
    var canvasHeight: Double

    init(shapes: [ShapeNode] = [], edges: [EdgeConnection] = [],
         canvasWidth: Double = 4000, canvasHeight: Double = 4000) {
        self.shapes = shapes
        self.edges = edges
        self.canvasWidth = canvasWidth
        self.canvasHeight = canvasHeight
    }

    var canvasSize: CGSize { CGSize(width: canvasWidth, height: canvasHeight) }
}
