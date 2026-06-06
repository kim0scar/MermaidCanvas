import CoreGraphics

/// v66: delad bezier-matte för kanter — EN sanning för drawEdge OCH edgeAnchors
/// (koden var tidigare duplicerad och kunde glida isär → midpoint-handtag
/// bredvid den synliga kurvan).
enum EdgeMath {

    /// Kontrollpunkter för kant-kurvan (Lucidchart-stil).
    ///
    /// v66: VINKELMEDVETEN — när utgångsnormalen (n1, vald via fromSide) pekar
    /// BORT från målet förlängs kontrollpunkten längs normalen så kurvan svänger
    /// ut i en RUND BÅGE i stället för att knäcka spetsigt (Kims fynd).
    /// Förlängningen aktiveras BARA när normalen pekar bort (alignment < 0) —
    /// vanliga raka/diagonala pilar får exakt samma kurva som tidigare
    /// (ingen v50 F-04-regression).
    static func controlPoints(start: CGPoint, end: CGPoint,
                              n1: CGPoint, n2: CGPoint) -> (cp1: CGPoint, cp2: CGPoint) {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let dist = hypot(dx, dy)
        guard dist > 0.01 else { return (start, end) }
        // v50 F-04: 0.18 + cap 60 = dämpad böjning för diagonaler
        let base = min(dist * 0.18, 60)
        let ux = dx / dist
        let uy = dy / dist
        // alignment: 1 = normalen pekar rakt mot målet, -1 = rakt bort
        let align1 = n1.x * ux + n1.y * uy
        let align2 = -(n2.x * ux + n2.y * uy)   // n2 ska peka mot starten
        let k: CGFloat = 2.0
        let maxTension: CGFloat = 150
        let t1 = min(base * (1 + k * max(0, -align1)), maxTension)
        let t2 = min(base * (1 + k * max(0, -align2)), maxTension)
        // Vinkelrät sväng-komponent: när normalen pekar bort från målet räcker
        // det inte att förlänga längs normalen — i värsta fallet (rakt motsatt
        // håll) blir alla punkter kollinjära och kurvan viker 180° på sig själv.
        // En vinkelrät komponent (mot målets sida) gör vändningen till en båge.
        let cp1 = swungControl(from: start, normal: n1, tension: t1,
                               align: align1, ux: ux, uy: uy, cap: maxTension)
        let cp2 = swungControl(from: end, normal: n2, tension: t2,
                               align: align2, ux: -ux, uy: -uy, cap: maxTension)
        return (cp1, cp2)
    }

    private static func swungControl(from p: CGPoint, normal n: CGPoint,
                                     tension: CGFloat, align: CGFloat,
                                     ux: CGFloat, uy: CGFloat,
                                     cap: CGFloat) -> CGPoint {
        // perp till normalen, vald så den pekar mot målets håll
        var perpX = -n.y
        var perpY = n.x
        if perpX * ux + perpY * uy < 0 { perpX = -perpX; perpY = -perpY }
        let swing = tension * 0.9 * max(0, -align)
        var vx = n.x * tension + perpX * swing
        var vy = n.y * tension + perpY * swing
        // cappen gäller hela offset-vektorn, inte bara normal-komponenten
        let len = hypot(vx, vy)
        if len > cap { vx *= cap / len; vy *= cap / len }
        return CGPoint(x: p.x + vx, y: p.y + vy)
    }
}
