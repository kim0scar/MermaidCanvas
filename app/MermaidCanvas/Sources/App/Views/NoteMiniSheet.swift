import SwiftUI

/// Mini-sheet för att läsa/redigera bara anteckningen — utan att öppna hela EditShapeSheet.
/// Öppnas när användaren tappar på gula pricken på formen.
struct NoteMiniSheet: View {
    @Binding var note: String
    var onDone: () -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Anteckning")
                    .font(.headline)
                TextEditor(text: $note)
                    .scrollContentBackground(.hidden)
                    .background(Color.appSecondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .frame(minHeight: 150)
            }
            .padding(20)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Klar") { onDone() }
                        .font(.body.weight(.semibold))
                }
            }
        }
        .presentationDetents([.height(320), .medium])
        .presentationDragIndicator(.visible)
    }
}
