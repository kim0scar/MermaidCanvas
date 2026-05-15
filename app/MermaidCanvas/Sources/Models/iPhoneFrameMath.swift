import Foundation
import CoreGraphics

/// Delad aspect-fit-matte för iPhone-ramen.
/// Används av:
/// - `iPhoneFrameOverlay` för att rita ramen på canvas
/// - `UIScreenRenderer` för att rita preview-iphonen
/// - `MermaidGenerator` för att spara ramens position i canvas-meta
///
/// Genom att ha EN sanningskälla undviker vi att de tre platserna driftar isär.
enum iPhoneFrameMath {
    static let designSize = CGSize(width: 393, height: 852)
    static let aspect: CGFloat = 393.0 / 852.0
    static let padding: CGFloat = 16

    /// Aspect-fit:ar iPhone-ramen i en canvas. Returnerar ramens absoluta CGRect
    /// (origin + storlek) i canvasens koordinatsystem.
    static func frame(in canvas: CGSize) -> CGRect {
        let availW = max(0, canvas.width - padding * 2)
        let availH = max(0, canvas.height - padding * 2)
        let byW = CGSize(width: availW, height: availW / aspect)
        let size = byW.height <= availH ? byW : CGSize(width: availH * aspect, height: availH)
        let x = (canvas.width - size.width) / 2
        let y = (canvas.height - size.height) / 2
        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }
}
