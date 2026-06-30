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
                // 1.5.5 (Kims fynd): tap på tom yta i markeringsläge — nollställ markeringen;
                // är den redan tom → lämna läget. (Ersätter den borttagna dubbeltryck-vägen ut.)
                .onTapGesture {
                    if model.multiSelection.isEmpty {
                        model.toggleMarkerMode()
                    } else {
                        model.multiSelection = []
                    }
                }
                .accessibilityIdentifier("marker.overlay")

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
        // v50.3 R5: minimumDistance höjd från 8 → 20 så att UIScrollView's
        // egen pan-gesture (10 screen-pt) inte vinner och stjäl marquee-draget
        // vid låg zoom. Tap-pass-through fungerar fortfarande.
        DragGesture(minimumDistance: 20, coordinateSpace: .named("canvas"))
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
        // v50.3 R5: bbox-intersect istället för center-baserad hitTest.
        // Tidigare missades stora former vars CENTER låg utanför rect även
        // om större delen av formen syntes inom. Nu fångas alla former som
        // OVERLAPPAR rect, vilket är användarens förväntning.
        let inside = model.shapes.filter { shape in
            let w = ShapeGeometry.width(for: shape)
            let h = ShapeGeometry.height(for: shape)
            let bbox = CGRect(x: shape.position.x - w / 2,
                              y: shape.position.y - h / 2,
                              width: w, height: h)
            return rect.intersects(bbox)
        }.map { $0.id }
        model.multiSelection = Set(inside)
    }
}
