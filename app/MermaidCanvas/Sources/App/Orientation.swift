#if os(iOS)
import SwiftUI
import UIKit

/// v51.2: användarvalt skärmläge (porträtt/landskap). ÄKTA orientering — UIKit roterar
/// hela koordinatsystemet korrekt, så drag-släpp, UIScrollView-pan/zoom, sheets och
/// tangentbord följer med automatiskt (till skillnad från en manuell rotateEffect).
enum OrientationMode: String, CaseIterable {
    case portrait
    case landscape

    var mask: UIInterfaceOrientationMask {
        self == .landscape ? .landscape : .portrait
    }
    /// v60.1: Konkret orientering för `requestGeometryUpdate`. `.landscape`-masken är
    /// tvetydig (landscapeLeft|landscapeRight) → iOS kan inte avgöra vilket håll skärmen
    /// ska rotera och roterar då inte alls (sim: sidledes innehåll, enhet: svart nedre
    /// halva). En konkret riktning tvingar fram en korrekt fysisk rotation.
    var geometryOrientations: UIInterfaceOrientationMask {
        self == .landscape ? .landscapeRight : .portrait
    }
    var displayName: String { self == .landscape ? "Landskapsläge" : "Porträttläge" }
}

/// v60.1: Hosting-controller som TVINGAR igenom orienteringslåset. Enbart AppDelegate-metoden
/// räcker inte i SwiftUI-livscykeln (iOS 26 lät appen följa hårdvaruorienteringen och
/// ignorera låset). Genom att toppvyns view controller själv rapporterar låst orientering
/// blir snittet entydigt → iOS roterar (eller låser) på riktigt.
final class OrientationLockedHostingController<Content: View>: UIHostingController<Content> {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        OrientationStore.current.mask
    }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        OrientationStore.current == .landscape ? .landscapeRight : .portrait
    }
    override var shouldAutorotate: Bool { true }
}

/// v60.1: SceneDelegate som äger ett SCENE-anslutet fönster med vår låsbara
/// hosting-controller. Ett scene-anslutet fönster (till skillnad från ett manuellt
/// `UIWindow(frame:)`) får iOS orienteringshantering → låset gäller på riktigt.
/// Registreras explicit i Info.plist (UISceneDelegateClassName).
final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        // 1.5.5 (Kim): appen följer systemets ljust/mörkt-läge (1.5.4:s tvinga-ljus borttagen) —
        // canvasen + element är nu adaptiva så mörkt läge fungerar på riktigt.
        window.rootViewController = OrientationLockedHostingController(rootView: ContentView())
        self.window = window
        window.makeKeyAndVisible()
    }
}

/// AppDelegate: rapporterar tillåten orientering till iOS. `orientationLock` styrs av
/// användarens val (OrientationStore). Fönstret skapas i SceneDelegate.
final class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock: UIInterfaceOrientationMask = OrientationStore.current.mask

    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        AppDelegate.orientationLock
    }
}

enum OrientationStore {
    static let key = "orientationMode"

    static var current: OrientationMode {
        OrientationMode(rawValue: UserDefaults.standard.string(forKey: key) ?? "") ?? .portrait
    }

    /// Sätt nytt läge: spara + uppdatera lås + tvinga toppvyn att rotera direkt.
    @MainActor
    static func set(_ mode: OrientationMode) {
        UserDefaults.standard.set(mode.rawValue, forKey: key)
        AppDelegate.orientationLock = mode.mask
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first else { return }
        // Toppvyns VC måste be om ny orientering FÖRE geometry-uppdateringen så att
        // snittet (delegate ∩ VC) pekar på den nya, konkreta orienteringen.
        let rootVC = scene.keyWindow?.rootViewController
            ?? scene.windows.first?.rootViewController
        rootVC?.setNeedsUpdateOfSupportedInterfaceOrientations()
        scene.requestGeometryUpdate(.iOS(interfaceOrientations: mode.geometryOrientations)) { _ in }
    }
}
#endif
