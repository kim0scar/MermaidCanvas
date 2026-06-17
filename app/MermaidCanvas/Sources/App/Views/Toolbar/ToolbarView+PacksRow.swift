// Form-paket-rad — utbruten ur ToolbarView (MA spår A steg 7–11). Beteende oförändrat.

import SwiftUI

extension ToolbarView {
    /// v29: pack-chip — tap lägger rektangel med pack:s default-kategori.
    /// Stödjer inte drag-ut (drag är för basformer); pack-chips är ett snabbsätt
    /// att lägga form med rätt kategori vid canvas-mitten.
    @ViewBuilder
    func packChip(pack: ShapePack, category: ShapeCategory) -> some View {
        Button {
            model.addShape(.rectangle, at: canvasCenter, category: category)
        } label: {
            ChipFace(systemImage: pack.systemImage)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("chip.pack.\(pack.rawValue)")
        .accessibilityLabel(a11yLabel(for: "chip.pack.\(pack.rawValue)"))
    }

    /// v31: Form-paket-rad — togglar för UI, Prompt-Process och n8n.
    /// v67: när n8n-paketet är aktivt visas flödesnoderna direkt under togglarna.
    @ViewBuilder
    var packsSecondary: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                ForEach(ShapePack.userToggleable, id: \.self) { pack in
                    packToggle(pack)
                }
                mallarMenu
            }
            if model.activeShapePacks.contains(.n8n) {
                n8nFlowChips
            }
            // v73: UI- och Prompt-Process-paketen hade ALDRIG chips (P5-fynd:
            // segmentet såg dött ut). Samma mönster som n8n.
            if model.activeShapePacks.contains(.promptProcess) {
                promptProcessChips
            }
            if model.activeShapePacks.contains(.ui) {
                uiPackChips
            }
        }
        .padding(.horizontal, 2)
    }

    /// v73: chips för Prompt-Process-paketet (kategorier ur ShapePack.categories).
    var promptProcessChips: some View {
        HStack(spacing: 6) {
            flowChip(.rectangle, .subagent, "Subagent", accId: "chip.pp.subagent")
            flowChip(.rectangle, .prompt, "Prompt", accId: "chip.pp.prompt")
            flowChip(.container, .skill, "Skill", accId: "chip.pp.skill")
            flowChip(.rectangle, .tool, "Verktyg", accId: "chip.pp.tool")
            flowChip(.rectangle, .memory, "MD-fil", accId: "chip.pp.memory")
            flowChip(.pill, .output, "Output", accId: "chip.pp.output")
        }
    }

    /// v73: chips för UI-paketet.
    var uiPackChips: some View {
        HStack(spacing: 6) {
            flowChip(.rectangle, .ui, "UI", accId: "chip.uipack.ui")
            flowChip(.rectangle, .zone, "Zon", accId: "chip.uipack.zone")
            flowChip(.rectangle, .overlay, "Overlay", accId: "chip.uipack.overlay")
        }
    }

    /// v68: Mallar-meny — fördefinierade former att bygga UI på (iPhone-modeller).
    /// Förberedd för fler modeller; en post nu (Kims val: bara 16 Pro).
    @ViewBuilder
    var mallarMenu: some View {
        Menu {
            Button {
                model.addShape(.phoneFrame, at: canvasCenter, label: "iPhone 16 Pro")
            } label: {
                Label("iPhone 16 Pro", systemImage: "iphone")
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "iphone").font(.subheadline)
                Text("Mallar").font(.subheadline.weight(.medium))
            }
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color(.systemBackground)))
            .overlay(Capsule().stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
        }
        .accessibilityIdentifier("toolbar.mallar")
        .accessibilityLabel("Mallar")
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
