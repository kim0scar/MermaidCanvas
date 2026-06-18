import SwiftUI

// MARK: - Color hex helper
// Utbruten ur ShapeCategory.swift (steg 8, R5-ratchet) — en färg-util hör inte hemma i kategori-enumen.

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xff) / 255.0
        let g = Double((hex >> 8) & 0xff) / 255.0
        let b = Double(hex & 0xff) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    /// v62: "#rrggbb"-sträng → Color. nil vid ogiltigt format.
    init?(hexString: String) {
        let raw = hexString.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "#", with: "")
        guard raw.count == 6, let value = UInt32(raw, radix: 16) else { return nil }
        self.init(hex: value)
    }

    /// v62: är hex-färgen mörk? (YIQ-luminans) — styr svart/vit text på egen fyllning.
    static func isDarkHex(_ hexString: String) -> Bool {
        let raw = hexString.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "#", with: "")
        guard raw.count == 6, let value = UInt32(raw, radix: 16) else { return false }
        let r = Double((value >> 16) & 0xff)
        let g = Double((value >> 8) & 0xff)
        let b = Double(value & 0xff)
        return (r * 299 + g * 587 + b * 114) / 1000 < 128
    }

    /// Hex-string för Mermaid-classDef (i format "#rrggbb").
    var hex: String {
        // Bästa-möjliga: läs ut UIColor-komponenter.
        #if canImport(UIKit)
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02x%02x%02x",
                      Int((r * 255).rounded()),
                      Int((g * 255).rounded()),
                      Int((b * 255).rounded()))
        #else
        return "#000000"
        #endif
    }
}
