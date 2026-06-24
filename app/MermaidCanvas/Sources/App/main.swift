#if os(iOS)
import UIKit

// v60.1: UIKit-livscykel (ersätter SwiftUI WindowGroup) så att appen kan ÄGA sitt fönster
// via SceneDelegate + OrientationLockedHostingController och därmed tvinga igenom
// orienteringslåset. Med WindowGroup gav SwiftUI oss en hosting-controller som rapporterade
// `.all` → låset ignorerades (iOS 26 lät appen följa hårdvaruorienteringen). ContentView är
// oförändrad; bara hur fönstret skapas har bytts. Se Orientation.swift.
// 1.1: hela iOS-entrén bakom #if os(iOS) — macOS-entrén är MenuBarExtra i MermaidCanvasApp.swift.
UIApplicationMain(
    CommandLine.argc,
    CommandLine.unsafeArgv,
    nil,
    NSStringFromClass(AppDelegate.self)
)
#endif
