import Foundation

/// De fyra tankelägena (plus general fallback). Skrivs som `spec_type` i frontmatter.
/// Styr vilka kategorier som visas i kategori-pickern och färgschemat på canvasen.
enum SpecType: String, Codable, CaseIterable, Identifiable {
    case ui
    case roadmap
    case architecture
    case flow
    case general

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ui:           return "UI"
        case .roadmap:      return "Roadmap"
        case .architecture: return "Arkitektur"
        case .flow:         return "Flow"
        case .general:      return "Allmänt"
        }
    }

    /// Visas i topp-pickern. .general döljs (auto-fallback om fil saknar frontmatter).
    static var pickable: [SpecType] { [.ui, .roadmap, .architecture, .flow] }

    var defaultCategory: ShapeCategory {
        switch self {
        case .ui:           return .ui
        case .roadmap:      return .feat
        case .architecture: return .module
        case .flow:         return .agent
        case .general:      return .ui
        }
    }

    /// Iconfärg/badge för spec-typen i toppen.
    var badgeSystemImage: String {
        switch self {
        case .ui:           return "iphone"
        case .roadmap:      return "map"
        case .architecture: return "rectangle.3.group"
        case .flow:         return "arrow.triangle.branch"
        case .general:      return "square.grid.2x2"
        }
    }
}
