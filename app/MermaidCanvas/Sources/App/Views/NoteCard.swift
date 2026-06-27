import SwiftUI

/// v66/v67: Kvarliggande anteckningar PÅ canvasen (ersätter QuickReadSheet-modalen).
/// 1.4 (Kim): omgjorda till eleganta PRATBUBBLOR — gul ton + svans mot formen, redigeras
/// direkt i bubblan, vik-ikon (inget kryss). Ligger kvar tills man viker in dem.
struct NoteCardsLayer: View {
    @ObservedObject var model: CanvasModel
    @Binding var openCards: [UUID]

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(openCards, id: \.self) { id in
                if let shape = model.shapes.first(where: { $0.id == id }) {
                    NoteCard(model: model, shapeId: id,
                             onFold: { openCards.removeAll { $0 == id } })
                        .position(cardPosition(for: shape))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    /// Canvas-koordinat: bubblan läggs intill formen (höger sida), svansen pekar vänster
    /// mot formen. Ingen skärm-klamp — den hör till tavlan, inte skärmen.
    static let cardWidth: CGFloat = 244
    private func cardPosition(for shape: ShapeNode) -> CGPoint {
        let halfShapeW = ShapeGeometry.width(for: shape) / 2
        let x = shape.position.x + halfShapeW + Self.cardWidth / 2 + 16
        return CGPoint(x: x, y: shape.position.y)
    }
}

/// En anteckningsbubbla: gul ton + svans mot formen. Anteckningen redigeras direkt här
/// (Kims "skriv direkt på canvas"). Vik-ikonen fäller in bubblan (formens bubbel-badge
/// står kvar). Prompt visas read-only om formen bär en.
struct NoteCard: View {
    @ObservedObject var model: CanvasModel
    let shapeId: UUID
    var onFold: () -> Void

    @State private var note = ""
    @State private var loaded = false
    @State private var snapped = false

    private var shape: ShapeNode? { model.shapes.first { $0.id == shapeId } }
    private let tailWidth: CGFloat = 12

    // Gul antecknings-palett (bubblan ligger på den ljus-låsta canvasen).
    private let bubbleFill = Color(hex: 0xFFF6D6)
    private let bubbleStroke = Color(hex: 0xE6C766)
    private let ink = Color(hex: 0x8A6D00)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 11))
                Text("Anteckning")
                    .font(.caption2.weight(.semibold))
                Spacer(minLength: 4)
                Button(action: onFold) {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("notecard.fold")
                .accessibilityLabel("Fäll in anteckningen")
            }
            .foregroundStyle(ink)

            if let p = shape?.prompt, !p.isEmpty {
                section(icon: "brain", color: Color(hex: 0x4338ca),
                        heading: "Prompt (blir skill)", text: p)
            }

            TextEditor(text: $note)
                .font(.footnote)
                .foregroundStyle(Color(hex: 0x3A2E00))
                .frame(minHeight: 52, maxHeight: 150)
                .scrollContentBackground(.hidden)
                .background(Color.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 8))
                .onChange(of: note) { _, v in commit(note: v) }
                .accessibilityIdentifier("notecard.note")
        }
        .padding(.vertical, 10)
        .padding(.trailing, 12)
        .padding(.leading, 12 + tailWidth)   // plats för svansen till vänster
        .frame(width: NoteCardsLayer.cardWidth)
        .background(SpeechBubble(tailWidth: tailWidth).fill(bubbleFill))
        .overlay(SpeechBubble(tailWidth: tailWidth).stroke(bubbleStroke, lineWidth: 1))
        .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
        .accessibilityIdentifier("notecard")
        .onAppear {
            guard !loaded else { return }
            note = shape?.note ?? ""
            loaded = true
        }
    }

    /// Skriver live till modellen; tar EN undo-snapshot per redigeringssession.
    private func commit(note: String) {
        if note == shape?.note { return }
        if !snapped { model.snapshotForUndo(); snapped = true }
        model.setShapeText(id: shapeId, note: note)
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

/// Pratbubbla: rundad kropp + en svans (triangel) på vänster sida som pekar mot formen.
/// Kroppen är indragen `tailWidth` från vänsterkanten; svansen fyller den vänstra biten.
struct SpeechBubble: Shape {
    var cornerRadius: CGFloat = 14
    var tailWidth: CGFloat = 12
    var tailHeight: CGFloat = 18

    func path(in rect: CGRect) -> Path {
        let body = CGRect(x: rect.minX + tailWidth, y: rect.minY,
                          width: rect.width - tailWidth, height: rect.height)
        var p = Path(roundedRect: body, cornerRadius: cornerRadius)
        let cy = rect.midY
        var tail = Path()
        tail.move(to: CGPoint(x: body.minX + 1, y: cy - tailHeight / 2))
        tail.addLine(to: CGPoint(x: rect.minX, y: cy))
        tail.addLine(to: CGPoint(x: body.minX + 1, y: cy + tailHeight / 2))
        tail.closeSubpath()
        p.addPath(tail)
        return p
    }
}
