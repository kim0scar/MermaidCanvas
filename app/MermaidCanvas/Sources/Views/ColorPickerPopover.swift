import SwiftUI

/// 8 fördefinierade färger + "återställ till kategori-färg".
/// Apple-design: kompakt grid, stora tap-targets.
struct ColorPickerPopover: View {
    var selectedHex: String?
    var onPick: (String?) -> Void

    static let palette: [(name: String, hex: String)] = [
        ("Blå",   "#3b82f6"),
        ("Grön",  "#22c55e"),
        ("Röd",   "#ef4444"),
        ("Gul",   "#eab308"),
        ("Lila",  "#a855f7"),
        ("Orange","#f97316"),
        ("Svart", "#111827"),
        ("Vit",   "#f3f4f6")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Färg")
                .font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                ForEach(Self.palette, id: \.hex) { item in
                    Button {
                        onPick(item.hex)
                    } label: {
                        Circle()
                            .fill(Color(hex: hexInt(item.hex)))
                            .overlay(
                                Circle().stroke(selectedHex == item.hex ? Color.accentColor : Color.primary.opacity(0.15),
                                                lineWidth: selectedHex == item.hex ? 3 : 1)
                            )
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.plain)
                }
            }
            Divider()
            Button(role: .destructive) {
                onPick(nil)
            } label: {
                Label("Använd kategori-färg", systemImage: "arrow.uturn.backward")
            }
            .disabled(selectedHex == nil)
        }
        .padding(20)
        .frame(minWidth: 260)
    }

    private func hexInt(_ hex: String) -> UInt32 {
        let trimmed = hex.replacingOccurrences(of: "#", with: "")
        return UInt32(trimmed, radix: 16) ?? 0
    }
}
