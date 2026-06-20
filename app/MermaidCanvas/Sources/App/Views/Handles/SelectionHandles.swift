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
        let handleSize: CGFloat = DesignTokens.screenPt(26, scale: canvasScale)
        let strokeWidth: CGFloat = max(1.5, 2.0 / canvasScale)
        // v66: 48 → 20 (Kims fynd: rotera-ikonen "väldigt långt ut") — ligger
        // nu i nivå med resize-handtagen. Diagonal placering behålls medvetet:
        // centrerat ovanför skulle krocka med fromSide=top-pilens utgång.
        let rotationOffset: CGFloat = DesignTokens.screenPt(20, scale: canvasScale)

        ZStack {
            // v50.5 v4 F8/F10: markeringsramen följer formens EGEN GEOMETRI
            // via delad SelectionOutline-utility (även multi-select använder
            // den så båda renderas konsekvent).
            SelectionOutline(
                shapeType: shape.type,
                width: w,
                height: h,
                strokeWidth: strokeWidth,
                canvasScale: canvasScale
            )
            .rotationEffect(.degrees(shape.rotation))
            .position(center)
            .allowsHitTesting(false)

            // Bottom-right: proportional resize (bevarar aspect ratio).
            // v66: INTE för container — en container ska aldrig låsas till
            // proportion (Kims fynd); fri resize är dess enda handtag.
            if shape.type != .container {
                proportionalHandle(size: handleSize, w: w, h: h)
            }

            // Bottom-left: fri resize med diagonal ikon.
            // Steg 9: INTE för phoneFrame — en telefon-mall ska behålla sin
            // proportion (fri resize skulle töja skärmen ur device-format).
            if shape.type != .phoneFrame {
                freeResizeHandle(size: handleSize, w: w, h: h)
            }

            // Top-left: rotation med transparent bakgrund
            rotationHandle(size: handleSize, offset: rotationOffset, w: w, h: h)
        }
    }

    /// v63: hur långt utanför formens hörn handtagens CENTRUM ligger.
    private var handleMargin: CGFloat { DesignTokens.screenPt(16, scale: canvasScale) }

    // MARK: - Handle-views

    /// Proportional resize — bottom-right hörn.
    @ViewBuilder
    private func proportionalHandle(size: CGFloat, w: CGFloat, h: CGFloat) -> some View {
        // v63: handtaget ligger UTANFÖR hörnet (Kims fynd: gick in i formen)
        let m = handleMargin
        let pos = cornerPosition(dx: w / 2 + m, dy: h / 2 + m)
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
        .accessibilityLabel("Ändra storlek proportionerligt")
        .accessibilityAddTraits(.isButton)
    }

    /// Fri resize — bottom-left hörn, diagonal ikon (tydlig resize-signal).
    @ViewBuilder
    private func freeResizeHandle(size: CGFloat, w: CGFloat, h: CGFloat) -> some View {
        // v63: utanför hörnet
        let m = handleMargin
        let pos = cornerPosition(dx: -w / 2 - m, dy: h / 2 + m)
        ZStack {
            Circle()
                .fill(Color.white)
                .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
            // v42: Custom-ritad 4-pilars-ikon — tydligt diagonala pilar
            FreeResizeIcon(color: Color.accentColor)
                .frame(width: size * 0.65, height: size * 0.65)
        }
        .frame(width: size, height: size)
        .contentShape(Circle().inset(by: -size * 0.5))
        .position(pos)
        .gesture(freeResizeGesture)
        .accessibilityIdentifier("resize.free")
        .accessibilityLabel("Ändra storlek fritt")
        .accessibilityAddTraits(.isButton)
    }

    /// Rotation — top-left hörn, transparent bakgrund (som övriga handles).
    @ViewBuilder
    private func rotationHandle(size: CGFloat, offset: CGFloat, w: CGFloat, h: CGFloat) -> some View {
        // v63: full offset utåt (var offset/2 → gick in i hörnet)
        let pos = cornerPosition(dx: -w / 2 - offset, dy: -h / 2 - offset)

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
        .accessibilityLabel("Rotera")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Selection-ram cornerRadius

    /// v50.2 F-6: cornerRadius per formtyp så streckad markeringsram följer
    /// formens egen geometri. Värdena ska matcha hur formerna ritas
    /// (rektangel: 10, square: 14, pill: full kapsel). Diamond + processArrow
    /// + circle har egna geometrier som inte är RoundedRectangle — där
    /// faller vi tillbaka på 0 (rät bbox, känns OK för dessa).
    private func selectionCornerRadius(for shape: ShapeNode) -> CGFloat {
        // v50.4: delegerar till DesignTokens — så selection-ramen automatiskt
        // matchar formens cornerRadius om den ändras centralt.
        DesignTokens.Selection.cornerRadius(
            for: shape.type,
            width: ShapeGeometry.width(for: shape),
            height: ShapeGeometry.height(for: shape)
        )
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
                // v50.5 (v5) M1: räkna mot formens TYP-bas (container 280×200,
                // pill 130, square 80…) — annars hoppade storleken direkt man
                // grep handtaget (container → 2.4×) eftersom generisk 120×80
                // inte matchar handtagets faktiska hörn-avstånd.
                let bw = ShapeGeometry.typeBaseWidth(for: shape.type)
                let bh = ShapeGeometry.typeBaseHeight(for: shape.type)
                let baseHalfDiag = sqrt(bw * bw + bh * bh) / 2
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
                // v50.5 (v5) M1: typ-bas även här (se proportionalResizeGesture).
                let bw = ShapeGeometry.typeBaseWidth(for: shape.type)
                let bh = ShapeGeometry.typeBaseHeight(for: shape.type)
                let newW = min(max(dx / (bw / 2), 0.3), 3.0)
                let newH = min(max(dy / (bh / 2), 0.3), 3.0)
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
