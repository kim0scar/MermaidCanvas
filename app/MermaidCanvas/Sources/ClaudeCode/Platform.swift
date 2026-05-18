import Foundation

/// v27: En riktig plattform = regelstyrt mål med claude-protokoll + lexicon-sidecar.
/// Skillnad mot ShapePack (form-paket): plattform LÅSER canvasen, packs kan slås på/av fritt.
/// v31: Ny plattform `.iosSwiftUI` (native iOS-app, regler kommer fyllas senare).
enum Platform: String, Codable, CaseIterable, Identifiable {
    case blank      // ingen plattform-regelsats; alla form-paketer kan slås på
    case godot      // Godot UI/Scene — sidecar med godot-lexicon
    case iosSwiftUI // v31: native iOS SwiftUI-app — stub-regler

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .blank: return "Blank canvas"
        case .godot: return "Godot"
        case .iosSwiftUI: return "iOS SwiftUI"
        }
    }

    var hint: String {
        switch self {
        case .blank: return "Inga plattformsregler — slå på form-paketer du behöver via Form-paket-knappen."
        case .godot: return "Godot-spel-scener (.tscn). Lexicon-sidecar för Claude Code skrivs vid Spara."
        case .iosSwiftUI: return "Native iOS-app (SwiftUI). Regler kommer fyllas på i kommande version."
        }
    }

    var badgeSystemImage: String {
        switch self {
        case .blank: return "square.dashed"
        case .godot: return "gamecontroller"
        case .iosSwiftUI: return "iphone"
        }
    }

    /// Intern SpecType för bakåtkomp (iPhone-frame, default-kategori, etc.)
    /// Mappning: .blank → .general, .godot → .godot, .iosSwiftUI → .ui.
    var legacySpecType: SpecType {
        switch self {
        case .blank: return .general
        case .godot: return .godot
        case .iosSwiftUI: return .ui
        }
    }
}
