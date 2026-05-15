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
    var onShapeTap: (UUID) -> Void
    var onShapeEdit: (UUID) -> Void
    var onShapeDelete: (UUID) -> Void
    var onEdgeDelete: (UUID) -> Void

    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea(edges: [.horizontal, .bottom])

            DotGridBackground()
                .ignoresSafeArea(edges: [.horizontal, .bottom])

            if model.specType == .ui {
                iPhoneFrameOverlay(size: model.canvasSize)
                    .ignoresSafeArea(edges: [.horizontal, .bottom])
            }

            EdgesView(edges: model.edges,
                      shapes: model.shapes,
                      onEdgeTap: onEdgeDelete)

            ForEach($model.shapes) { $shape in
                ShapeView(
                    shape: $shape,
                    edgeMode: model.isEdgeMode,
                    isPendingFrom: model.pendingEdgeFrom == shape.id,
                    onTap: { onShapeTap(shape.id) },
                    onEdit: { onShapeEdit(shape.id) },
                    onDelete: { onShapeDelete(shape.id) }
                )
            }
        }
        .dropDestination(for: ShapeType.self) { items, location in
            for item in items {
                model.addShape(item, at: location)
            }
            return !items.isEmpty
        }
    }
}

struct ShapeView: View {
    @Binding var shape: ShapeNode
    let edgeMode: Bool
    let isPendingFrom: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var dragOffset: CGSize = .zero

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
        .contentShape(Rectangle())
        .position(
            x: shape.position.x + dragOffset.width,
            y: shape.position.y + dragOffset.height
        )
        .onTapGesture {
            if edgeMode {
                onTap()
            } else {
                onEdit()
            }
        }
        .gesture(edgeMode ? nil : dragGesture)
        .contextMenu {
            Button {
                onEdit()
            } label: {
                Label("Redigera", systemImage: "pencil")
            }
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Ta bort", systemImage: "trash")
            }
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
            Circle().fill(shape.category.fillColor)
        case .rectangle:
            RoundedRectangle(cornerRadius: 12).fill(shape.category.fillColor)
        case .diamond:
            DiamondShape().fill(shape.category.fillColor)
        case .text:
            EmptyView()
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
        case .text:
            EmptyView()
        }
    }

    @ViewBuilder
    private var highlight: some View {
        if isPendingFrom {
            switch shape.type {
            case .circle:
                Circle().stroke(Color.accentColor, lineWidth: 3.5)
            case .rectangle:
                RoundedRectangle(cornerRadius: 12).stroke(Color.accentColor, lineWidth: 3.5)
            case .diamond:
                DiamondShape().stroke(Color.accentColor, lineWidth: 3.5)
            case .text:
                RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor, lineWidth: 3.5)
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

/// Pilarna ritas i en separat ZStack-lager. Tap på pilen → delete-callback.
/// Vi använder en gestur-overlay per edge eftersom Canvas själv inte är tappable.
struct EdgesView: View {
    let edges: [EdgeConnection]
    let shapes: [ShapeNode]
    var onEdgeTap: (UUID) -> Void

    var body: some View {
        ZStack {
            Canvas { context, _ in
                for edge in edges {
                    guard let fromShape = shapes.first(where: { $0.id == edge.from }),
                          let toShape = shapes.first(where: { $0.id == edge.to })
                    else { continue }
                    let start = edgePoint(for: fromShape, towards: toShape.position)
                    let end = edgePoint(for: toShape, towards: fromShape.position)
                    drawArrow(context: context, from: start, to: end, bidirectional: edge.bidirectional)
                }
            }
            .allowsHitTesting(false)

            // Klickbara cirklar i mitten av varje pil — för delete
            ForEach(edges) { edge in
                if let fromShape = shapes.first(where: { $0.id == edge.from }),
                   let toShape = shapes.first(where: { $0.id == edge.to }) {
                    let mid = CGPoint(
                        x: (fromShape.position.x + toShape.position.x) / 2,
                        y: (fromShape.position.y + toShape.position.y) / 2
                    )
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 24, height: 24)
                        .contentShape(Circle())
                        .position(mid)
                        .contextMenu {
                            Button(role: .destructive) {
                                onEdgeTap(edge.id)
                            } label: {
                                Label("Ta bort pil", systemImage: "trash")
                            }
                        }
                }
            }
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
            let absX = abs(dx)
            let absY = abs(dy)
            let hw = ShapeGeometry.halfWidth(for: shape)
            let hh = ShapeGeometry.halfHeight(for: shape)
            let tx = absX > 0.001 ? hw / absX : .greatestFiniteMagnitude
            let ty = absY > 0.001 ? hh / absY : .greatestFiniteMagnitude
            let t = min(tx, ty)
            return CGPoint(x: center.x + t * dx, y: center.y + t * dy)

        case .diamond:
            let absX = abs(dx)
            let absY = abs(dy)
            let hw = ShapeGeometry.halfWidth(for: shape)
            let hh = ShapeGeometry.halfHeight(for: shape)
            let denom = absX / hw + absY / hh
            guard denom > 0.001 else { return center }
            let t = 1.0 / denom
            return CGPoint(x: center.x + t * dx, y: center.y + t * dy)

        case .text:
            // Text-shape använder rektangulär hit-box som anslutningspunkt
            let absX = abs(dx)
            let absY = abs(dy)
            let hw = ShapeGeometry.halfWidth(for: shape)
            let hh = ShapeGeometry.halfHeight(for: shape)
            let tx = absX > 0.001 ? hw / absX : .greatestFiniteMagnitude
            let ty = absY > 0.001 ? hh / absY : .greatestFiniteMagnitude
            let t = min(tx, ty)
            return CGPoint(x: center.x + t * dx, y: center.y + t * dy)
        }
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
