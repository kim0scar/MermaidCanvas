import SwiftUI

/// Ångra/Gör om-knapparna för ToolbarView (utbrutna ur ToolbarView.swift för
/// R5-ratchet, V79-svep). Beteende verbatim.
extension ToolbarView {
    @ViewBuilder
    var undoButton: some View {
        Button(action: onUndo) {
            ToolbarIconButton(systemImage: "arrow.uturn.backward",
                              isActive: false,
                              foregroundColor: model.canUndo ? .primary : .secondary.opacity(0.4))
        }
        .buttonStyle(.plain)
        .disabled(!model.canUndo)
        .accessibilityIdentifier("toolbar.undo")
        .accessibilityLabel(a11yLabel(for: "toolbar.undo"))
    }

    /// V79-svep: gör om (redo) — ångra åt båda håll.
    @ViewBuilder
    var redoButton: some View {
        Button(action: onRedo) {
            ToolbarIconButton(systemImage: "arrow.uturn.forward",
                              isActive: false,
                              foregroundColor: model.canRedo ? .primary : .secondary.opacity(0.4))
        }
        .buttonStyle(.plain)
        .disabled(!model.canRedo)
        .accessibilityIdentifier("toolbar.redo")
        .accessibilityLabel(a11yLabel(for: "toolbar.redo"))
    }
}
