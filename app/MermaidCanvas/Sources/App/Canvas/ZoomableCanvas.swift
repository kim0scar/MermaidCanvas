import SwiftUI
import UIKit

/// v34 — UIScrollView-wrap för canvasen. Ersätter ren-SwiftUI-implementationen
/// med transformEffect + DragGesture + MagnifyGesture som hade tre grundbuggar:
///
/// - Drop landade fel (race-condition mellan @Published offset/scale och drop-event)
/// - Pan var riktningsskev (clamp-logik gav asymmetrisk UX)
/// - Zoom driftade (MagnifyGesture.value.startLocation invariant under gesten)
///
/// UIScrollView löser alla tre gratis:
/// - Pinch-to-zoom är ankrad där fingrarna är (UIPinchGestureRecognizer sedan iOS 3.2)
/// - Pan är symmetrisk åt alla håll
/// - `.dropDestination` ger canvas-lokala koordinater direkt → drop är deterministisk
///
/// API:
/// ```
/// ZoomableCanvas(
///     contentSize: CGSize(width: 4000, height: 4000),
///     zoomPercent: $zoomPercent,
///     resetTrigger: resetTrigger,
///     centerOnPoint: $centerOnPoint
/// ) {
///     canvasContent   // SwiftUI-content som ligger inuti scrollviewen
/// }
/// ```
struct ZoomableCanvas<Content: View>: UIViewRepresentable {
    /// Storlek på den vita canvas-papperytan (i canvas-koordinater).
    let contentSize: CGSize

    /// Rapporterar aktuell zoom som heltalsprocent (toolbar visar detta).
    @Binding var zoomPercent: Int

    /// Rapporterar aktuell zoom som CGFloat. Används av selection/connection-handtag
    /// för att skala stroke/linewidth invers så de inte blir för stora/små vid zoom.
    @Binding var zoomScale: CGFloat

    /// Räknare som ökar varje gång toolbar vill nollställa zoom (fit-screen).
    let resetTrigger: Int

    /// Bindning för att centrera på en specifik canvas-punkt (t.ex. jump-link partner).
    /// Sätts till nil när centreringen är klar.
    @Binding var centerOnPoint: CGPoint?

    /// SwiftUI-content som hostas inuti scrollviewen.
    let content: Content

    init(
        contentSize: CGSize,
        zoomPercent: Binding<Int>,
        zoomScale: Binding<CGFloat>,
        resetTrigger: Int,
        centerOnPoint: Binding<CGPoint?>,
        @ViewBuilder content: () -> Content
    ) {
        self.contentSize = contentSize
        self._zoomPercent = zoomPercent
        self._zoomScale = zoomScale
        self.resetTrigger = resetTrigger
        self._centerOnPoint = centerOnPoint
        self.content = content()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            hostingController: UIHostingController(rootView: content),
            zoomPercent: $zoomPercent,
            zoomScale: $zoomScale,
            centerOnPoint: $centerOnPoint
        )
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 4.0
        scrollView.minimumZoomScale = 0.1   // beräknas i layout
        scrollView.bouncesZoom = true
        scrollView.bounces = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.backgroundColor = .systemGray5
        scrollView.decelerationRate = .normal
        // För XCUITest: så testerna kan hitta canvas-elementet via otherElements["canvas"]
        // ELLER scrollViews["canvas"]. UIScrollView är av default ett accessibility-element.
        scrollView.accessibilityIdentifier = "canvas"

        // Lägg den hostade SwiftUI-vyn som content
        let hosted = context.coordinator.hostingController.view!
        hosted.translatesAutoresizingMaskIntoConstraints = true
        hosted.frame = CGRect(origin: .zero, size: contentSize)
        hosted.backgroundColor = .clear
        scrollView.contentSize = contentSize
        scrollView.addSubview(hosted)

        // Initial fit + centrera när bounds finns
        DispatchQueue.main.async {
            context.coordinator.fitToScreen(scrollView: scrollView, animated: false)
        }

        // Stötta UIDropInteraction (UIScrollView blockerar inte drops av default,
        // men vi sätter det explicit för att vara säker).
        scrollView.isUserInteractionEnabled = true
        hosted.isUserInteractionEnabled = true

        // Spara referenser
        context.coordinator.scrollView = scrollView
        context.coordinator.contentSize = contentSize
        context.coordinator.lastResetTrigger = resetTrigger

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        // Uppdatera SwiftUI-contenten (rootView är värdetyp — varje gång body
        // renderas i parent skapas ny content, så vi måste reassigna här)
        context.coordinator.hostingController.rootView = content

        // Triggat reset?
        if resetTrigger != context.coordinator.lastResetTrigger {
            context.coordinator.lastResetTrigger = resetTrigger
            context.coordinator.fitToScreen(scrollView: scrollView, animated: true)
        }

        // Begäran om att centrera på en specifik canvas-punkt?
        if let p = centerOnPoint {
            context.coordinator.center(on: p, scrollView: scrollView, animated: true)
            DispatchQueue.main.async {
                self.centerOnPoint = nil
            }
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UIScrollViewDelegate {
        let hostingController: UIHostingController<Content>
        @Binding var zoomPercent: Int
        @Binding var zoomScale: CGFloat
        @Binding var centerOnPoint: CGPoint?
        weak var scrollView: UIScrollView?
        var contentSize: CGSize = .zero
        var lastResetTrigger: Int = 0
        private var hasDoneInitialFit = false

        init(
            hostingController: UIHostingController<Content>,
            zoomPercent: Binding<Int>,
            zoomScale: Binding<CGFloat>,
            centerOnPoint: Binding<CGPoint?>
        ) {
            self.hostingController = hostingController
            self._zoomPercent = zoomPercent
            self._zoomScale = zoomScale
            self._centerOnPoint = centerOnPoint
            super.init()
            // Gör hostingController-vyn transparent och utan auto-resize-magi
            hostingController.view.backgroundColor = .clear
        }

        // UIScrollViewDelegate

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            hostingController.view
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            // Rapportera zoom till SwiftUI (toolbar visar procent)
            let percent = Int((scrollView.zoomScale * 100).rounded())
            let scale = scrollView.zoomScale
            if percent != zoomPercent || abs(scale - zoomScale) > 0.0001 {
                DispatchQueue.main.async {
                    if percent != self.zoomPercent { self.zoomPercent = percent }
                    if abs(scale - self.zoomScale) > 0.0001 { self.zoomScale = scale }
                }
            }
            // Håll content centrerat när det är mindre än viewport
            centerContentIfNeeded(scrollView: scrollView)
        }

        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            centerContentIfNeeded(scrollView: scrollView)
        }

        // Hjälp-metoder

        /// Beräkna min-zoom så canvasen alltid fyller minst en dimension av viewporten
        /// (Apple Maps/Photos-stil). Då uppstår aldrig grå "tomma" områden runt canvasen —
        /// max på en led i taget, beroende på vilken kant användaren panorerar mot.
        ///
        /// Startzoom = 1.0 (naturlig storlek) om min-zoom är mindre, annars min-zoom.
        /// Centrera på canvas-mitten så Kim ser canvasen i naturlig storlek vid start.
        func fitToScreen(scrollView: UIScrollView, animated: Bool) {
            let viewport = scrollView.bounds.size
            guard viewport.width > 0, viewport.height > 0 else { return }
            let xScale = viewport.width / contentSize.width
            let yScale = viewport.height / contentSize.height
            // max så canvasen alltid täcker minst en dimension — inget grått alla sidor
            let minScale = max(xScale, yScale)
            scrollView.minimumZoomScale = minScale
            // Startzoom: 1.0 om möjligt, annars min-scale
            let initialScale: CGFloat = max(1.0, minScale)
            scrollView.setZoomScale(initialScale, animated: animated)
            // Centrera på canvas-mitten
            let centerCanvas = CGPoint(x: contentSize.width / 2,
                                       y: contentSize.height / 2)
            center(on: centerCanvas, scrollView: scrollView, animated: animated)
        }

        /// Centrera scrollviewens content när det är mindre än viewport
        /// (annars är det inget grått runt — papperet fyller hela skärmen).
        func centerContentIfNeeded(scrollView: UIScrollView) {
            let viewport = scrollView.bounds.size
            let scaled = scrollView.contentSize
            let hostedView = hostingController.view!
            var frame = hostedView.frame
            frame.origin.x = scaled.width < viewport.width
                ? (viewport.width - scaled.width) / 2
                : 0
            frame.origin.y = scaled.height < viewport.height
                ? (viewport.height - scaled.height) / 2
                : 0
            hostedView.frame = frame
        }

        /// Centrera på en specifik canvas-punkt (i canvas-koordinater).
        func center(on point: CGPoint, scrollView: UIScrollView, animated: Bool) {
            let scale = scrollView.zoomScale
            let viewport = scrollView.bounds.size
            // Konvertera canvas-punkt till content-punkt (i scrollview-koord)
            let target = CGPoint(
                x: point.x * scale - viewport.width / 2,
                y: point.y * scale - viewport.height / 2
            )
            // Clamp till tillåtet område
            let maxX = max(0, scrollView.contentSize.width - viewport.width)
            let maxY = max(0, scrollView.contentSize.height - viewport.height)
            let clamped = CGPoint(
                x: min(max(0, target.x), maxX),
                y: min(max(0, target.y), maxY)
            )
            scrollView.setContentOffset(clamped, animated: animated)
        }

        /// Initial fit som körs när scrollViewens bounds är kända.
        func initialFitIfNeeded(scrollView: UIScrollView) {
            guard !hasDoneInitialFit else { return }
            guard scrollView.bounds.width > 0 else { return }
            hasDoneInitialFit = true
            fitToScreen(scrollView: scrollView, animated: false)
        }
    }
}
