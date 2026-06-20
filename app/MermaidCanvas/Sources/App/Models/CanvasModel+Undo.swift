// Undo-snapshot — utbruten ur CanvasModel (MA spår A steg 14–18). @Published-fasaden ligger kvar i CanvasModel.swift → rerender oförändrad. Beteende verbatim.
import Foundation
import SwiftUI

extension CanvasModel {
    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }   // V79-svep

    // MARK: - Snapshot

    /// Nuvarande tillstånd som snapshot (delas av undo/redo/snapshotForUndo).
    private func currentSnapshot() -> CanvasSnapshot {
        CanvasSnapshot(
            shapes: shapes,
            edges: edges,
            title: canvasTitle,
            specType: specType,
            platform: platform,
            activeShapePacks: activeShapePacks
        )
    }

    private func apply(_ snap: CanvasSnapshot) {
        shapes = snap.shapes
        edges = snap.edges
        canvasTitle = snap.title
        specType = snap.specType
        platform = snap.platform
        activeShapePacks = snap.activeShapePacks
        pendingEdgeFrom = nil
        edgeCreationMode = .off
    }

    func snapshotForUndo() {
        undoStack.append(currentSnapshot())
        if undoStack.count > undoLimit { undoStack.removeFirst() }
        // V79-svep: en NY redigering ogiltigförklarar redo-historiken.
        redoStack.removeAll()
    }

    func undo() {
        guard let last = undoStack.popLast() else { return }
        redoStack.append(currentSnapshot())   // V79-svep: så undo kan göras om
        if redoStack.count > undoLimit { redoStack.removeFirst() }
        apply(last)
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(currentSnapshot())    // V79-svep: så redo kan ångras
        if undoStack.count > undoLimit { undoStack.removeFirst() }
        apply(next)
    }
}
