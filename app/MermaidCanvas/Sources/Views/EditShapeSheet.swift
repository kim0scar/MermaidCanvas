import SwiftUI

struct ShapeEdit {
    var label: String
    var showLabel: Bool
    var sizeMultiplier: CGFloat
    var note: String
    var category: ShapeCategory
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
                Section("Kategori") {
                    Picker("Kategori", selection: $draft.category) {
                        ForEach(ShapeCategory.allCases) { cat in
                            Text(cat.displayName).tag(cat)
                        }
                    }
                    .pickerStyle(.segmented)
                    Text(categoryHint(draft.category))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

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

    private func categoryHint(_ cat: ShapeCategory) -> String {
        switch cat {
        case .ui:      return "UI-element — text syns på skärmen."
        case .zone:    return "Layout-zon — region där UI placeras."
        case .note:    return "Kommentar — syns aldrig som UI-text."
        case .overlay: return "Overlay — modal, tooltip eller HUD-överlägg."
        }
    }
}
