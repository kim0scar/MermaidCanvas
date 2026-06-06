import SwiftUI

/// v66: Ändpunkts-handtag för lösa linjer/pilar (.line/.arrow).
/// Drar man i det flyttas shape.lineEnd DIREKT — strecket blir längre/kortare
/// och kan vinklas fritt (Kims fynd: gick inte att dra ut strecket).
/// Ersätter de vanliga resize-handtagen för linjer (bbox-skalning kändes trasig).
struct LineEndpointHandle: View {
    @Binding var shape: ShapeNode
    let canvasScale: CGFloat

    var body: some View {
        let end = shape.lineEnd ?? CGPoint(x: 60, y: 0)
        let pos = CGPoint(x: shape.position.x + end.x,
                          y: shape.position.y + end.y)
        let size = DesignTokens.screenPt(26, scale: canvasScale)
        ZStack {
            Circle()
                .fill(Color.white)
                .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(Color.accentColor)
        }
        .frame(width: size, height: size)
        .contentShape(Circle().inset(by: -size * 0.5))
        .position(pos)
        .gesture(
            DragGesture(coordinateSpace: .named("canvas"))
                .onChanged { v in
                    let dx = v.location.x - shape.position.x
                    let dy = v.location.y - shape.position.y
                    // minst 20pt så strecket inte kan kollapsa till en prick
                    guard hypot(dx, dy) > 20 else { return }
                    shape.lineEnd = CGPoint(x: dx, y: dy)
                    // multipliers utfasade för linjer — lineEnd äger längden
                    shape.sizeMultiplier = 1
                    shape.widthMultiplier = nil
                    shape.heightMultiplier = nil
                }
        )
        .accessibilityIdentifier("line.endpoint")
        .accessibilityLabel("Dra ut strecket")
    }
}
