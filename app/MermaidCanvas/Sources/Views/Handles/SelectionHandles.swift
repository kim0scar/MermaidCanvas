import SwiftUI

/// Visar markerings-handtag på en vald form: 4 hörn för resize + 1 topp-knopp för rotation.
/// Handtagen ligger i canvas-koordinatsystemet (samma scale/offset som shapes).
struct SelectionHandles: View {
    @Binding var shape: ShapeNode
    let canvasScale: CGFloat

    var body: some View {
        let w = ShapeGeometry.width(for: shape)
        let h = ShapeGeometry.height(for: shape)
        let center = shape.position
        // Storlek anpassad så handtagen blir lagom stora oavsett zoom.
        let handleSize: CGFloat = max(24, 28 / canvasScale)
        let strokeWidth: CGFloat = max(1.5, 2.0 / canvasScale)
        let rotationOffset: CGFloat = 40 / canvasScale

        ZStack {
            // Streckad markeringsram runt formen
            Rectangle()
                .stroke(Color.accentColor,
                        style: StrokeStyle(lineWidth: strokeWidth,
                                           dash: [6 / canvasScale, 4 / canvasScale]))
                .frame(width: w, height: h)
                .rotationEffect(.degrees(shape.rotation))
                .position(center)
                .allowsHitTesting(false)

            // 4 resize-handtag
            resizeHandle(corner: .topLeading,     size: handleSize)
            resizeHandle(corner: .topTrailing,    size: handleSize)
            resizeHandle(corner: .bottomLeading,  size: handleSize)
            resizeHandle(corner: .bottomTrailing, size: handleSize)

            // Rotation-handtag (ovanför topp-mitten)
            rotationHandle(size: handleSize, offset: rotationOffset, halfH: h / 2)
        }
    }

    // MARK: - Handle-views

    @ViewBuilder
    private func resizeHandle(corner: Corner, size: CGFloat) -> some View {
        let pos = cornerPositionInCanvas(corner)
        Circle()
            .fill(Color.white)
            .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
            .frame(width: size, height: size)
            .contentShape(Circle().inset(by: -size * 0.5))
            .position(pos)
            .gesture(resizeGesture)
    }

    @ViewBuilder
    private func rotationHandle(size: CGFloat, offset: CGFloat, halfH: CGFloat) -> some View {
        // Position: ovanför form, roterad med formens rotation
        let baseTop = CGPoint(x: shape.position.x, y: shape.position.y - halfH - offset)
        let rotated = rotatePoint(baseTop, around: shape.position, byDegrees: shape.rotation)

        Image(systemName: "arrow.clockwise")
            .font(.system(size: size * 0.5, weight: .bold))
            .foregroundStyle(Color.white)
            .frame(width: size, height: size)
            .background(Color.accentColor)
            .clipShape(Circle())
            .contentShape(Circle().inset(by: -size * 0.5))
            .position(rotated)
            .gesture(rotationGesture)
    }

    // MARK: - Hörn-koordinater

    enum Corner { case topLeading, topTrailing, bottomLeading, bottomTrailing }

    private func cornerPositionInCanvas(_ corner: Corner) -> CGPoint {
        let w = ShapeGeometry.width(for: shape)
        let h = ShapeGeometry.height(for: shape)
        let hw = w / 2
        let hh = h / 2
        // Lokala offsets från center
        let local: CGPoint
        switch corner {
        case .topLeading:     local = CGPoint(x: -hw, y: -hh)
        case .topTrailing:    local = CGPoint(x:  hw, y: -hh)
        case .bottomLeading:  local = CGPoint(x: -hw, y:  hh)
        case .bottomTrailing: local = CGPoint(x:  hw, y:  hh)
        }
        // Rotera om formen är roterad
        let rotated = rotatePoint(
            CGPoint(x: shape.position.x + local.x, y: shape.position.y + local.y),
            around: shape.position,
            byDegrees: shape.rotation
        )
        return rotated
    }

    private func rotatePoint(_ p: CGPoint, around c: CGPoint, byDegrees deg: CGFloat) -> CGPoint {
        guard abs(deg) > 0.5 else { return p }
        let r = deg * .pi / 180
        let cos_r = cos(r)
        let sin_r = sin(r)
        let dx = p.x - c.x
        let dy = p.y - c.y
        return CGPoint(
            x: c.x + dx * cos_r - dy * sin_r,
            y: c.y + dx * sin_r + dy * cos_r
        )
    }

    // MARK: - Gestures

    private var resizeGesture: some Gesture {
        DragGesture(coordinateSpace: .named("canvas"))
            .onChanged { v in
                // Mät avstånd från shape-center till fingret. Jämför med bas-diagonal.
                let dx = v.location.x - shape.position.x
                let dy = v.location.y - shape.position.y
                let dist = sqrt(dx * dx + dy * dy)
                let baseHalfDiag = sqrt(
                    ShapeGeometry.baseWidth * ShapeGeometry.baseWidth +
                    ShapeGeometry.baseHeight * ShapeGeometry.baseHeight
                ) / 2
                let newMult = dist / baseHalfDiag
                shape.sizeMultiplier = min(max(newMult, 0.3), 3.0)
            }
    }

    private var rotationGesture: some Gesture {
        DragGesture(coordinateSpace: .named("canvas"))
            .onChanged { v in
                let dx = v.location.x - shape.position.x
                let dy = v.location.y - shape.position.y
                // atan2 ger vinkel från positiv x-axel. Vi vill att 0° = handtaget pekar UPP.
                // Topp = -y-riktning, så vinkeln blir atan2(dy, dx) + 90°.
                let angleRad = atan2(dy, dx)
                var degrees = angleRad * 180 / .pi + 90
                // Klampa till -180..180
                while degrees > 180 { degrees -= 360 }
                while degrees < -180 { degrees += 360 }
                shape.rotation = degrees
            }
    }
}
