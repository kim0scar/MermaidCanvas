// Form-paket-rad — utbruten ur ToolbarView (MA spår A steg 7–11). Beteende oförändrat.

import SwiftUI

extension ToolbarView {
    /// v31: Form-paket-rad — togglar för UI, Prompt-Process och n8n.
    /// v67: när n8n-paketet är aktivt visas flödesnoderna direkt under togglarna.
    @ViewBuilder
    var packsSecondary: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ForEach(ShapePack.userToggleable, id: \.self) { pack in
                    packToggle(pack)
                }
            }
            // Steg 8: Skillflöde-paketet visar byggsten-chipsen direkt under togglarna.
            if model.activeShapePacks.contains(.skillFlow) {
                skillFlowChips
            }
            if model.activeShapePacks.contains(.ui) {
                uiPackChips
            }
        }
        .padding(.horizontal, 2)
    }

    /// v73: chips för UI-paketet. Steg 9: iPhone-mallarna bor här (ersätter Mallar-menyn).
    var uiPackChips: some View {
        HStack(spacing: 6) {
            flowChip(.rectangle, .ui, "UI", accId: "chip.uipack.ui")
            flowChip(.rectangle, .zone, "Zon", accId: "chip.uipack.zone")
            flowChip(.rectangle, .overlay, "Overlay", accId: "chip.uipack.overlay")
            deviceChip("iPhone 15 Pro", "15 Pro", accId: "chip.uipack.iphone15")
            deviceChip("iPhone 16 Pro", "16 Pro", accId: "chip.uipack.iphone16")
        }
    }

    /// Steg 9: device-chip — lägger en phoneFrame med modellnamnet som etikett
    /// (namnet visas UTANPÅ ramen, se ShapeView). Ersätter v68:s Mallar-meny.
    @ViewBuilder
    func deviceChip(_ name: String, _ short: String, accId: String) -> some View {
        Button {
            model.addShape(.phoneFrame, at: canvasCenter, label: name)
        } label: {
            VStack(spacing: 2) {
                Image(systemName: "iphone")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.primary)
                    .frame(width: 36, height: 24)
                    .background(Circle().fill(.ultraThinMaterial).frame(width: 34, height: 34))
                Text(short)
                    .font(.system(size: 8.5, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(width: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accId)
        .accessibilityLabel("Lägg till \(name)")
    }

    @ViewBuilder
    func packToggle(_ pack: ShapePack) -> some View {
        let isActive = model.activeShapePacks.contains(pack)
        Button {
            model.toggleShapePack(pack)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: pack.systemImage).font(.subheadline)
                // v73: aldrig radbrytning (P5: "Prompt-Process" blev 2 rader → ojämn rad)
                Text(pack.displayName).font(.subheadline.weight(.medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if isActive {
                    Image(systemName: "checkmark").font(.caption.weight(.bold))
                }
            }
            .foregroundStyle(isActive ? Color.white : Color.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(isActive ? Color.accentColor : Color(.systemBackground))
            )
            .overlay(Capsule().stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("toggle.pack.\(pack.rawValue)")
    }
}
