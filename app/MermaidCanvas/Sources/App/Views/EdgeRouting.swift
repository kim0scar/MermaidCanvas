import SwiftUI
import CoreGraphics

/// v43: Visuell routing av kanter runt former (Lucidchart-style).
/// Påverkar endast app-rendering, INTE Mermaid-export.
enum EdgeRouting {

    /// Returnerar kontrollpunkter för en cubic bezier som routar runt obstacles.
    /// Om ingen krock: returnerar standard control points (mjuk kurva).
    /// Om krock: justerar control points så kurvan böjer sig runt obstacle.
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

        // Hitta första obstacle som linjen korsar
        guard let obstacle = firstIntersectingObstacle(from: from, to: to, obstacles: obstacles) else {
            return (cp1, cp2)
        }

        // Beräkna routing: pusha control points sidledes från obstacle
        let obsCenter = CGPoint(x: obstacle.midX, y: obstacle.midY)
        // Normal-riktning vinkelrätt mot linjen
        let nx = -dy / dist
        let ny = dx / dist
        // Vilken sida av linjen är obstacle? (positiv = höger, negativ = vänster)
        let side = (obsCenter.x - from.x) * nx + (obsCenter.y - from.y) * ny
        // Pusha control points i MOTSATT riktning från obstacle
        let pushDir: CGFloat = side >= 0 ? -1 : 1
        // Pusha så långt att kurvan tydligt går runt
        let pushAmount = (max(obstacle.width, obstacle.height) / 2) + 40

        cp1.x += nx * pushAmount * pushDir
        cp1.y += ny * pushAmount * pushDir
        cp2.x += nx * pushAmount * pushDir
        cp2.y += ny * pushAmount * pushDir

        return (cp1, cp2)
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
