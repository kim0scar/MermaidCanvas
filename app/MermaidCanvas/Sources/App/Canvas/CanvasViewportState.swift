import SwiftUI
import Combine

/// v34 — Synkroniserad spegel av UIScrollView's pan/zoom-state.
///
/// `ZoomableCanvas`'s Coordinator uppdaterar dessa SYNKRONT i scrollViewDidScroll
/// och scrollViewDidZoom — inte via DispatchQueue.async. Det betyder att när
/// en manuell chip-drag-gesture beräknar drop-position vid `.onEnded`, läser den
/// EXAKT samma värde som UIScrollView visar just nu. Ingen race-condition.
///
/// Detta löser den fundamentala bugg som plågade v22–v33: drop-koordinaten
/// räknades mot stale `@Published`-spegel som inte uppdaterades synkront med
/// gesten.
@MainActor
final class CanvasViewportState: ObservableObject {
    /// UIScrollView's contentOffset. Speglat live från delegate-callbacks.
    @Published var contentOffset: CGSize = .zero

    /// UIScrollView's zoomScale. Speglat live från delegate-callbacks.
    @Published var zoomScale: CGFloat = 1.0

    /// UIScrollView's frame i SCREEN-koordinater. Behövs för att konvertera
    /// finger-position (global) → canvas-koord. Uppdateras i layoutSubviews.
    @Published var globalFrame: CGRect = .zero

    /// Konvertera en global skärm-punkt (finger-position) till canvas-koordinater.
    /// Returnerar nil om globalFrame inte är satt än (race vid första render).
    func canvasPoint(forGlobal global: CGPoint) -> CGPoint? {
        guard globalFrame != .zero else { return nil }
        let local = CGPoint(
            x: global.x - globalFrame.minX,
            y: global.y - globalFrame.minY
        )
        // contentOffset är hur mycket scrollViewen är scrollad — vi LÄGGER till
        // det till local-koord och delar med zoom för att få canvas-koord.
        let canvasX = (local.x + contentOffset.width) / zoomScale
        let canvasY = (local.y + contentOffset.height) / zoomScale
        return CGPoint(x: canvasX, y: canvasY)
    }

    /// Är denna globala punkt inom canvas-viewporten?
    func isInsideCanvas(_ global: CGPoint) -> Bool {
        guard globalFrame != .zero else { return false }
        return globalFrame.contains(global)
    }

    /// Canvas-koordinat för MITTEN av nuvarande synliga viewport.
    var visibleCenterInCanvas: CGPoint {
        guard zoomScale > 0.0001 else { return CGPoint(x: 2000, y: 2000) }
        let scrollCenterX = contentOffset.width + globalFrame.width / 2
        let scrollCenterY = contentOffset.height + globalFrame.height / 2
        return CGPoint(x: scrollCenterX / zoomScale, y: scrollCenterY / zoomScale)
    }

    /// v39: auto-scroll-hastighet (scroll-koordinater per sekund) begärd av shape-drag.
    /// ZoomableCanvas läser detta och rullar UIScrollView. Noll = ingen scroll.
    @Published var autoScrollVelocity: CGSize = .zero
}

/// v34 — Tillstånd för aktiv chip-drag.
///
/// När användaren drar en form-chip från toolbarn:
/// - `activeType` sätts till den typ som dras
/// - `globalLocation` uppdateras kontinuerligt med finger-position
///
/// ContentView ritar en flytande chip-preview vid `globalLocation` så Kim ser
/// var han släpper. Vid drag-end läser vi `globalLocation` synkront och
/// konverterar till canvas-koord via `CanvasViewportState.canvasPoint`.
@MainActor
final class ChipDragState: ObservableObject {
    @Published var activeType: ShapeType? = nil
    @Published var globalLocation: CGPoint = .zero
}
