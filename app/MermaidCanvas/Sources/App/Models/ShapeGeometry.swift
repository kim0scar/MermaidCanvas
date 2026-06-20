import Foundation
import CoreGraphics

/// Geometri för former — bredd/höjd/hit-test. Ren domänlogik (ingen SwiftUI):
/// både View-lagret (rendering) och Model-lagret (`CanvasModel.shapesInside`) frågar
/// härifrån, så den hör hemma i Model-lagret. (MA spår A steg 1: flyttad ur CanvasView
/// så Model inte längre når in i en View-fil.)
enum ShapeGeometry {
    static let baseWidth: CGFloat = 120
    static let baseHeight: CGFloat = 80

    /// v35.1/v36: typ-specifika basbredder/-höjder.
    static func typeBaseWidth(for type: ShapeType) -> CGFloat {
        switch type {
        case .pill:         return 138   // G2d: bredare än rektangeln (120) → läses som egen form
        case .square:       return 80    // liksidig kvadrat
        case .processArrow: return 110   // kompakt pil (spets 40% av bredden)
        case .container:    return 280   // v44: grupperande container ska rymma flera former
        case .octagon:      return 80    // v51.1: symmetrisk åttahörning
        case .phoneFrame:   return 180   // v67: iPhone 16 Pro-proportion (~0.46 b/h)
        case .triangle:     return 88    // v68: liksidig trekant (bredd ≈ höjd-ram)
        case .cylinder:     return 100   // v69: databas/bevis-cylinder
        default:            return baseWidth
        }
    }
    static func typeBaseHeight(for type: ShapeType) -> CGFloat {
        switch type {
        case .pill:       return 74    // fix: 60 var för platt (ful oval-ikon) → 138×74 = proportionerlig kapsel
        case .square:     return 80    // liksidig kvadrat
        case .container:  return 200   // v44: container — högre default-höjd
        case .octagon:    return 80    // v51.1: symmetrisk åttahörning
        case .phoneFrame: return 391   // v67/v68: exakt iPhone 16 Pro-proportion (180×391 = 0.460)
        case .triangle:   return 80    // v68: liksidig trekant
        case .cylinder:   return 90    // v69: databas/bevis-cylinder
        default:          return baseHeight
        }
    }

    /// v68: canvas-formerna ritas 10% större (Kim: lättare att greppa/ändra storlek).
    /// Gäller BARA canvas-rendering — toolbar-chips läser typeBaseWidth/Height direkt
    /// och påverkas inte. Lösa linjer/pilar (lineEnd-baserade) returnerar före faktorn.
    static let canvasScaleBoost: CGFloat = 1.10

    static func width(for shape: ShapeNode) -> CGFloat {
        // v66: linjens/pilens bbox följer lineEnd-spannet — ändpunkts-handtaget
        // styr längden direkt, inte multipliers (som klippte utdragna streck).
        if shape.type == .line || shape.type == .arrow, let e = shape.lineEnd {
            return max(abs(e.x) * 2 + 24, 44)
        }
        return typeBaseWidth(for: shape.type) * shape.effectiveWidth * canvasScaleBoost
    }
    static func height(for shape: ShapeNode) -> CGFloat {
        if shape.type == .line || shape.type == .arrow, let e = shape.lineEnd {
            return max(abs(e.y) * 2 + 24, 44)
        }
        return typeBaseHeight(for: shape.type) * shape.effectiveHeight * canvasScaleBoost
    }
    static func halfWidth(for shape: ShapeNode) -> CGFloat { width(for: shape) / 2 }
    static func halfHeight(for shape: ShapeNode) -> CGFloat { height(for: shape) / 2 }
    static func circleRadius(for shape: ShapeNode) -> CGFloat {
        min(width(for: shape), height(for: shape)) / 2
    }

    /// Hitta vilken form (om någon) som ligger under en canvas-punkt.
    static func hitTest(_ point: CGPoint, shapes: [ShapeNode], excludingId: UUID? = nil) -> ShapeNode? {
        for shape in shapes.reversed() {
            if let exc = excludingId, shape.id == exc { continue }
            let hw = halfWidth(for: shape)
            let hh = halfHeight(for: shape)
            if point.x >= shape.position.x - hw && point.x <= shape.position.x + hw &&
               point.y >= shape.position.y - hh && point.y <= shape.position.y + hh {
                return shape
            }
        }
        return nil
    }
}
