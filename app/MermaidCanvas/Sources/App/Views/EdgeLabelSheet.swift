import SwiftUI

/// v44: Sheet för att redigera kant-etikett (text på pilen).
/// Öppnas via context-menu på pilens midpoint-handle.
struct EdgeLabelSheet: View {
    let initial: String
    let onSave: (String) -> Void
    let onCancel: () -> Void
    @State private var text: String

    init(initial: String, onSave: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.initial = initial
        self.onSave = onSave
        self.onCancel = onCancel
        _text = State(initialValue: initial)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Text på pilen") {
                    TextField("Beskrivning", text: $text)
                }
            }
            .navigationTitle("Pil-text")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Klar") { onSave(text) }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
