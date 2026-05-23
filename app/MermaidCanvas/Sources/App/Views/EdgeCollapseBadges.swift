import SwiftUI

/// v48 Fel #4: Plus-badge vid stub-änden för en kollapsad kant.
/// Visas ALLTID (även när omarkerad) så användaren ser att något är dolt.
/// Tryck → expandera (onTap → toggleCollapse på from-shape).
struct EdgeStubBadge: View {
    let position: CGPoint
    let canvasScale: CGFloat
    var onTap: () -> Void

    var body: some View {
        let size: CGFloat = max(20, 22 / canvasScale)
        Button(action: onTap) {
            Image(systemName: "plus")
                .font(.system(size: size * 0.55, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(Color(.systemIndigo))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 1))
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
        // v50.2 F-2: badge syntes knappt. Större (24/26pt), tjockare vit
        // stroke (2pt) och systemPurple för högre kontrast mot vit canvas.
        let size: CGFloat = max(24, 26 / canvasScale)
        Button(action: onTap) {
            Image(systemName: "minus")
                .font(.system(size: size * 0.55, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(Color(.systemPurple))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .position(position)
        .accessibilityIdentifier("edge.collapse.minus")
    }
}
