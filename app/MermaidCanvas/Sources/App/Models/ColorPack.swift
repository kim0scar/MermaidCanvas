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

    // 1.0: harmoniserad pastell-palett — jämn ram-mättnad + jämn fyll-ljushet så paketen
    // ser genomtänkta ut tillsammans (tidigare varierade ramarna från skrikiga till matta).
    static let persika = ColorPack(id: "persika", displayName: "Persika",
                                   fill: 0xFFE6D6, stroke: 0xEFA379, text: 0x7E4226)
    static let rosa    = ColorPack(id: "rosa",    displayName: "Rosa",
                                   fill: 0xFFE1EA, stroke: 0xF291A8, text: 0x883350)
    static let blå     = ColorPack(id: "blå",     displayName: "Blå",
                                   fill: 0xDEEDFD, stroke: 0x74B0E6, text: 0x18497E)
    static let grön    = ColorPack(id: "grön",    displayName: "Grön",
                                   fill: 0xDAF0E0, stroke: 0x74C09A, text: 0x205A3C)
    static let gul     = ColorPack(id: "gul",     displayName: "Gul",
                                   fill: 0xFFF0CD, stroke: 0xE4B854, text: 0x6C4B16)
    static let lila    = ColorPack(id: "lila",    displayName: "Lila",
                                   fill: 0xEBDCFB, stroke: 0xAD92DD, text: 0x46296F)

    // v1.1 "Färger UI bygg": kraftiga UI-färger (knappar/ytor) för UI-mockups — iOS-system-
    // färger med vit/mörk text för kontrast. Round-trippar via colorPackId som pastellerna.
    static let uiBlå  = ColorPack(id: "ui-blå",  displayName: "UI Blå (knapp)",   fill: 0x0A84FF, stroke: 0x0A6CD8, text: 0xFFFFFF)
    static let uiGrön = ColorPack(id: "ui-grön", displayName: "UI Grön",          fill: 0x34C759, stroke: 0x28A745, text: 0xFFFFFF)
    static let uiRöd  = ColorPack(id: "ui-röd",  displayName: "UI Röd",           fill: 0xFF3B30, stroke: 0xD70015, text: 0xFFFFFF)
    static let uiGrå  = ColorPack(id: "ui-grå",  displayName: "UI Grå (yta)",     fill: 0xF2F2F7, stroke: 0xC7C7CC, text: 0x1C1C1E)
    static let uiMörk = ColorPack(id: "ui-mörk", displayName: "UI Mörk (navbar)", fill: 0x1C1C1E, stroke: 0x3A3A3C, text: 0xFFFFFF)

    /// Alla paket — round-trip-uppslag (by(id:)). ALLA ids finns kvar så gamla filer
    /// behåller sin färg även om pickern visar färre.
    static let all: [ColorPack] = [.none, .persika, .rosa, .blå, .grön, .gul, .lila,
                                   .uiBlå, .uiGrön, .uiRöd, .uiGrå, .uiMörk]

    /// 1.4 (Kim: "max 8 snygga smarta val", numrerade): de 8 som visas i picker-ordning.
    /// De fem ui-* (utom UI Blå) visas ej men laddas korrekt vid round-trip via `all`.
    static let pickerVisible: [ColorPack] = [.none, .blå, .grön, .gul, .rosa, .lila, .persika, .uiBlå]

    static func by(id: String?) -> ColorPack {
        guard let id = id else { return .none }
        return all.first { $0.id == id } ?? .none
    }
}
