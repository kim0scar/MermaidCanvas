import SwiftUI

// 1.1 dual-platform: iOS-bara navigations-modifierare → no-op på macOS (MenuBarExtra
// har ingen navigation-bar). iOS-beteendet är EXAKT som förr.
extension View {
    /// iOS: `navigationBarTitleDisplayMode(.inline)`. macOS: oförändrad.
    func inlineNavTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}
