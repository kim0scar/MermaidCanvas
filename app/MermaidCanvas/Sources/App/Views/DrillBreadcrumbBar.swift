import SwiftUI

/// v1.0+ Visio "hoppa in": brödsmule-bar överst när man är nere i ett underflöde. Visar VAR
/// man är (anti-vilse för 2e/ADHD) + en alltid-synlig "← Ut". Varje smula är tappbar och
/// hoppar direkt till den nivån — en djup felväg är ETT tryck tillbaka, aldrig N.
struct DrillBreadcrumbBar: View {
    @ObservedObject var model: CanvasModel

    var body: some View {
        let crumbs = model.drillBreadcrumb
        HStack(spacing: 8) {
            Button { model.exitSubprocess() } label: {
                Label("Ut", systemImage: "chevron.left")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.accentColor)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("drill.exit")
            Divider().frame(height: 18)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(crumbs.enumerated()), id: \.offset) { i, name in
                        if i > 0 {
                            Image(systemName: "chevron.right")
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        Button { model.drillTo(level: i) } label: {
                            Text(i == 0 ? "🏠 \(name)" : name)
                                .font(.subheadline.weight(i == crumbs.count - 1 ? .bold : .regular))
                                .foregroundStyle(i == crumbs.count - 1 ? Color.primary : Color.accentColor)
                                .lineLimit(1)
                        }
                        .buttonStyle(.plain)
                        .disabled(i == crumbs.count - 1)
                    }
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 9)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(Color.primary.opacity(0.12), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.12), radius: 5, y: 2)
        .padding(.top, 8)
        .padding(.horizontal, 12)
    }
}
