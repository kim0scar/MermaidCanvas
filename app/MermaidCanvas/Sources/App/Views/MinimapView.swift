import SwiftUI

/// v28: Minikarta som visar översikt av hela canvasen + viewport-rektangel.
/// Tap på minikartan flyttar vyn till den punkten.
/// Placeras som .overlay(alignment: .topTrailing) — INTE som ZStack-layer som blockerar touches.
struct MinimapView: View {
    @ObservedObject var model: CanvasModel
    let viewportRect: CGRect
    var onTapPoint: (CGPoint) -> Void
    var onClose: () -> Void

    private let mapSize: CGSize = CGSize(width: 180, height: 140)

    var body: some View {
        let contentSize = model.contentSize
        let scaleX = mapSize.width / contentSize.width
        let scaleY = mapSize.height / contentSize.height
        let scale = min(scaleX, scaleY)
        let mappedW = contentSize.width * scale
        let mappedH = contentSize.height * scale

        ZStack(alignment: .topTrailing) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                    )
                    .frame(width: mappedW, height: mappedH)

                ForEach(model.shapes) { shape in
                    let w = max(2, ShapeGeometry.width(for: shape) * scale)
                    let h = max(2, ShapeGeometry.height(for: shape) * scale)
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(shape.category.fillColor.opacity(0.85))
                        .frame(width: w, height: h)
                        .position(x: shape.position.x * scale,
                                  y: shape.position.y * scale)
                }

                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.red, lineWidth: 1.5)
                    .frame(width: max(8, viewportRect.width * scale),
                           height: max(8, viewportRect.height * scale))
                    .position(x: viewportRect.midX * scale,
                              y: viewportRect.midY * scale)
            }
            .frame(width: mappedW, height: mappedH, alignment: .topLeading)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .contentShape(Rectangle())
            .onTapGesture { local in
                let canvasPoint = CGPoint(x: local.x / scale, y: local.y / scale)
                onTapPoint(canvasPoint)
            }
            .accessibilityIdentifier("minimap.canvas")

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
