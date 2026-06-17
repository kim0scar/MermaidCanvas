import SwiftUI

/// Ren kant-ritning (MA spår A steg 6): bezier-linje, pilhuvuden, linjestilar.
/// Statiska funktioner; formerna och dolda-id trådas in (inget eget tillstånd).
/// Bröts ut ur EdgesView — ritningen är ordagrant oförändrad. Geometrin ligger
/// i `EdgeGeometry`; den här filen äger bara hur det ritas.
enum EdgeDrawing {

    /// v27: hel eller streckad — tjockare pilar (2.5pt) för bättre läsbarhet på iPhone.
    static func strokeStyle(for edgeStyle: EdgeStyle) -> StrokeStyle {
        switch edgeStyle {
        case .solid:  return StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
        case .dashed: return StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round, dash: [8, 6])
        }
    }

    /// v50.2 F-1: cubic bezier-evaluering vid godtyckligt t.
    /// Används av drawEdge för pilspets-tangent vid t=0.92/0.08 (stabilare
    /// än atan2(end-cp2) för korta pilar).
    static func cubicBezier(t: CGFloat, p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint) -> CGPoint {
        let u = 1 - t
        let uu = u * u, uuu = uu * u
        let tt = t * t, ttt = tt * t
        return CGPoint(
            x: uuu * p0.x + 3 * uu * t * p1.x + 3 * u * tt * p2.x + ttt * p3.x,
            y: uuu * p0.y + 3 * uu * t * p1.y + 3 * u * tt * p2.y + ttt * p3.y
        )
    }

    /// v62: kvadratisk bezier — för pilspets-vinkeln på waypoint-kanter
    /// (de ritas som två quad-segment, se drawEdge).
    static func quadBezier(t: CGFloat, p0: CGPoint, p1: CGPoint, p2: CGPoint) -> CGPoint {
        let u = 1 - t
        return CGPoint(
            x: u * u * p0.x + 2 * u * t * p1.x + t * t * p2.x,
            y: u * u * p0.y + 2 * u * t * p1.y + t * t * p2.y
        )
    }

    /// v28: pilhuvuden. v63: SOLID i samma färg som linjen (ingen opacity) —
    /// strecket kan inte lysa igenom; pil + linje ser ut som EN enhet.
    static func drawArrowHead(context: GraphicsContext, tip: CGPoint, angle: CGFloat,
                              color: Color) {
        let length: CGFloat = 14
        let spread: CGFloat = .pi / 7
        let a1 = CGPoint(
            x: tip.x - length * cos(angle - spread),
            y: tip.y - length * sin(angle - spread)
        )
        let a2 = CGPoint(
            x: tip.x - length * cos(angle + spread),
            y: tip.y - length * sin(angle + spread)
        )
        var head = Path()
        head.move(to: tip)
        head.addLine(to: a1)
        head.addLine(to: a2)
        head.closeSubpath()
        // v49 Fel #1 (Agent C 1/3-diagnos): bara fill, inte stroke. Stroke med
        // .round cap/join lade till ~0.75pt rundning på pilspets-sidorna som
        // kan ge subpixel-asymmetri vid diagonala vinklar. Ren fyllning ger
        // skarpare, mer symmetrisk pilspets.
        context.fill(head, with: .color(color))
    }

    /// v38: bezier-kurva för en kant — mjuk S-kurva utan waypoint, smidig böj med waypoint.
    static func drawEdge(context: GraphicsContext,
                         edge: EdgeConnection,
                         fromShape: ShapeNode,
                         toShape: ShapeNode,
                         shapes: [ShapeNode],
                         hiddenShapeIds: Set<UUID>) {
        let strokeStyle = strokeStyle(for: edge.style)

        // Start-/slutpunkter på formernas ytor.
        // v64: vald utgångssida (fromSide) vinner över automatiken.
        let start: CGPoint
        let end: CGPoint
        if let wp = edge.waypoints.first {
            start = edge.fromSide.map { EdgeGeometry.sidePoint(for: fromShape, side: $0) }
                ?? EdgeGeometry.edgePoint(for: fromShape, towards: wp.point)
            end   = EdgeGeometry.edgePoint(for: toShape,   towards: wp.point)
        } else {
            start = edge.fromSide.map { EdgeGeometry.sidePoint(for: fromShape, side: $0) }
                ?? EdgeGeometry.edgePoint(for: fromShape, towards: toShape.position)
            end   = EdgeGeometry.edgePoint(for: toShape,   towards: fromShape.position)
        }

        // Bezier-kontrollpunkter baserade på ytornas normalvektorer (Lucidchart-stil).
        // v66: delad vinkelmedveten matte (EdgeMath) — rund båge även när
        // fromSide-normalen pekar bort från målet.
        let n1 = EdgeGeometry.outwardNormal(for: fromShape, at: start)
        let n2 = EdgeGeometry.outwardNormal(for: toShape,   at: end)
        let cps = EdgeMath.controlPoints(start: start, end: end, n1: n1, n2: n2)
        var cp1 = cps.cp1
        var cp2 = cps.cp2

        // v43: D5 — routa runt obstacles (andra former som ligger i vägen).
        // Bara aktivt när användaren inte själv satt waypoint (waypoint = manuell routing).
        // Behåller default normal-baserade Lucidchart-cps när ingen krock finns;
        // bytar ut till sid-pushade cps endast vid faktisk obstacle.
        if edge.waypoints.isEmpty {
            let obstacleBboxes: [CGRect] = shapes.compactMap { obstacle in
                // Hoppa över source och target själva
                guard obstacle.id != edge.from && obstacle.id != edge.to else { return nil }
                // Hoppa även dolda noder (de syns inte, ska inte routa runt)
                guard !hiddenShapeIds.contains(obstacle.id) else { return nil }
                // v50: hoppa över container när pilen går mellan dess egna barn.
                // Annars ser routing-algoritmen containern som obstakel och bezier-
                // kontrollpunkterna dras långt utanför viewport (F-02 i bug-rapport).
                if obstacle.type == .container,
                   fromShape.childOfContainerId == obstacle.id
                   || toShape.childOfContainerId == obstacle.id {
                    return nil
                }
                let w = ShapeGeometry.width(for: obstacle)
                let h = ShapeGeometry.height(for: obstacle)
                // Lägg till lite margin runt obstacle för andningsutrymme
                let margin: CGFloat = 12
                return CGRect(x: obstacle.position.x - w/2 - margin,
                              y: obstacle.position.y - h/2 - margin,
                              width: w + margin * 2,
                              height: h + margin * 2)
            }
            if EdgeRouting.hasObstacle(from: start, to: end, obstacles: obstacleBboxes) {
                let routed = EdgeRouting.controlPoints(from: start, to: end, obstacles: obstacleBboxes)
                cp1 = routed.cp1
                cp2 = routed.cp2
            }
        }

        // Pilhuvud-vinklar.
        // v62: spetsen följer den SYNLIGA linjens riktning vid änden — sampla kurvan
        // nära spetsen (t=0.92/0.08) med de FAKTISKA kontrollpunkterna (inkl. routade).
        // v60 låste vinkeln till sidans inåt-normal, vilket gjorde spetsen skev när
        // linjen kom in diagonalt (Kims fynd i v61.2): linje och spets pekade åt olika
        // håll. Near-endpoint-sampling är numeriskt stabil även för korta pilar
        // (v50.2-resonemanget); normal-vinkeln behålls bara som fallback om samplet
        // degenererar (sammanfallande punkter).
        let nearEnd: CGPoint
        let nearStart: CGPoint
        if let wp = edge.waypoints.first {
            nearEnd   = quadBezier(t: 0.92, p0: wp.point, p1: cp2, p2: end)
            nearStart = quadBezier(t: 0.08, p0: start, p1: cp1, p2: wp.point)
        } else {
            nearEnd   = cubicBezier(t: 0.92, p0: start, p1: cp1, p2: cp2, p3: end)
            nearStart = cubicBezier(t: 0.08, p0: start, p1: cp1, p2: cp2, p3: end)
        }
        let endVec   = CGPoint(x: end.x - nearEnd.x,     y: end.y - nearEnd.y)
        let startVec = CGPoint(x: start.x - nearStart.x, y: start.y - nearStart.y)
        let endAngle   = hypot(endVec.x, endVec.y) > 0.01
            ? atan2(endVec.y, endVec.x)   : atan2(-n2.y, -n2.x)
        let startAngle = hypot(startVec.x, startVec.y) > 0.01
            ? atan2(startVec.y, startVec.x) : atan2(-n1.y, -n1.x)

        // v63: linjen slutar BAKOM spetsens bas (11pt från tip; basen ligger ~12.6pt
        // från tip) — så varken .round-cap eller strecket syns genom spetsen.
        // Allt ritas i SAMMA solida färg → ser ut som EN pil. (Ersätter v48:s
        // halfLW-indrag som lät strecket lysa igenom den halvtransparenta spetsen.)
        let headInset: CGFloat = 11
        let endHasHead   = (edge.direction == .forward  || edge.direction == .bidirectional)
        let startHasHead = (edge.direction == .backward || edge.direction == .bidirectional)
        let lineEnd: CGPoint = endHasHead
            ? CGPoint(x: end.x - headInset * cos(endAngle),
                      y: end.y - headInset * sin(endAngle))
            : end
        let lineStart: CGPoint = startHasHead
            ? CGPoint(x: start.x - headInset * cos(startAngle),
                      y: start.y - headInset * sin(startAngle))
            : start

        // v63: pilens färg — egen hex eller standard. Solid (ingen opacity).
        let edgeColor: Color = edge.colorHex.flatMap { Color(hexString: $0) }
            ?? Color(hex: 0x3a3f47)

        var path = Path()
        path.move(to: lineStart)
        if let wp = edge.waypoints.first {
            // Mjuk böj via waypoint (quadratic → quadratic)
            path.addQuadCurve(to: wp.point, control: cp1)
            path.addQuadCurve(to: lineEnd,  control: cp2)
        } else {
            // Klassisk S-kurva (cubic bezier)
            path.addCurve(to: lineEnd, control1: cp1, control2: cp2)
        }
        context.stroke(path, with: .color(edgeColor), style: strokeStyle)

        // Pilhuvuden ritas vid ORIGINAL end/start (linjen slutar vid spetsbasen)
        switch edge.direction {
        case .forward:       drawArrowHead(context: context, tip: end,   angle: endAngle, color: edgeColor)
        case .backward:      drawArrowHead(context: context, tip: start, angle: startAngle, color: edgeColor)
        case .bidirectional:
            drawArrowHead(context: context, tip: end,   angle: endAngle, color: edgeColor)
            drawArrowHead(context: context, tip: start, angle: startAngle, color: edgeColor)
        case .none: break
        }
    }
}
