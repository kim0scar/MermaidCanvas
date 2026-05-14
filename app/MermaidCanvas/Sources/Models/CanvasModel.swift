import Foundation
import SwiftUI

@MainActor
final class CanvasModel: ObservableObject {
    @Published var shapes: [ShapeNode] = []
    @Published var edges: [EdgeConnection] = []
    @Published var pendingEdgeFrom: UUID? = nil

    func addShape(_ type: ShapeType, at position: CGPoint) {
        let label = "Form \(shapes.count + 1)"
        shapes.append(ShapeNode(type: type, position: position, label: label))
    }

    func updatePosition(id: UUID, to position: CGPoint) {
        guard let index = shapes.firstIndex(where: { $0.id == id }) else { return }
        shapes[index].position = position
    }

    /// Hantera tap i pil-mode. Returnerar true om en pil precis skapades.
    @discardableResult
    func handleEdgeTap(on shapeId: UUID) -> Bool {
        if let from = pendingEdgeFrom {
            pendingEdgeFrom = nil
            guard from != shapeId else { return false }
            edges.append(EdgeConnection(from: from, to: shapeId))
            return true
        }
        pendingEdgeFrom = shapeId
        return false
    }

    func cancelEdgeMode() {
        pendingEdgeFrom = nil
    }

    func replaceAll(shapes: [ShapeNode], edges: [EdgeConnection]) {
        self.shapes = shapes
        self.edges = edges
        self.pendingEdgeFrom = nil
    }
}
