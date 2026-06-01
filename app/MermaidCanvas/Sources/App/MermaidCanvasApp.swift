import SwiftUI

@main
struct MermaidCanvasApp: App {
    // v51.2: AppDelegate krävs för att styra tillåten orientering (porträtt/landskap).
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
