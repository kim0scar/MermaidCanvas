import SwiftUI

struct ToolbarView: View {
    @ObservedObject var model: CanvasModel
    let canvasCenter: CGPoint
    var onOpen: () -> Void
    var onSave: () -> Void

    var body: some View {
        HStack(spacing: 10) {
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
                onOpen()
            } label: {
                Label("Öppna", systemImage: "folder")
                    .labelStyle(.titleAndIcon)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.bordered)
            .tint(.orange)
            .contentShape(Rectangle())

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
