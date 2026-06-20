import Foundation

/// Single source of truth för MermaidCanvas-versionsnummer.
/// Bumpas till nästa nummer vid varje deploy enligt VERSIONSHANTERING.md.
enum AppVersion {
    /// Bygg-räknare (driver bundle-version + arch-check version-sync). Bumpas vid varje deploy.
    static let current: String = "v88"
    /// Milstolpe-etikett (det Kim känner igen). Bumpas vid milstolpar, inte varje bygge.
    static let milestone: String = "v0.9"
}
