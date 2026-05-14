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
    let specType: SpecType
    var onSave: (ShapeEdit) -> Void
    var onCancel: () -> Void
    var onDelete: () -> Void

    @State private var draft: ShapeEdit
    @State private var showDeleteConfirm = false
    @FocusState private var labelFocused: Bool

    init(shapeId: UUID,
         initial: ShapeEdit,
         specType: SpecType,
         onSave: @escaping (ShapeEdit) -> Void,
         onCancel: @escaping () -> Void,
         onDelete: @escaping () -> Void) {
        self.shapeId = shapeId
        self.initial = initial
        self.specType = specType
        self.onSave = onSave
        self.onCancel = onCancel
        self.onDelete = onDelete
        _draft = State(initialValue: initial)
    }

    private var availableCategories: [ShapeCategory] {
        ShapeCategory.available(for: specType)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Kategori") {
                    // Stacka i 2-3 kolumner om många kategorier — annars segmented
                    if availableCategories.count <= 4 {
                        Picker("Kategori", selection: $draft.category) {
                            ForEach(availableCategories) { cat in
                                Text(cat.displayName).tag(cat)
                            }
                        }
                        .pickerStyle(.segmented)
                    } else {
                        WrapCategoryGrid(
                            categories: availableCategories,
                            selected: $draft.category
                        )
                    }
                    Text(draft.category.pickerHint)
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
                        Image(systemName: "minus.circle").foregroundStyle(.secondary)
                        Slider(value: $draft.sizeMultiplier, in: 0.5...2.0, step: 0.1)
                        Image(systemName: "plus.circle").foregroundStyle(.secondary)
                    }
                    Text(String(format: "%.1fx", draft.sizeMultiplier))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Anteckning (osynlig på canvasen)") {
                    TextField("Skriv anteckning här", text: $draft.note, axis: .vertical)
                        .lineLimit(2...8)
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
    }
}

/// Wrappad grid för kategorier — använd när vi har > 4 (roadmap/arch/flow).
private struct WrapCategoryGrid: View {
    let categories: [ShapeCategory]
    @Binding var selected: ShapeCategory

    let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 6)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(categories) { cat in
                Button {
                    selected = cat
                } label: {
                    Text(cat.displayName)
                        .font(.subheadline.weight(.medium))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(selected == cat ? Color.white : Color.primary)
                        .background(selected == cat ? Color.accentColor : Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
