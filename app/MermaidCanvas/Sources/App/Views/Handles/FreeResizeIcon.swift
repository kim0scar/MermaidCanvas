import SwiftUI

/// v42: Custom-ritad fri-resize-ikon med 4 tydliga diagonala pilar (↖↗↘↙).
/// SF Symbols' överlappande pilar smälte ihop till ett ✕ — så vi ritar själva.
struct FreeResizeIcon: View {
    let color: Color

    var body: some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let r = size.width * 0.34          // pillängd från centrum
            let inner = size.width * 0.10      // start-radius (gap i mitten)
            let headLen = size.width * 0.14    // pilhuvudets längd
            let lw: CGFloat = max(1.5, size.width * 0.085)
            let stroke = GraphicsContext.Shading.color(color)

            for angleDeg in [45.0, 135.0, 225.0, 315.0] {
                let rad = angleDeg * .pi / 180
                let dx = cos(rad), dy = sin(rad)
                let base = CGPoint(x: c.x + dx * inner, y: c.y + dy * inner)
                let tip  = CGPoint(x: c.x + dx * r,     y: c.y + dy * r)

                // Linje från base till tip
                var line = Path()
                line.move(to: base)
                line.addLine(to: tip)
                ctx.stroke(line, with: stroke, style: StrokeStyle(lineWidth: lw, lineCap: .round))

                // Pilhuvud: två vinklade linjer från tip
                let aL = rad + (.pi * 0.80)   // ca 145° relativ vinkel
                let aR = rad - (.pi * 0.80)
                var head = Path()
                head.move(to: tip)
                head.addLine(to: CGPoint(x: tip.x + cos(aL) * headLen,
                                         y: tip.y + sin(aL) * headLen))
                head.move(to: tip)
                head.addLine(to: CGPoint(x: tip.x + cos(aR) * headLen,
                                         y: tip.y + sin(aR) * headLen))
                ctx.stroke(head, with: stroke, style: StrokeStyle(lineWidth: lw, lineCap: .round))
            }
        }
    }
}
