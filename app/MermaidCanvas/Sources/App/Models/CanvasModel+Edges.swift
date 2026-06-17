// Edges + edge-mode — utbruten ur CanvasModel (MA spår A steg 14–18). @Published-fasaden ligger kvar i CanvasModel.swift → rerender oförändrad. Beteende verbatim.
import Foundation
import SwiftUI

extension CanvasModel {
    /// Räkna outgoing edges för en form — används för att avgöra om collapse-badge ska visas.
    func hasOutgoingEdges(id: UUID) -> Bool {
        edges.contains { $0.from == id }
    }

    /// v42: returnerar genomsnittlig riktning från shape till alla utgående kant-targets.
    /// nil om inga utgående kanter. Används för att placera collapse-badge vid kant-startpunkten.
    func averageOutgoingDirection(from shapeId: UUID) -> CGVector? {
        guard let from = shapes.first(where: { $0.id == shapeId }) else { return nil }
        let outgoing = edges.filter { $0.from == shapeId }
        guard !outgoing.isEmpty else { return nil }
        var sumX: CGFloat = 0
        var sumY: CGFloat = 0
        for edge in outgoing {
            guard let to = shapes.first(where: { $0.id == edge.to }) else { continue }
            let dx = to.position.x - from.position.x
            let dy = to.position.y - from.position.y
            let len = sqrt(dx*dx + dy*dy)
            guard len > 0.001 else { continue }
            sumX += dx / len
            sumY += dy / len
        }
        let norm = sqrt(sumX*sumX + sumY*sumY)
        guard norm > 0.001 else { return nil }
        return CGVector(dx: sumX / norm, dy: sumY / norm)
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
    func addEdge(from: UUID, to: UUID, direction: EdgeDirection = .forward) {
        guard from != to else { return }
        // Förhindra dubbletter åt samma håll
        if edges.contains(where: { $0.from == from && $0.to == to }) { return }
        snapshotForUndo()
        edges.append(EdgeConnection(from: from, to: to, direction: direction))
    }

    /// v37: sätt pilriktning (ersätter reverseEdge + setEdgeBidirectional).
    func setEdgeDirection(id: UUID, direction: EdgeDirection) {
        guard let idx = edges.firstIndex(where: { $0.id == id }) else { return }
        guard edges[idx].direction != direction else { return }
        snapshotForUndo()
        edges[idx].direction = direction
    }

    /// v63: färg på en pil (hex eller nil = standard mörk).
    func setEdgeColor(id: UUID, hex: String?) {
        guard let idx = edges.firstIndex(where: { $0.id == id }) else { return }
        snapshotForUndo()
        edges[idx].colorHex = hex
    }

    /// v64: vilken sida pilen går ut från (nil = automatisk).
    func setEdgeFromSide(id: UUID, side: EdgeSide?) {
        guard let idx = edges.firstIndex(where: { $0.id == id }) else { return }
        guard edges[idx].fromSide != side else { return }
        snapshotForUndo()
        edges[idx].fromSide = side
    }

    /// v62: egen fyllningsfärg på markerad form (nil = tillbaka till paket/kategori).
    func setFillColor(id: UUID, hex: String?) {
        guard let idx = shapes.firstIndex(where: { $0.id == id }) else { return }
        snapshotForUndo()
        shapes[idx].colorOverride = hex
    }

    /// v62: egen ram-färg på markerad form (nil = tillbaka till paket/kategori).
    func setStrokeColor(id: UUID, hex: String?) {
        guard let idx = shapes.firstIndex(where: { $0.id == id }) else { return }
        snapshotForUndo()
        shapes[idx].strokeColorOverride = hex
    }

    /// v38: sätt kant-etikett (visas bredvid midpoint-handtaget).
    /// v62: även placering (ovanför/under pilen).
    func setEdgeLabel(id: UUID, label: String, placement: EdgeLabelPlacement = .below) {
        guard let idx = edges.firstIndex(where: { $0.id == id }) else { return }
        snapshotForUndo()
        edges[idx].label = label
        edges[idx].labelPlacement = placement
    }

    /// v27: hel eller streckad linje.
    func setEdgeStyle(id: UUID, _ style: EdgeStyle) {
        guard let idx = edges.firstIndex(where: { $0.id == id }) else { return }
        guard edges[idx].style != style else { return }
        snapshotForUndo()
        edges[idx].style = style
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
            let direction: EdgeDirection = edgeCreationMode == .bidirectional ? .bidirectional : .forward
            snapshotForUndo()
            edges.append(EdgeConnection(from: from, to: shapeId, direction: direction))
            edgeCreationMode = .off
            return true
        }
        pendingEdgeFrom = shapeId
        return false
    }
}
