import Foundation

/// v27: En riktig plattform = regelstyrt mål med claude-protokoll + lexicon-sidecar.
/// Skillnad mot ShapePack (form-paket): plattform LÅSER canvasen, packs kan slås på/av fritt.
enum Platform: String, Codable, CaseIterable, Identifiable {
    case blank  // ingen plattform-regelsats; alla form-paketer kan slås på
    case godot  // Godot UI/Scene — sidecar med godot-lexicon

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .blank: return "Blank canvas"
        case .godot: return "Godot"
        }
    }

    var hint: String {
        switch self {
        case .blank: return "Inga plattformsregler — slå på form-paketer du behöver i Lägen-menyn."
        case .godot: return "Godot-spel-scener (.tscn). Lexicon-sidecar för Claude Code skrivs vid Spara."
        }
    }

    var badgeSystemImage: String {
        switch self {
        case .blank: return "square.dashed"
        case .godot: return "gamecontroller"
        }
    }

    /// Intern SpecType för bakåtkomp (iPhone-frame, default-kategori, etc.)
    /// Mappning: .blank → .general (öppen), .godot → .godot.
    var legacySpecType: SpecType {
        switch self {
        case .blank: return .general
        case .godot: return .godot
        }
    }
}
