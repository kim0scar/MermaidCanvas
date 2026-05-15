import Foundation
import CoreGraphics

/// Delad iPhone-frame-matte.
/// Två separata användningar:
/// - `canvasFrame(in:)` — fast 393×852pt centrerad i en stor canvas (för canvas-rendering + state-JSON)
/// - `previewFrame(in:)` — aspect-fit i en preview-container (för UIScreenRenderer)
enum iPhoneFrameMath {
    static let designSize = CGSize(width: 393, height: 852)
    static let aspect: CGFloat = 393.0 / 852.0

    /// Fast iPhone-storlek (393×852pt) centrerad i canvasen.
    /// Detta är den ABSOLUTA iPhone-frame-positionen i canvas-koordinatsystemet.
    static func canvasFrame(in canvas: CGSize) -> CGRect {
        let w = designSize.width
        let h = designSize.height
        let x = max(0, (canvas.width - w) / 2)
        let y = max(0, (canvas.height - h) / 2)
        return CGRect(x: x, y: y, width: w, height: h)
    }

    /// Aspect-fit iPhone i en preview-container. Används av UIScreenRenderer.
    static func previewFrame(in container: CGSize) -> CGRect {
        let padding: CGFloat = 16
        let availW = max(0, container.width - padding * 2)
        let availH = max(0, container.height - padding * 2)
        let byW = CGSize(width: availW, height: availW / aspect)
        let size = byW.height <= availH ? byW : CGSize(width: availH * aspect, height: availH)
        let x = (container.width - size.width) / 2
        let y = (container.height - size.height) / 2
        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }

    /// Bakåtkompatibel default (canvas-läge).
    static func frame(in size: CGSize) -> CGRect {
        canvasFrame(in: size)
    }
}
