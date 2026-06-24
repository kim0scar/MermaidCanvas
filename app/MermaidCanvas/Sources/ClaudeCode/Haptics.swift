import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// 1.1 dual-platform: plattforms-shim för haptik.
/// iOS = riktig feedback (oförändrat beteende); macOS = no-op.
/// Centraliserar `#if`-vakten så delade vyer slipper importera UIKit.
enum Haptics {
    static func success() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    static func error() {
        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        #endif
    }

    enum ImpactStyle { case light, medium }

    static func impact(_ style: ImpactStyle = .light) {
        #if canImport(UIKit)
        let s: UIImpactFeedbackGenerator.FeedbackStyle = (style == .medium) ? .medium : .light
        UIImpactFeedbackGenerator(style: s).impactOccurred()
        #endif
    }
}
