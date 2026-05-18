import SwiftUI

/// v31: Anteckning-popup som visar all canvas-text (label + note) i en läsbar lista.
/// Trigger: tap på pratbubbla-chip i Former-rad B.
struct NotePopupSheet: View {
    let shapes: [ShapeNode]
    var onClose: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if shapes.isEmpty {
                        Text("Inga anteckningar än.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding()
                    } else {
                        ForEach(shapes) { shape in
                            entry(for: shape)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Anteckningar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Stäng", action: onClose)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private func entry(for shape: ShapeNode) -> some View {
        let hasLabel = !shape.label.isEmpty
        let hasNote = !shape.note.isEmpty
        if hasLabel || hasNote {
            VStack(alignment: .leading, spacing: 6) {
                if hasLabel {
                    Text(shape.label)
                        .font(.headline)
                }
                if hasNote {
                    Text(shape.note)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                Text(shape.type.rawValue)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 6)
            Divider()
        }
    }
}
