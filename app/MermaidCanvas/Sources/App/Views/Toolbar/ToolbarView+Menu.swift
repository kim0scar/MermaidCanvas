import SwiftUI

/// Lägen-menyn för ToolbarView (utbruten ur ToolbarView.swift för R5-ratchet, steg H).
extension ToolbarView {
    var modesMenu: some View {
        LägenMenu(
            model: model,
            hasOpenFile: hasOpenFile,
            onSave: onSave,
            onSaveAs: onSaveAs,
            onOpen: onOpen,
            onNewCanvas: onNewCanvas,
            onShowCode: onShowCode,
            onCopyCode: onCopyCode,
            onExportImage: onExportImage,
            onShowCapabilities: onShowCapabilities,
            onShowRules: onShowRules,
            onImportMermaid: onImportMermaid,
            onImportMultiple: onImportMultiple,
            onToggleLegend: onToggleLegend,
            onResetZoom: onResetZoom,
            onShowNotePopup: onShowNotePopup
        )
    }
}
