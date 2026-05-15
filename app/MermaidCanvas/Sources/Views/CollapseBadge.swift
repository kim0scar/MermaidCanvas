import SwiftUI

/// Liten +/- badge i nedre hörnet på en form. Visas bara om formen har edges.
/// Tap → kollapsa/expand (modellen filtrerar då bort connected shapes).
struct CollapseBadge: View {
    var collapsed: Bool
    var canvasScale: CGFloat
    var onTap: () -> Void

    var body: some View {
        let size: CGFloat = max(20, 22 / canvasScale)
        Button(action: onTap) {
            Image(systemName: collapsed ? "plus" : "minus")
                .font(.system(size: size * 0.55, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(Color(.systemIndigo))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
