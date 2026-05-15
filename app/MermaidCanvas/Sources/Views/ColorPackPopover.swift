import SwiftUI

/// Sheet med 7 färg-paket (6 pastell + "ingen färg") för vald form.
/// Visar mini-preview för varje paket.
struct ColorPackSheet: View {
    @Binding var selectedPackId: String?
    var onPick: (String?) -> Void

    private let columns = [GridItem(.adaptive(minimum: 100, maximum: 130), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(ColorPack.all) { pack in
                        Button {
                            let value: String? = pack.id == "none" ? nil : pack.id
                            selectedPackId = value
                            onPick(value)
                        } label: {
                            packTile(pack)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .navigationTitle("Färg")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Stäng") { onPick(selectedPackId) }
                }
            }
        }
        .presentationDetents([.medium])
    }

    @ViewBuilder
    private func packTile(_ pack: ColorPack) -> some View {
        let isActive = (pack.id == "none" && selectedPackId == nil) ||
                       (pack.id == selectedPackId)
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(pack.fillColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(pack.strokeColor, lineWidth: 1.5)
                    )
                Text("Abc")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(pack.textColor)
            }
            .frame(height: 60)
            Text(pack.displayName)
                .font(.caption)
                .foregroundStyle(.primary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isActive ? Color.accentColor : Color.clear, lineWidth: 2.5)
        )
    }
}
