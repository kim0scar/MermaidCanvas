import SwiftUI

/// iPhone-ramen i canvas-koordinatsystem (fast 393×852pt, centrerad i 3000×3000-canvasen).
/// Ramen ligger inom samma scale/offset-transform som shapes.
struct iPhoneFrameOverlay: View {
    var canvasContentSize: CGSize
    var color: Color = Color.appLabel.opacity(0.30)

    var body: some View {
        let frame = iPhoneFrameMath.canvasFrame(in: canvasContentSize)
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 42, style: .continuous)
                .stroke(color, lineWidth: 3)
                .frame(width: frame.width, height: frame.height)

            // Dynamic Island som visuell guide för "topp av skärm"
            Capsule()
                .fill(color)
                .frame(width: 100, height: 28)
                .padding(.leading, (frame.width - 100) / 2)
                .padding(.top, 14)
        }
        .frame(width: frame.width, height: frame.height, alignment: .topLeading)
        .position(x: frame.midX, y: frame.midY)
        .allowsHitTesting(false)
    }
}
