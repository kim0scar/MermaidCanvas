import SwiftUI

/// Visas i topphögra hörnet när shape.note != "". Tap → snabbläsning.
/// v64: tydlig text-IKON i gul cirkel (prickarna var för dolda — Kims fynd).
struct NoteBadge: View {
    var canvasScale: CGFloat
    var onTap: () -> Void

    var body: some View {
        // v66: mindre + skärm-konstant (Kims fynd: "för stora och i vägen")
        let visual: CGFloat = DesignTokens.screenPt(15, scale: canvasScale)
        let hit: CGFloat = DesignTokens.screenPt(30, scale: canvasScale)
        Button(action: onTap) {
            ZStack {
                Color.clear.frame(width: hit, height: hit) // utvidgad tap-target
                Circle()
                    .fill(Color(hex: 0xFFCC00))
                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                    .frame(width: visual, height: visual)
                Image(systemName: "bubble.left.fill")
                    .font(.system(size: visual * 0.52, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.7))
            }
        }
        .buttonStyle(.plain)
        .contentShape(Circle().inset(by: -(hit - visual) / 2))
    }
}
