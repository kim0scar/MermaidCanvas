import Foundation

/// v27: Form-paket = Kims egna uppsättningar av kategorier som kan slås på/av i farten.
/// Oberoende av plattform — t.ex. "Arkitektur" kan vara aktivt i en Blank canvas.
/// `.basic` är alltid på och kan inte stängas av.
enum ShapePack: String, Codable, CaseIterable, Identifiable {
    case basic         // basformer: cirkel, rektangel, diamant, text, tabell, länk (alltid på)
    case ui            // iPhone UI: skärmar, knappar, zoner
    case roadmap       // now/next/later, milstolpar, blockers
    case architecture  // moduler, mappar, filer, services
    case flow          // input → router → agent → tool → memory → output

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .basic: return "Basformer"
        case .ui: return "UI"
        case .roadmap: return "Roadmap"
        case .architecture: return "Arkitektur"
        case .flow: return "Flow"
        }
    }

    var systemImage: String {
        switch self {
        case .basic: return "square.on.circle"
        case .ui: return "iphone"
        case .roadmap: return "map"
        case .architecture: return "rectangle.3.group"
        case .flow: return "arrow.triangle.branch"
        }
    }

    var hint: String {
        switch self {
        case .basic: return "Cirkel, rektangel, diamant, text, tabell, länk."
        case .ui: return "UI-element, zoner, overlays."
        case .roadmap: return "Features, milstolpar, blockers, future."
        case .architecture: return "Mappar, filer, moduler, services, data."
        case .flow: return "Input, agent, tool, router, memory, output."
        }
    }

    /// Vilka kategorier hör till detta paket?
    var categories: [ShapeCategory] {
        switch self {
        case .basic: return []  // basformer har ingen egen kategori (använder .note / aktiverade packs)
        case .ui: return [.ui, .zone, .overlay]
        case .roadmap: return [.feat, .milestone, .blocker, .future]
        case .architecture: return [.folder, .file, .module, .service, .data]
        case .flow: return [.input, .agent, .tool, .router, .memory, .output]
        }
    }

    /// Default-kategori när paketet är aktivt och användaren skapar en ny form.
    var defaultCategory: ShapeCategory? {
        switch self {
        case .basic: return nil
        case .ui: return .ui
        case .roadmap: return .feat
        case .architecture: return .module
        case .flow: return .agent
        }
    }
}

extension ShapePack {
    /// Bakåtkomp: mappa legacy SpecType → tillhörande ShapePack (om finns).
    static func from(legacySpecType: SpecType) -> ShapePack? {
        switch legacySpecType {
        case .ui: return .ui
        case .roadmap: return .roadmap
        case .architecture: return .architecture
        case .flow: return .flow
        case .godot, .general: return nil
        }
    }
}
