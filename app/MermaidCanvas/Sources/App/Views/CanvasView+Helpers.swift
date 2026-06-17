import SwiftUI

/// Canvas-interaktionshjälpare (MA spår A steg 6b): auto-scroll vid kant-drag och
/// val av form (jump-link-centrering + container-adoption). Bröts ut ur CanvasView
/// som en extension — samma typ, exakt samma beteende; bara separerad logik från
/// view-body. (canvasContent hålls ihop med flit: dess zIndex-lager är load-bearing.)
extension CanvasView {

    /// v39: Auto-scroll när form dras nära viewport-kant. canvasPoint=nil = avsluta scroll.
    func updateAutoScroll(at canvasPoint: CGPoint?) {
        guard let point = canvasPoint else {
            viewportState.autoScrollVelocity = .zero
            return
        }
        // Beräkna synlig viewport i canvas-koordinater
        let scale = viewportState.zoomScale
        guard scale > 0.001 else { return }
        let visLeft   = viewportState.contentOffset.width / scale
        let visTop    = viewportState.contentOffset.height / scale
        let visRight  = visLeft + viewportState.globalFrame.width / scale
        let visBottom = visTop  + viewportState.globalFrame.height / scale

        let threshold: CGFloat = 80 / scale   // 80 screen-pt tröskel
        let maxSpeed: CGFloat = 300            // scroll-koordinater/sek

        var vx: CGFloat = 0
        var vy: CGFloat = 0
        if point.x < visLeft + threshold   { vx = -maxSpeed * (1 - (point.x - visLeft) / threshold) }
        if point.x > visRight - threshold  { vx =  maxSpeed * (1 - (visRight - point.x) / threshold) }
        if point.y < visTop + threshold    { vy = -maxSpeed * (1 - (point.y - visTop) / threshold) }
        if point.y > visBottom - threshold { vy =  maxSpeed * (1 - (visBottom - point.y) / threshold) }

        viewportState.autoScrollVelocity = CGSize(width: vx, height: vy)
    }

    func handleShapeSelect(id: UUID) {
        if let shape = model.shapes.first(where: { $0.id == id }),
           shape.type == .link,
           let partner = model.partnerLink(for: id) {
            // v34: be ZoomableCanvas centrera på partner-positionen
            centerOnPoint = partner.position
        } else {
            // v60.1: när en container väljs — "adoptera" alla former som ligger inom den
            // NU (explicit childOfContainerId). Annars matchas barn som lades till FÖRE
            // containern bara via position-fallback, och de tappas mitt i en flytt när de
            // hinner glida ut ur containerns (statiska) bounds → "följer inte allt med".
            if let shape = model.shapes.first(where: { $0.id == id }),
               shape.type == .container {
                model.claimChildren(forContainer: id)
            }
            onShapeSelect(id)
        }
    }
}
