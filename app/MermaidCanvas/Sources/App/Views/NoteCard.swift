import SwiftUI

/// v66: Kvarliggande läs-LAPPAR på canvasen (ersätter QuickReadSheet-modalen,
/// Kims fynd: "popup som ligger kvar så man kan läsa alla"). Flera samtidigt.
/// Ritas i SKÄRM-space ovanpå canvasen → texten alltid läsbar oavsett zoom,
/// och ingen konflikt med canvasens pan-gester. Följer sin form vid pan/zoom.
struct NoteCardsLayer: View {
    @ObservedObject var model: CanvasModel
    @ObservedObject var viewportState: CanvasViewportState
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

    /// Lappen läggs intill formen (höger sida), clampad så den alltid syns.
    private func cardPosition(for shape: ShapeNode) -> CGPoint {
        let scale = viewportState.zoomScale
        let sx = shape.position.x * scale - viewportState.contentOffset.width
        let sy = shape.position.y * scale - viewportState.contentOffset.height
        let w = max(viewportState.globalFrame.width, 280)
        let h = max(viewportState.globalFrame.height, 300)
        let halfShapeW = ShapeGeometry.width(for: shape) / 2 * scale
        let x = min(max(sx + halfShapeW + 145, 135), w - 135)
        let y = min(max(sy, 130), h - 150)
        return CGPoint(x: x, y: y)
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
