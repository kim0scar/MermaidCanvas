import SwiftUI

/// Roadmap-läget renderas som listsektioner: Milestones → Features → Blockers → Future → Notes.
/// Inom varje sektion sorteras noder efter y-position (uppifrån ned).
struct RoadmapRenderer: View {
    let shapes: [ShapeNode]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                section(title: "🏁 Milestones",  symbol: "flag.fill", cat: .milestone)
                section(title: "✅ Features",    symbol: "checkmark.circle.fill", cat: .feat)
                section(title: "🚧 Blockers",   symbol: "exclamationmark.octagon.fill", cat: .blocker)
                section(title: "🔮 Future",     symbol: "sparkles", cat: .future)
                section(title: "📝 Anteckningar", symbol: "note.text", cat: .note)
            }
            .padding(20)
        }
        .background(Color.appGroupedBackground)
    }

    private func nodes(_ cat: ShapeCategory) -> [ShapeNode] {
        shapes.filter { $0.category == cat }
            .sorted { $0.position.y < $1.position.y }
    }

    @ViewBuilder
    private func section(title: String, symbol: String, cat: ShapeCategory) -> some View {
        let list = nodes(cat)
        if !list.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(.title3.bold())
                ForEach(list) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: symbol)
                            .foregroundStyle(cat.fillColor)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.label).font(.body.weight(.medium))
                            if !item.note.isEmpty {
                                Text(item.note)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(Color.appSecondaryGroupedBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }
}
