#if os(macOS)
import SwiftUI

/// 1.1 dual-platform STUB (Fas 3): macOS-canvasen. Den riktiga NSScrollView-tvillingen
/// (zoom/pan ankrad, chip-drop-precision) byggs i Fas 4. Här räcker en enkel ScrollView
/// så macOS-targeten kompilerar och menyrads-popupen visar canvasen.
/// Samma init-signatur som iOS-ZoomableCanvas → CanvasView/ContentView är oförändrade.
struct ZoomableCanvas<Content: View>: View {
    let contentSize: CGSize
    @Binding var zoomPercent: Int
    @Binding var zoomScale: CGFloat
    @ObservedObject var viewportState: CanvasViewportState
    var resetTrigger: Int
    @Binding var centerOnPoint: CGPoint?
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            content()
                .frame(width: contentSize.width, height: contentSize.height,
                       alignment: .topLeading)
        }
    }
}
#endif
