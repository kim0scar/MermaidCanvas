import SwiftUI

// MARK: - ConnectionRubberBand

struct ConnectionRubberBand: View {
    let from: CGPoint
    let to: CGPoint

    var body: some View {
        ZStack {
            Path { p in
                p.move(to: from)
                p.addLine(to: to)
            }
            .stroke(Color.accentColor.opacity(0.85),
                    style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
            // Mål-prick
            Circle()
                .fill(Color.accentColor)
                .frame(width: 10, height: 10)
                .position(to)
        }
    }
}

// MARK: - ConnectionHandles

/// v64 (Kims önskemål): ETT connection-handtag i stället för fyra — mindre röra
/// runt formen. Sitter i högerkanten; pilen får automatiskt närmaste utgångssida,
/// och sidan kan ändras i efterhand via pilens kontextmeny ("Går ut från").
struct ConnectionHandles: View {
    let shape: ShapeNode
    let canvasScale: CGFloat
    let onDragChanged: (CGPoint) -> Void
    let onDragEnded: (CGPoint) -> Void

    var body: some View {
        let w = ShapeGeometry.width(for: shape)
        let h = ShapeGeometry.height(for: shape)
        // v66: skärm-konstant storlek (DesignTokens.screenPt) som övriga handtag.
        let size: CGFloat = DesignTokens.screenPt(26, scale: canvasScale)
        let gap: CGFloat = size / 2 + 10 / canvasScale
        handle(offset: CGPoint(x: w/2 + gap, y: 0), icon: "arrow.right",
               accId: "connection.handle.right", size: size)
        .frame(width: w, height: h)
        .position(shape.position)
        .rotationEffect(.degrees(shape.rotation))
    }

    @ViewBuilder
    private func handle(offset: CGPoint, icon: String, accId: String, size: CGFloat) -> some View {
        ZStack {
            // v66: GRÖN + egen ikon — skiljer sig tydligt från de blå
            // resize-handtagen (Kims/UX-fynd: två blå cirklar intill varandra).
            Circle().fill(Color(hex: 0x15803d))
            Image(systemName: "arrow.up.right")
                .font(.system(size: size * 0.50, weight: .bold))
                .foregroundStyle(Color.white)
        }
        .frame(width: size, height: size)
        .overlay(Circle().stroke(Color.white, lineWidth: max(1.0, 1.5 / canvasScale)))
        .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
        .offset(x: offset.x, y: offset.y)
        .gesture(
            DragGesture(coordinateSpace: .named("canvas"))
                .onChanged { v in onDragChanged(v.location) }
                .onEnded { v in onDragEnded(v.location) }
        )
        // v73: svensk label i stället för rått symbolnamn ("arrow.up.right")
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Skapa pil — dra till en annan form")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(accId)
    }
}
