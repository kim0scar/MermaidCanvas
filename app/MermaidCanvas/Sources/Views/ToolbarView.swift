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
        HStack(spacing: 14) {
            shapeIconButton(.circle, system: "circle")
            shapeIconButton(.rectangle, system: "rectangle")
            shapeIconButton(.diamond, system: "diamond")

            pilControl

            Spacer()

            iconButton(system: "folder", action: onOpen)
            iconButton(system: "square.and.arrow.down", action: onSave, prominent: true)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    @ViewBuilder
    private func shapeIconButton(_ type: ShapeType, system: String) -> some View {
        Button {
            if !model.isEdgeMode {
                model.addShape(type, at: canvasCenter)
            }
        } label: {
            Image(systemName: system)
                .font(.title2)
                .foregroundStyle(Color.primary)
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(model.isEdgeMode)
        .opacity(model.isEdgeMode ? 0.35 : 1)
        .draggable(type) {
            Image(systemName: system)
                .font(.title2)
                .padding(10)
                .background(.thinMaterial, in: Circle())
        }
    }

    @ViewBuilder
    private var pilControl: some View {
        if edgeMode == .off {
            Menu {
                Button {
                    onStartEdgeMode(.directional)
                } label: {
                    Label("Pil", systemImage: "arrow.right")
                }
                Button {
                    onStartEdgeMode(.bidirectional)
                } label: {
                    Label("Dubbel-pil", systemImage: "arrow.left.arrow.right")
                }
            } label: {
                Image(systemName: "arrow.right")
                    .font(.title2)
                    .foregroundStyle(Color.primary)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
        } else {
            Button {
                onCancelEdgeMode()
            } label: {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundStyle(.red)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
        }
    }

    @ViewBuilder
    private func iconButton(system: String, action: @escaping () -> Void, prominent: Bool = false) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.title3)
                .foregroundStyle(prominent ? Color.white : Color.primary)
                .frame(width: 38, height: 32)
                .background(prominent ? Color.accentColor : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
