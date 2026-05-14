import Foundation
import SwiftUI

/// Semantisk kategori per form. Lager 2 i METOD-VISUELL-DIALOG.md.
/// Klassnamnet är auktoritativt — färgerna är estetik och kan justeras.
enum ShapeCategory: String, Codable, CaseIterable, Identifiable {
    case ui
    case zone
    case note
    case overlay

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ui: return "UI"
        case .zone: return "Zon"
        case .note: return "Note"
        case .overlay: return "Overlay"
        }
    }

    /// Prefix som används i Mermaid-blockets node-id (t.ex. "ui_N0").
    var idPrefix: String { rawValue }

    /// Estetisk bas-fyllfärg per kategori.
    var fillColor: Color {
        switch self {
        case .ui:      return Color(red: 0.114, green: 0.306, blue: 0.847) // #1d4ed8
        case .zone:    return Color(red: 0.898, green: 0.906, blue: 0.922) // #e5e7eb
        case .note:    return Color(red: 0.925, green: 0.992, blue: 0.953) // #ecfdf3
        case .overlay: return Color(red: 0.059, green: 0.090, blue: 0.165) // #0f172a
        }
    }

    var strokeColor: Color {
        switch self {
        case .ui:      return Color(red: 0.118, green: 0.161, blue: 0.231) // #1e293b
        case .zone:    return Color(red: 0.612, green: 0.639, blue: 0.686) // #9ca3af
        case .note:    return Color(red: 0.086, green: 0.639, blue: 0.290) // #16a34a
        case .overlay: return Color(red: 0.220, green: 0.741, blue: 0.973) // #38bdf8
        }
    }

    /// Föreslagen textfärg för displaytext.
    var textColor: Color {
        switch self {
        case .ui:      return Color(red: 0.976, green: 0.980, blue: 0.984) // #f9fafb
        case .zone:    return Color(red: 0.067, green: 0.094, blue: 0.153) // #111827
        case .note:    return Color(red: 0.086, green: 0.329, blue: 0.204) // #166534
        case .overlay: return Color(red: 0.878, green: 0.949, blue: 0.973) // #e0f2fe
        }
    }

    /// Hex-värden för Mermaid `classDef`-rader (matchar METOD-VISUELL-DIALOG.md).
    var mermaidClassDef: String {
        switch self {
        case .ui:      return "fill:#1d4ed8,stroke:#1e293b,color:#f9fafb"
        case .zone:    return "fill:#e5e7eb,stroke:#9ca3af,color:#111827"
        case .note:    return "fill:#ecfdf3,stroke:#16a34a,color:#166534"
        case .overlay: return "fill:#0f172a,stroke:#38bdf8,color:#e0f2fe"
        }
    }
}
