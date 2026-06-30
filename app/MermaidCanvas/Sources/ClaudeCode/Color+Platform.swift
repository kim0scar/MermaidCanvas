import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// 1.1 dual-platform: SwiftUI saknar plattformsneutrala semantiska systemfärger
/// (`Color(.systemBackground)` m.fl. är UIColor-bara). iOS = EXAKT samma färg som förr
/// (oförändrat utseende); macOS = närmaste NSColor.
extension Color {
    static var appBackground: Color {
        #if canImport(UIKit)
        Color(.systemBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .windowBackgroundColor)
        #else
        .white
        #endif
    }
    static var appSecondaryBackground: Color {
        #if canImport(UIKit)
        Color(.secondarySystemBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .underPageBackgroundColor)
        #else
        Color(white: 0.95)
        #endif
    }
    /// 1.4: chip-/knapp-yta som ALLTID kontrasterar mot verktygsfältets bakgrund i BÅDE
    /// ljust och mörkt läge. Inaktiva formaterings-/färgchips fyllde förr med appBackground
    /// och smälte in i ett lika mörkt verktygsfält i dark mode (osynliga). systemGray5 =
    /// ett garanterat kliv från både primär- och sekundärradens bakgrund.
    static var appChipBackground: Color {
        #if canImport(UIKit)
        Color(.systemGray5)
        #elseif canImport(AppKit)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(white: 0.9)
        #endif
    }
    static var appSeparator: Color {
        #if canImport(UIKit)
        Color(.separator)
        #elseif canImport(AppKit)
        Color(nsColor: .separatorColor)
        #else
        .gray
        #endif
    }
    static var appLabel: Color {
        #if canImport(UIKit)
        Color(.label)
        #elseif canImport(AppKit)
        Color(nsColor: .labelColor)
        #else
        .primary
        #endif
    }
    static var appTertiaryLabel: Color {
        #if canImport(UIKit)
        Color(.tertiaryLabel)
        #elseif canImport(AppKit)
        Color(nsColor: .tertiaryLabelColor)
        #else
        .secondary
        #endif
    }
    static var appGray5: Color {
        #if canImport(UIKit)
        Color(.systemGray5)
        #elseif canImport(AppKit)
        Color(nsColor: .quaternaryLabelColor)
        #else
        Color(white: 0.9)
        #endif
    }
    static var appGray6: Color {
        #if canImport(UIKit)
        Color(.systemGray6)
        #elseif canImport(AppKit)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(white: 0.95)
        #endif
    }
    static var appGroupedBackground: Color {
        #if canImport(UIKit)
        Color(.systemGroupedBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(white: 0.95)
        #endif
    }
    static var appSecondaryGroupedBackground: Color {
        #if canImport(UIKit)
        Color(.secondarySystemGroupedBackground)
        #elseif canImport(AppKit)
        Color(nsColor: .controlBackgroundColor)
        #else
        .white
        #endif
    }
    /// 1.5.5 (Kim): canvas-bakgrunden är ADAPTIV — ljus pappersyta i ljust läge (oförändrat),
    /// mörk yta i mörkt läge (så mörkt läge ser man saker, Kims fynd). Tidigare fast `white 0.9`.
    static var canvasBackground: Color {
        #if canImport(UIKit)
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(white: 0.16, alpha: 1) : UIColor(white: 0.9, alpha: 1) })
        #elseif canImport(AppKit)
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                ? NSColor(white: 0.16, alpha: 1) : NSColor(white: 0.9, alpha: 1) })
        #else
        Color(white: 0.9)
        #endif
    }
    /// 1.5.5: default-pilfärg adaptiv — mjuk mörkgrå (0x3a3f47) i ljust läge (oförändrat),
    /// ljusgrå i mörkt läge så pilen syns på den mörka canvasen.
    static var edgeDefault: Color {
        #if canImport(UIKit)
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
            ? UIColor(white: 0.78, alpha: 1)
            : UIColor(red: 0x3a/255.0, green: 0x3f/255.0, blue: 0x47/255.0, alpha: 1) })
        #elseif canImport(AppKit)
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
                ? NSColor(white: 0.78, alpha: 1)
                : NSColor(red: 0x3a/255.0, green: 0x3f/255.0, blue: 0x47/255.0, alpha: 1) })
        #else
        Color(white: 0.23)
        #endif
    }
}
