// Textstil-rad — utbruten ur ToolbarView (MA spår A steg 7–11). Beteende oförändrat.

import SwiftUI

extension ToolbarView {
    /// 1.3 S1.3: verktygsfältets textstil-rad = den delade FormattingBar:en
    /// (samma komponent som ovanför tangentbordet vid inline-redigering → kan aldrig
    /// glida isär). Muterar markerad form med undo-snapshot via beginShapeEdit().
    @ViewBuilder
    var textStylesSecondary: some View {
        let s = selectedShape
        FormattingBar(
            style: s?.textStyle ?? .body,
            alignment: s?.textAlignment ?? .center,
            hasBullets: s?.hasBullets ?? false,
            hasNumbered: s?.hasNumberedList ?? false,
            onStyle: { st in guard let idx = beginShapeEdit() else { return }
                model.shapes[idx].textStyle = st },
            onToggleBullets: { guard let idx = beginShapeEdit() else { return }
                let on = !model.shapes[idx].hasBullets
                model.shapes[idx].hasBullets = on
                if on { model.shapes[idx].hasNumberedList = false } },
            onToggleNumbered: { guard let idx = beginShapeEdit() else { return }
                let on = !model.shapes[idx].hasNumberedList
                model.shapes[idx].hasNumberedList = on
                if on { model.shapes[idx].hasBullets = false } },
            onAlign: { a in guard let idx = beginShapeEdit() else { return }
                model.shapes[idx].textAlignment = a },
            onIndent: { d in guard let idx = beginShapeEdit() else { return }
                model.shapes[idx].indentLevel = min(3, max(0, model.shapes[idx].indentLevel + d)) },
            bold: s?.bold ?? false, italic: s?.italic ?? false, underline: s?.underline ?? false,
            onToggleBold: { guard let idx = beginShapeEdit() else { return }; model.shapes[idx].bold.toggle() },
            onToggleItalic: { guard let idx = beginShapeEdit() else { return }; model.shapes[idx].italic.toggle() },
            onToggleUnderline: { guard let idx = beginShapeEdit() else { return }; model.shapes[idx].underline.toggle() },
            showColor: true,
            colorPackId: s?.colorPackId,
            onPickColorPack: { id in guard let idx = beginShapeEdit() else { return }; model.shapes[idx].colorPackId = id }
        )
    }

    var selectedShape: ShapeNode? {
        guard let id = model.selectedShapeId else { return nil }
        return model.shapes.first(where: { $0.id == id })
    }

    /// Markerad form: ta undo-snapshot och returnera index (nil om inget markerat).
    /// Gör text-radens ändringar ångringsbara — paritet med färg-raden (setFillColor m.fl.).
    func beginShapeEdit() -> Int? {
        guard let id = model.selectedShapeId,
              let idx = model.shapes.firstIndex(where: { $0.id == id }) else { return nil }
        model.snapshotForUndo()
        return idx
    }
}
