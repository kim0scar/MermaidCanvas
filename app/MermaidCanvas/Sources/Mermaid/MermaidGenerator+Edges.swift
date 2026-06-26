import Foundation

extension MermaidGenerator {
    /// v1.0: alla mermaid-rader för EN kant — pil-token + app-only `%%`-metadata + nativ
    /// linkStyle. Bröts ut ur generate() för att hålla MermaidGenerator under R5-taket.
    /// `appIndex` (i) = kantens plats i edges-arrayen (för `%% e<i>`-round-trip).
    /// `mermaidIndex` (me) = mermaids egen kant-räknare (bara emitterade kanter, för linkStyle).
    static func edgeLines(edge: EdgeConnection, appIndex i: Int, mermaidIndex me: Int,
                          from: String, to: String,
                          collapsed: Bool, indent: String) -> [String] {
        var lines: [String] = []
        // v37: linje-stil × riktning. Steg H-fynd: riktig mermaid har INGEN giltig bakåtpil —
        // `<--` kraschar renderaren och `<-.-` tappar pilspetsen tyst. En bakåtkant skrivs
        // därför som framåtpil med OMVÄNDA noder (to --> from); exakt riktning bevaras i state-JSON.
        let arrow: String
        var src = from, dst = to
        switch (edge.direction, edge.style) {
        case (.forward,       .solid):  arrow = "-->"
        case (.forward,       .dashed): arrow = "-.->"
        case (.backward,      .solid):  arrow = "-->";   src = to; dst = from
        case (.backward,      .dashed): arrow = "-.->";  src = to; dst = from
        case (.bidirectional, .solid):  arrow = "<-->"
        case (.bidirectional, .dashed): arrow = "<-.->"
        case (.none,          .solid):  arrow = "---"
        case (.none,          .dashed): arrow = "-.-"
        }
        if edge.label.isEmpty {
            lines.append("\(indent)\(src) \(arrow) \(dst)")
        } else {
            lines.append("\(indent)\(src) \(arrow)|\"\(escape(edge.label))\"| \(dst)")
        }
        // Waypoints som synliga kommentarer
        for wp in edge.waypoints {
            lines.append("\(indent)%% e\(i) waypoint: \(Int(wp.x.rounded())),\(Int(wp.y.rounded()))")
        }
        // v62: etikett-placering (bara när den avviker från default)
        if edge.labelPlacement != .below {
            lines.append("\(indent)%% e\(i) labelPlacement: \(edge.labelPlacement.rawValue)")
        }
        // v63: pilens färg
        if let hex = edge.colorHex {
            lines.append("\(indent)%% e\(i) color: \(hex)")
        }
        // v64: vald utgångssida
        if let side = edge.fromSide {
            lines.append("\(indent)%% e\(i) fromSide: \(side.rawValue)")
        }
        // 1.3: vald inkommande sida på mål-formen
        if let side = edge.toSide {
            lines.append("\(indent)%% e\(i) toSide: \(side.rawValue)")
        }
        // v63: kollaps per GREN
        if collapsed {
            lines.append("\(indent)%% e\(i) collapsed: true")
        }
        // v1.0: form på linjen — app-round-trip via %% (app-index i) + NATIV linkStyle
        // interpolate (mermaid-index me) så formen RENDERAR i mermaid.live. curved = global basis.
        if edge.lineShape != .curved {
            lines.append("\(indent)%% e\(i) lineShape: \(edge.lineShape.rawValue)")
            let interp = edge.lineShape == .straight ? "linear" : "stepAfter"
            lines.append("\(indent)linkStyle \(me) interpolate \(interp)")
        }
        return lines
    }
}
