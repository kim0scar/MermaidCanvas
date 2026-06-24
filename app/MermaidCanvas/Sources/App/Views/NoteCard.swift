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
                    NoteCard(model: model, shapeId: id,
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
/// V79-svep: namn + anteckning är REDIGERBARA direkt här på canvasen (Kims "skriv
/// direkt på canvas"). Prompt visas read-only; pennan öppnar full redigering.
struct NoteCard: View {
    @ObservedObject var model: CanvasModel
    let shapeId: UUID
    var onClose: () -> Void
    var onEdit: () -> Void

    @State private var label = ""
    @State private var note = ""
    @State private var loaded = false
    @State private var snapped = false

    private var shape: ShapeNode? { model.shapes.first { $0.id == shapeId } }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                // V79-svep: namnet skrivs direkt i lappen ("ny ikon T → skriv namn").
                TextField("Namn", text: $label)
                    .font(.subheadline.weight(.semibold))
                    .textFieldStyle(.plain)
                    .submitLabel(.done)
                    .onChange(of: label) { _, v in commit(label: v) }
                    .accessibilityIdentifier("notecard.name")
                Spacer(minLength: 4)
                Button(action: onEdit) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("notecard.edit")
                .accessibilityLabel("Redigera (reglage)")
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
            .background(Color.appSecondaryBackground)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if let p = shape?.prompt, !p.isEmpty {
                        section(icon: "brain", color: Color(hex: 0x4338ca),
                                heading: "Prompt (blir skill)", text: p)
                    }
                    // V79-svep: anteckningen REDIGERAS direkt på canvasen.
                    VStack(alignment: .leading, spacing: 5) {
                        Label("Anteckning (bara för dig)", systemImage: "text.alignleft")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color(hex: 0xB28A00))
                        TextEditor(text: $note)
                            .font(.footnote)
                            .frame(minHeight: 56, maxHeight: 130)
                            .scrollContentBackground(.hidden)
                            .background(Color.appSecondaryBackground,
                                        in: RoundedRectangle(cornerRadius: 8))
                            .onChange(of: note) { _, v in commit(note: v) }
                            .accessibilityIdentifier("notecard.note")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
            }
            .frame(maxHeight: 230)
        }
        .frame(width: 260)
        .background(Color.appBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12)
            .stroke(Color.appSeparator, lineWidth: 0.8))
        .shadow(color: .black.opacity(0.18), radius: 10, y: 4)
        .accessibilityIdentifier("notecard")
        .onAppear {
            guard !loaded else { return }
            label = shape?.label ?? ""
            note = shape?.note ?? ""
            loaded = true
        }
    }

    /// Skriver live till modellen; tar EN undo-snapshot per redigeringssession.
    /// No-op om värdet inte ändrats (skyddar mot ladd-triggad onChange).
    private func commit(label: String? = nil, note: String? = nil) {
        if let label, label == shape?.label { return }
        if let note, note == shape?.note { return }
        if !snapped { model.snapshotForUndo(); snapped = true }
        model.setShapeText(id: shapeId, label: label, note: note)
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
