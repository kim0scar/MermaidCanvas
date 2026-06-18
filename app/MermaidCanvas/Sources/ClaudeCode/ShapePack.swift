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
    /// v67: n8n-paket — flödesnoderna (Input/Agent/Verktyg/Router/Memory/Output)
    /// flyttade hit från Former-raden (Kims fynd: "ha n8n som paket-typ").
    case n8n
    /// Steg 8: Skillflöde — ersätter n8n + Prompt-Process. Claude Code-byggstenar för att
    /// SKISSA en skill visuellt (Subagent/Tool/MCP/Plugin/Skill-container/Input/Output/Fil).
    case skillFlow
    /// v31: legacy (kvar för fil-bakåtkompat — migreras till .note vid öppning)
    case roadmap
    case architecture
    case flow

    var id: String { rawValue }

    /// v31: pack:er som visas i form-pack-rad. .basic är alltid på, legacy är dolda.
    /// Steg 8: n8n + Prompt-Process ersatta av Skillflöde (cases kvar för fil-bakåtkompat).
    static var userToggleable: [ShapePack] { [.ui, .skillFlow] }

    var displayName: String {
        switch self {
        case .basic: return "Basformer"
        case .ui: return "UI"
        case .promptProcess: return "Prompt-Process"
        case .n8n: return "n8n"
        case .skillFlow: return "Skillflöde"
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
        case .n8n: return "arrow.triangle.branch"
        case .skillFlow: return "point.3.filled.connected.trianglepath.dotted"
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
        case .n8n: return "Hel skill-kedja: Input, Skill, Subagent, Agent, Verktyg, Router, Grind, Manual, Script, MD-fil, Bevis, Prompt, Output."
        case .skillFlow: return "Skissa en skill: Input, Skill-container, Subagent, Tool, MCP, Plugin, MD-fil, Excel-fil, Output."
        case .roadmap, .architecture, .flow: return "Utfasad i v31 — formerna migreras till anteckning."
        }
    }

    /// Vilka kategorier hör till detta paket?
    var categories: [ShapeCategory] {
        switch self {
        case .basic: return []
        case .ui: return [.ui, .zone, .overlay]
        case .promptProcess: return [.subagent, .prompt, .skill, .tool, .memory, .output]
        case .n8n: return [.input, .skill, .subagent, .agent, .tool, .router, .gate, .manual, .script, .memory, .evidence, .prompt, .output]
        case .skillFlow: return [.input, .skill, .subagent, .tool, .mcp, .plugin, .fileMarkdown, .fileExcel, .output]
        case .roadmap, .architecture, .flow: return []  // v31: tomt
        }
    }

    /// Default-kategori när paketet är aktivt och användaren skapar en ny form.
    var defaultCategory: ShapeCategory? {
        switch self {
        case .basic: return nil
        case .ui: return .ui
        case .promptProcess: return .subagent
        case .n8n: return .input
        case .skillFlow: return .input
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
