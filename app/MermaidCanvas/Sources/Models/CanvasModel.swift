import Foundation
import SwiftUI

enum EdgeCreationMode: Equatable {
    case off
    case directional
    case bidirectional
}

@MainActor
final class CanvasModel: ObservableObject {
    @Published var shapes: [ShapeNode] = []
    @Published var edges: [EdgeConnection] = []
    @Published var edgeCreationMode: EdgeCreationMode = .off
    @Published var pendingEdgeFrom: UUID? = nil
    @Published var canvasTitle: String = ""

    var isEdgeMode: Bool { edgeCreationMode != .off }

    func addShape(_ type: ShapeType, at position: CGPoint) {
        let label = "Form \(shapes.count + 1)"
        shapes.append(ShapeNode(type: type, position: position, label: label))
    }

    func updatePosition(id: UUID, to position: CGPoint) {
        guard let index = shapes.firstIndex(where: { $0.id == id }) else { return }
        shapes[index].position = position
    }

    func updateLabel(id: UUID, to label: String) {
        guard let index = shapes.firstIndex(where: { $0.id == id }) else { return }
        shapes[index].label = label
    }

    func startEdgeMode(_ mode: EdgeCreationMode) {
        edgeCreationMode = mode
        pendingEdgeFrom = nil
    }

    func cancelEdgeMode() {
        edgeCreationMode = .off
        pendingEdgeFrom = nil
    }

    @discardableResult
    func handleEdgeTap(on shapeId: UUID) -> Bool {
        guard edgeCreationMode != .off else { return false }
        if let from = pendingEdgeFrom {
            pendingEdgeFrom = nil
            guard from != shapeId else {
                edgeCreationMode = .off
                return false
            }
            let bidi = edgeCreationMode == .bidirectional
            edges.append(EdgeConnection(from: from, to: shapeId, bidirectional: bidi))
            edgeCreationMode = .off
            return true
        }
        pendingEdgeFrom = shapeId
        return false
    }

    func replaceAll(shapes: [ShapeNode], edges: [EdgeConnection], title: String = "") {
        self.shapes = shapes
        self.edges = edges
        self.canvasTitle = title
        self.pendingEdgeFrom = nil
        self.edgeCreationMode = .off
    }
}
