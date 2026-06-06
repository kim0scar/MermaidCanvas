import SwiftUI

/// Visas i topphögra hörnet när shape.note != "". Tap → snabbläsning.
/// v64: tydlig text-IKON i gul cirkel (prickarna var för dolda — Kims fynd).
struct NoteBadge: View {
    var canvasScale: CGFloat
    var onTap: () -> Void

    var body: some View {
        let visual: CGFloat = max(18, 22 / canvasScale)
        let hit: CGFloat = max(30, 36 / canvasScale)
        Button(action: onTap) {
            ZStack {
                Color.clear.frame(width: hit, height: hit) // utvidgad tap-target
                Circle()
                    .fill(Color(hex: 0xFFCC00))
                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                    .frame(width: visual, height: visual)
                Image(systemName: "text.alignleft")
                    .font(.system(size: visual * 0.5, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.75))
            }
        }
        .buttonStyle(.plain)
        .contentShape(Circle().inset(by: -(hit - visual) / 2))
    }
}
