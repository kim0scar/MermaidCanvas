import SwiftUI

/// Slimmad ShapeEdit (v23) — bara namn, toggle, textstil, anteckning.
/// v37: textAlignment + hasBullets tillagda.
struct ShapeEdit: Equatable {
    var label: String
    var showLabel: Bool
    var note: String
    var textStyle: TextStyle
    var textAlignment: TextAlignMode
    var hasBullets: Bool
    /// v60: prompt-text för n8n-flöden (följer med i Mermaid-exporten).
    var prompt: String
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
                Section("Namn / text i form") {
                    Toggle("Visa text", isOn: $draft.showLabel)
                    TextField("Namn på formen (syns i form + Mermaid)", text: $draft.label, axis: .vertical)
                        .lineLimit(1...4)
                        .focused($labelFocused)
                        .accessibilityIdentifier("edit.label")
                    Picker("Stil", selection: $draft.textStyle) {
                        ForEach(TextStyle.allCases) { st in
                            Text(st.displayName).tag(st)
                        }
                    }
                    .pickerStyle(.segmented)
                    // v37: textjustering + punktlista — kompakt rad
                    HStack(spacing: 12) {
                        Picker("Justering", selection: $draft.textAlignment) {
                            Image(systemName: "text.alignleft").tag(TextAlignMode.leading)
                            Image(systemName: "text.aligncenter").tag(TextAlignMode.center)
                            Image(systemName: "text.alignright").tag(TextAlignMode.trailing)
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 130)
                        Spacer()
                        Toggle(isOn: $draft.hasBullets) {
                            Image(systemName: "list.bullet")
                        }
                        .toggleStyle(.button)
                    }
                }

                // v60: prompt-fält. v73: flyttad ÖVER anteckningen + ny rubrik —
                // prompten är skill-kedjornas kärna och ska synas utan scroll.
                Section("Prompt (instruktionen till Claude — blir del av skillen)") {
                    TextField("Input → uppgift → output. Subagenten ser bara detta.", text: $draft.prompt, axis: .vertical)
                        .lineLimit(3...12)
                        .accessibilityIdentifier("edit.prompt")
                }

                Section("Anteckning (din egen — ingår aldrig i skillen)") {
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
        .presentationDetents([.medium, .large])
        // v73: osparade ändringar får inte försvinna av ett svep — stäng via Klar/Avbryt.
        .interactiveDismissDisabled(draft != initial)
    }
}
