import SwiftUI

/// Gul prick i topphögra hörnet på formen — visas när shape.note != "".
/// Tap → öppna NoteMiniSheet (bara anteckningen, inte hela edit-sheet).
struct NoteBadge: View {
    var canvasScale: CGFloat
    var onTap: () -> Void

    var body: some View {
        let visual: CGFloat = max(12, 14 / canvasScale)
        let hit: CGFloat = max(28, 32 / canvasScale)
        Button(action: onTap) {
            ZStack {
                Color.clear.frame(width: hit, height: hit) // utvidgad tap-target
                Circle()
                    .fill(Color(hex: 0xFFCC00))
                    .overlay(Circle().stroke(Color.white, lineWidth: 1))
                    .shadow(color: .black.opacity(0.15), radius: 1.5, y: 0.5)
                    .frame(width: visual, height: visual)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Circle().inset(by: -(hit - visual) / 2))
    }
}
