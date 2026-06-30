import SwiftUI

// v60.1: iOS-entrypoint = UIKit-livscykel (se main.swift + Orientation.swift) för att kunna
// tvinga igenom orienteringslåset. iOS har därför ingen `@main` här (den bor i main.swift).

#if os(macOS)
// 1.1 dual-platform: macOS-entré = menyrads-popup (MenuBarExtra) som hostar SAMMA ContentView.
// Klick på menyrads-ikonen fäller ut canvasen. Delar hela hjärnan med iPhone-appen.
@main
struct MermaidCanvasMacApp: App {
    var body: some Scene {
        MenuBarExtra("Visuali2e", systemImage: "scribble.variable") {
            ContentView()
                // 1.1 Fas 6: användbar popup-storlek (annars blir canvasen en liten ruta).
                .frame(minWidth: 920, idealWidth: 1100, minHeight: 640, idealHeight: 760)
                // 1.5.5 (Kim): följer systemets läge (1.5.4:s tvinga-ljus borttagen) — adaptivt mörkt läge.
        }
        .menuBarExtraStyle(.window)
    }
}
#endif
