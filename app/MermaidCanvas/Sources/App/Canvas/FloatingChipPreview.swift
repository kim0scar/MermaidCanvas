import SwiftUI

/// v34 — Liten visuell preview av en form som följer fingret under aktiv chip-drag.
/// Renders som en mörk semi-transparent rund yta med form-ikon i mitten.
/// Ligger ovanpå hela appen (i ContentView's översta ZStack-lager).
struct FloatingChipPreview: View {
    let type: ShapeType

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.85))
                .frame(width: 56, height: 56)
                .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.white)
        }
    }

    private var systemImage: String {
        switch type {
        case .circle:       return "circle"
        case .rectangle:    return "rectangle"
        case .diamond:      return "diamond"
        case .pill:         return "capsule"
        case .table:        return "tablecells"
        case .link:         return "link"
        case .line:         return "minus"
        case .arrow:        return "arrow.right"
        // v35.1/v36
        case .square:       return "square"
        case .processArrow: return "arrowshape.right"
        // v44
        case .container:    return "rectangle.dashed"
        case .octagon:      return "octagon"
        }
    }
}
