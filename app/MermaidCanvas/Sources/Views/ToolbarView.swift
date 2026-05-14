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
                    .padding(.horizontal, 4)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.blue)
            .contentShape(Rectangle())

            Spacer()

            Button {
                onSave()
            } label: {
                Label("Spara", systemImage: "square.and.arrow.down")
                    .labelStyle(.titleAndIcon)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .contentShape(Rectangle())
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}
