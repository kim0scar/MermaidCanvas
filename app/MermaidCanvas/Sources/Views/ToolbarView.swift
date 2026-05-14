import SwiftUI

struct ToolbarView: View {
    @ObservedObject var model: CanvasModel
    let canvasCenter: CGPoint
    var onStartEdgeMode: (EdgeCreationMode) -> Void
    var onCancelEdgeMode: () -> Void
    var onOpen: () -> Void
    var onSave: () -> Void

    private var edgeMode: EdgeCreationMode { model.edgeCreationMode }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                shapeButton(.circle, label: "Cirkel", system: "circle", color: .blue)
                shapeButton(.rectangle, label: "Box", system: "rectangle", color: .green)
                shapeButton(.diamond, label: "Romb", system: "diamond", color: .orange)
            }
            HStack(spacing: 6) {
                edgeButton(.directional,
                           label: edgeMode == .directional ? "Avbryt" : "Pil",
                           system: edgeMode == .directional ? "xmark" : "arrow.right",
                           tint: edgeMode == .directional ? .red : .purple)
                edgeButton(.bidirectional,
                           label: edgeMode == .bidirectional ? "Avbryt" : "Dubbel",
                           system: edgeMode == .bidirectional ? "xmark" : "arrow.left.arrow.right",
                           tint: edgeMode == .bidirectional ? .red : .purple)
                Spacer(minLength: 6)
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
            if !model.isEdgeMode {
                model.addShape(type, at: canvasCenter)
            }
        } label: {
            Label(label, systemImage: system)
                .labelStyle(.titleAndIcon)
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .tint(color)
        .contentShape(Rectangle())
        .disabled(model.isEdgeMode)
        .opacity(model.isEdgeMode ? 0.4 : 1)
        .draggable(type) {
            Label(label, systemImage: system)
                .labelStyle(.titleAndIcon)
                .padding(10)
                .background(color.opacity(0.85))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    @ViewBuilder
    private func edgeButton(_ mode: EdgeCreationMode, label: String, system: String, tint: Color) -> some View {
        Button {
            if model.edgeCreationMode == mode {
                onCancelEdgeMode()
            } else {
                onStartEdgeMode(mode)
            }
        } label: {
            Label(label, systemImage: system)
                .labelStyle(.titleAndIcon)
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .tint(tint)
        .contentShape(Rectangle())
    }
}
