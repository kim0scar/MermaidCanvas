import SwiftUI

/// iPhone-ram som "skärmkontext" i UI-läge.
/// Använder shared `iPhoneFrameMath` så ramens position alltid matchar
/// vad som sparas i canvas-meta.
struct iPhoneFrameOverlay: View {
    var size: CGSize
    var color: Color = Color(.label).opacity(0.18)

    var body: some View {
        GeometryReader { geo in
            let frame = iPhoneFrameMath.frame(in: geo.size)
            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .stroke(color, lineWidth: 2)
                .frame(width: frame.width, height: frame.height)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(color)
                        .frame(width: 90, height: 8)
                        .position(x: geo.size.width / 2, y: frame.minY + 14)
                }
        }
        .allowsHitTesting(false)
    }
}
