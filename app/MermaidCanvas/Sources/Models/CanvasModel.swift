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
    @Published var canvasSize: CGSize = CGSize(width: 3000, height: 3000)
    @Published var specType: SpecType = .ui

    // v23: pan/zoom-state hanteras nu som @State i CanvasView för perf
    // (60Hz @Published triggade hela hierarkin att rerendera)

    // v19: selection-state — bara UI
    @Published var selectedShapeId: UUID? = nil
    @Published var multiSelection: Set<UUID> = []
    @Published var markerMode: Bool = false
    @Published var collapsedIds: Set<UUID> = []

    // v19: konstant stor canvas-yta
    static let contentSize = CGSize(width: 3000, height: 3000)

    private var undoStack: [CanvasSnapshot] = []
    private let undoLimit = 30

    var isEdgeMode: Bool { edgeCreationMode != .off }
    var canUndo: Bool { !undoStack.isEmpty }

    /// Noder som ska döljas pga någon av deras "föräldrar" är kollapsad.
    /// BFS från varje collapsed-nod via edges; collapsed noden själv visas alltid.
    var hiddenShapeIds: Set<UUID> {
        var hidden: Set<UUID> = []
        for cid in collapsedIds {
            var queue: [UUID] = []
            // Direct neighbors via edges (where collapsed is the source)
            for e in edges {
                if e.from == cid { queue.append(e.to) }
            }
            var visited: Set<UUID> = [cid]
            while let cur = queue.first {
                queue.removeFirst()
                if visited.contains(cur) { continue }
                visited.insert(cur)
                hidden.insert(cur)
                for e in edges where e.from == cur {
                    if !visited.contains(e.to) { queue.append(e.to) }
                }
            }
        }
        return hidden
    }

    /// Räkna outgoing edges för en form — används för att avgöra om collapse-badge ska visas.
    func hasOutgoingEdges(id: UUID) -> Bool {
        edges.contains { $0.from == id }
    }

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
        // v23: tom label från start — Kim vill skriva själv
        shapes.append(ShapeNode(type: type, position: position, label: "", category: cat))
    }

    /// Lägg en tabell-form (3×3) på canvas-mitten.
    func addTable(at position: CGPoint, rows: Int = 3, cols: Int = 3) {
        snapshotForUndo()
        shapes.append(ShapeNode(
            type: .table,
            position: position,
            label: "",
            sizeMultiplier: 1.5,
            category: specType.defaultCategory,
            tableRows: rows,
            tableCols: cols
        ))
    }

    /// Lägg ett par jump-länkar med samma nummer.
    func addJumpLinkPair(near position: CGPoint) {
        snapshotForUndo()
        let usedNumbers = Set(shapes.compactMap { $0.linkNumber })
        var next = 1
        while usedNumbers.contains(next) { next += 1 }
        let a = ShapeNode(type: .link,
                          position: CGPoint(x: position.x - 100, y: position.y),
                          label: "",
                          sizeMultiplier: 0.7,
                          category: .note,
                          linkNumber: next)
        let b = ShapeNode(type: .link,
                          position: CGPoint(x: position.x + 100, y: position.y),
                          label: "",
                          sizeMultiplier: 0.7,
                          category: .note,
                          linkNumber: next)
        shapes.append(a)
        shapes.append(b)
    }

    /// Ny tom canvas (kallas efter spara-prompt).
    func clearCanvas() {
        snapshotForUndo()
        shapes.removeAll()
        edges.removeAll()
        selectedShapeId = nil
        multiSelection.removeAll()
        collapsedIds.removeAll()
        canvasTitle = ""
    }

    /// Duplicera en form med offset (+24, +24).
    @discardableResult
    func duplicateShape(id: UUID) -> UUID? {
        guard let o = shapes.first(where: { $0.id == id }) else { return nil }
        snapshotForUndo()
        let copy = ShapeNode(
            type: o.type,
            position: CGPoint(x: o.position.x + 24, y: o.position.y + 24),
            label: o.label,
            showLabel: o.showLabel,
            sizeMultiplier: o.sizeMultiplier,
            note: o.note,
            category: o.category,
            rotation: o.rotation,
            colorOverride: o.colorOverride,
            linkNumber: nil, // jump-link ska INTE dupliceras (skulle bli orphan-länk)
            tableRows: o.tableRows,
            tableCols: o.tableCols,
            textStyle: o.textStyle,
            colorPackId: o.colorPackId
        )
        shapes.append(copy)
        return copy.id
    }

    /// Beräkna alla noder som "hänger ihop" från en startnod (BFS via edges).
    /// Används vid kollaps.
    func descendantsFromBranch(startId: UUID, throughEdge edgeId: UUID) -> Set<UUID> {
        guard let edge = edges.first(where: { $0.id == edgeId }) else { return [] }
        let firstTarget = edge.from == startId ? edge.to : edge.from
        var visited: Set<UUID> = [startId]
        var queue: [UUID] = [firstTarget]
        var result: Set<UUID> = []
        while let cur = queue.first {
            queue.removeFirst()
            if visited.contains(cur) { continue }
            visited.insert(cur)
            result.insert(cur)
            for e in edges {
                if e.from == cur && !visited.contains(e.to) { queue.append(e.to) }
                if e.to == cur && !visited.contains(e.from) { queue.append(e.from) }
            }
        }
        return result
    }

    /// Toggle kollaps/expand för en form. Om expanderad: alla connected hide:as.
    func toggleCollapse(id: UUID) {
        snapshotForUndo()
        if collapsedIds.contains(id) {
            collapsedIds.remove(id)
        } else {
            collapsedIds.insert(id)
        }
    }

    /// Hitta partner-länken (samma linkNumber, annan id).
    func partnerLink(for id: UUID) -> ShapeNode? {
        guard let me = shapes.first(where: { $0.id == id }),
              let num = me.linkNumber else { return nil }
        return shapes.first { $0.id != id && $0.linkNumber == num && $0.type == .link }
    }

    func updatePosition(id: UUID, to position: CGPoint) {
        guard let index = shapes.firstIndex(where: { $0.id == id }) else { return }
        snapshotForUndo()
        shapes[index].position = position
    }

    func updateShape(id: UUID,
                     label: String,
                     showLabel: Bool,
                     note: String,
                     textStyle: TextStyle) {
        guard let index = shapes.firstIndex(where: { $0.id == id }) else { return }
        snapshotForUndo()
        shapes[index].label = label
        shapes[index].showLabel = showLabel
        shapes[index].note = note
        shapes[index].textStyle = textStyle
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

    func selectShape(_ id: UUID) {
        selectedShapeId = id
        multiSelection.removeAll()
    }

    func deselect() {
        selectedShapeId = nil
        multiSelection.removeAll()
    }

    func toggleMarkerMode() {
        markerMode.toggle()
        if markerMode {
            selectedShapeId = nil
        }
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

    /// v25: lägg pil direkt från drag-handtag (ej via tap-flow).
    func addEdge(from: UUID, to: UUID, bidirectional: Bool = false) {
        guard from != to else { return }
        // Förhindra dubbletter åt samma håll
        if edges.contains(where: { $0.from == from && $0.to == to }) { return }
        snapshotForUndo()
        edges.append(EdgeConnection(from: from, to: to, bidirectional: bidirectional))
    }

    /// v25: byt riktning på en pil.
    func reverseEdge(id: UUID) {
        guard let idx = edges.firstIndex(where: { $0.id == id }) else { return }
        snapshotForUndo()
        let old = edges[idx]
        edges[idx].from = old.to
        edges[idx].to = old.from
    }

    /// v25: sätt pil till en/båda riktningar utan att ändra ändpunkter.
    func setEdgeBidirectional(id: UUID, _ value: Bool) {
        guard let idx = edges.firstIndex(where: { $0.id == id }) else { return }
        guard edges[idx].bidirectional != value else { return }
        snapshotForUndo()
        edges[idx].bidirectional = value
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
                    specType: SpecType = .ui,
                    collapsedIds: Set<UUID> = []) {
        self.shapes = shapes
        self.edges = edges
        self.canvasTitle = title
        self.specType = specType
        self.collapsedIds = collapsedIds
        self.pendingEdgeFrom = nil
        self.edgeCreationMode = .off
        self.selectedShapeId = nil
        self.multiSelection.removeAll()
        self.markerMode = false
        self.undoStack.removeAll()
    }
}
