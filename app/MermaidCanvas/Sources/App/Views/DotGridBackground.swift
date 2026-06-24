import SwiftUI

/// Stillsam pricklayout på canvasen för visuell alignment.
/// Ingen export — bara UI-hjälp. Apple-design: subtil, ej dominant.
struct DotGridBackground: View {
    var spacing: CGFloat = 24
    var dotSize: CGFloat = 1.5
    var color: Color = Color.appTertiaryLabel

    var body: some View {
        Canvas(rendersAsynchronously: false) { ctx, size in
            let cols = Int(size.width / spacing) + 1
            let rows = Int(size.height / spacing) + 1
            let shading = GraphicsContext.Shading.color(color.opacity(0.6))
            for r in 0..<rows {
                for c in 0..<cols {
                    let x = CGFloat(c) * spacing
                    let y = CGFloat(r) * spacing
                    let rect = CGRect(x: x - dotSize / 2,
                                      y: y - dotSize / 2,
                                      width: dotSize,
                                      height: dotSize)
                    ctx.fill(Path(ellipseIn: rect), with: shading)
                }
            }
        }
        .drawingGroup() // Flatten:as till en Metal-texture — pan/zoom blir smooth
        .allowsHitTesting(false)
    }
}
