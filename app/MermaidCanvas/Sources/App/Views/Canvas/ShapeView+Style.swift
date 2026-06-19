import SwiftUI

/// Härledda presentations-värden för ShapeView (utbrutna ur ShapeView.swift för
/// R5-ratchet, steg H): färg (fyllning/ram/text), formaterat label, text-inset
/// och container-rubrik. Rena funktioner av `shape` — ingen state.
extension ShapeView {
    var pack: ColorPack { ColorPack.by(id: shape.colorPackId) }

    // v62: egna färger (fyllning + ram separat) går före paket/kategori.
    var effectiveFill: Color {
        if let hex = shape.colorOverride, let c = Color(hexString: hex) { return c }
        return pack.fillColor
    }
    var effectiveStroke: Color {
        if let hex = shape.strokeColorOverride, let c = Color(hexString: hex) { return c }
        return pack.id != "none" ? pack.strokeColor : shape.category.strokeColor
    }
    var effectiveTextColor: Color {
        // Egen fyllning → välj svart/vit på luminans så texten alltid syns.
        if let hex = shape.colorOverride, Color(hexString: hex) != nil {
            return Color.isDarkHex(hex) ? .white : Color(hex: 0x111827)
        }
        return pack.textColor
    }

    /// v39: formatterat label med bullets/numrering + indrag.
    var formattedLabel: String {
        let indent = String(repeating: "  ", count: max(0, shape.indentLevel))
        let lines = shape.label.split(separator: "\n", omittingEmptySubsequences: false)
        if shape.hasNumberedList {
            return lines.enumerated()
                .map { "\(indent)\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
        } else if shape.hasBullets {
            return lines.map { "\(indent)• \($0)" }.joined(separator: "\n")
        } else if shape.indentLevel > 0 {
            return lines.map { "\(indent)\($0)" }.joined(separator: "\n")
        }
        return shape.label
    }

    var textAlignment: TextAlignment {
        switch shape.textAlignment {
        case .leading:  return .leading
        case .trailing: return .trailing
        case .center:   return .center
        }
    }

    /// G2a: extra sido-marginal för former som smalnar av — texten centreras i
    /// bounding-boxen, så utan inset spiller den över triangelns/rombens sneda kanter.
    var textHorizontalInset: CGFloat {
        switch shape.type {
        case .triangle: return 18   // bara nedre mitten är bred nog
        case .diamond:  return 22   // romben smalnar mot vänster/höger spets
        default:        return 8
        }
    }

    /// G2a: triangeln är bred bara nedtill → skjut texten nedåt mot basen.
    var textVerticalOffset: CGFloat {
        switch shape.type {
        case .triangle: return ShapeGeometry.height(for: shape) * 0.20
        default:        return 0
        }
    }

    /// v74: container-rubrik — skill-containrar visar kedjenumret ("Skill 2 · namn").
    /// Steg 8: en skill-container inuti en annan container = "Subskill".
    var containerHeaderTitle: String {
        let name = shape.label.isEmpty ? "Grupp" : formattedLabel
        guard shape.category == .skill else { return name }
        let kind = shape.childOfContainerId != nil ? "Subskill" : "Skill"
        if let nr = shape.skillNumber { return "\(kind) \(nr) · \(name)" }
        return kind == "Subskill" ? "Subskill · \(name)" : name
    }
}
