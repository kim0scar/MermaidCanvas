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
            onShowRules: onShowRules,
            onToggleMarker: onToggleMarker,
            onImportMermaid: onImportMermaid,
            onToggleLegend: onToggleLegend
        )
    }
}
