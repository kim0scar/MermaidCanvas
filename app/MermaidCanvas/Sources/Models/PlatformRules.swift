import Foundation

/// v27: Plattform-regler. Bara Godot har riktiga regler + lexicon-sidecar.
/// Blank ger ingen sidecar (eller en tom protokoll-ref).
enum PlatformRules {
    static func text(for platform: Platform) -> String {
        switch platform {
        case .godot:
            return loadResource(name: "godot-lexicon", ext: "md")
                ?? fallback(for: .godot)
        case .blank:
            return fallback(for: .blank)
        }
    }

    /// Den auto-genererade sidecar-MD-en som skrivs bredvid canvas vid Spara.
    /// Returnerar nil för Blank canvas (ingen sidecar behövs).
    static func sidecarMarkdown(for platform: Platform) -> String? {
        guard platform == .godot else { return nil }
        let rules = text(for: platform)
        let protocolText = loadResource(name: "claude-canvas-protocol", ext: "md")
            ?? "(claude-canvas-protocol.md saknas i app-bundlen)"

        return """
        # MermaidCanvas — regler för plattform `\(platform.rawValue)`

        Denna fil skrivs automatiskt av MermaidCanvas-appen bredvid canvas-filen.
        Den är Claude Code's referens när Kim refererar till canvasen från Mac:en.

        ---

        ## Del 1 — Plattformsregler (\(platform.displayName))

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

    private static func fallback(for platform: Platform) -> String {
        switch platform {
        case .godot:
            return "(godot-lexicon.md saknas — fyll på i appens Resources/-mapp)"
        case .blank:
            return """
            # Blank canvas

            Ingen plattformslåsning — Kim ritar fritt med valda form-paketer.
            """
        }
    }
}
