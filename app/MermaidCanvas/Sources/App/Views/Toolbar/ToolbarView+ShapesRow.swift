// Former-rad — utbruten ur ToolbarView (MA spår A steg 7–11). Beteende oförändrat.

import SwiftUI

extension ToolbarView {
    /// v36: två rader med alla 12 former.
    /// Rad A (7): circle, rectangle, square, diamond, pill, triangle, processArrow
    /// Rad B (5): text, table, link, line, notePopup
    /// HStack (INTE ScrollView) — ScrollView konsumerar tap-events på iPhone (v29-lärdom).
    @ViewBuilder
    var shapesSecondary: some View {
        VStack(spacing: 8) {
            // v66: Rad A = 7 RIKTIGA former (container flyttad till Rad B —
            // Kims fynd: "bara former uppe"). Mer luft per chip.
            HStack(spacing: 6) {
                geoChip(.circle, accId: "chip.circle", frame: 40) { model.addShape(.circle, at: canvasCenter) }
                geoChip(.pill, accId: "chip.pill", frame: 40) { model.addShape(.pill, at: canvasCenter) }
                geoChip(.rectangle, accId: "chip.rectangle", frame: 40) { model.addShape(.rectangle, at: canvasCenter) }
                geoChip(.square, accId: "chip.square", frame: 40) { model.addShape(.square, at: canvasCenter) }
                geoChip(.diamond, accId: "chip.diamond", frame: 40) { model.addShape(.diamond, at: canvasCenter) }
                geoChip(.processArrow, accId: "chip.processArrow", frame: 40) { model.addShape(.processArrow, at: canvasCenter) }
                geoChip(.octagon, accId: "chip.octagon", frame: 40) { model.addShape(.octagon, at: canvasCenter) }
                // v68: liksidig trekant (grundformerna kompletta)
                geoChip(.triangle, accId: "chip.triangle", frame: 40) { model.addShape(.triangle, at: canvasCenter) }
            }
            // Rad B — behållare + verktyg, NU med små etiketter under ikonen (Kims fynd 3).
            HStack(alignment: .top, spacing: 8) {
                VStack(spacing: 2) {
                    geoChip(.container, accId: "chip.container", frame: 40) { model.addShape(.container, at: canvasCenter) }
                    chipLabel("Container")
                }
                VStack(spacing: 2) {
                    // v68: egenritad inramad tabell-glyf (Kims fynd 4 — grid-symbolen såg inte ut som tabell)
                    shapeChipGeneric(type: .table, accId: "chip.table", onTap: onAddTable) {
                        TableGlyph(stroke: .primary, lineWidth: 1.6)
                            .frame(width: 20, height: 18)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(.ultraThinMaterial))
                            .overlay(Circle().stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
                            .contentShape(Circle())
                    }
                    chipLabel("Tabell")
                }
                VStack(spacing: 2) {
                    shapeChip(.link, "link", accId: "chip.link", onTap: onAddJumpLink)
                    chipLabel("Länk")
                }
                VStack(spacing: 2) {
                    shapeChip(.line, "minus", accId: "chip.line") {
                        model.addFreeLine(at: canvasCenter, withArrow: false)
                    }
                    chipLabel("Linje")
                }
                VStack(spacing: 2) {
                    Button {
                        onShowNotePopup()
                    } label: {
                        ChipFace(systemImage: "bubble.left.and.text.bubble.right")
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("chip.notepopup")
                    .accessibilityLabel(a11yLabel(for: "chip.notepopup"))
                    chipLabel("Notis")
                }
                // v1.0: naken emoji — placeras fritt, byts genom att skriva valfri emoji.
                VStack(spacing: 2) {
                    shapeChip(.emoji, "face.smiling", accId: "chip.emoji") {
                        model.addShape(.emoji, at: canvasCenter, label: "😀")
                    }
                    chipLabel("Emoji")
                }
            }
            // v67: flödesnoderna (f.d. Rad C) flyttade till n8n-paketet (packs-raden).
        }
        .padding(.horizontal, 2)
    }
}
