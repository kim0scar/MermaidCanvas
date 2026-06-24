import SwiftUI

/// v27: Sheet vid Ny canvas — bara TVÅ val: Blank canvas (default) eller Godot.
/// Form-paketer aktiveras efter via Lägen-menyn.
struct NewCanvasSheet: View {
    var onCreate: (Platform) -> Void
    var onCancel: () -> Void

    @State private var selected: Platform = .blank

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Plattform")
                        .font(.headline)
                    Text("Plattform = regelstyrt mål (t.ex. Godot). För eget ritande, välj Blank canvas. Form-paketer (UI/Roadmap/Arkitektur/Flow) aktiveras sen i Lägen-menyn — oberoende av plattform.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    VStack(spacing: 10) {
                        ForEach(Platform.allCases) { p in
                            platformCard(p)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(20)
            }
            .navigationTitle("Ny canvas")
            .inlineNavTitle()
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
    private func platformCard(_ p: Platform) -> some View {
        Button {
            selected = p
        } label: {
            HStack(spacing: 14) {
                Image(systemName: p.badgeSystemImage)
                    .font(.title2)
                    .foregroundStyle(selected == p ? Color.white : Color.accentColor)
                    .frame(width: 44, height: 44)
                    .background(selected == p ? Color.accentColor : Color.accentColor.opacity(0.12))
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(p.displayName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.primary)
                    Text(p.hint)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                if selected == p {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(12)
            .background(Color.appSecondaryBackground)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(selected == p ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
