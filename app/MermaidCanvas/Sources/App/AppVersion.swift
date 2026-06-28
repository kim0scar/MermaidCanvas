import Foundation

/// Single source of truth för MermaidCanvas-versionsnummer.
///
/// **EN enda version — aldrig två** (Kims order 2026-06-24). Inget separat bygg-räknar-nummer:
/// `version` driver BÅDE det Kim ser i appen OCH bundle-versionen (project.yml MARKETING_VERSION
/// + CURRENT_PROJECT_VERSION, synkat av scripts/arch-check.py). Bumpas vid varje release (1.0 → 1.1 → …).
enum AppVersion {
    static let version: String = "1.5.1"
}
