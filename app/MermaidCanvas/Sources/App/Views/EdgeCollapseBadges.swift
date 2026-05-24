import SwiftUI

/// v48 Fel #4: Plus-badge vid stub-änden för en kollapsad kant.
/// Visas ALLTID (även när omarkerad) så användaren ser att något är dolt.
/// Tryck → expandera (onTap → toggleCollapse på from-shape).
struct EdgeStubBadge: View {
    let position: CGPoint
    let canvasScale: CGFloat
    var onTap: () -> Void

    var body: some View {
        // v50.4: storlek + färg + stroke från DesignTokens — synkat med
        // minus-badgen så de visuellt hänger ihop.
        let size: CGFloat = max(DesignTokens.Badge.plusSize,
                                (DesignTokens.Badge.plusSize + 2) / canvasScale)
        Button(action: onTap) {
            Image(systemName: "plus")
                .font(.system(size: size * 0.55, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(DesignTokens.Badge.plusColor)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white,
                                         lineWidth: DesignTokens.Badge.plusStrokeWidth))
        }
        .buttonStyle(.plain)
        .position(position)
        .accessibilityIdentifier("edge.stub.badge")
    }
}

/// v48 Fel #3: Minus-badge vid utgående kants start på MARKERAD form.
/// Visas bara när from-shape är markerad — tydlig signal om vilka kanter
/// som går att kollapsa. Per kant (en badge per utgående pil).
/// Tryck → kollapsa from-shape (alla utgående kanter).
struct EdgeStartCollapseBadge: View {
    let position: CGPoint
    let canvasScale: CGFloat
    var onTap: () -> Void

    var body: some View {
        // v50.4: storlek + färg + stroke + shadow från DesignTokens.
        let size: CGFloat = max(DesignTokens.Badge.minusSize,
                                (DesignTokens.Badge.minusSize + 2) / canvasScale)
        Button(action: onTap) {
            Image(systemName: "minus")
                .font(.system(size: size * 0.55, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(DesignTokens.Badge.minusColor)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white,
                                         lineWidth: DesignTokens.Badge.minusStrokeWidth))
                .shadow(color: DesignTokens.Badge.minusColor.opacity(0.5),
                        radius: DesignTokens.Badge.minusShadowRadius,
                        x: 0, y: 0)
        }
        .buttonStyle(.plain)
        .position(position)
        .accessibilityIdentifier("edge.collapse.minus")
    }
}
