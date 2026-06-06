import XCTest
import CoreGraphics
@testable import MermaidCanvas

/// v66: EdgeMath — rund båge för fromSide-pilar utan att röra vanliga pilar.
final class V66EdgeMathTests: XCTestCase {

    private func cubic(t: CGFloat, p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint) -> CGPoint {
        let u = 1 - t
        return CGPoint(
            x: u*u*u*p0.x + 3*u*u*t*p1.x + 3*u*t*t*p2.x + t*t*t*p3.x,
            y: u*u*u*p0.y + 3*u*u*t*p1.y + 3*u*t*t*p2.y + t*t*t*p3.y)
    }

    private func tangentAngle(t: CGFloat, p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint) -> CGFloat {
        let u = 1 - t
        let dx = 3*u*u*(p1.x-p0.x) + 6*u*t*(p2.x-p1.x) + 3*t*t*(p3.x-p2.x)
        let dy = 3*u*u*(p1.y-p0.y) + 6*u*t*(p2.y-p1.y) + 3*t*t*(p3.y-p2.y)
        return atan2(dy, dx)
    }

    /// Största tangent-vinkeländring mellan närliggande samplingar — "knyck-mått".
    private func maxKink(p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint) -> CGFloat {
        var worst: CGFloat = 0
        var prev = tangentAngle(t: 0.02, p0: p0, p1: p1, p2: p2, p3: p3)
        var t: CGFloat = 0.07
        while t <= 0.98 {
            let a = tangentAngle(t: t, p0: p0, p1: p1, p2: p2, p3: p3)
            var d = abs(a - prev)
            if d > .pi { d = 2 * .pi - d }
            worst = max(worst, d)
            prev = a
            t += 0.05
        }
        return worst
    }

    private let sides: [(namn: String, n: CGPoint)] = [
        ("top", CGPoint(x: 0, y: -1)), ("right", CGPoint(x: 1, y: 0)),
        ("bottom", CGPoint(x: 0, y: 1)), ("left", CGPoint(x: -1, y: 0)),
    ]

    /// Kims fynd: fromSide-normal mot motsatt håll fick spetsig knyck.
    /// Krav: kurvan lämnar formen LÄNGS vald sida och har ingen hård knyck.
    func testRundBageForAllaSidorOchMalriktningar() {
        for side in sides {
            for i in 0..<8 {
                let ang = CGFloat(i) * .pi / 4
                let start = CGPoint.zero
                let end = CGPoint(x: cos(ang) * 280, y: sin(ang) * 280)
                // målets inåt-normal: pekar tillbaka mot start (rak ingång)
                let n2 = CGPoint(x: -cos(ang), y: -sin(ang))
                let cps = EdgeMath.controlPoints(start: start, end: end, n1: side.n, n2: n2)

                // 1) Kurvan går ut längs vald sida: punkten vid t=0.1 ligger åt n1-hållet
                let p = cubic(t: 0.1, p0: start, p1: cps.cp1, p2: cps.cp2, p3: end)
                let outward = p.x * side.n.x + p.y * side.n.y
                XCTAssertGreaterThan(outward, 0,
                    "\(side.namn) mot mål \(i): kurvan ska lämna formen åt \(side.namn)-hållet")

                // 2) Ingen spetsig knyck: max tangent-sväng per 5%-steg < 45°.
                // Värsta lagliga fallet är en hårnål (sida rakt bort från målet,
                // 180° total vändning) — en RUND sådan toppar på ~41°/steg.
                // Gamla matten gav 180°/steg (tvär kollinjär vändning).
                let kink = maxKink(p0: start, p1: cps.cp1, p2: cps.cp2, p3: end)
                XCTAssertLessThan(kink, 45 * .pi / 180,
                    "\(side.namn) mot mål \(i): knyck \(kink * 180 / .pi)° — bågen ska vara rund")
            }
        }
    }

    /// Regressionslås (v50 F-04): pil där normalen redan pekar MOT målet
    /// får EXAKT samma kontrollpunkter som gamla formeln (tension = dist*0.18 cap 60).
    func testVanligPilOforandrad() {
        let start = CGPoint(x: 0, y: 0)
        let end = CGPoint(x: 300, y: 0)
        let n1 = CGPoint(x: 1, y: 0)
        let n2 = CGPoint(x: -1, y: 0)
        let cps = EdgeMath.controlPoints(start: start, end: end, n1: n1, n2: n2)
        let tension = min(300 * 0.18, 60)  // = 54
        XCTAssertEqual(cps.cp1.x, tension, accuracy: 0.001)
        XCTAssertEqual(cps.cp2.x, 300 - tension, accuracy: 0.001)
    }

    /// Diagonal pil (normal vinkelrät mot riktningen, alignment ≈ 0) ska
    /// inte heller förlängas — annars återkommer v50:s S-kurva.
    func testDiagonalPilOforandrad() {
        let start = CGPoint.zero
        let end = CGPoint(x: 200, y: 200)
        let n1 = CGPoint(x: 1, y: 0)   // höger sida, målet snett ner — alignment > 0? dot=0.707
        let n2 = CGPoint(x: 0, y: -1)  // målets ovansida
        let cps = EdgeMath.controlPoints(start: start, end: end, n1: n1, n2: n2)
        let base = min(hypot(200, 200) * 0.18, 60)
        // alignment > 0 → ingen förlängning alls
        XCTAssertEqual(hypot(cps.cp1.x - start.x, cps.cp1.y - start.y), base, accuracy: 0.001)
        XCTAssertEqual(hypot(cps.cp2.x - end.x, cps.cp2.y - end.y), base, accuracy: 0.001)
    }

    /// Förlängningen är cappad — ingen exploderande loop.
    func testTensionCap() {
        let cps = EdgeMath.controlPoints(start: .zero,
                                         end: CGPoint(x: 0, y: 800),
                                         n1: CGPoint(x: 0, y: -1),   // rakt bort från målet
                                         n2: CGPoint(x: 0, y: -1))
        let t1 = hypot(cps.cp1.x, cps.cp1.y)
        XCTAssertLessThanOrEqual(t1, 150.001, "Cap 150 ska hålla")
        XCTAssertGreaterThan(t1, 100, "Motriktad normal ska ge ordentlig utsväng")
    }
}
