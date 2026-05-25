import SwiftUI

// MARK: - Canvas-form-definitioner
// v42: Flyttat hit från CanvasView.swift så att toolbar-chips OCH canvas
// kan referera EXAKT samma form-definitioner. Tidigare divergerade chip-rendering
// från canvas-rendering vilket gav fel proportioner i toolbaren.

/// v28: rundad romb/diamant — mjuka hörn istället för vassa spetsar.
/// v35.1: fyller hela ramen (120×80) → bredare-än-hög romb som matchar Mermaid's {} render.
struct DiamondShape: Shape {
    // v50.4: default läses från DesignTokens så chip + canvas matchar
    // automatiskt. Kan fortfarande overridas per-instans om behövs.
    var cornerRadius: CGFloat = DesignTokens.Shape.diamondCornerRadius

    func path(in rect: CGRect) -> Path {
        let top    = CGPoint(x: rect.midX, y: rect.minY)
        let right  = CGPoint(x: rect.maxX, y: rect.midY)
        let bottom = CGPoint(x: rect.midX, y: rect.maxY)
        let left   = CGPoint(x: rect.minX, y: rect.midY)

        let r = min(cornerRadius, min(rect.width, rect.height) / 4)
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
    // v50.4: default från DesignTokens. Tidigare 14 → divergerade med
    // chip-rendering som hade 6.
    var cornerRadius: CGFloat = DesignTokens.Shape.squareCornerRadius
    func path(in rect: CGRect) -> Path {
        Path(roundedRect: rect, cornerRadius: cornerRadius, style: .continuous)
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
        // Radie = procent av höjd, cap vid (rect.width - tip)/2 så geometrin
        // inte degenererar på extremt smala former.
        let r = min(rect.height * cornerRadiusRatio, (rect.width - tip) / 2)

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
        // Diagonal upp till spetsen (skarp spets — ingen rundning här)
        p.addLine(to: off(tipPoint, by: tj_tp, -0.5))
        p.addLine(to: off(tipPoint, by: tp_bj, 0.5))
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
