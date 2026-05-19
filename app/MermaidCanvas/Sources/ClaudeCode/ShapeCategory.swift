import Foundation
import SwiftUI

/// Semantisk kategori per form. Lager 2 i METOD-VISUELL-DIALOG.md.
/// Varje kategori hör till en SpecType och styr färg + classDef-export.
/// Klassnamnet är auktoritativt — färgerna är estetik och kan justeras.
enum ShapeCategory: String, Codable, CaseIterable, Identifiable {
    // UI-läge
    case ui
    case zone
    case note
    case overlay

    // Roadmap-läge
    case feat
    case milestone
    case blocker
    case future

    // Arkitektur-läge
    case folder
    case file
    case module
    case service
    case data

    // Flow-läge (v31: behålls för bakåtkomp men användning fasas ut)
    case input
    case agent
    case tool
    case router
    case memory
    case output

    // v31 Prompt-Process-pack (Claude/AI agent-flow)
    case subagent
    case prompt
    case skill

    // Godot-läge — kategorier matchar Godot UI-noder
    case godot_scene       // .tscn scene-root (motsvarar "Screen")
    case godot_control     // generisk Control-nod
    case godot_container   // VBox/HBox/Margin/PanelContainer
    case godot_panel       // Panel (yta, kort)
    case godot_button      // Button (action)
    case godot_label       // Label (text)
    case godot_signal      // signal-koppling (för flow)
    case godot_script      // GDScript-fil

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ui: return "UI"
        case .zone: return "Zon"
        case .note: return "Note"
        case .overlay: return "Overlay"
        case .feat: return "Feature"
        case .milestone: return "Milestone"
        case .blocker: return "Blocker"
        case .future: return "Future"
        case .folder: return "Mapp"
        case .file: return "Fil"
        case .module: return "Modul"
        case .service: return "Service"
        case .data: return "Data"
        case .input: return "Input"
        case .agent: return "Agent"
        case .tool: return "Tool"
        case .router: return "Router"
        case .memory: return "Memory"
        case .output: return "Output"
        case .godot_scene:     return "Scene"
        case .godot_control:   return "Control"
        case .godot_container: return "Container"
        case .godot_panel:     return "Panel"
        case .godot_button:    return "Button"
        case .godot_label:     return "Label"
        case .godot_signal:    return "Signal"
        case .godot_script:    return "Script"
        case .subagent:        return "Subagent"
        case .prompt:          return "Prompt"
        case .skill:           return "Skill"
        }
    }

    /// Vilken SpecType varje kategori naturligt hör till.
    var specType: SpecType {
        switch self {
        case .ui, .zone, .overlay: return .ui
        case .feat, .milestone, .blocker, .future: return .roadmap
        case .folder, .file, .module, .service, .data: return .architecture
        case .input, .agent, .tool, .router, .memory, .output: return .flow
        case .godot_scene, .godot_control, .godot_container, .godot_panel,
             .godot_button, .godot_label, .godot_signal, .godot_script: return .godot
        case .subagent, .prompt, .skill: return .flow // v31: Prompt-Process delar SpecType.flow
        case .note: return .ui // note är gemensam men hör hem i UI som default
        }
    }

    /// Prefix i mermaid-ID (`ui_N0`, `feat_N1`, etc).
    var idPrefix: String { rawValue }

    /// Vilka kategorier som ska visas i pickern för ett visst läge.
    /// `note` finns med överallt — semantik som "kommentar" är universell.
    static func available(for specType: SpecType) -> [ShapeCategory] {
        let core: [ShapeCategory]
        switch specType {
        case .ui:
            core = [.ui, .zone, .overlay]
        case .roadmap:
            core = [.feat, .milestone, .blocker, .future]
        case .architecture:
            core = [.folder, .file, .module, .service, .data]
        case .flow:
            core = [.input, .agent, .tool, .router, .memory, .output]
        case .godot:
            core = [.godot_scene, .godot_control, .godot_container, .godot_panel,
                    .godot_button, .godot_label, .godot_signal, .godot_script]
        case .general:
            return ShapeCategory.allCases
        }
        return core + [.note]
    }

    // MARK: - Färger

    var fillColor: Color {
        switch self {
        // UI
        case .ui:       return Color(hex: 0x1d4ed8)
        case .zone:     return Color(hex: 0xe5e7eb)
        case .note:     return Color(hex: 0xecfdf3)
        case .overlay:  return Color(hex: 0x0f172a)
        // Roadmap
        case .feat:     return Color(hex: 0x2563eb) // blå
        case .milestone:return Color(hex: 0xf59e0b) // amber
        case .blocker:  return Color(hex: 0xdc2626) // röd
        case .future:   return Color(hex: 0xa78bfa) // lila
        // Arkitektur
        case .folder:   return Color(hex: 0xf3f4f6) // ljus grå
        case .file:     return Color(hex: 0xfafafa) // off-white
        case .module:   return Color(hex: 0x0ea5e9) // cyan
        case .service:  return Color(hex: 0x14b8a6) // teal
        case .data:     return Color(hex: 0x84cc16) // lime
        // Flow
        case .input:    return Color(hex: 0x22c55e) // grön
        case .agent:    return Color(hex: 0x6366f1) // indigo
        case .tool:     return Color(hex: 0xfb923c) // orange
        case .router:   return Color(hex: 0xeab308) // gul
        case .memory:   return Color(hex: 0x8b5cf6) // violett
        case .output:   return Color(hex: 0xef4444) // ljusröd
        // Godot — Godot brand-blå för scene, annars matchat-tema
        case .godot_scene:     return Color(hex: 0x478CBF) // Godot blå
        case .godot_control:   return Color(hex: 0x6B7280) // grå (generisk)
        case .godot_container: return Color(hex: 0xA479D3) // lila (layout)
        case .godot_panel:     return Color(hex: 0xE9ECEF) // beige (yta)
        case .godot_button:    return Color(hex: 0xFFA94D) // orange (action)
        case .godot_label:     return Color(hex: 0xF1F3F5) // ljus (text)
        case .godot_signal:    return Color(hex: 0xFCD34D) // gul (signal)
        case .godot_script:    return Color(hex: 0x4ADE80) // grön (kod)
        // v31 Prompt-Process — distinkta nyanser
        case .subagent:        return Color(hex: 0x7c3aed) // violett (agent-delegering)
        case .prompt:          return Color(hex: 0x10b981) // emerald (text-input)
        case .skill:           return Color(hex: 0xf97316) // orange (kapacitet)
        }
    }

    var strokeColor: Color {
        switch self {
        case .ui:       return Color(hex: 0x1e293b)
        case .zone:     return Color(hex: 0x9ca3af)
        case .note:     return Color(hex: 0x16a34a)
        case .overlay:  return Color(hex: 0x38bdf8)
        case .feat:     return Color(hex: 0x1e40af)
        case .milestone:return Color(hex: 0xb45309)
        case .blocker:  return Color(hex: 0x991b1b)
        case .future:   return Color(hex: 0x7c3aed)
        case .folder:   return Color(hex: 0x9ca3af)
        case .file:     return Color(hex: 0xd1d5db)
        case .module:   return Color(hex: 0x0369a1)
        case .service:  return Color(hex: 0x0f766e)
        case .data:     return Color(hex: 0x4d7c0f)
        case .input:    return Color(hex: 0x15803d)
        case .agent:    return Color(hex: 0x4338ca)
        case .tool:     return Color(hex: 0xc2410c)
        case .router:   return Color(hex: 0xa16207)
        case .memory:   return Color(hex: 0x6d28d9)
        case .output:   return Color(hex: 0xb91c1c)
        // Godot strokes
        case .godot_scene:     return Color(hex: 0x215378)
        case .godot_control:   return Color(hex: 0x374151)
        case .godot_container: return Color(hex: 0x7c3aed)
        case .godot_panel:     return Color(hex: 0xadb5bd)
        case .godot_button:    return Color(hex: 0xea580c)
        case .godot_label:     return Color(hex: 0xd1d5db)
        case .godot_signal:    return Color(hex: 0xca8a04)
        case .godot_script:    return Color(hex: 0x16a34a)
        case .subagent:        return Color(hex: 0x5b21b6)
        case .prompt:          return Color(hex: 0x059669)
        case .skill:           return Color(hex: 0xc2410c)
        }
    }

    var textColor: Color {
        switch self {
        // Mörka fyllningar → ljus text
        case .ui, .overlay, .feat, .milestone, .blocker, .future,
             .module, .service, .data, .input, .agent, .tool,
             .router, .memory, .output,
             .godot_scene, .godot_control, .godot_container,
             .subagent, .prompt, .skill:
            return Color(hex: 0xf9fafb)
        // Ljusa fyllningar → mörk text
        case .zone, .folder, .file,
             .godot_panel, .godot_label, .godot_signal:
            return Color(hex: 0x111827)
        case .godot_button:
            return Color(hex: 0x111827) // mörk text på orange
        case .godot_script:
            return Color(hex: 0x064e3b) // mörk grön på ljus grön
        case .note:
            return Color(hex: 0x166534)
        }
    }

    /// Hex för Mermaid `classDef`-rader.
    /// v35.1: vit fyllning + kategori-kantlinje — standard flödesschema-stil.
    /// Kategorifärgen syns i kantlinjen så semantiken bevaras.
    /// (Appen renderar formerna med fillColor — Mermaid-exporten är neutral.)
    var mermaidClassDef: String {
        let stroke = strokeColor.hex
        // font-weight:normal förhindrar att Mermaid-renderare sätter bold som default
        // på noder utan explicit textStyle (t.ex. "Hjulet" ska vara regular, inte fet).
        return "fill:#ffffff,stroke:\(stroke),color:#111827,font-weight:normal"
    }

    /// Föreslagen short-label på canvas när formen är tom (visar kategori).
    var emptyLabelHint: String {
        switch self {
        case .ui: return "UI"
        case .zone: return "Zon"
        case .note: return "Note"
        case .overlay: return "Overlay"
        case .feat: return "Feature"
        case .milestone: return "Milestone"
        case .blocker: return "Blocker"
        case .future: return "Future"
        case .folder: return "Mapp"
        case .file: return "Fil"
        case .module: return "Modul"
        case .service: return "Service"
        case .data: return "Data"
        case .input: return "Input"
        case .agent: return "Agent"
        case .tool: return "Tool"
        case .router: return "Router"
        case .memory: return "Memory"
        case .output: return "Output"
        case .godot_scene:     return "Scene"
        case .godot_control:   return "Control"
        case .godot_container: return "Container"
        case .godot_panel:     return "Panel"
        case .godot_button:    return "Button"
        case .godot_label:     return "Label"
        case .godot_signal:    return "Signal"
        case .godot_script:    return "Script"
        case .subagent:        return "Subagent"
        case .prompt:          return "Prompt"
        case .skill:           return "Skill"
        }
    }

    var pickerHint: String {
        switch self {
        case .ui: return "UI-element — text syns på skärmen."
        case .zone: return "Layout-zon — region för UI."
        case .note: return "Kommentar — syns aldrig som UI-text."
        case .overlay: return "Overlay — modal, tooltip, HUD-överlägg."
        case .feat: return "Feature — en konkret funktion."
        case .milestone: return "Milestone — en version eller leverans."
        case .blocker: return "Blocker — hinder eller risk."
        case .future: return "Future — idé som inte är med i nuvarande MVP."
        case .folder: return "Mapp i kodbasen."
        case .file: return "Fil i kodbasen."
        case .module: return "Logisk modul eller komponent."
        case .service: return "Service / manager / controller."
        case .data: return "Datalager eller källa."
        case .input: return "Ingångspunkt för data eller event."
        case .agent: return "AI-agent eller processlogik."
        case .tool: return "Verktyg som agenten anropar."
        case .router: return "Villkorad routing eller beslutspunkt."
        case .memory: return "Minne eller kontext mellan steg."
        case .output: return "Slutpunkt eller resultat."
        case .godot_scene:     return "Scene-root (.tscn) — motsvarar en skärm."
        case .godot_control:   return "Control-nod — generisk UI-bas."
        case .godot_container: return "Layout-container — VBox/HBox/MarginContainer."
        case .godot_panel:     return "Panel — yta/kort/bakgrund."
        case .godot_button:    return "Button — action."
        case .godot_label:     return "Label — text-element."
        case .godot_signal:    return "Signal-koppling (för Flow-mode kopplingar)."
        case .godot_script:    return "GDScript-fil med logik."
        case .subagent:        return "Subagent — delegerad uppgift till annan Claude-instans."
        case .prompt:          return "Prompt — text till LLM/agent."
        case .skill:           return "Skill — predefined kapacitet/protokoll."
        }
    }
}

// MARK: - Color hex helper

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xff) / 255.0
        let g = Double((hex >> 8) & 0xff) / 255.0
        let b = Double(hex & 0xff) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    /// Hex-string för Mermaid-classDef (i format "#rrggbb").
    var hex: String {
        // Bästa-möjliga: läs ut UIColor-komponenter.
        #if canImport(UIKit)
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02x%02x%02x",
                      Int((r * 255).rounded()),
                      Int((g * 255).rounded()),
                      Int((b * 255).rounded()))
        #else
        return "#000000"
        #endif
    }
}
