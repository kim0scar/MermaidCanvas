import SwiftUI

struct EditShapeSheet: View {
    let shapeId: UUID
    let initialLabel: String
    var onSave: (String) -> Void
    var onCancel: () -> Void

    @State private var draft: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Namn på form") {
                    TextField("Skriv text", text: $draft, axis: .vertical)
                        .lineLimit(1...4)
                        .focused($focused)
                        .submitLabel(.done)
                        .onSubmit(save)
                }
            }
            .navigationTitle("Byt namn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Klar", action: save)
                        .bold()
                }
            }
            .onAppear {
                draft = initialLabel
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    focused = true
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func save() {
        onSave(draft)
    }
}
