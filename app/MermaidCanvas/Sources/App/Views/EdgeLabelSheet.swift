import SwiftUI

/// v44: Sheet för att redigera kant-etikett (text på pilen).
/// Öppnas via context-menu på pilens midpoint-handle.
/// v62: även placering — ovanför eller under pilen.
struct EdgeLabelSheet: View {
    let initial: String
    let initialPlacement: EdgeLabelPlacement
    let onSave: (String, EdgeLabelPlacement) -> Void
    let onCancel: () -> Void
    @State private var text: String
    @State private var placement: EdgeLabelPlacement

    init(initial: String,
         initialPlacement: EdgeLabelPlacement = .below,
         onSave: @escaping (String, EdgeLabelPlacement) -> Void,
         onCancel: @escaping () -> Void) {
        self.initial = initial
        self.initialPlacement = initialPlacement
        self.onSave = onSave
        self.onCancel = onCancel
        _text = State(initialValue: initial)
        _placement = State(initialValue: initialPlacement)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Text på pilen") {
                    TextField("Beskrivning", text: $text)
                }
                Section("Placering") {
                    Picker("Placering", selection: $placement) {
                        Label("Ovanför", systemImage: "arrow.up.to.line")
                            .tag(EdgeLabelPlacement.above)
                        Label("Under", systemImage: "arrow.down.to.line")
                            .tag(EdgeLabelPlacement.below)
                    }
                    .pickerStyle(.segmented)
                }
            }
            .navigationTitle("Pil-text")
            .inlineNavTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Klar") { onSave(text, placement) }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
