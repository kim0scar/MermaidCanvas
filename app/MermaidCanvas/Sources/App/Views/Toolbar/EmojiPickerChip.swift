import SwiftUI

/// 1.3: emoji-chip med visuellt rutnät. Egen `@State` (undviker ToolbarView R5-tak 200/200).
/// Neutral ikon (ej smiley); tryck → popover med kurerade emojis → `onPick(tecken)`.
struct EmojiPickerChip: View {
    var onPick: (String) -> Void
    @State private var show = false

    private let emojis = ["😀", "😍", "👍", "✅", "⭐️", "🔥", "⚠️", "❤️", "🚀", "💡",
                          "📌", "🎯", "📈", "❓", "🛑", "💬", "📁", "🔔", "🧠", "🔒"]

    var body: some View {
        VStack(spacing: 2) {
            Button { show = true } label: {
                ChipFace(systemImage: "face.dashed")
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("chip.emoji")
            .accessibilityLabel("Välj emoji")
            .popover(isPresented: $show) {
                grid.presentationCompactAdaptation(.popover)
            }
            Text("Emoji")
                .font(.system(size: 8.5, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .frame(width: 52)
        }
    }

    private var grid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.fixed(40)), count: 5), spacing: 10) {
            ForEach(emojis, id: \.self) { e in
                Button {
                    onPick(e)
                    show = false
                } label: {
                    Text(e).font(.system(size: 26)).frame(width: 40, height: 40)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("emoji.\(e)")
            }
        }
        .padding(16)
    }
}
