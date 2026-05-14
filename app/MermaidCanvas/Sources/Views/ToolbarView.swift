import SwiftUI

struct ToolbarView: View {
    @ObservedObject var model: CanvasModel
    let canvasCenter: CGPoint
    var onSave: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button {
                model.addCircle(at: canvasCenter)
            } label: {
                Label("Cirkel", systemImage: "circle")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.borderedProminent)

            Spacer()

            Button {
                onSave()
            } label: {
                Label("Spara", systemImage: "square.and.arrow.down")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.thinMaterial)
    }
}
