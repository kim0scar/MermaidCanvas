import SwiftUI

/// 1.5 (Kim): visuellt storleks-galleri — varje nivå ritas i SIN verkliga storlek så man
/// ser exakt hur stor den blir innan man väljer. Visar bas-storleken (utan sizeMultiplier)
/// — det man väljer; formens egen resize skalar sen ovanpå.
struct TextSizeGallery: View {
    let current: TextStyle
    var onPick: (TextStyle) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(TextStyle.allCases.enumerated()), id: \.element.id) { idx, st in
                    Button { onPick(st) } label: {
                        HStack(spacing: 8) {
                            Text(st.displayName)
                                .font(.system(size: st.fontSize, weight: st.fontWeight, design: .rounded))
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                            Spacer(minLength: 6)
                            if st == current {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if idx < TextStyle.allCases.count - 1 { Divider() }
                }
            }
            .padding(.vertical, 6)
        }
        .frame(width: 280)
        .frame(maxHeight: 380)
    }
}
