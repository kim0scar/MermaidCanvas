// Skill-flöde-chips — utbruten ur ToolbarView+Chips.swift (1.5.4 R5: höll Chips.swift under tak).
// Beteende oförändrat.

import SwiftUI

extension ToolbarView {
    /// Steg 8: SEMANTISK NOD-PALETT för att SKISSA en skill — ett tryck ger rätt form +
    /// kategori + färg. Visas i Skillflöde-paketet (packs-raden). Claude Code-byggstenarna:
    /// Skill=container, Subagent, Tool, MCP, Plugin, Input/Output, Fil (MD/Excel).
    /// (Ersatte n8nFlowChips + promptProcessChips; prompt är nu ett fält PÅ formerna, inte en egen nod.)
    @ViewBuilder
    var skillFlowChips: some View {
        // 1.5.4 (Bug 2): varje rad horisontellt scrollbar så chipsen aldrig klipps på smal skärm.
        VStack(spacing: 8) {
            // Rad 1 — byggstenar
            ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                flowChip(.pill, .input, "Input", accId: "chip.skill.input")
                flowChip(.container, .skill, "Skill", accId: "chip.skill.skill")
                flowChip(.rectangle, .subagent, "Subagent", accId: "chip.skill.subagent")
                flowChip(.rectangle, .tool, "Tool", accId: "chip.skill.tool")
            }
            .padding(.vertical, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            // Rad 2 — resurser + utfall (fil-kategorierna får dokument-ikon)
            ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                flowChip(.rectangle, .mcp, "MCP", accId: "chip.skill.mcp")
                flowChip(.rectangle, .plugin, "Plugin", accId: "chip.skill.plugin")
                docChip(.fileMarkdown, "doc.text", "MD-fil", accId: "chip.skill.md")
                docChip(.fileExcel, "tablecells", "Excel", accId: "chip.skill.excel")
                flowChip(.pill, .output, "Output", accId: "chip.skill.output")
            }
            .padding(.vertical, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Steg 8: fil-chip — SF Symbol-ikon (dokument/kalkyl) i kategorins färg + etikett.
    /// Lägger en rektangel med fil-kategorin (kategorifärgen skiljer MD/Excel; canvas-glyf = 2d).
    @ViewBuilder
    func docChip(_ category: ShapeCategory, _ systemImage: String, _ label: String, accId: String) -> some View {
        Button {
            model.addShape(.rectangle, at: canvasCenter, category: category)
        } label: {
            VStack(spacing: 2) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(category.strokeColor)
                    .frame(width: 36, height: 24)
                    .background(Circle().fill(.ultraThinMaterial).frame(width: 34, height: 34))
                Text(label)
                    .font(.system(size: 8.5, weight: .medium))
                    .foregroundStyle(category.strokeColor)
                    .lineLimit(1)
            }
            .frame(width: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accId)
        .accessibilityLabel("Lägg till \(label)-nod")
    }
}
