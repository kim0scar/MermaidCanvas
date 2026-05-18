import SwiftUI

/// v31: Markeringshandtag på vald form.
/// - ETT proportional-resize-handtag i bottom-right (bevarar aspect ratio)
/// - ETT fri-resize-handtag staplat under (modifierar width/height oberoende)
/// - ETT rotation-handtag ovanför formen
struct SelectionHandles: View {
    @Binding var shape: ShapeNode
    let canvasScale: CGFloat

    var body: some View {
        let w = ShapeGeometry.width(for: shape)
        let h = ShapeGeometry.height(for: shape)
        let center = shape.position
        let handleSize: CGFloat = max(24, 28 / canvasScale)
        let strokeWidth: CGFloat = max(1.5, 2.0 / canvasScale)
        let rotationOffset: CGFloat = 40 / canvasScale
        let stackSpacing: CGFloat = max(4, 6 / canvasScale)

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

            // Bottom-right hörn: två handles staplade vertikalt
            // 1) Proportional resize (övre) — bevarar aspect ratio
            // 2) Fri resize (under) — modifierar bredd och höjd oberoende
            proportionalHandle(size: handleSize, w: w, h: h, spacing: stackSpacing)
            freeResizeHandle(size: handleSize, w: w, h: h, spacing: stackSpacing)

            // Rotation-handtag (ovanför topp-mitten)
            rotationHandle(size: handleSize, offset: rotationOffset, halfH: h / 2)
        }
    }

    // MARK: - Handle-views

    /// Proportional — bevarar aspect ratio. Placerad i bottom-right hörn.
    @ViewBuilder
    private func proportionalHandle(size: CGFloat, w: CGFloat, h: CGFloat, spacing: CGFloat) -> some View {
        let pos = handlePosition(forBottomRight: true, w: w, h: h, extraDown: 0)
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

    /// Fri resize — width och height oberoende. Placerad under proportional-handle.
    @ViewBuilder
    private func freeResizeHandle(size: CGFloat, w: CGFloat, h: CGFloat, spacing: CGFloat) -> some View {
        let pos = handlePosition(forBottomRight: true, w: w, h: h, extraDown: size + spacing)
        ZStack {
            Circle()
                .fill(Color.white)
                .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
            Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                .font(.system(size: size * 0.42, weight: .bold))
                .foregroundStyle(Color.accentColor)
        }
        .frame(width: size, height: size)
        .contentShape(Circle().inset(by: -size * 0.5))
        .position(pos)
        .gesture(freeResizeGesture)
        .accessibilityIdentifier("resize.free")
    }

    @ViewBuilder
    private func rotationHandle(size: CGFloat, offset: CGFloat, halfH: CGFloat) -> some View {
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
            .accessibilityIdentifier("resize.rotate")
    }

    // MARK: - Positioner

    private func handlePosition(forBottomRight: Bool, w: CGFloat, h: CGFloat, extraDown: CGFloat) -> CGPoint {
        let local = CGPoint(x: w / 2, y: h / 2 + extraDown)
        return rotatePoint(
            CGPoint(x: shape.position.x + local.x, y: shape.position.y + local.y),
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
