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

/// V79-svep (Kims "Fyra prickarna igen"): FYRA connection-handtag — ett per sida.
/// Pilen går ut från SIDAN man drog ifrån (ej automatiskt närmaste). Sidan kan ändras
/// i efterhand via pilens kontextmeny ("Går ut från").
struct ConnectionHandles: View {
    let shape: ShapeNode
    let canvasScale: CGFloat
    let onDragChanged: (CGPoint) -> Void
    let onDragEnded: (EdgeSide, CGPoint) -> Void

    var body: some View {
        let w = ShapeGeometry.width(for: shape)
        let h = ShapeGeometry.height(for: shape)
        // v66: skärm-konstant storlek (DesignTokens.screenPt) som övriga handtag.
        let size: CGFloat = DesignTokens.screenPt(24, scale: canvasScale)
        let gap: CGFloat = size / 2 + 8 / canvasScale
        ZStack {
            handle(side: .top,    offset: CGPoint(x: 0, y: -h/2 - gap), size: size)
            handle(side: .right,  offset: CGPoint(x: w/2 + gap, y: 0), size: size)
            handle(side: .bottom, offset: CGPoint(x: 0, y: h/2 + gap), size: size)
            handle(side: .left,   offset: CGPoint(x: -w/2 - gap, y: 0), size: size)
        }
        .frame(width: w, height: h)
        .position(shape.position)
        .rotationEffect(.degrees(shape.rotation))
    }

    @ViewBuilder
    private func handle(side: EdgeSide, offset: CGPoint, size: CGFloat) -> some View {
        ZStack {
            // v66: GRÖN + egen ikon — skiljer sig tydligt från de blå resize-handtagen.
            Circle().fill(Color(hex: 0x15803d))
            Image(systemName: "plus")
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
                .onEnded { v in onDragEnded(side, v.location) }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Skapa pil från \(side.rawValue) — dra till en annan form")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("connection.handle.\(side.rawValue)")
    }
}
