import SwiftUI

/// v66/v67: Kvarliggande läs-LAPPAR PÅ canvasen (ersätter QuickReadSheet-modalen,
/// Kims fynd: "popup som ligger kvar så man kan läsa alla"). Flera samtidigt.
/// v67: ritas i CANVAS-space (inuti den zoombara tavlan) → lappen panorerar och
/// zoomar med formen och försvinner ur vy när Kim panorerar bort, i stället för att
/// sitta fast på skärmen och täcka saker (Kims fynd 2).
struct NoteCardsLayer: View {
    @ObservedObject var model: CanvasModel
    @Binding var openCards: [UUID]
    var onEdit: (UUID) -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(openCards, id: \.self) { id in
                if let shape = model.shapes.first(where: { $0.id == id }) {
                    NoteCard(shape: shape,
                             onClose: { openCards.removeAll { $0 == id } },
                             onEdit: { onEdit(id) })
                        .position(cardPosition(for: shape))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// Canvas-koordinat: lappen läggs intill formen (höger sida). Ingen skärm-klamp —
    /// den hör till tavlan, inte skärmen.
    static let cardWidth: CGFloat = 260
    private func cardPosition(for shape: ShapeNode) -> CGPoint {
        let halfShapeW = ShapeGeometry.width(for: shape) / 2
        let x = shape.position.x + halfShapeW + Self.cardWidth / 2 + 16
        return CGPoint(x: x, y: shape.position.y)
    }
}

/// En lapp: formens namn + Prompt (blir skill) + Anteckning (bara för dig).
struct NoteCard: View {
    let shape: ShapeNode
    var onClose: () -> Void
    var onEdit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text(shape.label.isEmpty ? "Form" : shape.label)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Spacer(minLength: 4)
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("notecard.close")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color(.secondarySystemBackground))

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if !shape.prompt.isEmpty {
                        section(icon: "brain", color: Color(hex: 0x4338ca),
                                heading: "Prompt (blir skill)", text: shape.prompt)
                    }
                    if !shape.note.isEmpty {
                        section(icon: "text.alignleft", color: Color(hex: 0xB28A00),
                                heading: "Anteckning (bara för dig)", text: shape.note)
                    }
                    if shape.prompt.isEmpty && shape.note.isEmpty {
                        Text("Ingen prompt eller anteckning.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
            }
            .frame(maxHeight: 230)
        }
        .frame(width: 260)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(Color(.separator), lineWidth: 0.8))
        .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
        .accessibilityIdentifier("notecard")
    }

    @ViewBuilder
    private func section(icon: String, color: Color,
                         heading: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(heading, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
            Text(text)
                .font(.footnote)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
