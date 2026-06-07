import Foundation

/// v27/v31: Plattform-regler. Bara plattformar med "riktiga regler" får sidecar.
/// v31: lägger till iOS SwiftUI (stub). Blank ger fortfarande ingen sidecar.
enum PlatformRules {
    static func text(for platform: Platform) -> String {
        switch platform {
        case .godot:
            return loadResource(name: "godot-lexicon", ext: "md")
                ?? fallback(for: .godot)
        case .iosSwiftUI:
            return loadResource(name: "ios-swiftui-rules", ext: "md")
                ?? fallback(for: .iosSwiftUI)
        case .blank:
            return fallback(for: .blank)
        }
    }

    /// Den auto-genererade sidecar-MD-en som skrivs bredvid canvas vid Spara.
    /// Returnerar nil för Blank canvas (ingen sidecar behövs).
    static func sidecarMarkdown(for platform: Platform) -> String? {
        guard platform != .blank else { return nil }
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

    /// v31: text för form-pack-regler (visas i form-pack-sektion av regler-sheet).
    static func text(for pack: ShapePack) -> String? {
        switch pack {
        case .promptProcess:
            return loadResource(name: "prompt-process-rules", ext: "md")
        case .basic, .ui, .n8n:
            return nil  // dessa har inga separata regler
        case .roadmap, .architecture, .flow:
            return nil  // utfasade
        }
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
        case .iosSwiftUI:
            return """
            # iOS SwiftUI (v31 stub)

            Regler kommer fyllas på i kommande version. Fritt rita just nu.
            """
        case .blank:
            return """
            # Blank canvas

            Ingen plattformslåsning — Kim ritar fritt med valda form-paketer.
            """
        }
    }
}
