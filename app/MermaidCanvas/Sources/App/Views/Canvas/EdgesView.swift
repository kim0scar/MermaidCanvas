import SwiftUI

/// Pil-lagret (MA spår A steg 6): ritar alla kanter (via `EdgeDrawing`), stub-linjer
/// för kollapsade grenar, collapse-badges och midpoint-handtag (`EdgeMidpointHandle`).
/// Geometri/ritning ligger i `EdgeGeometry`/`EdgeDrawing` — den här filen är bara vyn.
struct EdgesView: View {
    @Binding var edges: [EdgeConnection]
    let shapes: [ShapeNode]
    let canvasScale: CGFloat
    let hiddenShapeIds: Set<UUID>
    /// v63: kollapsade GRENAR (kant-id) — styr stubbar/badges per gren.
    let collapsedEdgeIds: Set<UUID>
    /// v48: vilken form som är markerad — styr om minus-badges visas.
    let selectedShapeId: UUID?
    var onEdgeDelete: (UUID) -> Void
    var onEdgeSetDirection: (UUID, EdgeDirection) -> Void
    var onEdgeSetStyle: (UUID, EdgeStyle) -> Void
    /// v1.0: form på linjen (rak/böjd/vinklad)
    var onEdgeSetLineShape: (UUID, EdgeLineShape) -> Void = { _, _ in }
    /// v63: färg på pilen (hex eller nil = standard)
    var onEdgeSetColor: (UUID, String?) -> Void
    /// v64: byt utgångssida på pilen (nil = automatisk)
    var onEdgeSetFromSide: (UUID, EdgeSide?) -> Void
    /// 1.3: byt inkommande sida på mål-formen (nil = automatisk)
    var onEdgeSetToSide: (UUID, EdgeSide?) -> Void = { _, _ in }
    var onEdgeSnapshot: (UUID) -> Void = { _ in }
    var onEdgeRename: (UUID, String, EdgeLabelPlacement) -> Void
    /// v48: toggle-callback för collapse-badges. Tar shape-ID.
    /// v63: kollapsa/expandera EN gren (kant-id).
    var onToggleCollapseEdge: (UUID) -> Void
    /// Steg H: exportläge — rita bara linjer + pilspetsar + etiketter (ingen handtag/badge-chrome).
    var exportMode: Bool = false

    // v44: kant-namngivning via EdgeLabelSheet (ersätter v38-alerten).
    @State private var renamingEdgeId: UUID? = nil

    private func isVisible(_ edge: EdgeConnection) -> Bool {
        !hiddenShapeIds.contains(edge.from) && !hiddenShapeIds.contains(edge.to)
    }

    var body: some View {
        ZStack {
            Canvas { context, _ in
                // Normala kanter (båda ändar synliga)
                for edge in edges where isVisible(edge) {
                    guard let fromShape = shapes.first(where: { $0.id == edge.from }),
                          let toShape = shapes.first(where: { $0.id == edge.to })
                    else { continue }
                    EdgeDrawing.drawEdge(context: context, edge: edge,
                                         fromShape: fromShape, toShape: toShape,
                                         shapes: shapes, hiddenShapeIds: hiddenShapeIds)
                }
                // v48 Fel #4 / v63: Stub-linjer per KOLLAPSAD GREN (kant i
                // collapsedEdgeIds, from synlig). Solfjäder-spridning när flera
                // grenar från samma nod är kollapsade (Kims fynd: badges på varandra).
                for edge in edges where (collapsedEdgeIds.contains(edge.id)
                                         && !hiddenShapeIds.contains(edge.from)) {
                    guard let fromShape = shapes.first(where: { $0.id == edge.from }),
                          let toShape   = shapes.first(where: { $0.id == edge.to })
                    else { continue }
                    let geo = EdgeGeometry.stubGeometry(for: edge, fromShape: fromShape, toShape: toShape,
                                                        edges: edges, collapsedEdgeIds: collapsedEdgeIds)
                    let stubColor: Color = edge.colorHex.flatMap { Color(hexString: $0) }
                        ?? Color(hex: 0x3a3f47)
                    var stub = Path()
                    stub.move(to: geo.start)
                    stub.addLine(to: geo.end)
                    context.stroke(stub, with: .color(stubColor.opacity(0.5)),
                                   style: StrokeStyle(lineWidth: 2, lineCap: .round,
                                                      dash: [4, 3]))
                }
            }
            .allowsHitTesting(false)

            ForEach($edges) { $edge in
                if isVisible(edge),
                   let fromShape = shapes.first(where: { $0.id == edge.from }),
                   let toShape = shapes.first(where: { $0.id == edge.to }) {
                    EdgeMidpointHandle(edge: $edge,
                                       fromShape: fromShape,
                                       toShape: toShape,
                                       canvasScale: canvasScale,
                                       shapes: shapes,
                                       hiddenShapeIds: hiddenShapeIds,
                                       onEdgeDelete: onEdgeDelete,
                                       onEdgeSetDirection: onEdgeSetDirection,
                                       onEdgeSetStyle: onEdgeSetStyle,
                                       onEdgeSetLineShape: onEdgeSetLineShape,
                                       onEdgeSetColor: onEdgeSetColor,
                                       onEdgeSetFromSide: onEdgeSetFromSide,
                                       onEdgeSetToSide: onEdgeSetToSide,
                                       onEdgeSnapshot: onEdgeSnapshot,
                                       onRequestRename: { renamingEdgeId = $0 },
                                       exportMode: exportMode)
                }
            }

            // 1.3: collapse-badges (+/–) flyttade till EGET lager (EdgeCollapseBadgesLayer,
            // zIndex 4 i CanvasView) så de ritas ÖVER former (Kims fynd: minus-badgen doldes).
            // Stub-LINJEN ligger kvar i Canvas-lagret ovan (ska vara under former).
        }
        // v44: byt alert mot EdgeLabelSheet — mer rymligt för längre etiketter.
        .sheet(isPresented: Binding(
            get: { renamingEdgeId != nil },
            set: { if !$0 { renamingEdgeId = nil } }
        )) {
            if let id = renamingEdgeId,
               let edge = edges.first(where: { $0.id == id }) {
                EdgeLabelSheet(
                    initial: edge.label,
                    initialPlacement: edge.labelPlacement,
                    onSave: { newLabel, newPlacement in
                        onEdgeRename(id, newLabel, newPlacement)
                        renamingEdgeId = nil
                    },
                    onCancel: { renamingEdgeId = nil }
                )
            }
        }
    }

}
