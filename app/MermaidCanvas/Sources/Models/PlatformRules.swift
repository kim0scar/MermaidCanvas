import Foundation

/// v25: Centraliserad regel-text per spec_type. Används av:
/// - PlatformRulesSheet (visar i appen)
/// - CanvasDocument-spara-flödet (skriver sidecar bredvid canvas-fil)
enum PlatformRules {
    static func text(for specType: SpecType) -> String {
        switch specType {
        case .godot:
            return loadResource(name: "godot-lexicon", ext: "md")
                ?? fallback(for: .godot)
        case .ui:
            return loadResource(name: "METOD-VISUELL-DIALOG", ext: "md")
                ?? fallback(for: .ui)
        case .roadmap:    return fallback(for: .roadmap)
        case .architecture: return fallback(for: .architecture)
        case .flow:       return fallback(for: .flow)
        case .general:    return fallback(for: .general)
        }
    }

    /// Den auto-genererade sidecar-MD-en som skrivs bredvid canvas vid Spara.
    /// Innehåller plattform-regler + claude-canvas-protocol (filformat-spec).
    static func sidecarMarkdown(for specType: SpecType) -> String {
        let rules = text(for: specType)
        let protocolText = loadResource(name: "claude-canvas-protocol", ext: "md")
            ?? "(claude-canvas-protocol.md saknas i app-bundlen)"

        return """
        # MermaidCanvas — regler för plattform `\(specType.rawValue)`

        Denna fil skrivs automatiskt av MermaidCanvas-appen bredvid canvas-filen.
        Den är Claude Code's referens när Kim refererar till canvasen från Mac:en.

        ---

        ## Del 1 — Plattformsregler (\(specType.displayName))

        \(rules)

        ---

        ## Del 2 — Canvas-filformat (för Claude Code)

        \(protocolText)
        """
    }

    private static func loadResource(name: String, ext: String) -> String? {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext),
              let content = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }
        return content
    }

    private static func fallback(for specType: SpecType) -> String {
        switch specType {
        case .godot:
            return "(godot-lexicon.md saknas — fyll på i appens Resources/-mapp)"
        case .ui:
            return "(METOD-VISUELL-DIALOG.md saknas — fyll på i appens Resources/-mapp)"
        case .roadmap:
            return """
            # Roadmap-regler

            Kategorier:
            - **feat** — Feature, blå
            - **milestone** — Milestone, amber
            - **blocker** — Blocker, röd
            - **future** — Future, lila
            - **note** — Anteckning (inte runtime-konsekvens)

            Pilar = beroenden. Vad blockerar vad.
            """
        case .architecture:
            return """
            # Arkitektur-regler

            Kategorier: folder, file, module, service, data.
            Pilar = imports/användning.
            Gruppera relaterade noder i subgraphs.
            """
        case .flow:
            return """
            # Flow-regler

            Pipeline-ordning: Input → Router → Agent → Tool → Memory → Output.
            Pilar = dataflöde.
            För AI-agenter och processer.
            """
        case .general:
            return """
            # Allmänt-läge

            Inga specifika regler — använd som du vill.
            """
        }
    }
}
