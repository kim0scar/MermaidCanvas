// Färg-rad — utbruten ur ToolbarView (MA spår A steg 7–11). Beteende oförändrat.

import SwiftUI

extension ToolbarView {
    /// v62: vad färg-valet ska gälla — paket (trio), bara fyllningen eller bara ramen.
    enum ColorTarget: String, CaseIterable {
        case pack = "Paket"
        case fill = "Fyllning"
        case stroke = "Ram"
    }

    /// v62: swatch-palett för fyllning/ram — paketens färger + svart/vit/grå.
    var swatchHexes: [String] {
        let packs = ColorPack.all.filter { $0.id != "none" }
        let fills = packs.map { $0.fillColor.hex }
        let strokes = packs.map { $0.strokeColor.hex }
        return fills + strokes + ["#111827", "#6b7280", "#ffffff"]
    }

    @ViewBuilder
    var colorsSecondary: some View {
        HStack(spacing: 8) {
            Picker("", selection: $colorTarget) {
                ForEach(ColorTarget.allCases, id: \.self) { t in
                    Text(t.rawValue).tag(t)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 210)
            .accessibilityIdentifier("colors.target")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    switch colorTarget {
                    case .pack:
                        ForEach(ColorPack.all) { pack in
                            colorChip(pack)
                        }
                    case .fill, .stroke:
                        clearSwatchChip
                        ForEach(swatchHexes, id: \.self) { hex in
                            swatchChip(hex)
                        }
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    /// v62: "ingen egen färg"-chip (nollställer fyllning/ram-override).
    @ViewBuilder
    var clearSwatchChip: some View {
        Button {
            applySwatch(nil)
        } label: {
            ZStack {
                Circle().fill(Color.white)
                    .overlay(Circle().stroke(Color.secondary, lineWidth: 1.5))
                Image(systemName: "slash.circle")
                    .font(.caption)
                    .foregroundStyle(Color.secondary)
            }
            .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Ta bort egen \(colorTarget == .fill ? "fyllning" : "ram")")
    }

    /// v62: en swatch — fylld cirkel för fyllning, ring för ram.
    @ViewBuilder
    func swatchChip(_ hex: String) -> some View {
        let color = Color(hexString: hex) ?? .gray
        let isCurrent: Bool = {
            guard let id = model.selectedShapeId,
                  let s = model.shapes.first(where: { $0.id == id }) else { return false }
            let current = colorTarget == .fill ? s.colorOverride : s.strokeColorOverride
            return current?.lowercased() == hex.lowercased()
        }()
        Button {
            applySwatch(hex)
        } label: {
            ZStack {
                if colorTarget == .fill {
                    Circle().fill(color)
                        .overlay(Circle().stroke(Color.primary.opacity(0.25), lineWidth: 1))
                } else {
                    Circle().fill(Color.white)
                        .overlay(Circle().stroke(color, lineWidth: 4))
                }
                if isCurrent {
                    Circle().stroke(Color.accentColor, lineWidth: 2.5)
                }
            }
            .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
    }

    func applySwatch(_ hex: String?) {
        guard let id = model.selectedShapeId else { return }
        if colorTarget == .fill {
            model.setFillColor(id: id, hex: hex)
        } else {
            model.setStrokeColor(id: id, hex: hex)
        }
    }

    @ViewBuilder
    func colorChip(_ pack: ColorPack) -> some View {
        let isCurrent: Bool = {
            guard let id = model.selectedShapeId,
                  let s = model.shapes.first(where: { $0.id == id }) else { return false }
            return (pack.id == "none" && s.colorPackId == nil) || pack.id == s.colorPackId
        }()
        Button {
            applyColorPack(pack)
        } label: {
            ZStack {
                Circle()
                    .fill(pack.fillColor)
                    .overlay(Circle().stroke(pack.strokeColor, lineWidth: 1.5))
                if isCurrent {
                    Circle().stroke(Color.accentColor, lineWidth: 2.5)
                }
                if pack.id == "none" {
                    Image(systemName: "slash.circle")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
            }
            .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
    }

    func applyColorPack(_ pack: ColorPack) {
        guard let id = model.selectedShapeId,
              let idx = model.shapes.firstIndex(where: { $0.id == id }) else { return }
        model.shapes[idx].colorPackId = pack.id == "none" ? nil : pack.id
    }
}
