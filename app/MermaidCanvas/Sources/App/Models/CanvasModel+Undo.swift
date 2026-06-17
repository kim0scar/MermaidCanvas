// Undo-snapshot — utbruten ur CanvasModel (MA spår A steg 14–18). @Published-fasaden ligger kvar i CanvasModel.swift → rerender oförändrad. Beteende verbatim.
import Foundation
import SwiftUI

extension CanvasModel {
    var canUndo: Bool { !undoStack.isEmpty }

    // MARK: - Snapshot för undo

    func snapshotForUndo() {
        let snap = CanvasSnapshot(
            shapes: shapes,
            edges: edges,
            title: canvasTitle,
            specType: specType,
            platform: platform,
            activeShapePacks: activeShapePacks
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
        platform = last.platform
        activeShapePacks = last.activeShapePacks
        pendingEdgeFrom = nil
        edgeCreationMode = .off
    }
}
