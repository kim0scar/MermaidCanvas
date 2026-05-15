import Foundation
import SwiftUI

/// Färg-paket: matchad pastell-fyllning + ram + text-färg för läsbarhet.
/// Ersätter den gamla hex-baserade colorOverride. Per form sparas pack-id som sträng.
struct ColorPack: Identifiable, Hashable {
    let id: String
    let displayName: String
    let fill: UInt32
    let stroke: UInt32
    let text: UInt32

    var fillColor: Color { Color(hex: fill) }
    var strokeColor: Color { Color(hex: stroke) }
    var textColor: Color { Color(hex: text) }

    /// Default: ingen färg = vit fyllning + accent-ram (löses i view-kod via kategori-stroke).
    static let none = ColorPack(id: "none", displayName: "Ingen färg",
                                fill: 0xFFFFFF, stroke: 0x6B7280, text: 0x111827)

    static let persika = ColorPack(id: "persika", displayName: "Persika",
                                   fill: 0xFFE3D0, stroke: 0xE5A57A, text: 0x7A3F1A)
    static let rosa    = ColorPack(id: "rosa",    displayName: "Rosa",
                                   fill: 0xFFE5EC, stroke: 0xFF8FA3, text: 0x8B2A3E)
    static let blå     = ColorPack(id: "blå",     displayName: "Blå",
                                   fill: 0xE0F0FF, stroke: 0x7FB8E5, text: 0x1A4A7A)
    static let grön    = ColorPack(id: "grön",    displayName: "Grön",
                                   fill: 0xD9F5E0, stroke: 0x7CC196, text: 0x1F5733)
    static let gul     = ColorPack(id: "gul",     displayName: "Gul",
                                   fill: 0xFFF4D6, stroke: 0xE0B85C, text: 0x6B4A1A)
    static let lila    = ColorPack(id: "lila",    displayName: "Lila",
                                   fill: 0xECDFFF, stroke: 0xB89CE0, text: 0x4A2D7A)

    /// Alla paket i ordningen som visas i picker.
    static let all: [ColorPack] = [.none, .persika, .rosa, .blå, .grön, .gul, .lila]

    static func by(id: String?) -> ColorPack {
        guard let id = id else { return .none }
        return all.first { $0.id == id } ?? .none
    }
}
