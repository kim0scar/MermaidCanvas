import SwiftUI

enum ShapeGeometry {
    static let baseWidth: CGFloat = 120
    static let baseHeight: CGFloat = 80

    static func width(for shape: ShapeNode) -> CGFloat { baseWidth * shape.sizeMultiplier }
    static func height(for shape: ShapeNode) -> CGFloat { baseHeight * shape.sizeMultiplier }
    static func halfWidth(for shape: ShapeNode) -> CGFloat { width(for: shape) / 2 }
    static func halfHeight(for shape: ShapeNode) -> CGFloat { height(for: shape) / 2 }
    static func circleRadius(for shape: ShapeNode) -> CGFloat {
        min(width(for: shape), height(for: shape)) / 2
    }
}

struct CanvasView: View {
    @ObservedObject var model: CanvasModel
    var onShapeEdgeTap: (UUID) -> Void  // tap i edge-mode
    var onShapeEdit: (UUID) -> Void
    var onShapeDelete: (UUID) -> Void
    var onEdgeDelete: (UUID) -> Void
    var onShapeSelect: (UUID) -> Void

    // Pan/zoom-state (interna gestures)
    @State private var panStartOffset: CGSize? = nil
    @State private var pinchStartScale: CGFloat? = nil

    private let minScale: CGFloat = 0.25
    private let maxScale: CGFloat = 3.0

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                // Viewport-bakgrund — pan/zoom-gestures sitter här
                Color(.systemGray5)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .contentShape(Rectangle())
                    .gesture(panGesture)
                    .gesture(zoomGesture)
                    .onTapGesture(count: 2) { handleDoubleTap() }
                    .onTapGesture(count: 1) { model.deselect() }

                // Canvas-innehåll i fixed 3000×3000 ram, transformerat
                canvasContent
                    .frame(width: CanvasModel.contentSize.width,
                           height: CanvasModel.contentSize.height,
                           alignment: .topLeading)
                    .coordinateSpace(name: "canvas")
                    .scaleEffect(model.canvasScale, anchor: .topLeading)
                    .offset(x: model.canvasOffset.width, y: model.canvasOffset.height)
                    .allowsHitTesting(true)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
            .dropDestination(for: ShapeType.self) { items, location in
                let canvasLoc = screenToCanvas(location)
                for item in items {
                    model.addShape(item, at: canvasLoc)
                }
                return !items.isEmpty
            }
        }
    }

    // MARK: - Canvas-content (3000×3000)

    private var canvasContent: some View {
        ZStack(alignment: .topLeading) {
            // Vit canvas-yta
            Color(.systemGray6)
                .frame(width: CanvasModel.contentSize.width,
                       height: CanvasModel.contentSize.height)

            // Prickrutnät över hela canvas
            DotGridBackground()
                .frame(width: CanvasModel.contentSize.width,
                       height: CanvasModel.contentSize.height)

            // iPhone-ram i UI-läge (fast 393×852 centrerad i canvasen)
            if model.specType == .ui {
                iPhoneFrameOverlay(canvasContentSize: CanvasModel.contentSize)
                    .frame(width: CanvasModel.contentSize.width,
                           height: CanvasModel.contentSize.height)
            }

            // Pilar — visa bara om båda ändarna är synliga
            let hiddenForEdges = model.hiddenShapeIds
            EdgesView(edges: $model.edges,
                      shapes: model.shapes,
                      canvasScale: model.canvasScale,
                      hiddenShapeIds: hiddenForEdges,
                      onEdgeTap: onEdgeDelete)
                .frame(width: CanvasModel.contentSize.width,
                       height: CanvasModel.contentSize.height)

            // Former (filtrera bort kollapsade descendants)
            let hidden = model.hiddenShapeIds
            ForEach($model.shapes) { $shape in
                if !hidden.contains(shape.id) {
                    ShapeView(
                        shape: $shape,
                        edgeMode: model.isEdgeMode,
                        markerMode: model.markerMode,
                        canvasScale: model.canvasScale,
                        isCollapsed: model.collapsedIds.contains(shape.id),
                        showCollapseBadge: model.hasOutgoingEdges(id: shape.id),
                        isPendingFrom: model.pendingEdgeFrom == shape.id,
                        onEdgeTap: { onShapeEdgeTap(shape.id) },
                        onSelect: { onShapeSelect(shape.id) },
                        onEdit: { onShapeEdit(shape.id) },
                        onDelete: { onShapeDelete(shape.id) },
                        onShowNote: { onShapeEdit(shape.id) },
                        onToggleCollapse: { model.toggleCollapse(id: shape.id) }
                    )
                }
            }

            // Multi-selection markeringsringar
            ForEach(model.shapes.filter { model.multiSelection.contains($0.id) }) { s in
                Rectangle()
                    .stroke(Color.accentColor,
                            style: StrokeStyle(lineWidth: 2 / model.canvasScale,
                                               dash: [5 / model.canvasScale, 4 / model.canvasScale]))
                    .frame(width: ShapeGeometry.width(for: s) + 8,
                           height: ShapeGeometry.height(for: s) + 8)
                    .position(s.position)
                    .allowsHitTesting(false)
            }

            // Selection-handtag på vald form (bara om EJ multi-selection)
            if model.multiSelection.isEmpty,
               let selectedId = model.selectedShapeId,
               let idx = model.shapes.firstIndex(where: { $0.id == selectedId }) {
                SelectionHandles(
                    shape: $model.shapes[idx],
                    canvasScale: model.canvasScale
                )
            }

            // Marker-mode-overlay (drag-rectangle)
            if model.markerMode {
                MarkerOverlay(model: model, canvasContentSize: CanvasModel.contentSize)
            }
        }
    }

    // MARK: - Gestures

    private var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if panStartOffset == nil {
                    panStartOffset = model.canvasOffset
                }
                let start = panStartOffset ?? .zero
                model.canvasOffset = CGSize(
                    width: start.width + value.translation.width,
                    height: start.height + value.translation.height
                )
            }
            .onEnded { _ in
                panStartOffset = nil
            }
    }

    private var zoomGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                if pinchStartScale == nil {
                    pinchStartScale = model.canvasScale
                }
                let start = pinchStartScale ?? 1
                model.canvasScale = clamp(start * value, minScale, maxScale)
            }
            .onEnded { _ in
                pinchStartScale = nil
            }
    }

    private func handleDoubleTap() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if model.canvasScale < 1.25 {
                model.canvasScale = 1.5
            } else {
                model.canvasScale = 1.0
            }
        }
    }

    // MARK: - Koord-konvertering

    private func screenToCanvas(_ p: CGPoint) -> CGPoint {
        CGPoint(
            x: (p.x - model.canvasOffset.width) / model.canvasScale,
            y: (p.y - model.canvasOffset.height) / model.canvasScale
        )
    }

    private func clamp<T: Comparable>(_ v: T, _ lo: T, _ hi: T) -> T {
        min(max(v, lo), hi)
    }
}

// MARK: - ShapeView

struct ShapeView: View {
    @Binding var shape: ShapeNode
    let edgeMode: Bool
    let markerMode: Bool
    let canvasScale: CGFloat
    let isCollapsed: Bool
    let showCollapseBadge: Bool
    let isPendingFrom: Bool
    let onEdgeTap: () -> Void
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onShowNote: () -> Void
    let onToggleCollapse: () -> Void

    @State private var dragOffset: CGSize = .zero

    /// Effektiv fyllfärg: colorOverride om satt, annars kategori-färg.
    private var effectiveFill: Color {
        if let hex = shape.colorOverride {
            return Color(hex: parseHex(hex))
        }
        return shape.category.fillColor
    }

    private func parseHex(_ hex: String) -> UInt32 {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        return UInt32(cleaned, radix: 16) ?? 0
    }

    var body: some View {
        ZStack {
            background
            stroke
            highlight
            if shape.showLabel {
                Text(shape.label)
                    .font(.system(size: 13 * shape.sizeMultiplier,
                                  weight: shape.type == .text ? .semibold : .medium,
                                  design: .rounded))
                    .foregroundStyle(shape.type == .text ? Color.primary : shape.category.textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(6)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, shape.type == .text ? 2 : 8)
            }
        }
        .frame(width: ShapeGeometry.width(for: shape),
               height: ShapeGeometry.height(for: shape))
        .rotationEffect(.degrees(shape.rotation))
        .opacity(markerMode && !edgeMode ? 0.6 : 1.0)
        .overlay(alignment: .topTrailing) {
            if !shape.note.isEmpty && !markerMode {
                NoteBadge(canvasScale: canvasScale, onTap: onShowNote)
                    .offset(x: 8 / canvasScale, y: -8 / canvasScale)
                    .rotationEffect(.degrees(-shape.rotation))
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if showCollapseBadge && !markerMode {
                CollapseBadge(collapsed: isCollapsed,
                              canvasScale: canvasScale,
                              onTap: onToggleCollapse)
                    .offset(x: 8 / canvasScale, y: 8 / canvasScale)
                    .rotationEffect(.degrees(-shape.rotation))
            }
        }
        .contentShape(Rectangle())
        .position(
            x: shape.position.x + dragOffset.width,
            y: shape.position.y + dragOffset.height
        )
        .onTapGesture(count: 2) {
            if !edgeMode && !markerMode { onEdit() }
        }
        .onTapGesture(count: 1) {
            if markerMode { return }
            if edgeMode {
                onEdgeTap()
            } else {
                onSelect()
            }
        }
        .gesture((edgeMode || markerMode) ? nil : dragGesture)
        .contextMenu {
            Button { onEdit() } label: { Label("Redigera", systemImage: "pencil") }
            Button(role: .destructive) { onDelete() } label: { Label("Ta bort", systemImage: "trash") }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { v in dragOffset = v.translation }
            .onEnded { v in
                shape.position.x += v.translation.width
                shape.position.y += v.translation.height
                dragOffset = .zero
            }
    }

    @ViewBuilder
    private var background: some View {
        switch shape.type {
        case .circle:
            Circle().fill(effectiveFill)
        case .rectangle:
            RoundedRectangle(cornerRadius: 12).fill(effectiveFill)
        case .diamond:
            DiamondShape().fill(effectiveFill)
        case .text:
            EmptyView()
        case .table:
            TableShapeBackground(rows: shape.tableRows ?? 3,
                                 cols: shape.tableCols ?? 3,
                                 fill: effectiveFill,
                                 stroke: shape.category.strokeColor)
        case .link:
            JumpLinkShapeBackground(number: shape.linkNumber ?? 0, fill: effectiveFill)
        }
    }

    @ViewBuilder
    private var stroke: some View {
        switch shape.type {
        case .circle:
            Circle().stroke(shape.category.strokeColor, lineWidth: 1.5)
        case .rectangle:
            RoundedRectangle(cornerRadius: 12).stroke(shape.category.strokeColor, lineWidth: 1.5)
        case .diamond:
            DiamondShape().stroke(shape.category.strokeColor, lineWidth: 1.5)
        case .text, .table, .link:
            EmptyView()
        }
    }

    @ViewBuilder
    private var highlight: some View {
        if isPendingFrom {
            switch shape.type {
            case .circle:
                Circle().stroke(Color.accentColor, lineWidth: 3.5)
            case .rectangle, .table:
                RoundedRectangle(cornerRadius: 12).stroke(Color.accentColor, lineWidth: 3.5)
            case .diamond:
                DiamondShape().stroke(Color.accentColor, lineWidth: 3.5)
            case .text:
                RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor, lineWidth: 3.5)
            case .link:
                Circle().stroke(Color.accentColor, lineWidth: 3.5)
            }
        }
    }
}

// MARK: - Special shape backgrounds

private struct TableShapeBackground: View {
    var rows: Int
    var cols: Int
    var fill: Color
    var stroke: Color

    var body: some View {
        GeometryReader { geo in
            let cellW = geo.size.width / CGFloat(cols)
            let cellH = geo.size.height / CGFloat(rows)
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(fill.opacity(0.18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(stroke, lineWidth: 1.5)
                    )
                // Grid-linjer
                Path { p in
                    for r in 1..<rows {
                        let y = cellH * CGFloat(r)
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                    for c in 1..<cols {
                        let x = cellW * CGFloat(c)
                        p.move(to: CGPoint(x: x, y: 0))
                        p.addLine(to: CGPoint(x: x, y: geo.size.height))
                    }
                }
                .stroke(stroke.opacity(0.5), lineWidth: 1)
            }
        }
    }
}

private struct JumpLinkShapeBackground: View {
    var number: Int
    var fill: Color

    var body: some View {
        ZStack {
            Circle().fill(fill)
            Circle().stroke(Color.white, lineWidth: 2)
            VStack(spacing: 0) {
                Image(systemName: "link")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                Text("\(number)")
                    .font(.callout.weight(.heavy))
                    .foregroundStyle(.white)
            }
        }
    }
}

struct DiamondShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        p.closeSubpath()
        return p
    }
}

// MARK: - EdgesView

struct EdgesView: View {
    @Binding var edges: [EdgeConnection]
    let shapes: [ShapeNode]
    let canvasScale: CGFloat
    let hiddenShapeIds: Set<UUID>
    var onEdgeTap: (UUID) -> Void

    private func isVisible(_ edge: EdgeConnection) -> Bool {
        !hiddenShapeIds.contains(edge.from) && !hiddenShapeIds.contains(edge.to)
    }

    var body: some View {
        ZStack {
            // Linjer
            Canvas { context, _ in
                for edge in edges where isVisible(edge) {
                    guard let fromShape = shapes.first(where: { $0.id == edge.from }),
                          let toShape = shapes.first(where: { $0.id == edge.to })
                    else { continue }
                    drawEdge(context: context, edge: edge, fromShape: fromShape, toShape: toShape)
                }
            }
            .allowsHitTesting(false)

            // Mid-punkt-handtag (klickbara cirklar)
            ForEach($edges) { $edge in
                if isVisible(edge),
                   let fromShape = shapes.first(where: { $0.id == edge.from }),
                   let toShape = shapes.first(where: { $0.id == edge.to }) {
                    midpointHandle(edge: $edge, fromShape: fromShape, toShape: toShape)
                }
            }
        }
    }

    // MARK: - Mid-punkt-handtag

    @ViewBuilder
    private func midpointHandle(edge: Binding<EdgeConnection>,
                                fromShape: ShapeNode,
                                toShape: ShapeNode) -> some View {
        let hasWaypoint = !edge.wrappedValue.waypoints.isEmpty
        let mid: CGPoint = {
            if hasWaypoint { return edge.wrappedValue.waypoints[0].point }
            return CGPoint(
                x: (fromShape.position.x + toShape.position.x) / 2,
                y: (fromShape.position.y + toShape.position.y) / 2
            )
        }()
        let size: CGFloat = max(14, 18 / canvasScale)
        ZStack {
            Circle()
                .fill(hasWaypoint ? Color.accentColor : Color.white)
                .overlay(Circle().stroke(Color.accentColor,
                                         lineWidth: max(1.0, 1.5 / canvasScale)))
                .frame(width: size, height: size)
        }
        .contentShape(Circle().inset(by: -size * 0.5))
        .position(mid)
        .gesture(midpointGesture(edge: edge, fromShape: fromShape, toShape: toShape))
        .contextMenu {
            if hasWaypoint {
                Button {
                    edge.wrappedValue.waypoints = []
                } label: {
                    Label("Räta ut pil", systemImage: "minus")
                }
            }
            Button(role: .destructive) {
                onEdgeTap(edge.wrappedValue.id)
            } label: {
                Label("Ta bort pil", systemImage: "trash")
            }
        }
    }

    private func midpointGesture(edge: Binding<EdgeConnection>,
                                 fromShape: ShapeNode,
                                 toShape: ShapeNode) -> some Gesture {
        DragGesture(coordinateSpace: .named("canvas"))
            .onChanged { v in
                let newPoint = v.location
                if edge.wrappedValue.waypoints.isEmpty {
                    edge.wrappedValue.waypoints = [EdgeWaypoint(newPoint)]
                } else {
                    edge.wrappedValue.waypoints[0] = EdgeWaypoint(newPoint)
                }
            }
    }

    // MARK: - Drawing

    private func drawEdge(context: GraphicsContext,
                          edge: EdgeConnection,
                          fromShape: ShapeNode,
                          toShape: ShapeNode) {
        if let wp = edge.waypoints.first {
            // L-form: from → waypoint → to
            let firstSeg = edgePoint(for: fromShape, towards: wp.point)
            let lastSeg = edgePoint(for: toShape, towards: wp.point)

            var line = Path()
            line.move(to: firstSeg)
            line.addLine(to: wp.point)
            line.addLine(to: lastSeg)
            context.stroke(line, with: .color(.primary.opacity(0.6)), lineWidth: 1.5)

            let angle = atan2(lastSeg.y - wp.point.y, lastSeg.x - wp.point.x)
            drawArrowHead(context: context, tip: lastSeg, angle: angle)
            if edge.bidirectional {
                let startAngle = atan2(firstSeg.y - wp.point.y, firstSeg.x - wp.point.x)
                drawArrowHead(context: context, tip: firstSeg, angle: startAngle)
            }
        } else {
            // Rak linje
            let start = edgePoint(for: fromShape, towards: toShape.position)
            let end = edgePoint(for: toShape, towards: fromShape.position)
            drawArrow(context: context, from: start, to: end, bidirectional: edge.bidirectional)
        }
    }

    private func edgePoint(for shape: ShapeNode, towards target: CGPoint) -> CGPoint {
        let center = shape.position
        let dx = target.x - center.x
        let dy = target.y - center.y
        let length = sqrt(dx * dx + dy * dy)
        guard length > 0.001 else { return center }

        switch shape.type {
        case .circle:
            let r = ShapeGeometry.circleRadius(for: shape)
            return CGPoint(x: center.x + r * dx / length, y: center.y + r * dy / length)
        case .rectangle:
            return rectEdge(center: center, dx: dx, dy: dy, shape: shape)
        case .diamond:
            let absX = abs(dx)
            let absY = abs(dy)
            let hw = ShapeGeometry.halfWidth(for: shape)
            let hh = ShapeGeometry.halfHeight(for: shape)
            let denom = absX / hw + absY / hh
            guard denom > 0.001 else { return center }
            let t = 1.0 / denom
            return CGPoint(x: center.x + t * dx, y: center.y + t * dy)
        case .text, .table:
            return rectEdge(center: center, dx: dx, dy: dy, shape: shape)
        case .link:
            let r = ShapeGeometry.circleRadius(for: shape)
            return CGPoint(x: center.x + r * dx / length, y: center.y + r * dy / length)
        }
    }

    private func rectEdge(center: CGPoint, dx: CGFloat, dy: CGFloat, shape: ShapeNode) -> CGPoint {
        let absX = abs(dx)
        let absY = abs(dy)
        let hw = ShapeGeometry.halfWidth(for: shape)
        let hh = ShapeGeometry.halfHeight(for: shape)
        let tx = absX > 0.001 ? hw / absX : .greatestFiniteMagnitude
        let ty = absY > 0.001 ? hh / absY : .greatestFiniteMagnitude
        let t = min(tx, ty)
        return CGPoint(x: center.x + t * dx, y: center.y + t * dy)
    }

    private func drawArrow(context: GraphicsContext, from: CGPoint, to: CGPoint, bidirectional: Bool) {
        var line = Path()
        line.move(to: from)
        line.addLine(to: to)
        context.stroke(line, with: .color(.primary.opacity(0.6)), lineWidth: 1.5)

        let angle = atan2(to.y - from.y, to.x - from.x)
        drawArrowHead(context: context, tip: to, angle: angle)
        if bidirectional {
            drawArrowHead(context: context, tip: from, angle: angle + .pi)
        }
    }

    private func drawArrowHead(context: GraphicsContext, tip: CGPoint, angle: CGFloat) {
        let length: CGFloat = 12
        let spread: CGFloat = .pi / 7
        let a1 = CGPoint(
            x: tip.x - length * cos(angle - spread),
            y: tip.y - length * sin(angle - spread)
        )
        let a2 = CGPoint(
            x: tip.x - length * cos(angle + spread),
            y: tip.y - length * sin(angle + spread)
        )
        var head = Path()
        head.move(to: tip); head.addLine(to: a1)
        head.move(to: tip); head.addLine(to: a2)
        context.stroke(head, with: .color(.primary.opacity(0.6)), lineWidth: 1.5)
    }
}
