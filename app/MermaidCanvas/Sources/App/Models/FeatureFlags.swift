import Foundation

/// Centrala på/av-flaggor för funktioner som PARKERATS men vars kod ligger kvar.
/// Sätts vid Kims governance-beslut — inte en runtime-inställning.
enum FeatureFlags {
    /// Underflöden (Visio-drill / `subCanvas`) — PARKERAT 2026-06-28 (Kims governance-reset).
    /// Datamodellen (`ShapeNode.subCanvas`) + round-trip lever kvar så befintliga filer inte
    /// bryts, men ENTRY-punkten (kontextmenyn "Skapa underflöde / Hoppa in →") + dubbel-ram-
    /// markören är gömda. Funktionen bröt kärnprincipen "allt syns i ren mermaid" (subCanvas är
    /// state-JSON-only, osynlig för en vän i mermaid.live). Återupptas BARA via ombyggnad på
    /// native mermaid-subgraphs — då sätts denna true igen.
    /// Se ROADMAP.md → Kommande funktioner + CLAUDE.md regel 3b + PRODUKT.md kärnprincip.
    static let underflodenEnabled = false
}
