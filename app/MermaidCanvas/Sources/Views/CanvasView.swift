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

    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea(edges: [.horizontal, .bottom])

            EdgesView(edges: model.edges, shapes: model.shapes)

            ForEach($model.shapes) { $shape in
                ShapeView(
                    shape: $shape,
                    edgeMode: model.isEdgeMode,
                    isPendingFrom: model.pendingEdgeFrom == shape.id,
                    onTap: { onShapeTap(shape.id) },
                    onEdit: { onShapeEdit(shape.id) }
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

    @State private var dragOffset: CGSize = .zero

    var body: some View {
        ZStack {
            background
            stroke
            highlight
            if shape.showLabel {
                Text(shape.label)
                    .font(.system(size: 13 * shape.sizeMultiplier,
                                  weight: .medium,
                                  design: .rounded))
                    .foregroundStyle(shape.category.textColor)
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 8)
            }
        }
        .frame(width: ShapeGeometry.width(for: shape),
               height: ShapeGeometry.height(for: shape))
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

struct EdgesView: View {
    let edges: [EdgeConnection]
    let shapes: [ShapeNode]

    var body: some View {
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
