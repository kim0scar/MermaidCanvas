import SwiftUI

// MARK: - Canvas-form-definitioner
// v42: Flyttat hit från CanvasView.swift så att toolbar-chips OCH canvas
// kan referera EXAKT samma form-definitioner. Tidigare divergerade chip-rendering
// från canvas-rendering vilket gav fel proportioner i toolbaren.

/// v28: rundad romb/diamant — mjuka hörn istället för vassa spetsar.
/// v35.1: fyller hela ramen (120×80) → bredare-än-hög romb som matchar Mermaid's {} render.
struct DiamondShape: Shape {
    /// v50.8 F6-analogt: radie = procent av höjd (default 0.075) så chip OCH canvas
    /// får proportionellt likvärdig rundning. Tidigare fixt 6pt → chip (h=20) blev
    /// 30% rundat (knubbigt), canvas (h=80) 7.5% (vasst). Nu samma proportion på båda.
    var cornerRadiusRatio: CGFloat = DesignTokens.Shape.diamondCornerRadiusRatio

    func path(in rect: CGRect) -> Path {
        let top    = CGPoint(x: rect.midX, y: rect.minY)
        let right  = CGPoint(x: rect.maxX, y: rect.midY)
        let bottom = CGPoint(x: rect.midX, y: rect.maxY)
        let left   = CGPoint(x: rect.minX, y: rect.midY)

        let r = min(rect.height * cornerRadiusRatio, min(rect.width, rect.height) / 4)
        // För varje hörn: gå r-pt åt vardera håll längs kanten innan hörnet
        // och rita en quad-curve runt själva hörnet.
        let topToRightDir = unitVector(from: top, to: right)
        let rightToBottomDir = unitVector(from: right, to: bottom)
        let bottomToLeftDir = unitVector(from: bottom, to: left)
        let leftToTopDir = unitVector(from: left, to: top)

        var p = Path()
        p.move(to: offset(top, by: topToRightDir, amount: r))
        p.addLine(to: offset(right, by: topToRightDir, amount: -r))
        p.addQuadCurve(to: offset(right, by: rightToBottomDir, amount: r), control: right)
        p.addLine(to: offset(bottom, by: rightToBottomDir, amount: -r))
        p.addQuadCurve(to: offset(bottom, by: bottomToLeftDir, amount: r), control: bottom)
        p.addLine(to: offset(left, by: bottomToLeftDir, amount: -r))
        p.addQuadCurve(to: offset(left, by: leftToTopDir, amount: r), control: left)
        p.addLine(to: offset(top, by: leftToTopDir, amount: -r))
        p.addQuadCurve(to: offset(top, by: topToRightDir, amount: r), control: top)
        p.closeSubpath()
        return p
    }

    private func unitVector(from a: CGPoint, to b: CGPoint) -> CGVector {
        let dx = b.x - a.x
        let dy = b.y - a.y
        let len = sqrt(dx * dx + dy * dy)
        guard len > 0.001 else { return CGVector(dx: 0, dy: 0) }
        return CGVector(dx: dx / len, dy: dy / len)
    }

    private func offset(_ p: CGPoint, by v: CGVector, amount: CGFloat) -> CGPoint {
        CGPoint(x: p.x + v.dx * amount, y: p.y + v.dy * amount)
    }
}

// MARK: - Nya grundformer v35.1

/// Liksidig kvadrat med rundade hörn — identisk med RoundedRectangle men kvadratisk.
/// ShapeGeometry ger 80×80-ram; formen fyller den.
struct SquareShape: Shape {
    /// v50.5 F6: radie = procent av min(width, height) så chip OCH canvas
    /// får visuellt likvärdig rundning. Default 12.5% från DesignTokens.
    /// Behåller cornerRadius som override för fall där fixt värde behövs.
    var cornerRadiusRatio: CGFloat = DesignTokens.Shape.squareCornerRadiusRatio
    func path(in rect: CGRect) -> Path {
        let r = min(rect.width, rect.height) * cornerRadiusRatio
        return Path(roundedRect: rect, cornerRadius: r, style: .continuous)
    }
}

/// Processsteg-pil — pentagon med rak vänsterkant och spetsig högerände.
/// v41: platt vänsterkant → matchar arrowshape.right-ikonen exakt.
/// v50.2 F-4: rundade hörn (cornerRadius=8) på alla 4 raka hörn så formspråket
/// matchar rektangel/square/pill. Spetsen (rightmost punkt) hålls skarp för
/// att behålla "processpil"-identiteten.
struct ProcessArrowShape: Shape {
    /// v50.5 F3: radie = procent av höjd (default 0.18) så chip OCH canvas får
    /// proportionellt likvärdig rundning. Tidigare fixt 8pt clampades olika
    /// (chip 18pt → 3.24pt vs canvas 80pt → 8pt). Procent → båda ~18% av höjd.
    var cornerRadiusRatio: CGFloat = DesignTokens.Shape.processArrowCornerRadiusRatio

    func path(in rect: CGRect) -> Path {
        let tip: CGFloat = rect.width * 0.35   // spets = 35% av bredden
        // Radie = procent av höjd, cappad så geometrin inte degenererar:
        // - (width - tip)/2 skyddar bredden (smala former)
        // - height/2 skyddar höjden (platta former) — v50.9-tillägg
        let r = min(rect.height * cornerRadiusRatio, (rect.width - tip) / 2, rect.height / 2)

        // De fem hörnen i ordning runt formen
        let topLeft      = CGPoint(x: rect.minX,       y: rect.minY)
        let topJoint     = CGPoint(x: rect.maxX - tip, y: rect.minY)
        let tipPoint     = CGPoint(x: rect.maxX,       y: rect.midY)
        let bottomJoint  = CGPoint(x: rect.maxX - tip, y: rect.maxY)
        let bottomLeft   = CGPoint(x: rect.minX,       y: rect.maxY)

        // Rikt-vektorer mellan hörn (för att veta åt vilket håll radien ska "krympa")
        func unit(from a: CGPoint, to b: CGPoint) -> CGVector {
            let dx = b.x - a.x, dy = b.y - a.y
            let len = sqrt(dx * dx + dy * dy)
            return len > 0.001 ? CGVector(dx: dx / len, dy: dy / len) : .zero
        }
        func off(_ p: CGPoint, by v: CGVector, _ amt: CGFloat) -> CGPoint {
            CGPoint(x: p.x + v.dx * amt, y: p.y + v.dy * amt)
        }

        // Riktningar längs perimetern medurs: topLeft→topJoint→tip→bottomJoint→bottomLeft→topLeft
        let tl_tj = unit(from: topLeft, to: topJoint)
        let tj_tp = unit(from: topJoint, to: tipPoint)
        let tp_bj = unit(from: tipPoint, to: bottomJoint)
        let bj_bl = unit(from: bottomJoint, to: bottomLeft)
        let bl_tl = unit(from: bottomLeft, to: topLeft)

        var p = Path()
        // Start: en bit höger om topLeft (efter top-left-rundning)
        p.move(to: off(topLeft, by: tl_tj, r))
        // Övre kant → topJoint, runda hörnet ner mot spetsen
        p.addLine(to: off(topJoint, by: tl_tj, -r))
        p.addQuadCurve(to: off(topJoint, by: tj_tp, r), control: topJoint)
        // v60: RUNDAD spets — quadCurve runt tipPoint (Kim: "rund på högersidan").
        // tipR cappad mot spetsbredd + höjd så den inte degenererar på små/platta former.
        let tipR = min(r, tip * 0.5, rect.height / 3)
        p.addLine(to: off(tipPoint, by: tj_tp, -tipR))
        p.addQuadCurve(to: off(tipPoint, by: tp_bj, tipR), control: tipPoint)
        // Diagonal ner till bottomJoint, runda hörnet upp mot botten
        p.addLine(to: off(bottomJoint, by: tp_bj, -r))
        p.addQuadCurve(to: off(bottomJoint, by: bj_bl, r), control: bottomJoint)
        // Nedre kant → bottomLeft, runda hörnet upp
        p.addLine(to: off(bottomLeft, by: bj_bl, -r))
        p.addQuadCurve(to: off(bottomLeft, by: bl_tl, r), control: bottomLeft)
        // Vänsterkant → topLeft, runda hörnet höger
        p.addLine(to: off(topLeft, by: bl_tl, -r))
        p.addQuadCurve(to: off(topLeft, by: tl_tj, r), control: topLeft)
        p.closeSubpath()
        return p
    }

    private func amt(_ v: CGFloat) -> CGFloat { v }
}

// MARK: - Octagon v51.1

/// Åttahörning med rundade hörn. Reguljär oktagon i bounding-box (hörnen avfasade)
/// + lätt rundning på de 8 vertexarna (quadCurve) så formspråket matchar övriga
/// rundade former. chip OCH canvas använder samma `cornerRadiusRatio` → matchar.
struct OctagonShape: Shape {
    var cornerRadiusRatio: CGFloat = DesignTokens.Shape.octagonCornerRadiusRatio
    /// Hur mycket hörnen fasas (andel av min-sida) — definierar oktagon-silhuetten.
    var chamferRatio: CGFloat = 0.29

    func path(in rect: CGRect) -> Path {
        let c = min(rect.width, rect.height) * chamferRatio
        let pts = [
            CGPoint(x: rect.minX + c, y: rect.minY),
            CGPoint(x: rect.maxX - c, y: rect.minY),
            CGPoint(x: rect.maxX,     y: rect.minY + c),
            CGPoint(x: rect.maxX,     y: rect.maxY - c),
            CGPoint(x: rect.maxX - c, y: rect.maxY),
            CGPoint(x: rect.minX + c, y: rect.maxY),
            CGPoint(x: rect.minX,     y: rect.maxY - c),
            CGPoint(x: rect.minX,     y: rect.minY + c)
        ]
        // Runda de 8 hörnen, men aldrig mer än halva kortaste kanten tål.
        let r = min(rect.height * cornerRadiusRatio, c * 0.8)
        var p = Path()
        let n = pts.count
        for i in 0..<n {
            let curr = pts[i]
            let prev = pts[(i - 1 + n) % n]
            let next = pts[(i + 1) % n]
            let dIn = unit(from: prev, to: curr)
            let dOut = unit(from: curr, to: next)
            let pStart = CGPoint(x: curr.x - dIn.dx * r, y: curr.y - dIn.dy * r)
            let pEnd   = CGPoint(x: curr.x + dOut.dx * r, y: curr.y + dOut.dy * r)
            if i == 0 { p.move(to: pStart) } else { p.addLine(to: pStart) }
            p.addQuadCurve(to: pEnd, control: curr)
        }
        p.closeSubpath()
        return p
    }

    private func unit(from a: CGPoint, to b: CGPoint) -> CGVector {
        let dx = b.x - a.x, dy = b.y - a.y
        let len = sqrt(dx * dx + dy * dy)
        return len > 0.001 ? CGVector(dx: dx / len, dy: dy / len) : .zero
    }
}

// MARK: - Trekant v68

/// v68: liksidig trekant med rundade hörn. Topp-vertex centrerad upptill,
/// nedre två hörnen i botten — höjden anpassas så sidorna blir lika långa
/// inom ramen (ShapeGeometry ger 80×80, men vi ritar den liksidiga triangeln
/// centrerad). Rundade hörn via quadCurve (samma mönster som OctagonShape).
struct TriangleShape: Shape {
    var cornerRadiusRatio: CGFloat = DesignTokens.Shape.triangleCornerRadiusRatio
    func path(in rect: CGRect) -> Path {
        // Liksidig triangel centrerad i rect: sidlängd = min(bredd, höjd-anpassad).
        let side = min(rect.width, rect.height * 2 / sqrt(3))
        let h = side * sqrt(3) / 2
        let cx = rect.midX
        let cy = rect.midY
        let top    = CGPoint(x: cx,            y: cy - h / 2)
        let left   = CGPoint(x: cx - side / 2, y: cy + h / 2)
        let right  = CGPoint(x: cx + side / 2, y: cy + h / 2)
        let r = min(h * cornerRadiusRatio, side / 4)

        func unit(from a: CGPoint, to b: CGPoint) -> CGVector {
            let dx = b.x - a.x, dy = b.y - a.y
            let len = sqrt(dx * dx + dy * dy)
            return len > 0.001 ? CGVector(dx: dx / len, dy: dy / len) : .zero
        }
        func off(_ p: CGPoint, by v: CGVector, _ amt: CGFloat) -> CGPoint {
            CGPoint(x: p.x + v.dx * amt, y: p.y + v.dy * amt)
        }
        let t_l = unit(from: top, to: left)
        let l_r = unit(from: left, to: right)
        let r_t = unit(from: right, to: top)

        var p = Path()
        p.move(to: off(top, by: t_l, r))
        p.addLine(to: off(left, by: t_l, -r))
        p.addQuadCurve(to: off(left, by: l_r, r), control: left)
        p.addLine(to: off(right, by: l_r, -r))
        p.addQuadCurve(to: off(right, by: r_t, r), control: right)
        p.addLine(to: off(top, by: r_t, -r))
        p.addQuadCurve(to: off(top, by: t_l, r), control: top)
        p.closeSubpath()
        return p
    }
}

// MARK: - Cylinder v69

/// v69: cylinder/databas-form (för Bevis-noder). Topp-ellips + raka sidor +
/// botten-båge. Round-trippar som native mermaid `[(...)]`.
struct CylinderShape: Shape {
    /// Ellipsens höjd som andel av formens höjd (locket).
    var capRatio: CGFloat = 0.18
    func path(in rect: CGRect) -> Path {
        let ry = min(rect.height * capRatio, rect.height / 2)
        let topRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: ry * 2)
        var p = Path()
        // Vänster sida ned
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + ry))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - ry))
        // Botten-halvellips (framsidan) — samma ellipshöjd som locket, håller sig
        // inom formens ram (tidigare cirkelbåge med radie = halva bredden svämmade
        // över ramen och fick breda cylindrar att se ut som djupa koppar).
        let k: CGFloat = 0.5523
        let rx = rect.width / 2
        let cy = rect.maxY - ry
        p.addCurve(to: CGPoint(x: rect.midX, y: rect.maxY),
                   control1: CGPoint(x: rect.minX, y: cy + k * ry),
                   control2: CGPoint(x: rect.midX - k * rx, y: rect.maxY))
        p.addCurve(to: CGPoint(x: rect.maxX, y: cy),
                   control1: CGPoint(x: rect.midX + k * rx, y: rect.maxY),
                   control2: CGPoint(x: rect.maxX, y: cy + k * ry))
        // Höger sida upp
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + ry))
        // Topp-ellips (hela locket)
        p.addEllipse(in: topRect)
        return p
    }
}

// MARK: - Tabell-glyf v68

/// v68: inramad tabell-ikon för toolbar-chipet (Kims fynd: SF-symbolen såg inte
/// ut som en tabell). Yttre rundad ram + 2 lodräta + 2 vågräta inre linjer = 3×3.
struct TableGlyph: View {
    var stroke: Color = .primary
    var lineWidth: CGFloat = 1.5
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .stroke(stroke, lineWidth: lineWidth)
                Path { p in
                    // Lodräta inre linjer (3 kolumner)
                    p.move(to: CGPoint(x: w / 3, y: 0));     p.addLine(to: CGPoint(x: w / 3, y: h))
                    p.move(to: CGPoint(x: 2 * w / 3, y: 0)); p.addLine(to: CGPoint(x: 2 * w / 3, y: h))
                    // Vågräta inre linjer (3 rader)
                    p.move(to: CGPoint(x: 0, y: h / 3));     p.addLine(to: CGPoint(x: w, y: h / 3))
                    p.move(to: CGPoint(x: 0, y: 2 * h / 3)); p.addLine(to: CGPoint(x: w, y: 2 * h / 3))
                }
                .stroke(stroke, lineWidth: lineWidth * 0.8)
            }
        }
    }
}

// MARK: - iPhone-ram v67

/// v67: yttre bezel-silhuett för iPhone-ramen — används av stroke/highlight/selection.
/// Rundningen följer min-sidan (bredden) så den ser ut som en telefon vid alla storlekar.
struct PhoneFrameShape: Shape {
    var cornerRadiusRatio: CGFloat = DesignTokens.Shape.phoneFrameCornerRadiusRatio
    func path(in rect: CGRect) -> Path {
        let r = min(rect.width, rect.height) * cornerRadiusRatio
        return Path(roundedRect: rect, cornerRadius: r, style: .continuous)
    }
}

/// v67: iPhone 16 Pro-ram — mörk bezel + ljus skärm + dynamic island.
/// Bezel = formens ram-färg (mörk default), skärm = formens fyllning (ljus default),
/// så Kim kan bygga UI ovanpå och färgväljaren funkar som på andra former.
struct PhoneFrameBackground: View {
    var bezel: Color
    var screen: Color
    /// v68: modellnamn (t.ex. "iPhone 16 Pro") som liten caption under dynamic island.
    var caption: String = ""
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            let r = min(w, h) * DesignTokens.Shape.phoneFrameCornerRadiusRatio
            let inset: CGFloat = max(4, w * 0.045)
            ZStack {
                RoundedRectangle(cornerRadius: r, style: .continuous)
                    .fill(bezel)
                    .shadow(color: .black.opacity(0.10), radius: 4, y: 2)
                RoundedRectangle(cornerRadius: max(2, r - inset), style: .continuous)
                    .fill(screen)
                    .padding(inset)
                // Dynamic island
                Capsule()
                    .fill(bezel)
                    .frame(width: w * 0.34, height: max(8, h * 0.028))
                    .position(x: w / 2, y: inset + h * 0.035)
                // v68: diskret modell-caption upptill, lämnar skärmytan fri för UI-bygge
                if !caption.isEmpty {
                    Text(caption)
                        .font(.system(size: max(8, w * 0.075), weight: .semibold, design: .rounded))
                        .foregroundStyle(bezel.opacity(0.75))
                        .lineLimit(1)
                        .position(x: w / 2, y: inset + h * 0.085)
                }
            }
        }
    }
}
