import SwiftUI
import CoreGraphics

/// v43: Visuell routing av kanter runt former (Lucidchart-style).
/// Påverkar endast app-rendering, INTE Mermaid-export.
enum EdgeRouting {

    /// Returnerar kontrollpunkter för en cubic bezier som routar runt obstacles.
    /// Om ingen krock: returnerar standard control points (mjuk kurva).
    /// v47: iterativ multi-obstacle-routing — om bezier-kurvan med justerade cps
    /// fortfarande krockar med ett annat obstacle, pusha ytterligare; max 5 iterationer.
    /// Ger jämn kurva förbi 2–3 hindrande former istället för att fastna på det första.
    static func controlPoints(
        from: CGPoint,
        to: CGPoint,
        obstacles: [CGRect]
    ) -> (cp1: CGPoint, cp2: CGPoint) {
        let dx = to.x - from.x
        let dy = to.y - from.y
        let dist = sqrt(dx*dx + dy*dy)

        // Standard control points (ingen routing) — ger en mjuk svag kurva
        var cp1 = CGPoint(x: from.x + dx * 0.35, y: from.y + dy * 0.35)
        var cp2 = CGPoint(x: from.x + dx * 0.65, y: from.y + dy * 0.65)

        guard dist > 1 else { return (cp1, cp2) }

        let nx = -dy / dist
        let ny = dx / dist

        // v47: iterativ obstacle-avoidance. För varje obstacle som ligger på den
        // nuvarande bezier-kurvan, addera push i motsatt riktning. Begränsa till
        // 5 iterationer för stabilitet — vid degenererad geometri (alla obstacles
        // ligger på samma sida) ger fler iterationer ingen förbättring.
        var iterations = 0
        let maxIterations = 5
        while iterations < maxIterations {
            guard let obstacle = firstObstacleOnBezier(
                start: from, cp1: cp1, cp2: cp2, end: to,
                obstacles: obstacles
            ) else { break }

            let obsCenter = CGPoint(x: obstacle.midX, y: obstacle.midY)
            let side = (obsCenter.x - from.x) * nx + (obsCenter.y - from.y) * ny
            let pushDir: CGFloat = side >= 0 ? -1 : 1
            let pushAmount = (max(obstacle.width, obstacle.height) / 2) + 40

            cp1.x += nx * pushAmount * pushDir
            cp1.y += ny * pushAmount * pushDir
            cp2.x += nx * pushAmount * pushDir
            cp2.y += ny * pushAmount * pushDir
            iterations += 1
        }
        return (cp1, cp2)
    }

    /// v47: Returnerar första obstacle som en cubic bezier (start→cp1→cp2→end) korsar.
    /// Approximation via 16 sample-segment längs kurvan + line-segment-rect-intersection.
    private static func firstObstacleOnBezier(
        start: CGPoint, cp1: CGPoint, cp2: CGPoint, end: CGPoint,
        obstacles: [CGRect]
    ) -> CGRect? {
        let samples = 16
        var pts: [CGPoint] = []
        pts.reserveCapacity(samples + 1)
        for i in 0...samples {
            let t = CGFloat(i) / CGFloat(samples)
            pts.append(cubicBezierPoint(t: t, p0: start, p1: cp1, p2: cp2, p3: end))
        }
        for obstacle in obstacles {
            for j in 0..<pts.count - 1 {
                if lineSegmentIntersects(rect: obstacle, p1: pts[j], p2: pts[j + 1]) {
                    return obstacle
                }
            }
        }
        return nil
    }

    /// v47: utvärderar en cubic bezier-kurva vid parameter t ∈ [0, 1].
    private static func cubicBezierPoint(
        t: CGFloat, p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint
    ) -> CGPoint {
        let u = 1 - t
        let uu = u * u
        let uuu = uu * u
        let tt = t * t
        let ttt = tt * t
        let x = uuu * p0.x + 3 * uu * t * p1.x + 3 * u * tt * p2.x + ttt * p3.x
        let y = uuu * p0.y + 3 * uu * t * p1.y + 3 * u * tt * p2.y + ttt * p3.y
        return CGPoint(x: x, y: y)
    }

    /// v43: snabb check — finns det överhuvudtaget en obstacle som blockerar linjen?
    /// Används för att avgöra om vi ska byta ut befintliga (Lucidchart-normal-baserade)
    /// kontrollpunkter mot routing-baserade. Returnerar false → behåll befintliga cps.
    static func hasObstacle(from: CGPoint, to: CGPoint, obstacles: [CGRect]) -> Bool {
        firstIntersectingObstacle(from: from, to: to, obstacles: obstacles) != nil
    }

    /// Returnerar den första obstacle-bbox:en linjen från→till korsar (nil om ingen).
    private static func firstIntersectingObstacle(
        from: CGPoint, to: CGPoint, obstacles: [CGRect]
    ) -> CGRect? {
        for r in obstacles {
            if lineSegmentIntersects(rect: r, p1: from, p2: to) {
                return r
            }
        }
        return nil
    }

    /// Cohen-Sutherland-baserad segment-vs-rect intersection.
    /// Sann om linjesegmentet (p1→p2) skär eller är inuti rektangeln.
    private static func lineSegmentIntersects(rect: CGRect, p1: CGPoint, p2: CGPoint) -> Bool {
        // Kollar först om någon endpoint är inuti rect
        if rect.contains(p1) || rect.contains(p2) { return true }
        // Kollar sedan om segmentet korsar någon av rektanglens 4 kanter
        let corners = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.maxY)
        ]
        let edges: [(CGPoint, CGPoint)] = [
            (corners[0], corners[1]),
            (corners[1], corners[2]),
            (corners[2], corners[3]),
            (corners[3], corners[0])
        ]
        for (a, b) in edges {
            if segmentsIntersect(p1, p2, a, b) { return true }
        }
        return false
    }

    private static func segmentsIntersect(_ p: CGPoint, _ p2: CGPoint, _ q: CGPoint, _ q2: CGPoint) -> Bool {
        func cross(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> CGFloat {
            (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x)
        }
        let d1 = cross(q, q2, p)
        let d2 = cross(q, q2, p2)
        let d3 = cross(p, p2, q)
        let d4 = cross(p, p2, q2)
        if ((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
           ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0)) {
            return true
        }
        return false
    }
}
