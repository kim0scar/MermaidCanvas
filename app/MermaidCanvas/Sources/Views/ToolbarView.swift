import SwiftUI

struct ToolbarView: View {
    @ObservedObject var model: CanvasModel
    let canvasCenter: CGPoint
    let edgeMode: Bool
    var onToggleEdgeMode: () -> Void
    var onOpen: () -> Void
    var onSave: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                shapeButton(.circle, label: "Cirkel", system: "circle", color: .blue)
                shapeButton(.rectangle, label: "Box", system: "rectangle", color: .green)
                shapeButton(.diamond, label: "Romb", system: "diamond", color: .orange)
                Spacer(minLength: 6)
                Button {
                    onToggleEdgeMode()
                } label: {
                    Label(edgeMode ? "Avbryt pil" : "Pil",
                          systemImage: edgeMode ? "xmark" : "arrow.right")
                        .labelStyle(.titleAndIcon)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(edgeMode ? .red : .purple)
                .contentShape(Rectangle())
            }
            HStack(spacing: 8) {
                Spacer()
                Button {
                    onOpen()
                } label: {
                    Label("Öppna", systemImage: "folder")
                        .labelStyle(.titleAndIcon)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 4)
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
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
                .contentShape(Rectangle())
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    private func shapeButton(_ type: ShapeType, label: String, system: String, color: Color) -> some View {
        Button {
            model.addShape(type, at: canvasCenter)
        } label: {
            Label(label, systemImage: system)
                .labelStyle(.titleAndIcon)
                .padding(.horizontal, 2)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .tint(color)
        .contentShape(Rectangle())
        .disabled(edgeMode)
    }
}
