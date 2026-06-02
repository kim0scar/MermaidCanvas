import SwiftUI

// v60.1: App-entrypoint flyttad till UIKit-livscykel (se main.swift + Orientation.swift).
// Den tidigare `@main struct MermaidCanvasApp: App { WindowGroup { ContentView() } }`
// gav SwiftUI kontroll över fönstret och gjorde orienteringslåset omöjligt att tvinga
// igenom. Fönstret skapas nu i SceneDelegate med en låsbar hosting-controller.
//
// Filen behålls avsiktligt utan typer för att undvika dubbel `@main`.
