import Foundation
import SwiftUI

/// Textstil för label inuti en form. Ersätter den gamla bold-toggle:n.
/// Persistas i state-JSON som rawValue, i mermaid som `%% NX style: r1`.
enum TextStyle: String, Codable, CaseIterable, Identifiable {
    case jatte // Jätterubrik — störst (1.5, Kim: R1 var för liten)
    case r1    // Rubrik 1
    case r2    // Rubrik 2
    case r3    // Rubrik 3
    case body  // Brödtext — default

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .jatte: return "Jätterubrik"
        case .r1:    return "Rubrik 1"
        case .r2:    return "Rubrik 2"
        case .r3:    return "Rubrik 3"
        case .body:  return "Brödtext"
        }
    }

    /// Basstorlek i pt (multipliceras med shape.sizeMultiplier). 1.5: 5 tydliga steg.
    var fontSize: CGFloat {
        switch self {
        case .jatte: return 40
        case .r1:    return 30
        case .r2:    return 24
        case .r3:    return 18
        case .body:  return 14
        }
    }

    var fontWeight: Font.Weight {
        switch self {
        case .jatte: return .bold
        case .r1:    return .bold
        case .r2:    return .semibold
        case .r3:    return .medium
        case .body:  return .regular
        }
    }

    /// CSS-vikt för mermaid.live-rendering (UI-fri sträng → Mermaid-lagret slipper SwiftUI).
    var cssFontWeight: String? {
        switch self {
        case .jatte, .r1: return "bold"
        case .r2:         return "600"
        case .r3:         return "500"
        case .body:       return nil
        }
    }
}
