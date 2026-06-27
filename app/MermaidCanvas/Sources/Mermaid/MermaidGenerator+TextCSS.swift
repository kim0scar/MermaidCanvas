import Foundation

extension MermaidGenerator {
    /// 1.5: textstil → CSS (font-size + font-weight) för mermaid.live-rendering. Läser
    /// `TextStyle` DIREKT och UI-fritt (`fontSize` + `cssFontWeight`) → nya storlekar ändras
    /// bara i TextStyle. Render-hint; parsas ej tillbaka (`style:` bär round-trip).
    /// `body` ≈ 14px = Mermaids default → hoppas över för ren utdata.
    static func textStyleFontCSS(_ style: TextStyle, visSize: Double) -> [String] {
        var props: [String] = []
        let scaledFont = max(8, Int((Double(style.fontSize) * visSize).rounded()))
        if abs(scaledFont - 14) > 1 { props.append("font-size:\(scaledFont)px") }
        if let w = style.cssFontWeight { props.append("font-weight:\(w)") }
        return props
    }
}
