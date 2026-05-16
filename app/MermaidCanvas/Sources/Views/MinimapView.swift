import SwiftUI

/// v27: Minikarta som visar översikt av hela canvasen + viewport-rektangel.
/// Tap på minikartan flyttar vyn till den punkten.
struct MinimapView: View {
    @ObservedObject var model: CanvasModel
    /// Aktuellt synligt område i canvas-koordinater (innan scale, från CanvasView).
    let viewportRect: CGRect
    /// Kommer in från CanvasView som vyport-bredd/höjd i pt.
    let canvasScale: CGFloat
    /// Anropas när användaren tappar på minikartan — argumentet är center-position i canvas-koord.
    var onTapPoint: (CGPoint) -> Void
    var onClose: () -> Void

    private let mapSize: CGSize = CGSize(width: 200, height: 150)

    var body: some View {
        let contentSize = model.contentSize
        let scaleX = mapSize.width / contentSize.width
        let scaleY = mapSize.height / contentSize.height
        let scale = min(scaleX, scaleY)
        let mappedW = contentSize.width * scale
        let mappedH = contentSize.height * scale

        ZStack(alignment: .topTrailing) {
            ZStack(alignment: .topLeading) {
                // Bakgrund
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
                    .frame(width: mappedW, height: mappedH)

                // Shapes som små rektanglar
                ForEach(model.shapes) { shape in
                    let w = ShapeGeometry.width(for: shape) * scale
                    let h = ShapeGeometry.height(for: shape) * scale
                    Rectangle()
                        .fill(shape.category.fillColor.opacity(0.8))
                        .frame(width: max(2, w), height: max(2, h))
                        .position(x: shape.position.x * scale,
                                  y: shape.position.y * scale)
                }

                // Viewport-rektangel (röd ram)
                Rectangle()
                    .stroke(Color.red, lineWidth: 1.5)
                    .frame(width: max(8, viewportRect.width * scale),
                           height: max(8, viewportRect.height * scale))
                    .position(x: (viewportRect.midX) * scale,
                              y: (viewportRect.midY) * scale)
            }
            .frame(width: mappedW, height: mappedH, alignment: .topLeading)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.primary.opacity(0.2), lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture { local in
                let canvasPoint = CGPoint(x: local.x / scale, y: local.y / scale)
                onTapPoint(canvasPoint)
            }
            .accessibilityIdentifier("minimap.canvas")

            // Stäng-knapp
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color.secondary)
                    .background(Circle().fill(Color(.systemBackground)))
            }
            .buttonStyle(.plain)
            .offset(x: 8, y: -8)
            .accessibilityIdentifier("minimap.close")
        }
        .padding(8)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(radius: 6)
    }
}
