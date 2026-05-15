import SwiftUI

struct ToolbarView: View {
    @ObservedObject var model: CanvasModel
    let canvasCenter: CGPoint
    var hasOpenFile: Bool
    var onStartEdgeMode: (EdgeCreationMode) -> Void
    var onCancelEdgeMode: () -> Void
    var onOpen: () -> Void
    var onSave: () -> Void
    var onSaveAs: () -> Void
    var onUndo: () -> Void
    var onShowCode: () -> Void

    private var edgeMode: EdgeCreationMode { model.edgeCreationMode }

    var body: some View {
        HStack(spacing: 10) {
            shapeIconButton(.circle, system: "circle")
            shapeIconButton(.rectangle, system: "rectangle")
            shapeIconButton(.diamond, system: "diamond")
            shapeIconButton(.text, system: "textformat")

            pilControl

            Divider().frame(height: 24)

            iconButton(system: "arrow.uturn.backward",
                       action: onUndo,
                       disabled: !model.canUndo)

            iconButton(system: "curlybraces",
                       action: onShowCode)

            Spacer()

            iconButton(system: "folder", action: onOpen)
            saveMenu
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) { Divider() }
    }

    @ViewBuilder
    private var saveMenu: some View {
        Menu {
            Button { onSave() } label: {
                Label(hasOpenFile ? "Spara" : "Spara…", systemImage: "internaldrive")
            }
            Button { onSaveAs() } label: {
                Label("Spara som ny fil…", systemImage: "doc.badge.plus")
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "internaldrive")
                    .font(.body.weight(.semibold))
                Text("Spara")
                    .font(.body.weight(.semibold))
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .contentShape(Rectangle())
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
                Button { onStartEdgeMode(.directional) } label: {
                    Label("Pil", systemImage: "arrow.right")
                }
                Button { onStartEdgeMode(.bidirectional) } label: {
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
            Button { onCancelEdgeMode() } label: {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundStyle(.red)
                    .frame(width: 36, height: 36)
                    .contentShape(Rectangle())
            }
        }
    }

    @ViewBuilder
    private func iconButton(system: String,
                            action: @escaping () -> Void,
                            disabled: Bool = false) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.title3)
                .foregroundStyle(disabled ? Color.secondary.opacity(0.4) : Color.primary)
                .frame(width: 36, height: 32)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}
