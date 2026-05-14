import SwiftUI

/// iPhone-ram som "skärmkontext" i UI-läge.
/// Inte exportable — bara visuell ramning. Apple-design: tunn linje, hörn-radius som faktisk iPhone.
struct iPhoneFrameOverlay: View {
    var size: CGSize
    var color: Color = Color(.label).opacity(0.18)

    var body: some View {
        GeometryReader { geo in
            let frame = aspectFitFrame(in: geo.size)
            RoundedRectangle(cornerRadius: 38, style: .continuous)
                .stroke(color, lineWidth: 2)
                .frame(width: frame.width, height: frame.height)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                .overlay(alignment: .top) {
                    notch
                        .position(x: geo.size.width / 2, y: (geo.size.height - frame.height) / 2 + 14)
                }
        }
        .allowsHitTesting(false)
    }

    private var notch: some View {
        Capsule()
            .fill(color)
            .frame(width: 90, height: 8)
    }

    private func aspectFitFrame(in container: CGSize) -> CGSize {
        // Sikta mot 393:852 (iPhone 15 Pro) — fit i tillgänglig yta med marginal.
        let target: CGFloat = 393.0 / 852.0
        let pad: CGFloat = 16
        let availW = max(0, container.width - pad * 2)
        let availH = max(0, container.height - pad * 2)
        let byWidth = CGSize(width: availW, height: availW / target)
        let byHeight = CGSize(width: availH * target, height: availH)
        return byWidth.height <= availH ? byWidth : byHeight
    }
}
