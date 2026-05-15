import SwiftUI

/// Sheet som visas när användaren skapar en ny canvas — kräver plattformsval först.
/// Plattformen LÅSES när canvas skapas och kan inte bytas mitt i.
struct NewCanvasSheet: View {
    var onCreate: (SpecType) -> Void
    var onCancel: () -> Void

    @State private var selected: SpecType = .ui

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Plattform")
                        .font(.headline)
                    Text("Plattformen styr vilka regler och kategorier som gäller. Den låses till canvasen och kan inte bytas mitt i — börja om med ny canvas om du vill byta.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 10) {
                        ForEach(SpecType.pickable) { st in
                            platformCard(st)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .navigationTitle("Ny canvas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Skapa") { onCreate(selected) }
                        .bold()
                }
            }
        }
    }

    @ViewBuilder
    private func platformCard(_ st: SpecType) -> some View {
        Button {
            selected = st
        } label: {
            HStack(spacing: 14) {
                Image(systemName: st.badgeSystemImage)
                    .font(.title2)
                    .foregroundStyle(selected == st ? Color.white : Color.accentColor)
                    .frame(width: 44, height: 44)
                    .background(selected == st ? Color.accentColor : Color.accentColor.opacity(0.12))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(st.displayName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.primary)
                    Text(platformHint(st))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                if selected == st {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected == st ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func platformHint(_ st: SpecType) -> String {
        switch st {
        case .ui:           return "UI för iPhone-app. Skärmar, knappar, zoner. iPhone-ram visas på canvas."
        case .roadmap:      return "Plan för funktioner över tid. Now/Next/Later, milstolpar, blockers."
        case .architecture: return "Kodstruktur. Mappar, filer, moduler, services."
        case .flow:         return "Process eller AI-flöde. Input → agent → tool → memory → output."
        case .godot:        return "Godot-spel-scener (.tscn). Control-noder, signaler, GDScript."
        case .general:      return "Generell canvas utan specifika regler."
        }
    }
}
