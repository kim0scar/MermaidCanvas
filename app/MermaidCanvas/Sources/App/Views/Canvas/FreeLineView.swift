import SwiftUI

/// v36: Ritar en lös linje eller pil på canvas.
/// Linjen går från formens centrum (0,0 i view-space) till lineEnd (relativ offset).
/// Används för ShapeType.line och .arrow — dessa renderas INTE av background/stroke.
struct FreeLineView: View {
    let shape: ShapeNode
    let stroke: Color

    var body: some View {
        Canvas { ctx, size in
            guard let end = shape.lineEnd else { return }
            let from = CGPoint(x: size.width / 2, y: size.height / 2)
            // v66: lineEnd används DIREKT (ändpunkts-handtaget skriver det) —
            // multipliers är utfasade för linjer (migreras vid inläsning).
            // Bboxen växer med lineEnd via ShapeGeometry så inget clippas.
            let scaledX = end.x
            let scaledY = end.y
            let to = CGPoint(x: size.width / 2 + scaledX, y: size.height / 2 + scaledY)

            // Linje — 1.5pt matchar EdgesView kant-linjer
            var path = Path()
            path.move(to: from)
            path.addLine(to: to)
            ctx.stroke(path, with: .color(stroke),
                       style: StrokeStyle(lineWidth: 1.5, lineCap: .round))

            // Pilhuvud (endast .arrow)
            if shape.type == .arrow {
                let angle = atan2(scaledY, scaledX)
                let headLen: CGFloat = 12
                let headAngle: CGFloat = .pi / 6   // 30°

                let a1 = CGPoint(
                    x: to.x - headLen * cos(angle - headAngle),
                    y: to.y - headLen * sin(angle - headAngle))
                let a2 = CGPoint(
                    x: to.x - headLen * cos(angle + headAngle),
                    y: to.y - headLen * sin(angle + headAngle))

                var head = Path()
                head.move(to: to)
                head.addLine(to: a1)
                head.move(to: to)
                head.addLine(to: a2)
                ctx.stroke(head, with: .color(stroke),
                           style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            }
        }
        .frame(width: ShapeGeometry.width(for: shape),
               height: ShapeGeometry.height(for: shape))
        .allowsHitTesting(false)
    }
}
