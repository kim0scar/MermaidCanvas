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

    /// v63: stub-linjens geometri för en kollapsad gren. Solfjäder-spridning
    /// (±0.5 rad/steg) när flera kollapsade grenar delar samma from-nod —
    /// annars hamnar plus-badges ovanpå varandra. Stub-linje och plus-badge
    /// använder SAMMA geometri så de alltid linjerar.
    private func stubGeometry(for edge: EdgeConnection,
                              fromShape: ShapeNode,
                              toShape: ShapeNode) -> (start: CGPoint, end: CGPoint) {
        let siblings = edges.filter {
            $0.from == edge.from && collapsedEdgeIds.contains($0.id)
        }
        let idx = siblings.firstIndex(where: { $0.id == edge.id }) ?? 0
        let count = max(siblings.count, 1)
        let dx = toShape.position.x - fromShape.position.x
        let dy = toShape.position.y - fromShape.position.y
        let baseAngle = atan2(dy, dx)
        let spreadStep: CGFloat = 0.5
        let angle = baseAngle + (CGFloat(idx) - CGFloat(count - 1) / 2) * spreadStep
        let start = EdgeGeometry.edgePoint(for: fromShape, towards: toShape.position)
        let stubLen: CGFloat = 62
        let end = CGPoint(x: start.x + stubLen * cos(angle),
                          y: start.y + stubLen * sin(angle))
        return (start, end)
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
                    let geo = stubGeometry(for: edge, fromShape: fromShape, toShape: toShape)
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
                                       onRequestRename: { renamingEdgeId = $0 },
                                       exportMode: exportMode)
                }
            }

            // v48 Fel #3+#4 / v63: Collapse-badges PER GREN.
            // Minus: på utgående o-kollapsad kant, BARA när from är markerad —
            //        kollapsar bara DEN grenen. Förskjuten vinkelrätt från linjen
            //        (Kims fynd: låg ihop med midpoint-ikonen).
            // Plus:  vid stub-änden för varje kollapsad gren, alltid synlig.
            ForEach(edges) { edge in
                if let fromShape = shapes.first(where: { $0.id == edge.from }),
                   let toShape   = shapes.first(where: { $0.id == edge.to }),
                   !hiddenShapeIds.contains(edge.from) {
                    let isCollapsed = collapsedEdgeIds.contains(edge.id)
                    let isFromSelected = (selectedShapeId == edge.from)
                    // Steg H: i exportläge ritas inga +/–-badges (men stub-linjen i
                    // Canvas-lagret ovan står kvar → kollapsad gren syns ändå).
                    if isCollapsed, !exportMode {
                        let geo = stubGeometry(for: edge, fromShape: fromShape, toShape: toShape)
                        EdgeStubBadge(position: geo.end,
                                      canvasScale: canvasScale,
                                      onTap: { onToggleCollapseEdge(edge.id) })
                    } else if isFromSelected, !hiddenShapeIds.contains(edge.to) {
                        // v67: minus-badgen sitter vid pilens UTGÅNGSPUNKT på
                        // källnodens kant (inte mitt på pilen) och bara när noden
                        // är markerad — Kims fynd 3. Pilen blir ren i normalläge.
                        EdgeStartCollapseBadge(
                            position: minusBadgePosition(edge: edge,
                                                         fromShape: fromShape,
                                                         toShape: toShape),
                            canvasScale: canvasScale,
                            onTap: { onToggleCollapseEdge(edge.id) })
                    }
                }
            }
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

    /// v67: minus-badgens position — vid pilens UTGÅNGSPUNKT på källnodens kant
    /// (inte mitt på pilen). Liten radiell knuff utåt + vinkelrätt så den ligger
    /// på kanten utan att täcka linjen. Flera grenar lämnar olika perimeter-
    /// punkter → badges hamnar naturligt isär (Kims fynd 3).
    private func minusBadgePosition(edge: EdgeConnection,
                                    fromShape: ShapeNode,
                                    toShape: ShapeNode) -> CGPoint {
        let anchors = EdgeGeometry.edgeAnchors(edge: edge, fromShape: fromShape, toShape: toShape,
                                               shapes: shapes, hiddenShapeIds: hiddenShapeIds)
        let dx = anchors.start.x - fromShape.position.x
        let dy = anchors.start.y - fromShape.position.y
        let len = max(hypot(dx, dy), 0.001)
        let tx = dx / len, ty = dy / len                 // radiell riktning utåt från noden
        var px = -ty, py = tx                             // vinkelrät mot utgångsriktningen
        if py > 0 { px = -px; py = -py }                 // peka uppåt på skärmen
        return CGPoint(x: anchors.start.x + tx * 6 + px * 16,
                       y: anchors.start.y + ty * 6 + py * 16)
    }
}
