import Foundation
import CoreGraphics

/// Ren kant-geometri (MA spår A steg 6): utgångspunkter på formernas ytor,
/// sid-/diamant-centra, rotation och bezier-anchors. Statiska funktioner utan
/// eget tillstånd — formerna och dolda-id trådas in. Bröts ut ur EdgesView;
/// matematiken är ordagrant oförändrad (samma round-trip-garanti).
enum EdgeGeometry {

    /// v50 F-03: bezier-anchors för en edge — start, end, bezier-mid och tangent vid t=0.5.
    /// Använder samma routing-logik som `EdgeDrawing.drawEdge` så midpoint-handle hamnar på
    /// den faktiska synliga kurvan, även när bezier böjer sig runt obstakel.
    struct EdgeAnchors {
        let start: CGPoint
        let end: CGPoint
        let cp1: CGPoint
        let cp2: CGPoint
        let mid: CGPoint
        let midAngle: Double
    }

    /// v38: utåtriktad normalvektor för en forms yta vid en given kant-punkt.
    /// Avgör vilken yta (V/H/T/B) som är närmast och returnerar ortogonal riktning därifrån.
    static func outwardNormal(for shape: ShapeNode, at point: CGPoint) -> CGPoint {
        var dx = point.x - shape.position.x
        var dy = point.y - shape.position.y
        // v60: rotations-medveten — räkna normalen i formens LOKALA (oroterade) rum
        // och rotera tillbaka. Då blir cp + pilhuvud vinkelrätt mot den FAKTISKA
        // (roterade) sidan → pilen går in rakt även på roterade former.
        let rot = shape.rotation
        if abs(rot) > 0.5 {
            let a = -rot * .pi / 180
            let c = cos(a), s = sin(a)
            let lx = dx * c - dy * s
            let ly = dx * s + dy * c
            dx = lx; dy = ly
        }
        let localNormal: CGPoint
        switch shape.type {
        case .circle, .link:
            let len = hypot(dx, dy)
            localNormal = len > 0.01 ? CGPoint(x: dx / len, y: dy / len) : CGPoint(x: 1, y: 0)
        default:
            let hw = ShapeGeometry.halfWidth(for: shape)
            let hh = ShapeGeometry.halfHeight(for: shape)
            let tx = hw > 0.01 ? abs(dx) / hw : 0
            let ty = hh > 0.01 ? abs(dy) / hh : 0
            if tx >= ty {
                localNormal = dx > 0 ? CGPoint(x: 1, y: 0) : CGPoint(x: -1, y: 0)
            } else {
                localNormal = dy > 0 ? CGPoint(x: 0, y: 1) : CGPoint(x: 0, y: -1)
            }
        }
        guard abs(rot) > 0.5 else { return localNormal }
        let a = rot * .pi / 180
        let c = cos(a), s = sin(a)
        return CGPoint(x: localNormal.x * c - localNormal.y * s,
                       y: localNormal.x * s + localNormal.y * c)
    }

    /// v40: Kant-utgångspunkt med rotationsstöd.
    /// Roterar target-punkten bakåt (−rotation) för att beräkna sida i lokalt koordinatsystem,
    /// sedan roteras resultatet framåt (+rotation) till world-space.
    static func edgePoint(for shape: ShapeNode, towards target: CGPoint) -> CGPoint {
        let center = shape.position
        // Rotera target bakåt för att jobba i formens lokala koordinatsystem
        let unrotatedTarget = canvasRotatePoint(target, around: center, byDegrees: -shape.rotation)
        let dx = unrotatedTarget.x - center.x
        let dy = unrotatedTarget.y - center.y
        guard abs(dx) > 0.001 || abs(dy) > 0.001 else { return center }

        let localPoint: CGPoint
        switch shape.type {
        case .circle, .link:
            // Cirklar: rotation spelar ingen roll, men vi håller konsistens
            let r = ShapeGeometry.circleRadius(for: shape)
            let length = sqrt(dx * dx + dy * dy)
            localPoint = CGPoint(x: center.x + r * dx / length, y: center.y + r * dy / length)
        case .diamond:
            localPoint = diamondSideCenter(center: center, dx: dx, dy: dy, shape: shape)
        case .rectangle, .table, .pill, .square, .processArrow, .container, .octagon, .phoneFrame, .triangle, .cylinder, .emoji:
            localPoint = rectSideCenter(center: center, dx: dx, dy: dy, shape: shape)
        case .line, .arrow:
            return center
        }
        // Rotera resultatet tillbaka till world-space
        return canvasRotatePoint(localPoint, around: center, byDegrees: shape.rotation)
    }

    /// v64: punkt mitt på en VALD sida (i stället för närmaste) — med rotationsstöd.
    /// Används när användaren valt utgångssida via pilens kontextmeny.
    static func sidePoint(for shape: ShapeNode, side: EdgeSide) -> CGPoint {
        let center = shape.position
        let hw: CGFloat
        let hh: CGFloat
        switch shape.type {
        case .circle, .link:
            let r = ShapeGeometry.circleRadius(for: shape)
            hw = r; hh = r
        case .line, .arrow:
            return center
        default:
            hw = ShapeGeometry.halfWidth(for: shape)
            hh = ShapeGeometry.halfHeight(for: shape)
        }
        let local: CGPoint
        switch side {
        case .top:    local = CGPoint(x: center.x,      y: center.y - hh)
        case .bottom: local = CGPoint(x: center.x,      y: center.y + hh)
        case .left:   local = CGPoint(x: center.x - hw, y: center.y)
        case .right:  local = CGPoint(x: center.x + hw, y: center.y)
        }
        return canvasRotatePoint(local, around: center, byDegrees: shape.rotation)
    }

    /// Hjälpfunktion: rotera en punkt runt ett center med grader.
    static func canvasRotatePoint(_ p: CGPoint, around c: CGPoint, byDegrees deg: Double) -> CGPoint {
        guard abs(deg) > 0.5 else { return p }
        let r = deg * .pi / 180
        let dx = p.x - c.x
        let dy = p.y - c.y
        return CGPoint(
            x: c.x + dx * cos(r) - dy * sin(r),
            y: c.y + dx * sin(r) + dy * cos(r)
        )
    }

    /// Mitten på närmaste sida för rektangulära former.
    static func rectSideCenter(center: CGPoint, dx: CGFloat, dy: CGFloat, shape: ShapeNode) -> CGPoint {
        let hw = ShapeGeometry.halfWidth(for: shape)
        let hh = ShapeGeometry.halfHeight(for: shape)
        // Bestäm om vi träffar vänster/höger eller topp/botten
        // Normalisera mot formen (dx/hw vs dy/hh) — störst normaliserad komponent vinner
        let normX = abs(dx) / hw
        let normY = abs(dy) / hh
        if normX >= normY {
            // Vänster eller höger sida
            return CGPoint(x: center.x + (dx > 0 ? hw : -hw), y: center.y)
        } else {
            // Topp eller botten
            return CGPoint(x: center.x, y: center.y + (dy > 0 ? hh : -hh))
        }
    }

    /// Närmaste diamant-spets (top/bottom/left/right).
    static func diamondSideCenter(center: CGPoint, dx: CGFloat, dy: CGFloat, shape: ShapeNode) -> CGPoint {
        let hw = ShapeGeometry.halfWidth(for: shape)
        let hh = ShapeGeometry.halfHeight(for: shape)
        let normX = abs(dx) / hw
        let normY = abs(dy) / hh
        if normX >= normY {
            return CGPoint(x: center.x + (dx > 0 ? hw : -hw), y: center.y)
        } else {
            return CGPoint(x: center.x, y: center.y + (dy > 0 ? hh : -hh))
        }
    }

    /// v50 F-03: bezier-anchors för en edge — samma routing-logik som `EdgeDrawing.drawEdge`.
    static func edgeAnchors(edge: EdgeConnection,
                            fromShape: ShapeNode,
                            toShape: ShapeNode,
                            shapes: [ShapeNode],
                            hiddenShapeIds: Set<UUID>) -> EdgeAnchors {
        let start: CGPoint
        let end: CGPoint
        if let wp = edge.waypoints.first {
            start = edge.fromSide.map { sidePoint(for: fromShape, side: $0) }
                ?? edgePoint(for: fromShape, towards: wp.point)
            end   = edge.toSide.map { sidePoint(for: toShape, side: $0) }
                ?? edgePoint(for: toShape, towards: wp.point)
        } else {
            start = edge.fromSide.map { sidePoint(for: fromShape, side: $0) }
                ?? edgePoint(for: fromShape, towards: toShape.position)
            end   = edge.toSide.map { sidePoint(for: toShape, side: $0) }
                ?? edgePoint(for: toShape, towards: fromShape.position)
        }
        let n1 = outwardNormal(for: fromShape, at: start)
        let n2 = outwardNormal(for: toShape,   at: end)
        // v66: SAMMA delade matte som drawEdge — annars hamnar midpoint-handtaget
        // bredvid den synliga kurvan.
        let cps = EdgeMath.controlPoints(start: start, end: end, n1: n1, n2: n2)
        var cp1 = cps.cp1
        var cp2 = cps.cp2
        // v1.0: linjeform — waypoint vinner (curved); annars edge.lineShape.
        let hasWaypoint = edge.waypoints.first != nil
        let lineShape: EdgeLineShape = hasWaypoint ? .curved : edge.lineShape
        if !hasWaypoint && lineShape == .curved {
            let obstacleBboxes: [CGRect] = shapes.compactMap { obstacle in
                guard obstacle.id != edge.from && obstacle.id != edge.to else { return nil }
                guard !hiddenShapeIds.contains(obstacle.id) else { return nil }
                // V79-svep (Kim): gå runt former, men inte containrar/iPhone-ram.
                if obstacle.type.actsAsContainer { return nil }
                let w = ShapeGeometry.width(for: obstacle)
                let h = ShapeGeometry.height(for: obstacle)
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
        // Mid + vinkel där midpoint-handtaget ska sitta — speglar drawEdge per linjeform.
        let mid: CGPoint
        let midAngle: Double
        switch lineShape {
        case .straight:
            mid = CGPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
            midAngle = atan2(Double(end.y - start.y), Double(end.x - start.x))
        case .orthogonal:
            let corners = EdgeRouting.orthogonalCorners(start: start, end: end, n1: n1, n2: n2)
            let midCorner = corners[corners.count / 2]
            mid = midCorner   // handtaget sitter på en böj
            midAngle = atan2(Double(end.y - midCorner.y), Double(end.x - midCorner.x))
        case .curved:
            let u: CGFloat = 0.5
            let v: CGFloat = 1 - u
            mid = CGPoint(
                x: v*v*v*start.x + 3*v*v*u*cp1.x + 3*v*u*u*cp2.x + u*u*u*end.x,
                y: v*v*v*start.y + 3*v*v*u*cp1.y + 3*v*u*u*cp2.y + u*u*u*end.y
            )
            let tx = 3*v*v*(cp1.x - start.x) + 6*v*u*(cp2.x - cp1.x) + 3*u*u*(end.x - cp2.x)
            let ty = 3*v*v*(cp1.y - start.y) + 6*v*u*(cp2.y - cp1.y) + 3*u*u*(end.y - cp2.y)
            midAngle = atan2(Double(ty), Double(tx))
        }
        return EdgeAnchors(start: start, end: end,
                           cp1: cp1, cp2: cp2,
                           mid: mid, midAngle: midAngle)
    }

    /// 1.3: kollaps-stubbens geometri (flyttad hit ur EdgesView så badge-LAGRET kan dela den).
    /// Solfjäder-spridning när flera kollapsade grenar delar samma from-nod. Matematik oförändrad.
    static func stubGeometry(for edge: EdgeConnection, fromShape: ShapeNode, toShape: ShapeNode,
                             edges: [EdgeConnection], collapsedEdgeIds: Set<UUID>) -> (start: CGPoint, end: CGPoint) {
        let siblings = edges.filter { $0.from == edge.from && collapsedEdgeIds.contains($0.id) }
        let idx = siblings.firstIndex(where: { $0.id == edge.id }) ?? 0
        let count = max(siblings.count, 1)
        let baseAngle = atan2(toShape.position.y - fromShape.position.y,
                              toShape.position.x - fromShape.position.x)
        let angle = baseAngle + (CGFloat(idx) - CGFloat(count - 1) / 2) * 0.5
        let start = edgePoint(for: fromShape, towards: toShape.position)
        let stubLen: CGFloat = 62
        return (start, CGPoint(x: start.x + stubLen * cos(angle), y: start.y + stubLen * sin(angle)))
    }

    /// 1.5.4 (Bug 4 — Kim "på pilen"): minus-badgen sitter på pilens MITTPUNKT (samma `mid`
    /// som midpoint-handtaget, rätt även på böjda/ortogonala pilar) — långt från de fyra gröna
    /// kant-mitt-handtagen, så ingen krock. Liten perpendikulär knuff så linjen syns bredvid.
    /// (Tidigare: vid utgångspunkten + 36pt radiell puff — räckte inte, låg kvar på höger +-handtag.)
    static func minusBadgePosition(edge: EdgeConnection, fromShape: ShapeNode, toShape: ShapeNode,
                                   shapes: [ShapeNode], hiddenShapeIds: Set<UUID>) -> CGPoint {
        let anchors = edgeAnchors(edge: edge, fromShape: fromShape, toShape: toShape,
                                  shapes: shapes, hiddenShapeIds: hiddenShapeIds)
        let nudge: CGFloat = 14
        let px = CGFloat(-sin(anchors.midAngle))
        let py = CGFloat(cos(anchors.midAngle))
        return CGPoint(x: anchors.mid.x + px * nudge,
                       y: anchors.mid.y + py * nudge)
    }
}
