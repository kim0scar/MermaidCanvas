import SwiftUI

// v60.1: iOS-entrypoint = UIKit-livscykel (se main.swift + Orientation.swift) för att kunna
// tvinga igenom orienteringslåset. iOS har därför ingen `@main` här (den bor i main.swift).

#if os(macOS)
// 1.5.7 (Kims order): macOS-entré = ett RIKTIGT fönster (Window), inte en menyrads-popup.
// En MenuBarExtra kan per design inte flyttas/storleksändras/gå i helskärm — Window kan allt tre
// och ger Dock-ikon + standard-menyrad (Arkiv/Redigera/Fönster). `Window` (ej `WindowGroup`) =
// EN canvas-vy, inga duplicerade fönster, öppnas igen vid Dock-klick. Delar SAMMA ContentView
// (hela hjärnan) med iPhone-appen. LSUIElement togs bort (Info-macOS.plist + project.yml).
@main
struct MermaidCanvasMacApp: App {
    var body: some Scene {
        Window("Visuali2e", id: "main") {
            ContentView()
                // Golv-storlek (min) + rimlig första-start-storlek (ideal). Fönstret är fritt
                // storleksbart över detta; systemets läge (ljust/mörkt) följs (1.5.5).
                .frame(minWidth: 720, idealWidth: 1100, minHeight: 480, idealHeight: 760)
        }
    }
}
#endif
