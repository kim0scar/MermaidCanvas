import SwiftUI

/// v63: Snabbläsning — visar formens anteckning och prompt som REN TEXT,
/// ingen redigering. Öppnas från badges på formen (gul = anteckning,
/// indigo hjärna = prompt). Höjden anpassar sig efter textmängden via detents.
struct QuickReadSheet: View {
    let title: String
    let note: String
    let prompt: String
    var onEdit: () -> Void
    var onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if !prompt.isEmpty {
                        section(icon: "brain", iconColor: Color(hex: 0x4338ca),
                                heading: "Prompt", text: prompt)
                    }
                    if !note.isEmpty {
                        section(icon: "note.text", iconColor: Color(hex: 0xB28A00),
                                heading: "Anteckning", text: note)
                    }
                    if note.isEmpty && prompt.isEmpty {
                        Text("Ingen anteckning eller prompt på den här formen.")
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            }
            .navigationTitle(title.isEmpty ? "Form" : title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Stäng", action: onClose)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Redigera", action: onEdit)
                }
            }
        }
        // Liten text → liten ruta; mycket text → dra upp (medium/large)
        .presentationDetents([.height(280), .medium, .large])
        .presentationDragIndicator(.visible)
    }

    @ViewBuilder
    private func section(icon: String, iconColor: Color,
                         heading: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(heading, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(iconColor)
            Text(text)
                .font(.body)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}
