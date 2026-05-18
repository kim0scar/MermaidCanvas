import Foundation
import SwiftUI

/// Textstil för label inuti en form. Ersätter den gamla bold-toggle:n.
/// Persistas i state-JSON som rawValue, i mermaid som `%% NX style: r1`.
enum TextStyle: String, Codable, CaseIterable, Identifiable {
    case r1   // Rubrik 1 — stor
    case r2   // Rubrik 2 — medel
    case r3   // Rubrik 3 — liten rubrik
    case body // Brödtext — default

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .r1:   return "Rubrik 1"
        case .r2:   return "Rubrik 2"
        case .r3:   return "Rubrik 3"
        case .body: return "Brödtext"
        }
    }

    /// Basstorlek i pt (multipliceras med shape.sizeMultiplier).
    var fontSize: CGFloat {
        switch self {
        case .r1:   return 20
        case .r2:   return 17
        case .r3:   return 14
        case .body: return 13
        }
    }

    var fontWeight: Font.Weight {
        switch self {
        case .r1:   return .bold
        case .r2:   return .semibold
        case .r3:   return .medium
        case .body: return .regular
        }
    }
}
