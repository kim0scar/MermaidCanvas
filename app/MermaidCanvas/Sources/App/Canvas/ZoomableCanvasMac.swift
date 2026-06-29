#if os(macOS)
import SwiftUI
import AppKit

/// 1.1 Fas 4 — macOS-tvillingen till iOS-ZoomableCanvas. NSScrollView med magnification
/// (pinch/scroll-zoom + pan) som hostar SAMMA SwiftUI-canvas via NSHostingView.
/// Populerar SAMMA `CanvasViewportState`-kontrakt (zoomScale, contentOffset, globalFrame)
/// som iOS → resten av appen (toolbar, chip-drop, handtag) är oförändrad.
/// Top-left-origin via en flippad documentView så koordinatmattan matchar iOS exakt.

/// Flippad NSView → origin uppe-vänster (som iOS), inte AppKits default nere-vänster.
final class FlippedDocumentView: NSView {
    override var isFlipped: Bool { true }
}

struct ZoomableCanvas<Content: View>: NSViewRepresentable {
    let contentSize: CGSize
    @Binding var zoomPercent: Int
    @Binding var zoomScale: CGFloat
    @ObservedObject var viewportState: CanvasViewportState
    var resetTrigger: Int
    @Binding var centerOnPoint: CGPoint?
    @ViewBuilder var content: () -> Content

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.allowsMagnification = true
        scrollView.minMagnification = 0.1
        scrollView.maxMagnification = 4.0
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.drawsBackground = false

        let doc = FlippedDocumentView(frame: CGRect(origin: .zero, size: contentSize))
        let hosting = NSHostingView(rootView: AnyView(content()))
        hosting.frame = doc.bounds
        hosting.autoresizingMask = [.width, .height]
        doc.addSubview(hosting)
        scrollView.documentView = doc

        let c = context.coordinator
        c.scrollView = scrollView
        c.hosting = hosting
        scrollView.contentView.postsBoundsChangedNotifications = true
        NotificationCenter.default.addObserver(
            c, selector: #selector(Coordinator.boundsChanged),
            name: NSView.boundsDidChangeNotification, object: scrollView.contentView)
        NotificationCenter.default.addObserver(
            c, selector: #selector(Coordinator.boundsChanged),
            name: NSScrollView.didEndLiveMagnifyNotification, object: scrollView)
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let c = context.coordinator
        c.parent = self
        c.hosting?.rootView = AnyView(content())
        if c.lastReset != resetTrigger {
            c.lastReset = resetTrigger
            DispatchQueue.main.async { c.fitToScreen() }
        }
        if let p = centerOnPoint {
            DispatchQueue.main.async { c.center(on: p); centerOnPoint = nil }
        }
        // 1.5.2: synka ALDRIG från ritnings-passet synkront (som iOS-tvillingen).
        // Synkron skrivning till @Published här + saknad likhetskoll i syncViewport
        // gav en oändlig SwiftUI-loop → Mac-appen frös på 94% CPU (1.5.1).
        DispatchQueue.main.async { c.syncViewport() }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    @MainActor final class Coordinator: NSObject {
        var parent: ZoomableCanvas
        weak var scrollView: NSScrollView?
        var hosting: NSHostingView<AnyView>?
        var lastReset: Int = .min
        init(_ p: ZoomableCanvas) { parent = p }

        @objc func boundsChanged() { syncViewport() }

        func syncViewport() {
            guard let sv = scrollView else { return }
            let mag = sv.magnification
            let origin = sv.contentView.bounds.origin
            // 1.5.2: likhetskoll på VARJE @Published/@Binding (som iOS-tvillingen,
            // ZoomableCanvas.syncViewportState). @Published saknar inbyggd likhetskoll
            // → skriv bara när värdet faktiskt ändrats, annars evig omritnings-loop.
            if abs(parent.viewportState.zoomScale - mag) > 0.0001 {
                parent.viewportState.zoomScale = mag
            }
            let newOffset = CGSize(width: origin.x * mag, height: origin.y * mag)
            if parent.viewportState.contentOffset != newOffset {
                parent.viewportState.contentOffset = newOffset
            }
            if let win = sv.window, let winContent = win.contentView {
                let inWin = sv.convert(sv.bounds, to: nil)
                let topLeftY = winContent.bounds.height - inWin.maxY   // flippa till top-left
                let newFrame = CGRect(x: inWin.minX, y: topLeftY,
                                      width: inWin.width, height: inWin.height)
                if parent.viewportState.globalFrame != newFrame {
                    parent.viewportState.globalFrame = newFrame
                }
            }
            if abs(parent.zoomScale - mag) > 0.0001 { parent.zoomScale = mag }
            let newPercent = Int((mag * 100).rounded())
            if parent.zoomPercent != newPercent { parent.zoomPercent = newPercent }
        }

        func fitToScreen() {
            guard let sv = scrollView else { return }
            let vp = sv.bounds.size
            guard vp.width > 1, vp.height > 1 else { return }
            let sx = vp.width / parent.contentSize.width
            let sy = vp.height / parent.contentSize.height
            sv.magnification = min(max(max(sx, sy), 0.1), 4.0)
            center(on: CGPoint(x: parent.contentSize.width / 2, y: parent.contentSize.height / 2))
        }

        func center(on p: CGPoint) {
            guard let sv = scrollView, let doc = sv.documentView else { return }
            let visible = sv.contentView.bounds.size
            doc.scroll(CGPoint(x: p.x - visible.width / 2, y: p.y - visible.height / 2))
            syncViewport()
        }
    }
}
#endif
