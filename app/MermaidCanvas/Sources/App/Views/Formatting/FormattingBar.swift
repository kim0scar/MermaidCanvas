import SwiftUI

/// 1.3 S1.3: EN formateringsmeny — delad komponent. Renderas i TVÅ lägen med exakt
/// samma knappar (kan aldrig glida isär): (1) verktygsfältets textstil-rad när en form
/// är markerad, (2) ovanför tangentbordet när text redigeras direkt i formen (Apple
/// Notes-mönstret). Ren presentation — värden in, åtgärder ut via closures; varje host
/// sköter sin egen undo-snapshot.
struct FormattingBar: View {
    let style: TextStyle
    let alignment: TextAlignMode
    let hasBullets: Bool
    let hasNumbered: Bool
    var onStyle: (TextStyle) -> Void
    var onBold: () -> Void
    var onToggleBullets: () -> Void
    var onToggleNumbered: () -> Void
    var onAlign: (TextAlignMode) -> Void
    /// delta: +1 ökar indrag, -1 minskar (host klampar 0…3).
    var onIndent: (Int) -> Void

    @State private var showSizePicker = false

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                // Storlek/rubrik — popup med R1/R2/R3/Aa.
                Button { showSizePicker = true } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "textformat.size")
                            .font(.system(size: 15, weight: .medium))
                        Text(stylePreview(style))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .accessibilityIdentifier("toolbar.textSize")
                .accessibilityLabel("Textstorlek")
                .confirmationDialog("Textstorlek", isPresented: $showSizePicker, titleVisibility: .visible) {
                    ForEach(TextStyle.allCases) { st in
                        Button(st.displayName) { onStyle(st) }
                    }
                    Button("Avbryt", role: .cancel) {}
                }

                button(icon: "bold", label: "Fet", active: style == .r1, action: onBold)

                Divider().frame(height: 28).padding(.horizontal, 2)

                button(icon: "list.bullet", label: "Punkter",
                       active: hasBullets && !hasNumbered, action: onToggleBullets)
                button(icon: "list.number", label: "Numrerad",
                       active: hasNumbered, action: onToggleNumbered)

                Divider().frame(height: 28).padding(.horizontal, 2)

                button(icon: "text.alignleft", label: "Vänster",
                       active: alignment == .leading) { onAlign(.leading) }
                button(icon: "text.aligncenter", label: "Centrera",
                       active: alignment == .center) { onAlign(.center) }
                button(icon: "text.alignright", label: "Höger",
                       active: alignment == .trailing) { onAlign(.trailing) }

                Divider().frame(height: 28).padding(.horizontal, 2)

                button(icon: "decrease.indent", label: "Indrag–", active: false) { onIndent(-1) }
                button(icon: "increase.indent", label: "Indrag+", active: false) { onIndent(1) }
            }
            .padding(.horizontal, 2)
        }
    }

    @ViewBuilder
    private func button(icon: String, label: String, active: Bool,
                        action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(active ? Color.white : Color.primary)
                .frame(width: 38, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(active ? Color.accentColor : Color.appBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func stylePreview(_ st: TextStyle) -> String {
        switch st {
        case .r1:   return "R1"
        case .r2:   return "R2"
        case .r3:   return "R3"
        case .body: return "Aa"
        }
    }
}
