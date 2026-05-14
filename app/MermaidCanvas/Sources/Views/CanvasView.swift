import SwiftUI

private enum ShapeGeometry {
    static let width: CGFloat = 110
    static let height: CGFloat = 78
    static let halfWidth: CGFloat = width / 2
    static let halfHeight: CGFloat = height / 2
    static let circleRadius: CGFloat = min(width, height) / 2
}

struct CanvasView: View {
    @ObservedObject var model: CanvasModel
    let edgeMode: Bool
    var onShapeTap: (UUID) -> Void

    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea(edges: [.horizontal, .bottom])

            EdgesView(edges: model.edges, shapes: model.shapes)

            ForEach($model.shapes) { $shape in
                ShapeView(
                    shape: $shape,
                    edgeMode: edgeMode,
                    isPendingFrom: model.pendingEdgeFrom == shape.id,
                    onTap: { onShapeTap(shape.id) }
                )
            }
        }
    }
}

struct ShapeView: View {
    @Binding var shape: ShapeNode
    let edgeMode: Bool
    let isPendingFrom: Bool
    let onTap: () -> Void

    @State private var dragOffset: CGSize = .zero

    var body: some View {
        ZStack {
            background
            stroke
            highlight
            Text(shape.label)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .padding(.horizontal, 6)
        }
        .frame(width: ShapeGeometry.width, height: ShapeGeometry.height)
        .contentShape(Rectangle())
        .position(
            x: shape.position.x + dragOffset.width,
            y: shape.position.y + dragOffset.height
        )
        .onTapGesture {
            if edgeMode { onTap() }
        }
        .gesture(edgeMode ? nil : dragGesture)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { v in dragOffset = v.translation }
            .onEnded { v in
                shape.position.x += v.translation.width
                shape.position.y += v.translation.height
                dragOffset = .zero
            }
    }

    private var color: Color {
        switch shape.type {
        case .circle:    return .blue
        case .rectangle: return .green
        case .diamond:   return .orange
        }
    }

    @ViewBuilder
    private var background: some View {
        switch shape.type {
        case .circle:
            Circle().fill(color.opacity(0.22))
        case .rectangle:
            RoundedRectangle(cornerRadius: 10).fill(color.opacity(0.22))
        case .diamond:
            DiamondShape().fill(color.opacity(0.22))
        }
    }

    @ViewBuilder
    private var stroke: some View {
        switch shape.type {
        case .circle:
            Circle().stroke(color, lineWidth: 2)
        case .rectangle:
            RoundedRectangle(cornerRadius: 10).stroke(color, lineWidth: 2)
        case .diamond:
            DiamondShape().stroke(color, lineWidth: 2)
        }
    }

    @ViewBuilder
    private var highlight: some View {
        if isPendingFrom {
            switch shape.type {
            case .circle:
                Circle().stroke(Color.red, lineWidth: 4)
            case .rectangle:
                RoundedRectangle(cornerRadius: 10).stroke(Color.red, lineWidth: 4)
            case .diamond:
                DiamondShape().stroke(Color.red, lineWidth: 4)
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
                drawArrow(context: context, from: start, to: end)
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
            let r = ShapeGeometry.circleRadius
            return CGPoint(x: center.x + r * dx / length,
                           y: center.y + r * dy / length)

        case .rectangle:
            let absX = abs(dx)
            let absY = abs(dy)
            let tx = absX > 0.001 ? ShapeGeometry.halfWidth / absX : .greatestFiniteMagnitude
            let ty = absY > 0.001 ? ShapeGeometry.halfHeight / absY : .greatestFiniteMagnitude
            let t = min(tx, ty)
            return CGPoint(x: center.x + t * dx, y: center.y + t * dy)

        case .diamond:
            let absX = abs(dx)
            let absY = abs(dy)
            let denom = absX / ShapeGeometry.halfWidth + absY / ShapeGeometry.halfHeight
            guard denom > 0.001 else { return center }
            let t = 1.0 / denom
            return CGPoint(x: center.x + t * dx, y: center.y + t * dy)
        }
    }

    private func drawArrow(context: GraphicsContext, from: CGPoint, to: CGPoint) {
        var line = Path()
        line.move(to: from)
        line.addLine(to: to)
        context.stroke(line, with: .color(.primary.opacity(0.55)), lineWidth: 2)

        let angle = atan2(to.y - from.y, to.x - from.x)
        let arrowLen: CGFloat = 12
        let spread: CGFloat = .pi / 7
        let a1 = CGPoint(
            x: to.x - arrowLen * cos(angle - spread),
            y: to.y - arrowLen * sin(angle - spread)
        )
        let a2 = CGPoint(
            x: to.x - arrowLen * cos(angle + spread),
            y: to.y - arrowLen * sin(angle + spread)
        )
        var head = Path()
        head.move(to: to); head.addLine(to: a1)
        head.move(to: to); head.addLine(to: a2)
        context.stroke(head, with: .color(.primary.opacity(0.55)), lineWidth: 2)
    }
}
