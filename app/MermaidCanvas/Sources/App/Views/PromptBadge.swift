import SwiftUI

/// v63: Indigo hjärn-prick i toppvänstra hörnet — visas när shape.prompt != "".
/// Tap → QuickReadSheet (läs texten direkt, ingen redigering).
struct PromptBadge: View {
    var canvasScale: CGFloat
    var onTap: () -> Void

    var body: some View {
        let visual: CGFloat = max(12, 14 / canvasScale)
        let hit: CGFloat = max(28, 32 / canvasScale)
        Button(action: onTap) {
            ZStack {
                Color.clear.frame(width: hit, height: hit) // utvidgad tap-target
                Circle()
                    .fill(Color(hex: 0x4338ca))
                    .overlay(Circle().stroke(Color.white, lineWidth: 1))
                    .shadow(color: .black.opacity(0.15), radius: 1.5, y: 0.5)
                    .frame(width: visual, height: visual)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Circle().inset(by: -(hit - visual) / 2))
    }
}
