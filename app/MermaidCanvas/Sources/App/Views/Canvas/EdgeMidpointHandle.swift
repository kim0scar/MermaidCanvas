import SwiftUI

/// Midpoint-handtaget på en pil (MA spår A steg 6): rund knapp mitt på den synliga
/// kurvan + kontextmeny (riktning, stil, färg, utgångssida, ta bort) + kant-etikett.
/// Bröts ut ur EdgesView. Drar man i handtaget skapas/flyttas en waypoint. Namnge-
/// sheeten ligger kvar i EdgesView (state där) — vi når den via `onRequestRename`.
struct EdgeMidpointHandle: View {
    @Binding var edge: EdgeConnection
    let fromShape: ShapeNode
    let toShape: ShapeNode
    let canvasScale: CGFloat
    let shapes: [ShapeNode]
    let hiddenShapeIds: Set<UUID>
    var onEdgeDelete: (UUID) -> Void
    var onEdgeSetDirection: (UUID, EdgeDirection) -> Void
    var onEdgeSetStyle: (UUID, EdgeStyle) -> Void
    var onEdgeSetColor: (UUID, String?) -> Void
    var onEdgeSetFromSide: (UUID, EdgeSide?) -> Void
    var onRequestRename: (UUID) -> Void

    var body: some View {
        let hasWaypoint = !edge.waypoints.isEmpty
        let direction = edge.direction
        // v37: ikon speglar aktuell riktning
        let icon: String = {
            switch direction {
            case .forward:       return "arrow.right"
            case .backward:      return "arrow.left"
            case .bidirectional: return "arrow.left.and.right"
            case .none:          return "minus"
            }
        }()
        // v48 Fel #2: positionera mid på den FAKTISKA synliga linjen (mellan
        // edgePoints, inte mellan shape-centra). Beräkna också linjens vinkel
        // så att ikonen kan roteras med linjens fortsättning.
        // v50 F-03: vid bezier-routing runt obstakel måste mid räknas PÅ
        // kurvan, annars hamnar handlen inuti obstaklet.
        let anchors = EdgeGeometry.edgeAnchors(edge: edge,
                                               fromShape: fromShape,
                                               toShape: toShape,
                                               shapes: shapes,
                                               hiddenShapeIds: hiddenShapeIds)
        let edgeStart = anchors.start
        let mid: CGPoint = {
            if hasWaypoint { return edge.waypoints[0].point }
            return anchors.mid
        }()
        let lineAngle: Double = {
            if hasWaypoint {
                let wp = edge.waypoints[0].point
                return atan2(Double(wp.y - edgeStart.y), Double(wp.x - edgeStart.x))
            }
            return anchors.midAngle
        }()
        let size: CGFloat = DesignTokens.screenPt(16, scale: canvasScale)
        let label = edge.label
        // Handle
        ZStack {
            Circle()
                .fill(hasWaypoint ? Color.accentColor : Color.white)
                .overlay(Circle().stroke(Color.accentColor,
                                         lineWidth: max(1.0, 1.5 / canvasScale)))
                .frame(width: size, height: size)
            Image(systemName: icon)
                .font(.system(size: size * 0.45, weight: .bold))
                .foregroundStyle(hasWaypoint ? Color.white : Color.accentColor)
                .rotationEffect(.radians(lineAngle)) // v48: roterar med linjen
        }
        .contentShape(Circle().inset(by: -size * 0.5))
        .position(mid)
        .gesture(midpointGesture())
        .contextMenu {
            // v44: redigera text på pilen via EdgeLabelSheet
            Button {
                onRequestRename(edge.id)
            } label: {
                Label("Redigera text", systemImage: "textformat")
            }
            Divider()
            // v37: 4 riktningsval
            Button {
                onEdgeSetDirection(edge.id, .forward)
            } label: {
                Label("→ Pil åt höger", systemImage: "arrow.right")
            }
            Button {
                onEdgeSetDirection(edge.id, .backward)
            } label: {
                Label("← Pil åt vänster", systemImage: "arrow.left")
            }
            Button {
                onEdgeSetDirection(edge.id, .bidirectional)
            } label: {
                Label("↔ Båda hållen", systemImage: "arrow.left.arrow.right")
            }
            Button {
                onEdgeSetDirection(edge.id, .none)
            } label: {
                Label("— Ingen pil", systemImage: "minus")
            }
            Divider()
            // v27: linje-stil
            Button {
                onEdgeSetStyle(edge.id, .solid)
            } label: {
                Label("Hel linje", systemImage: "minus")
            }
            Button {
                onEdgeSetStyle(edge.id, .dashed)
            } label: {
                Label("Streckad linje", systemImage: "ellipsis")
            }
            Divider()
            // v63: färg på pilen — emoji syns i iOS-menyer (ikoner blir mallfärgade)
            Menu {
                Button("⚫️ Standard") { onEdgeSetColor(edge.id, nil) }
                Button("🔴 Röd")      { onEdgeSetColor(edge.id, "#b91c1c") }
                Button("🔵 Blå")      { onEdgeSetColor(edge.id, "#1d4ed8") }
                Button("🟢 Grön")     { onEdgeSetColor(edge.id, "#15803d") }
                Button("🟠 Orange")   { onEdgeSetColor(edge.id, "#c2410c") }
                Button("🟣 Lila")     { onEdgeSetColor(edge.id, "#6d28d9") }
                Button("🟡 Gul")      { onEdgeSetColor(edge.id, "#a16207") }
                Button("⚪️ Grå")      { onEdgeSetColor(edge.id, "#6b7280") }
            } label: {
                Label("Färg på pilen", systemImage: "paintpalette")
            }
            // v64: välj vilken sida pilen går ut från (ersätter de fyra handtagen)
            Menu {
                Button { onEdgeSetFromSide(edge.id, nil) } label: {
                    Label("Automatisk (närmaste sida)", systemImage: "sparkles")
                }
                Button { onEdgeSetFromSide(edge.id, .top) } label: {
                    Label("Uppåt", systemImage: "arrow.up")
                }
                Button { onEdgeSetFromSide(edge.id, .right) } label: {
                    Label("Höger", systemImage: "arrow.right")
                }
                Button { onEdgeSetFromSide(edge.id, .bottom) } label: {
                    Label("Neråt", systemImage: "arrow.down")
                }
                Button { onEdgeSetFromSide(edge.id, .left) } label: {
                    Label("Vänster", systemImage: "arrow.left")
                }
            } label: {
                Label("Går ut från", systemImage: "arrow.up.right.square")
            }
            Divider()
            if hasWaypoint {
                Button {
                    edge.waypoints = []
                } label: {
                    Label("Räta ut pil", systemImage: "minus")
                }
            }
            Button(role: .destructive) {
                onEdgeDelete(edge.id)
            } label: {
                Label("Ta bort pil", systemImage: "trash")
            }
        }
        // v38: kant-etikett vid midpoint. v62: ovanför/under enligt labelPlacement.
        if !label.isEmpty {
            let labelOffset = size * 0.85 + 8 / canvasScale
            let labelY = edge.labelPlacement == .above
                ? mid.y - labelOffset
                : mid.y + labelOffset
            Text(label)
                .font(.system(size: max(8, 10 / canvasScale), weight: .medium, design: .rounded))
                .foregroundStyle(Color.accentColor)
                .lineLimit(1)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color(.systemBackground).opacity(0.88))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .allowsHitTesting(false)
                .position(CGPoint(x: mid.x, y: labelY))
        }
    }

    private func midpointGesture() -> some Gesture {
        DragGesture(coordinateSpace: .named("canvas"))
            .onChanged { v in
                let newPoint = v.location
                if edge.waypoints.isEmpty {
                    edge.waypoints = [EdgeWaypoint(newPoint)]
                } else {
                    edge.waypoints[0] = EdgeWaypoint(newPoint)
                }
            }
    }
}
