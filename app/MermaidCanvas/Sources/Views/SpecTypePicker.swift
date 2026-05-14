import SwiftUI

/// Topp-toggle som visar vilket tankeläge canvasen är i.
/// Apple-design: segmented control, ikon + label, ingen extra meny.
struct SpecTypePicker: View {
    @Binding var specType: SpecType
    var onChange: (SpecType) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(SpecType.pickable) { type in
                Button {
                    if specType != type {
                        onChange(type)
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: type.badgeSystemImage)
                            .font(.caption.weight(.semibold))
                        Text(type.displayName)
                            .font(.caption.weight(.semibold))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(specType == type ? Color.white : Color.primary)
                    .background(specType == type ? Color.accentColor : Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
    }
}
