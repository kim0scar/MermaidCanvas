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
    var displayName: String { self == .landscape ? "Landskapsläge" : "Porträttläge" }
}

/// AppDelegate som rapporterar nuvarande tillåtna orientering till iOS.
/// `orientationLock` styrs av användarens val (OrientationStore).
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

    /// Sätt nytt läge: spara + uppdatera lås + be scenen rotera direkt.
    @MainActor
    static func set(_ mode: OrientationMode) {
        UserDefaults.standard.set(mode.rawValue, forKey: key)
        AppDelegate.orientationLock = mode.mask
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first else { return }
        scene.requestGeometryUpdate(.iOS(interfaceOrientations: mode.mask)) { _ in }
        scene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
    }
}
