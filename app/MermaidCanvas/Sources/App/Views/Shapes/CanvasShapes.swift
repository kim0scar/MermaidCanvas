import SwiftUI

// MARK: - Canvas-form-definitioner
// v42: Flyttat hit från CanvasView.swift så att toolbar-chips OCH canvas
// kan referera EXAKT samma form-definitioner. Tidigare divergerade chip-rendering
// från canvas-rendering vilket gav fel proportioner i toolbaren.

/// v28: rundad romb/diamant — mjuka hörn istället för vassa spetsar.
/// v35.1: fyller hela ramen (120×80) → bredare-än-hög romb som matchar Mermaid's {} render.
struct DiamondShape: Shape {
    var cornerRadius: CGFloat = 8

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
    var cornerRadius: CGFloat = 14
    func path(in rect: CGRect) -> Path {
        Path(roundedRect: rect, cornerRadius: cornerRadius, style: .continuous)
    }
}

/// Processsteg-pil — pentagon med rak vänsterkant och spetsig högerände.
/// v41: platt vänsterkant → matchar arrowshape.right-ikonen exakt.
struct ProcessArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        let tip: CGFloat = rect.width * 0.35   // spets = 35% av bredden
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - tip, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX - tip, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}
