import SwiftUI

/// Slimmad ShapeEdit (v23) — bara namn, toggle, textstil, anteckning.
/// Storlek/rotation hanteras via handtag på canvas. Kategori sätts via plattform-läget.
struct ShapeEdit {
    var label: String
    var showLabel: Bool
    var note: String
    var textStyle: TextStyle
}

struct EditShapeSheet: View {
    let shapeId: UUID
    let initial: ShapeEdit
    var onSave: (ShapeEdit) -> Void
    var onCancel: () -> Void
    var onDelete: () -> Void

    @State private var draft: ShapeEdit
    @State private var showDeleteConfirm = false
    @FocusState private var labelFocused: Bool

    init(shapeId: UUID,
         initial: ShapeEdit,
         onSave: @escaping (ShapeEdit) -> Void,
         onCancel: @escaping () -> Void,
         onDelete: @escaping () -> Void) {
        self.shapeId = shapeId
        self.initial = initial
        self.onSave = onSave
        self.onCancel = onCancel
        self.onDelete = onDelete
        _draft = State(initialValue: initial)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Text i form") {
                    Toggle("Visa text", isOn: $draft.showLabel)
                    TextField("Skriv text", text: $draft.label, axis: .vertical)
                        .lineLimit(1...4)
                        .focused($labelFocused)
                        .accessibilityIdentifier("edit.label")
                    Picker("Stil", selection: $draft.textStyle) {
                        ForEach(TextStyle.allCases) { st in
                            Text(st.displayName).tag(st)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Anteckning (osynlig på canvasen)") {
                    TextField("Skriv anteckning här", text: $draft.note, axis: .vertical)
                        .lineLimit(2...8)
                        .accessibilityIdentifier("edit.note")
                }

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Ta bort form", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Redigera form")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Klar") { onSave(draft) }.bold()
                }
            }
            .onAppear {
                if draft.showLabel {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        labelFocused = true
                    }
                }
            }
            .alert("Ta bort den här formen?", isPresented: $showDeleteConfirm) {
                Button("Avbryt", role: .cancel) {}
                Button("Ta bort", role: .destructive) { onDelete() }
            } message: {
                Text("Alla pilar till och från formen försvinner också.")
            }
        }
        .presentationDetents([.height(380), .medium])
    }
}
