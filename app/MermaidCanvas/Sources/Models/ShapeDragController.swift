import SwiftUI
import os

/// v27: OSLog-kategori för drag-out-diagnostik. Läs på Mac med:
/// xcrun devicectl device log --device F271CF8E-... --predicate 'subsystem == "com.kimlundqvist.mermaidcanvas" AND category == "drag"'
let dragLog = Logger(subsystem: "com.kimlundqvist.mermaidcanvas", category: "drag")

/// v26: Egen drag-controller — ersätter Apple's Transferable/.draggable/.dropDestination
/// som visade sig opålitlig på iPhone (gesture-konflikter mellan pan/zoom/draggable).
///
/// Flöde:
/// 1. Toolbar-chip startar DragGesture(coordinateSpace: .global). På .onChanged
///    sätter den `activeType` och uppdaterar `globalLocation`.
/// 2. ContentView visar en flytande chip-preview vid `globalLocation`.
/// 3. CanvasView mäter sin egen globala frame via PreferenceKey och uppdaterar
///    `canvasGlobalFrame` här.
/// 4. På .onEnded: om släpp:et ligger inom `canvasGlobalFrame` → konvertera
///    global→canvas-koordinat och anropa addShape. Annars: om totalDistance < 8pt
///    → behandla som tap (lägg form i canvas-mitten).
@MainActor
final class ShapeDragController: ObservableObject {
    @Published var activeType: ShapeType? = nil
    @Published var globalLocation: CGPoint = .zero
    @Published var canvasGlobalFrame: CGRect = .zero

    /// Pan/zoom-state som CanvasView speglar hit så ContentView kan konvertera
    /// global → canvas-koordinat utan att läsa CanvasView's private state.
    @Published var canvasOffset: CGSize = .zero
    @Published var canvasScale: CGFloat = 1.0
    /// v28: viewport-storlek (pt) — fylls från CanvasView. Används av minikartan.
    @Published var viewportSize: CGSize = .zero
    /// v28: trigger för CanvasView att centrera på en specifik canvas-punkt.
    @Published var requestedCenterPoint: CGPoint? = nil

    /// Översätt en global skärm-punkt till canvas-koordinatsystemet.
    /// v27: om frame är .zero (race-condition vid första render) använd lokal = global
    /// så drop:n inte tappas helt — bättre att lägga form i fel position än att tappa den.
    func canvasPoint(forGlobal global: CGPoint) -> CGPoint {
        let originX = canvasGlobalFrame != .zero ? canvasGlobalFrame.minX : 0
        let originY = canvasGlobalFrame != .zero ? canvasGlobalFrame.minY : 0
        let local = CGPoint(
            x: global.x - originX,
            y: global.y - originY
        )
        return CGPoint(
            x: (local.x - canvasOffset.width) / canvasScale,
            y: (local.y - canvasOffset.height) / canvasScale
        )
    }

    /// Sant om global-punkten är inom canvasen.
    /// v27: om frame är .zero (race vid första render) returnera true — annars blockerar
    /// vi drag-end:s som råkar köras innan PreferenceKey hunnit propagera.
    func isInsideCanvas(_ global: CGPoint) -> Bool {
        if canvasGlobalFrame == .zero { return true }
        return canvasGlobalFrame.contains(global)
    }
}

/// PreferenceKey för att rapportera CanvasView's globala frame uppåt
/// till ContentView (som äger dragController).
struct CanvasGlobalFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let v = nextValue()
        if v != .zero { value = v }
    }
}
