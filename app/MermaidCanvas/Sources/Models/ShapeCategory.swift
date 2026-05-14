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

    // Flow-läge
    case input
    case agent
    case tool
    case router
    case memory
    case output

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
        }
    }

    /// Vilken SpecType varje kategori naturligt hör till.
    var specType: SpecType {
        switch self {
        case .ui, .zone, .overlay: return .ui
        case .feat, .milestone, .blocker, .future: return .roadmap
        case .folder, .file, .module, .service, .data: return .architecture
        case .input, .agent, .tool, .router, .memory, .output: return .flow
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
        }
    }

    var textColor: Color {
        switch self {
        // Mörka fyllningar → ljus text
        case .ui, .overlay, .feat, .milestone, .blocker, .future,
             .module, .service, .data, .input, .agent, .tool,
             .router, .memory, .output:
            return Color(hex: 0xf9fafb)
        // Ljusa fyllningar → mörk text
        case .zone, .folder, .file:
            return Color(hex: 0x111827)
        case .note:
            return Color(hex: 0x166534)
        }
    }

    /// Hex för Mermaid `classDef`-rader.
    var mermaidClassDef: String {
        let fill = fillColor.hex
        let stroke = strokeColor.hex
        let text = textColor.hex
        return "fill:\(fill),stroke:\(stroke),color:\(text)"
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
