import Foundation
import SwiftUI

@MainActor
final class CanvasModel: ObservableObject {
    @Published var shapes: [ShapeNode] = []

    func addCircle(at position: CGPoint) {
        let label = "Form \(shapes.count + 1)"
        shapes.append(ShapeNode(type: .circle, position: position, label: label))
    }

    func updatePosition(id: UUID, to position: CGPoint) {
        guard let index = shapes.firstIndex(where: { $0.id == id }) else { return }
        shapes[index].position = position
    }
}
