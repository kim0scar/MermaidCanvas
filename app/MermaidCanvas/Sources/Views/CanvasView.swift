import SwiftUI

struct CanvasView: View {
    @ObservedObject var model: CanvasModel

    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea(edges: [.horizontal, .bottom])
            ForEach($model.shapes) { $shape in
                CircleNodeView(shape: $shape)
            }
        }
    }
}

struct CircleNodeView: View {
    @Binding var shape: ShapeNode
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.25))
            Circle()
                .stroke(Color.blue, lineWidth: 2)
            Text(shape.label)
                .font(.caption)
                .foregroundStyle(.primary)
        }
        .frame(width: 90, height: 90)
        .position(
            x: shape.position.x + dragOffset.width,
            y: shape.position.y + dragOffset.height
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    shape.position.x += value.translation.width
                    shape.position.y += value.translation.height
                    dragOffset = .zero
                }
        )
    }
}
