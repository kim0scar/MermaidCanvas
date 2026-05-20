import SwiftUI

/// v39: Markeringshandtag på vald form.
/// - Proportional-resize: bottom-right (bevarar aspect ratio)
/// - Fri resize (diagonal): bottom-left (tydlig resize-ikon)
/// - Rotation: top-left, transparent bakgrund
struct SelectionHandles: View {
    @Binding var shape: ShapeNode
    let canvasScale: CGFloat

    var body: some View {
        let w = ShapeGeometry.width(for: shape)
        let h = ShapeGeometry.height(for: shape)
        let center = shape.position
        let handleSize: CGFloat = max(24, 28 / canvasScale)
        let strokeWidth: CGFloat = max(1.5, 2.0 / canvasScale)
        let rotationOffset: CGFloat = 36 / canvasScale

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

            // Bottom-right: proportional resize (bevarar aspect ratio)
            proportionalHandle(size: handleSize, w: w, h: h)

            // Bottom-left: fri resize med diagonal ikon
            freeResizeHandle(size: handleSize, w: w, h: h)

            // Top-left: rotation med transparent bakgrund
            rotationHandle(size: handleSize, offset: rotationOffset, w: w, h: h)
        }
    }

    // MARK: - Handle-views

    /// Proportional resize — bottom-right hörn.
    @ViewBuilder
    private func proportionalHandle(size: CGFloat, w: CGFloat, h: CGFloat) -> some View {
        let pos = cornerPosition(dx: w / 2, dy: h / 2)
        ZStack {
            Circle()
                .fill(Color.white)
                .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(Color.accentColor)
        }
        .frame(width: size, height: size)
        .contentShape(Circle().inset(by: -size * 0.5))
        .position(pos)
        .gesture(proportionalResizeGesture)
        .accessibilityIdentifier("resize.proportional")
    }

    /// Fri resize — bottom-left hörn, diagonal ikon (tydlig resize-signal).
    @ViewBuilder
    private func freeResizeHandle(size: CGFloat, w: CGFloat, h: CGFloat) -> some View {
        let pos = cornerPosition(dx: -w / 2, dy: h / 2)
        ZStack {
            Circle()
                .fill(Color.white)
                .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
            // v40: 4 pilar roterade 45° → ↖↗↙↘ — kommunicerar "ändra fritt åt alla håll"
            Image(systemName: "arrows.up.down.left.right")
                .font(.system(size: size * 0.40, weight: .bold))
                .foregroundStyle(Color.accentColor)
                .rotationEffect(.degrees(45))
        }
        .frame(width: size, height: size)
        .contentShape(Circle().inset(by: -size * 0.5))
        .position(pos)
        .gesture(freeResizeGesture)
        .accessibilityIdentifier("resize.free")
    }

    /// Rotation — top-left hörn, transparent bakgrund (som övriga handles).
    @ViewBuilder
    private func rotationHandle(size: CGFloat, offset: CGFloat, w: CGFloat, h: CGFloat) -> some View {
        let pos = cornerPosition(dx: -w / 2 - offset / 2, dy: -h / 2 - offset / 2)

        ZStack {
            Circle()
                .fill(Color.white.opacity(0.0))  // transparent
                .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
            Image(systemName: "arrow.clockwise")
                .font(.system(size: size * 0.48, weight: .bold))
                .foregroundStyle(Color.accentColor)
        }
        .frame(width: size, height: size)
        .contentShape(Circle().inset(by: -size * 0.5))
        .position(pos)
        .gesture(rotationGesture)
        .accessibilityIdentifier("resize.rotate")
    }

    // MARK: - Positioner

    /// Beräknar en hörn-position relativt formens center, med rotation.
    private func cornerPosition(dx: CGFloat, dy: CGFloat) -> CGPoint {
        rotatePoint(
            CGPoint(x: shape.position.x + dx, y: shape.position.y + dy),
            around: shape.position,
            byDegrees: shape.rotation
        )
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

    /// Proportional resize: avstånd från center → enhetlig multiplier (både width och height).
    private var proportionalResizeGesture: some Gesture {
        DragGesture(coordinateSpace: .named("canvas"))
            .onChanged { v in
                let dx = v.location.x - shape.position.x
                let dy = v.location.y - shape.position.y
                let dist = sqrt(dx * dx + dy * dy)
                let baseHalfDiag = sqrt(
                    ShapeGeometry.baseWidth * ShapeGeometry.baseWidth +
                    ShapeGeometry.baseHeight * ShapeGeometry.baseHeight
                ) / 2
                let newMult = min(max(dist / baseHalfDiag, 0.3), 3.0)
                shape.sizeMultiplier = newMult
                shape.widthMultiplier = newMult
                shape.heightMultiplier = newMult
            }
    }

    /// v31: Fri resize — separata multipliers för bredd och höjd baserat på finger-position.
    private var freeResizeGesture: some Gesture {
        DragGesture(coordinateSpace: .named("canvas"))
            .onChanged { v in
                let dx = abs(v.location.x - shape.position.x)
                let dy = abs(v.location.y - shape.position.y)
                let newW = min(max(dx / (ShapeGeometry.baseWidth / 2), 0.3), 3.0)
                let newH = min(max(dy / (ShapeGeometry.baseHeight / 2), 0.3), 3.0)
                shape.widthMultiplier = newW
                shape.heightMultiplier = newH
            }
    }

    private var rotationGesture: some Gesture {
        DragGesture(coordinateSpace: .named("canvas"))
            .onChanged { v in
                let dx = v.location.x - shape.position.x
                let dy = v.location.y - shape.position.y
                let angleRad = atan2(dy, dx)
                var degrees = angleRad * 180 / .pi + 90
                while degrees > 180 { degrees -= 360 }
                while degrees < -180 { degrees += 360 }
                shape.rotation = degrees
            }
    }
}
