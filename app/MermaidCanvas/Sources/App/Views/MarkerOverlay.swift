import SwiftUI

/// Overlay som lägger sig ovanpå canvas i marker-mode.
/// Drag på den ritar en markerings-rektangel som väljer alla former inom rektangeln.
struct MarkerOverlay: View {
    @ObservedObject var model: CanvasModel
    let canvasContentSize: CGSize

    @State private var startCanvas: CGPoint? = nil
    @State private var currentCanvas: CGPoint? = nil

    var body: some View {
        ZStack {
            // v46: Genomskinlig fångst-yta över hela canvasen.
            // Tap-gestures tas INTE upp här — de passerar igenom till underliggande
            // shapes (som hanterar tap i markerMode genom att toggla multiSelection
            // via model.selectShape). Endast drag (>= 10pt) konsumeras för marquee.
            Color.clear
                .contentShape(Rectangle())
                .frame(width: canvasContentSize.width, height: canvasContentSize.height)
                .gesture(dragGesture)

            // Rita markerings-rektangel om vi drar
            if let start = startCanvas, let current = currentCanvas {
                let rect = CGRect(
                    x: min(start.x, current.x),
                    y: min(start.y, current.y),
                    width: abs(current.x - start.x),
                    height: abs(current.y - start.y)
                )
                Rectangle()
                    .fill(Color.accentColor.opacity(0.12))
                    .overlay(
                        Rectangle().stroke(Color.accentColor,
                                           style: StrokeStyle(lineWidth: 1.5,
                                                              dash: [4, 3]))
                    )
                    .frame(width: rect.width, height: rect.height)
                    .position(x: rect.midX, y: rect.midY)
                    .allowsHitTesting(false)
            }
        }
    }

    private var dragGesture: some Gesture {
        // v46: minimumDistance > 0 så att taps passerar genom till shapes
        DragGesture(minimumDistance: 8, coordinateSpace: .named("canvas"))
            .onChanged { v in
                if startCanvas == nil {
                    startCanvas = v.startLocation
                }
                currentCanvas = v.location
                updateSelection()
            }
            .onEnded { _ in
                startCanvas = nil
                currentCanvas = nil
            }
    }

    private func updateSelection() {
        guard let start = startCanvas, let current = currentCanvas else { return }
        let rect = CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )
        let inside = model.shapes
            .filter { rect.contains($0.position) }
            .map { $0.id }
        model.multiSelection = Set(inside)
    }
}
