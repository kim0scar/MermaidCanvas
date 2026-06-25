// Multi-select-rad — utbruten ur ToolbarView (MA spår A steg 7–11). Beteende oförändrat.

import SwiftUI

extension ToolbarView {
    /// Operationsrad som visas automatiskt när markerMode är aktivt.
    @ViewBuilder
    var multiSelectSecondary: some View {
        let count = model.multiSelection.count
        HStack(spacing: 10) {
            // Räknare — hur många former är markerade
            Text("\(count) markerade")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(minWidth: 70)

            Divider().frame(height: 28)

            // Duplicera
            multiSelectButton("plus.square.on.square", label: "Duplicera",
                               accId: "multiselect.duplicate",
                               disabled: count == 0) { onDuplicateSelection() }

            // Ta bort
            multiSelectButton("trash", label: "Ta bort",
                               accId: "multiselect.delete",
                               disabled: count == 0, destructive: true) { onDeleteSelection() }

            Divider().frame(height: 28)

            // Align horisontellt (dela vertikalt centrallinje)
            multiSelectButton("align.horizontal.center", label: "Centrera H",
                               accId: "multiselect.alignH",
                               disabled: count < 2) { onAlignHorizontal() }

            // Align vertikalt (dela horisontellt centrallinje)
            multiSelectButton("align.vertical.center", label: "Centrera V",
                               accId: "multiselect.alignV",
                               disabled: count < 2) { onAlignVertical() }

            Divider().frame(height: 28)

            // 1.2: synlig väg UT ur markeringsläget (gesten för IN är dold dubbeltryck).
            multiSelectButton("checkmark.circle.fill", label: "Klar",
                               accId: "multiselect.done",
                               disabled: false) { onToggleMarker() }
        }
    }

    @ViewBuilder
    func multiSelectButton(_ icon: String,
                           label: String,
                           accId: String,
                           disabled: Bool,
                           destructive: Bool = false,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(label)
                    .font(.system(size: 9, weight: .medium))
            }
            .foregroundStyle(disabled ? .secondary.opacity(0.4) : (destructive ? .red : Color.primary))
            .frame(minWidth: 44, minHeight: 44)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .accessibilityIdentifier(accId)
        .accessibilityLabel(label)
    }
}
