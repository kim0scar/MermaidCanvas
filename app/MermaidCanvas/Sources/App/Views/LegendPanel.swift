import SwiftUI

/// v66: Legend-panel på canvasen (Kims önskemål) — listar kategorierna som
/// ANVÄNDS på canvasen och låter Kim skriva vad varje form/färg betyder.
/// Texten round-trippar i mermaid som `%% legend <kategori>: <text>` så
/// Claude Code läser förklaringen direkt i koden.
struct LegendPanel: View {
    @ObservedObject var model: CanvasModel
    var onClose: () -> Void

    /// Kategorier på canvasen + de som redan har legend-text (sorterade stabilt).
    private var categories: [ShapeCategory] {
        var keys = Set(model.shapes.map { $0.category })
        for raw in model.legend.keys {
            if let c = ShapeCategory(rawValue: raw) { keys.insert(c) }
        }
        return ShapeCategory.allCases.filter { keys.contains($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Label("Legend", systemImage: "list.bullet.rectangle")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("legend.close")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color.appSecondaryBackground)

            if categories.isEmpty {
                Text("Lägg till former så dyker deras kategorier upp här.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(12)
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(categories, id: \.self) { cat in
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(cat.strokeColor, lineWidth: 2)
                                    .frame(width: 22, height: 15)
                                Text(cat.rawValue)
                                    .font(.caption2.weight(.medium))
                                    .foregroundStyle(cat.strokeColor)
                                    .frame(width: 52, alignment: .leading)
                                TextField("betyder…", text: binding(for: cat))
                                    .font(.footnote)
                                    .textFieldStyle(.roundedBorder)
                            }
                        }
                    }
                    .padding(10)
                }
                .frame(maxHeight: 240)
            }
        }
        .frame(width: 300)
        .background(Color.appBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(Color.appSeparator, lineWidth: 0.8))
        .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
        .accessibilityIdentifier("legend.panel")
    }

    private func binding(for cat: ShapeCategory) -> Binding<String> {
        Binding(
            get: { model.legend[cat.rawValue] ?? "" },
            set: { newValue in
                let trimmed = newValue
                if trimmed.isEmpty {
                    model.legend.removeValue(forKey: cat.rawValue)
                } else {
                    model.legend[cat.rawValue] = trimmed
                }
            }
        )
    }
}
