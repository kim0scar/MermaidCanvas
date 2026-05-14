import SwiftUI

struct ShapeEdit {
    var label: String
    var showLabel: Bool
    var sizeMultiplier: CGFloat
    var note: String
}

struct EditShapeSheet: View {
    let shapeId: UUID
    let initial: ShapeEdit
    var onSave: (ShapeEdit) -> Void
    var onCancel: () -> Void

    @State private var draft: ShapeEdit
    @FocusState private var labelFocused: Bool

    init(shapeId: UUID,
         initial: ShapeEdit,
         onSave: @escaping (ShapeEdit) -> Void,
         onCancel: @escaping () -> Void) {
        self.shapeId = shapeId
        self.initial = initial
        self.onSave = onSave
        self.onCancel = onCancel
        _draft = State(initialValue: initial)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Text i form") {
                    Toggle("Visa text", isOn: $draft.showLabel)
                    if draft.showLabel {
                        TextField("Skriv text", text: $draft.label, axis: .vertical)
                            .lineLimit(1...4)
                            .focused($labelFocused)
                    }
                }

                Section("Storlek") {
                    HStack {
                        Image(systemName: "minus.circle")
                            .foregroundStyle(.secondary)
                        Slider(value: $draft.sizeMultiplier, in: 0.5...2.0, step: 0.1)
                        Image(systemName: "plus.circle")
                            .foregroundStyle(.secondary)
                    }
                    Text(String(format: "%.1fx", draft.sizeMultiplier))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Anteckning (osynlig på canvasen)") {
                    TextField("Skriv anteckning här", text: $draft.note, axis: .vertical)
                        .lineLimit(2...8)
                }
            }
            .navigationTitle("Redigera form")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Klar") { onSave(draft) }
                        .bold()
                }
            }
            .onAppear {
                if draft.showLabel {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        labelFocused = true
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
