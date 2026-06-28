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
    /// v74: kedje-ordningsnummer för skill-containrar. nil = inget nummer.
    var skillNumber: Int?
}

struct EditShapeSheet: View {
    let shapeId: UUID
    let initial: ShapeEdit
    /// v74: visar skill-nummer-sektionen (bara skill-containrar).
    let isSkillContainer: Bool
    /// Steg 8: visar prompt-sektionen (bara skill-flöde-former + containrar, inte basformer).
    let showsPrompt: Bool
    var onSave: (ShapeEdit) -> Void
    var onCancel: () -> Void
    var onDelete: () -> Void

    @State private var draft: ShapeEdit
    @State private var showDeleteConfirm = false
    @FocusState private var labelFocused: Bool

    init(shapeId: UUID,
         initial: ShapeEdit,
         isSkillContainer: Bool = false,
         showsPrompt: Bool = true,
         onSave: @escaping (ShapeEdit) -> Void,
         onCancel: @escaping () -> Void,
         onDelete: @escaping () -> Void) {
        self.shapeId = shapeId
        self.initial = initial
        self.isSkillContainer = isSkillContainer
        self.showsPrompt = showsPrompt
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
                        .autocorrectionDisabled()   // 1.5-fix: diagram-etiketter ändras ej bakom ryggen
                        .accessibilityIdentifier("edit.label")
                }
                // 1.3 S1.3: stil/justering/punktlista borttagna här — formateras i den delade
                // FormattingBar:en (verktygsfält + ovanför tangentbordet). EN formateringsyta.
                // Värdena bevaras orört via draft (textStyle/textAlignment/hasBullets).

                // v74: skill-nummer — ordningen i kedjan ("Skill 2 · namn" i rubriken).
                if isSkillContainer {
                    Section("Skill-nummer (ordning i kedjan)") {
                        Toggle("Har nummer", isOn: Binding(
                            get: { draft.skillNumber != nil },
                            set: { draft.skillNumber = $0 ? (draft.skillNumber ?? 1) : nil }
                        ))
                        if let nr = draft.skillNumber {
                            Stepper("Skill \(nr)", value: Binding(
                                get: { draft.skillNumber ?? 1 },
                                set: { draft.skillNumber = $0 }
                            ), in: 1...20)
                            .accessibilityIdentifier("edit.skillNumber")
                        }
                    }
                }

                // v60: prompt-fält. v73: flyttad ÖVER anteckningen + ny rubrik —
                // prompten är skill-kedjornas kärna och ska synas utan scroll.
                // Steg 8: bara skill-flöde-former + containrar (inte basformer).
                if showsPrompt {
                    Section("Prompt (instruktionen till Claude — blir del av skillen)") {
                        TextField("Input → uppgift → output. Subagenten ser bara detta.", text: $draft.prompt, axis: .vertical)
                            .lineLimit(3...12)
                            .accessibilityIdentifier("edit.prompt")
                    }
                }

                // 1.3 S1.2: anteckningsfältet borttaget — anteckning redigeras i NoteCard
                // på canvasen (EN väg). Värdet bevaras orört via draft.note.

                Section {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Ta bort form", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Redigera form")
            .inlineNavTitle()
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
