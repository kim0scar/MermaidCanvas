import SwiftUI

/// Toolbar v17 — Apple-design: primary actions synliga, sekundära i ...-meny.
/// Tap-targets minst 44×44 enligt HIG.
///
/// Primary (alltid synliga): 4 shape-knappar, pil, undo, spara
/// Secondary (i ...-meny): Visa kod, Preview, Öppna fil
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
    var onShowPreview: () -> Void

    private var edgeMode: EdgeCreationMode { model.edgeCreationMode }
    private let tapTarget: CGFloat = 44

    var body: some View {
        HStack(spacing: 4) {
            shapeIconButton(.circle, system: "circle")
            shapeIconButton(.rectangle, system: "rectangle")
            shapeIconButton(.diamond, system: "diamond")
            shapeIconButton(.text, system: "textformat")

            pilControl

            Spacer(minLength: 6)

            undoButton
            moreMenu
            saveMenu
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
        .overlay(alignment: .bottom) { Divider() }
    }

    // MARK: - Primary

    @ViewBuilder
    private func shapeIconButton(_ type: ShapeType, system: String) -> some View {
        Button {
            if !model.isEdgeMode {
                model.addShape(type, at: canvasCenter)
            }
        } label: {
            Image(systemName: system)
                .font(.title3)
                .foregroundStyle(Color.primary)
                .frame(width: tapTarget, height: tapTarget)
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
                    .font(.title3)
                    .foregroundStyle(Color.primary)
                    .frame(width: tapTarget, height: tapTarget)
                    .contentShape(Rectangle())
            }
        } else {
            Button { onCancelEdgeMode() } label: {
                Image(systemName: "xmark")
                    .font(.title3)
                    .foregroundStyle(.red)
                    .frame(width: tapTarget, height: tapTarget)
                    .contentShape(Rectangle())
            }
        }
    }

    @ViewBuilder
    private var undoButton: some View {
        Button(action: onUndo) {
            Image(systemName: "arrow.uturn.backward")
                .font(.title3)
                .foregroundStyle(model.canUndo ? Color.primary : Color.secondary.opacity(0.4))
                .frame(width: tapTarget, height: tapTarget)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!model.canUndo)
    }

    // MARK: - Secondary (...-meny)

    @ViewBuilder
    private var moreMenu: some View {
        Menu {
            Button { onShowPreview() } label: {
                Label("Preview (simulerad app)", systemImage: "eye")
            }
            Button { onShowCode() } label: {
                Label("Visa filinnehåll", systemImage: "curlybraces")
            }
            Divider()
            Button { onOpen() } label: {
                Label("Öppna fil…", systemImage: "folder")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
                .foregroundStyle(Color.primary)
                .frame(width: tapTarget, height: tapTarget)
                .contentShape(Rectangle())
        }
    }

    // MARK: - Primary save

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
            HStack(spacing: 5) {
                Image(systemName: "internaldrive")
                    .font(.body.weight(.semibold))
                Text("Spara")
                    .font(.body.weight(.semibold))
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(minHeight: tapTarget)
            .background(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .contentShape(Rectangle())
        }
    }
}
