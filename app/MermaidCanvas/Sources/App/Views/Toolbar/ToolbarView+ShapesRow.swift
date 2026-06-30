// Former-rad — utbruten ur ToolbarView (MA spår A steg 7–11).
// 1.2: ETT "lägg till"-ställe med flikar (Grundformer/Paket/Mallar) + alltid synlig verktygsrad.

import SwiftUI

extension ToolbarView {
    /// 1.2: vilken flik i Former-raden som visas. Speglar ColorsRow:s segment-mönster.
    enum ShapeSection: String, CaseIterable {
        case basic = "Grundformer"
        case packs = "Paket"
        case templates = "Mallar"
    }

    @ViewBuilder
    var shapesSecondary: some View {
        VStack(spacing: 8) {
            Picker("", selection: $shapeSection) {
                ForEach(ShapeSection.allCases, id: \.self) { s in
                    Text(s.rawValue).tag(s)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("shapes.section")

            switch shapeSection {
            case .basic:     basicShapesRow
            case .packs:     packsSecondary
            case .templates: templatesRow
            }

            Divider()
            shapeToolsRow
        }
        .padding(.horizontal, 2)
    }

    /// Grundformer — 8 rena geo-chips.
    var basicShapesRow: some View {
        // 1.5.4 (Bug 2): horisontell scroll så grundformerna aldrig klipps på smal skärm.
        ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 6) {
            geoChip(.circle, accId: "chip.circle", frame: 40) { model.addShape(.circle, at: canvasCenter) }
            geoChip(.pill, accId: "chip.pill", frame: 40) { model.addShape(.pill, at: canvasCenter) }
            geoChip(.rectangle, accId: "chip.rectangle", frame: 40) { model.addShape(.rectangle, at: canvasCenter) }
            geoChip(.square, accId: "chip.square", frame: 40) { model.addShape(.square, at: canvasCenter) }
            geoChip(.diamond, accId: "chip.diamond", frame: 40) { model.addShape(.diamond, at: canvasCenter) }
            geoChip(.processArrow, accId: "chip.processArrow", frame: 40) { model.addShape(.processArrow, at: canvasCenter) }
            geoChip(.octagon, accId: "chip.octagon", frame: 40) { model.addShape(.octagon, at: canvasCenter) }
            geoChip(.triangle, accId: "chip.triangle", frame: 40) { model.addShape(.triangle, at: canvasCenter) }
        }
        .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Mallar — 3 snabb-mallar (flyttade hit från Lägen-menyn i steg 5).
    var templatesRow: some View {
        // 1.5.4 (Bug 2): horisontell scroll.
        ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 10) {
            ForEach(CanvasModel.TemplateKind.allCases, id: \.self) { kind in
                Button { onInsertTemplate(kind) } label: {
                    VStack(spacing: 2) {
                        ChipFace(systemImage: kind.systemImage)
                        chipLabel(kind.title)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("chip.template.\(kind)")
                .accessibilityLabel("Mall: \(kind.title)")
            }
        }
        .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Verktyg — alltid synliga: Container, Tabell, Länk, Linje, Emoji. (Notis → menyn, steg 5.)
    var shapeToolsRow: some View {
        // 1.5.4 (Bug 2): horisontell scroll så verktygen aldrig klipps på smal skärm.
        ScrollView(.horizontal, showsIndicators: false) {
        HStack(alignment: .top, spacing: 8) {
            VStack(spacing: 2) {
                geoChip(.container, accId: "chip.container", frame: 40) { model.addShape(.container, at: canvasCenter) }
                chipLabel("Container")
            }
            VStack(spacing: 2) {
                // egenritad inramad tabell-glyf (Kims fynd 4 — grid-symbolen såg inte ut som tabell)
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
            // 1.3: emoji-väljare (rutnät) — neutral ikon, popover med kurerade emojis.
            EmojiPickerChip { emoji in model.addShape(.emoji, at: canvasCenter, label: emoji) }
        }
        .padding(.vertical, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
