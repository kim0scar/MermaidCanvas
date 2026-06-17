// Kollaps per gren — utbruten ur CanvasModel (MA spår A steg 14–18). @Published-fasaden ligger kvar i CanvasModel.swift → rerender oförändrad. Beteende verbatim.
import Foundation
import SwiftUI

extension CanvasModel {
    /// Noder som ska döljas. v63: BFS NEDSTRÖMS från varje kollapsad KANT —
    /// bara den grenens efterföljare döljs; syskon-grenar från samma nod visas.
    /// (Förenkling som tidigare: en nod som även nås via en o-kollapsad väg
    /// döljs ändå om den ligger nedströms den kollapsade kanten.)
    var hiddenShapeIds: Set<UUID> {
        var hidden: Set<UUID> = []
        for eid in collapsedEdgeIds {
            guard let edge = edges.first(where: { $0.id == eid }) else { continue }
            var visited: Set<UUID> = [edge.from]
            var queue: [UUID] = [edge.to]
            while let cur = queue.first {
                queue.removeFirst()
                if visited.contains(cur) { continue }
                visited.insert(cur)
                hidden.insert(cur)
                for e in edges where e.from == cur && !visited.contains(e.to) {
                    queue.append(e.to)
                }
            }
        }
        return hidden
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

    /// v63: toggle kollaps/expand för EN GREN (kant).
    func toggleCollapseEdge(_ edgeId: UUID) {
        snapshotForUndo()
        if collapsedEdgeIds.contains(edgeId) {
            collapsedEdgeIds.remove(edgeId)
        } else {
            collapsedEdgeIds.insert(edgeId)
        }
    }

    /// Kompat-shim (gamla tester/scenarier): toggla ALLA nodens utgående grenar.
    func toggleCollapse(id: UUID) {
        snapshotForUndo()
        let outgoing = edges.filter { $0.from == id }.map { $0.id }
        guard !outgoing.isEmpty else { return }
        let allCollapsed = outgoing.allSatisfy { collapsedEdgeIds.contains($0) }
        if allCollapsed {
            outgoing.forEach { collapsedEdgeIds.remove($0) }
        } else {
            outgoing.forEach { collapsedEdgeIds.insert($0) }
        }
    }

    /// Hitta partner-länken (samma linkNumber, annan id).
    func partnerLink(for id: UUID) -> ShapeNode? {
        guard let me = shapes.first(where: { $0.id == id }),
              let num = me.linkNumber else { return nil }
        return shapes.first { $0.id != id && $0.linkNumber == num && $0.type == .link }
    }
}
