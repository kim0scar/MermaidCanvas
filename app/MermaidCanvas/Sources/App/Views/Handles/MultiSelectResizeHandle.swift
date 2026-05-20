import SwiftUI

/// v43: Samlat resize-handtag som visas i nedre höger hörnet av multi-select bounding box.
/// Drag → proportionerlig skalning av alla markerade former kring deras centrum.
struct MultiSelectResizeHandle: View {
    @ObservedObject var model: CanvasModel
    let canvasScale: CGFloat
    @State private var dragStartScale: CGFloat? = nil
    @State private var startBoundingBox: CGRect? = nil

    var body: some View {
        if let bbox = model.selectionBoundingBox(), model.multiSelection.count >= 1 {
            let handleSize: CGFloat = max(28, 32 / canvasScale)
            let pos = CGPoint(x: bbox.maxX + handleSize * 0.3,
                              y: bbox.maxY + handleSize * 0.3)
            ZStack {
                Circle().fill(Color.white)
                    .overlay(Circle().stroke(Color.accentColor, lineWidth: 2.5))
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: handleSize * 0.42, weight: .bold))
                    .foregroundStyle(Color.accentColor)
            }
            .frame(width: handleSize, height: handleSize)
            .position(pos)
            .gesture(
                DragGesture(coordinateSpace: .named("canvas"))
                    .onChanged { v in
                        if startBoundingBox == nil {
                            startBoundingBox = bbox
                            dragStartScale = 1.0
                        }
                        guard let start = startBoundingBox else { return }
                        // Räkna ut ny scale från diagonal-avstånd
                        let center = CGPoint(x: start.midX, y: start.midY)
                        let startCorner = CGPoint(x: start.maxX, y: start.maxY)
                        let startDist = hypot(startCorner.x - center.x,
                                              startCorner.y - center.y)
                        let curDist = hypot(v.location.x - center.x,
                                            v.location.y - center.y)
                        guard startDist > 1 else { return }
                        let totalScale = max(0.1, min(5.0, curDist / startDist))
                        // Delta-scale från förra applicering
                        let lastScale = dragStartScale ?? 1.0
                        let deltaScale = totalScale / lastScale
                        model.resizeSelection(scale: deltaScale)
                        dragStartScale = totalScale
                    }
                    .onEnded { _ in
                        startBoundingBox = nil
                        dragStartScale = nil
                    }
            )
            .accessibilityIdentifier("multiselect.resize")
        }
    }
}
