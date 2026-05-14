import Foundation
import SwiftUI

enum EdgeCreationMode: Equatable {
    case off
    case directional
    case bidirectional
}

private struct CanvasSnapshot {
    let shapes: [ShapeNode]
    let edges: [EdgeConnection]
    let title: String
    let specType: SpecType
}

@MainActor
final class CanvasModel: ObservableObject {
    @Published var shapes: [ShapeNode] = []
    @Published var edges: [EdgeConnection] = []
    @Published var edgeCreationMode: EdgeCreationMode = .off
    @Published var pendingEdgeFrom: UUID? = nil
    @Published var canvasTitle: String = ""
    @Published var canvasSize: CGSize = CGSize(width: 393, height: 600)
    @Published var specType: SpecType = .ui

    private var undoStack: [CanvasSnapshot] = []
    private let undoLimit = 30

    var isEdgeMode: Bool { edgeCreationMode != .off }
    var canUndo: Bool { !undoStack.isEmpty }

    // MARK: - Snapshot för undo

    private func snapshotForUndo() {
        let snap = CanvasSnapshot(
            shapes: shapes,
            edges: edges,
            title: canvasTitle,
            specType: specType
        )
        undoStack.append(snap)
        if undoStack.count > undoLimit { undoStack.removeFirst() }
    }

    func undo() {
        guard let last = undoStack.popLast() else { return }
        shapes = last.shapes
        edges = last.edges
        canvasTitle = last.title
        specType = last.specType
        pendingEdgeFrom = nil
        edgeCreationMode = .off
    }

    // MARK: - Mutationer

    func addShape(_ type: ShapeType, at position: CGPoint) {
        snapshotForUndo()
        let cat = specType.defaultCategory
        let label = cat.emptyLabelHint
        shapes.append(ShapeNode(type: type, position: position, label: label, category: cat))
    }

    func updatePosition(id: UUID, to position: CGPoint) {
        guard let index = shapes.firstIndex(where: { $0.id == id }) else { return }
        snapshotForUndo()
        shapes[index].position = position
    }

    func updateShape(id: UUID,
                     label: String,
                     showLabel: Bool,
                     sizeMultiplier: CGFloat,
                     note: String,
                     category: ShapeCategory) {
        guard let index = shapes.firstIndex(where: { $0.id == id }) else { return }
        snapshotForUndo()
        shapes[index].label = label
        shapes[index].showLabel = showLabel
        shapes[index].sizeMultiplier = sizeMultiplier
        shapes[index].note = note
        shapes[index].category = category
    }

    func deleteShape(id: UUID) {
        snapshotForUndo()
        edges.removeAll { $0.from == id || $0.to == id }
        shapes.removeAll { $0.id == id }
        if pendingEdgeFrom == id { pendingEdgeFrom = nil }
    }

    func deleteEdge(id: UUID) {
        snapshotForUndo()
        edges.removeAll { $0.id == id }
    }

    func setSpecType(_ new: SpecType) {
        guard new != specType else { return }
        snapshotForUndo()
        specType = new
    }

    // MARK: - Edge-mode

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
            snapshotForUndo()
            edges.append(EdgeConnection(from: from, to: shapeId, bidirectional: bidi))
            edgeCreationMode = .off
            return true
        }
        pendingEdgeFrom = shapeId
        return false
    }

    // MARK: - Bulk replace (vid fil-öppning)

    func replaceAll(shapes: [ShapeNode],
                    edges: [EdgeConnection],
                    title: String = "",
                    specType: SpecType = .ui) {
        self.shapes = shapes
        self.edges = edges
        self.canvasTitle = title
        self.specType = specType
        self.pendingEdgeFrom = nil
        self.edgeCreationMode = .off
        self.undoStack.removeAll()
    }
}
