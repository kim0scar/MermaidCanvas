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

#if os(macOS)
extension ContentView {
    /// Per-launch-flagga: återöppna senaste filen EN gång (ej vid varje popup-öppning).
    static var didRestoreMac = false

    /// macOS: klick på menyrads-ikonen → återöppna Kims senaste canvas (samma iCloud-fil).
    func restoreLastFileMac() {
        guard !ContentView.didRestoreMac else { return }
        ContentView.didRestoreMac = true
        guard !fileManager.hasOpenFile,
              let path = UserDefaults.standard.string(forKey: "mac.lastFilePath"),
              FileManager.default.fileExists(atPath: path) else { return }
        openFile(URL(fileURLWithPath: path))
    }
}
#endif
