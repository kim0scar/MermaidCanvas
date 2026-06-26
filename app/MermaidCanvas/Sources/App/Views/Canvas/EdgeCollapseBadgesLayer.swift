import SwiftUI

/// 1.3: kollaps-badges (+/–) i ETT EGET lager ÖVER formerna (CanvasView zIndex 4).
/// Tidigare låg de i EdgesView (zIndex 0) → ritades UNDER former och kunde döljas (Kims fynd).
/// Stub-LINJEN stannar i EdgesView (ska ligga under former som andra linjer); bara badge-knappen lyfts hit.
struct EdgeCollapseBadgesLayer: View {
    let edges: [EdgeConnection]
    let shapes: [ShapeNode]
    let canvasScale: CGFloat
    let hiddenShapeIds: Set<UUID>
    let collapsedEdgeIds: Set<UUID>
    let selectedShapeId: UUID?
    var onToggleCollapseEdge: (UUID) -> Void

    var body: some View {
        ForEach(edges) { edge in
            if let fromShape = shapes.first(where: { $0.id == edge.from }),
               let toShape = shapes.first(where: { $0.id == edge.to }),
               !hiddenShapeIds.contains(edge.from) {
                // Plus vid stub-änden (kollapsad gren); minus vid utgången (när from markerad).
                if collapsedEdgeIds.contains(edge.id) {
                    let geo = EdgeGeometry.stubGeometry(for: edge, fromShape: fromShape, toShape: toShape,
                                                        edges: edges, collapsedEdgeIds: collapsedEdgeIds)
                    EdgeStubBadge(position: geo.end, canvasScale: canvasScale,
                                  onTap: { onToggleCollapseEdge(edge.id) })
                } else if selectedShapeId == edge.from, !hiddenShapeIds.contains(edge.to) {
                    EdgeStartCollapseBadge(
                        position: EdgeGeometry.minusBadgePosition(edge: edge, fromShape: fromShape, toShape: toShape,
                                                                  shapes: shapes, hiddenShapeIds: hiddenShapeIds),
                        canvasScale: canvasScale,
                        onTap: { onToggleCollapseEdge(edge.id) })
                }
            }
        }
    }
}
