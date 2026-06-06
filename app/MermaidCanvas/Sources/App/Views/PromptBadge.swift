import SwiftUI

/// v63: visas när shape.prompt != "". Tap → QuickReadSheet (läs direkt, ingen redigering).
/// v64: tydlig hjärn-IKON i indigo-cirkel (prickarna var för dolda — Kims fynd).
struct PromptBadge: View {
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
                    .fill(Color(hex: 0x4338ca))
                    .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                    .frame(width: visual, height: visual)
                Image(systemName: "brain")
                    .font(.system(size: visual * 0.55, weight: .semibold))
                    .foregroundStyle(Color.white)
            }
        }
        .buttonStyle(.plain)
        .contentShape(Circle().inset(by: -(hit - visual) / 2))
    }
}
