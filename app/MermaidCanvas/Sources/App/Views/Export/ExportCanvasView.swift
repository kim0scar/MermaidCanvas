import SwiftUI

/// Steg H: statisk, icke-interaktiv komposit av RITAD canvas (former + kanter).
/// Återanvänder EXAKT samma vyer som canvasen (ShapeView/EdgesView i exportläge,
/// ingen chrome) så den exporterade bilden aldrig kan avvika från det Kim ser.
/// Ritas i full canvas-koordinat; beskärningen till ritade ytan görs i
/// CanvasImageExporter (offset + frame + clip).
struct ExportCanvasView: View {
    let shapes: [ShapeNode]
    let edges: [EdgeConnection]
    let hiddenShapeIds: Set<UUID>
    let collapsedEdgeIds: Set<UUID>
    let contentSize: CGSize

    var body: some View {
        ZStack(alignment: .topLeading) {
            EdgesView(
                edges: .constant(edges),
                shapes: shapes,
                canvasScale: 1,
                hiddenShapeIds: hiddenShapeIds,
                collapsedEdgeIds: collapsedEdgeIds,
                selectedShapeId: nil,
                onEdgeDelete: { _ in },
                onEdgeSetDirection: { _, _ in },
                onEdgeSetStyle: { _, _ in },
                onEdgeSetColor: { _, _ in },
                onEdgeSetFromSide: { _, _ in },
                onEdgeRename: { _, _, _ in },
                onToggleCollapseEdge: { _ in },
                exportMode: true
            )
            .frame(width: contentSize.width, height: contentSize.height)
            .zIndex(0)

            ForEach(shapes) { shape in
                if !hiddenShapeIds.contains(shape.id) {
                    ShapeView(
                        shape: .constant(shape),
                        edgeMode: false,
                        markerMode: false,
                        canvasScale: 1,
                        isPendingFrom: false,
                        onEdgeTap: {},
                        onSelect: {},
                        onEdit: {},
                        onDelete: {},
                        onDuplicate: {},
                        onShowNote: {},
                        onQuickRead: {},
                        exportMode: true
                    )
                    // Samma zIndex-regel som canvasen: container under pilar/noder.
                    .zIndex(shape.type == .container ? -1 : 1)
                }
            }
        }
        .frame(width: contentSize.width, height: contentSize.height, alignment: .topLeading)
        // Samma som canvasen: tvinga ljust schema så .primary-kanter blir mörka.
        .environment(\.colorScheme, .light)
    }
}
