import SwiftUI

/// 1.5 (Kim): visuellt storleks-galleri + fet/kursiv/understruken. Varje storleks-nivå
/// ritas i SIN verkliga storlek så man ser exakt hur stor den blir. B/I/U är separata
/// toggles överst (stänger inte galleriet).
struct TextSizeGallery: View {
    let current: TextStyle
    let bold: Bool
    let italic: Bool
    let underline: Bool
    var onPick: (TextStyle) -> Void
    var onToggleBold: () -> Void
    var onToggleItalic: () -> Void
    var onToggleUnderline: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                emphasisToggle("bold", "Fet", bold, onToggleBold)
                emphasisToggle("italic", "Kursiv", italic, onToggleItalic)
                emphasisToggle("underline", "Understruken", underline, onToggleUnderline)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16).padding(.top, 10).padding(.bottom, 8)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(TextStyle.allCases.enumerated()), id: \.element.id) { idx, st in
                        Button { onPick(st) } label: {
                            HStack(spacing: 8) {
                                Text(st.displayName)
                                    .font(.system(size: st.fontSize, weight: st.fontWeight, design: .rounded))
                                    .lineLimit(1).minimumScaleFactor(0.6)
                                Spacer(minLength: 6)
                                if st == current {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if idx < TextStyle.allCases.count - 1 { Divider() }
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .frame(width: 280)
        .frame(maxHeight: 420)
    }

    @ViewBuilder
    private func emphasisToggle(_ icon: String, _ label: String,
                                _ active: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(active ? Color.white : Color.primary)
                .frame(width: 46, height: 38)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(active ? Color.accentColor : Color.appChipBackground)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
