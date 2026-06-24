import SwiftUI

// 1.1 dual-platform: plattforms-skillnader för ContentView samlade här
// (R5: ContentView.swift är cappad och får bara krympa).
extension ContentView {
    /// macOS saknar size classes → alltid topp-bar. iOS: landskap (compact höjd) → vänster sidebar.
    var isCompactHeight: Bool {
        #if os(iOS)
        vSizeClass == .compact
        #else
        false
        #endif
    }
}
