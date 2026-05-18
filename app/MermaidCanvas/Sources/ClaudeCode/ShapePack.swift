import Foundation

/// v27/v31: Form-paket = Kims egna uppsättningar av kategorier som kan slås på/av i farten.
/// Oberoende av plattform — t.ex. "Prompt-Process" kan vara aktivt i en Blank canvas.
/// `.basic` är alltid på och kan inte stängas av.
/// v31: rensning — `.basic` + `.ui` + ny `.promptProcess`. Tidigare `.roadmap/.architecture/.flow`
/// borttagna från UI men kvar i enum för Codable-bakåtkompatibilitet.
enum ShapePack: String, Codable, CaseIterable, Identifiable {
    case basic
    case ui
    /// v31: Claude/AI-agent-flow (n8n-inspirerat) — subagent, prompt, skill, tool, memory, output.
    case promptProcess
    /// v31: legacy (kvar för fil-bakåtkompat — migreras till .note vid öppning)
    case roadmap
    case architecture
    case flow

    var id: String { rawValue }

    /// v31: pack:er som visas i form-pack-rad. .basic är alltid på, legacy är dolda.
    static var userToggleable: [ShapePack] { [.ui, .promptProcess] }

    var displayName: String {
        switch self {
        case .basic: return "Basformer"
        case .ui: return "UI"
        case .promptProcess: return "Prompt-Process"
        case .roadmap: return "Roadmap (utfasad)"
        case .architecture: return "Arkitektur (utfasad)"
        case .flow: return "Flow (utfasad)"
        }
    }

    var systemImage: String {
        switch self {
        case .basic: return "square.on.circle"
        case .ui: return "iphone"
        case .promptProcess: return "brain.head.profile"
        case .roadmap: return "map"
        case .architecture: return "rectangle.3.group"
        case .flow: return "arrow.triangle.branch"
        }
    }

    var hint: String {
        switch self {
        case .basic: return "Cirkel, rektangel, diamant, pill, text, tabell, länk, lös linje/pil."
        case .ui: return "UI-element, zoner, overlays."
        case .promptProcess: return "Subagents, prompter, skills, tools, memory, output (Claude/agent-flow)."
        case .roadmap, .architecture, .flow: return "Utfasad i v31 — formerna migreras till anteckning."
        }
    }

    /// Vilka kategorier hör till detta paket?
    var categories: [ShapeCategory] {
        switch self {
        case .basic: return []
        case .ui: return [.ui, .zone, .overlay]
        case .promptProcess: return [.subagent, .prompt, .skill, .tool, .memory, .output]
        case .roadmap, .architecture, .flow: return []  // v31: tomt
        }
    }

    /// Default-kategori när paketet är aktivt och användaren skapar en ny form.
    var defaultCategory: ShapeCategory? {
        switch self {
        case .basic: return nil
        case .ui: return .ui
        case .promptProcess: return .subagent
        case .roadmap, .architecture, .flow: return nil
        }
    }
}

extension ShapePack {
    /// Bakåtkomp: mappa legacy SpecType → tillhörande ShapePack.
    /// v31: roadmap/architecture/flow returnerar nil (utfasade).
    static func from(legacySpecType: SpecType) -> ShapePack? {
        switch legacySpecType {
        case .ui: return .ui
        case .roadmap, .architecture, .flow, .godot, .general: return nil
        }
    }
}
