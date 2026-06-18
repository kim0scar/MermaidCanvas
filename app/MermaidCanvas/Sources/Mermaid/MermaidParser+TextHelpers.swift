import Foundation

/// Text-/regex-hjälpare för fallback-parsningen (ren mermaid → datastruktur).
/// Utbruten ur MermaidParser.swift (R5-ratchet): rena strängoperationer utan
/// beroende till parserns övriga interna typer.
extension MermaidParser {

    /// v61: Skala bort nod-kroppar och kommentarer inför kant-parsning.
    /// `a["Träffa (kanske) Bo"] --> b{Val}` → `a --> b`. Innersta klamrar
    /// tas bort först, upprepat tills inget ändras (strängen krymper varje varv).
    static func stripNodeBodies(_ block: String) -> String {
        // %%-kommentarer bort (kan innehålla pil-tecken i notis/prompt-text)
        var s = block.split(separator: "\n", omittingEmptySubsequences: false)
            .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("%%") }
            .joined(separator: "\n")
        let bracketPatterns = [#"\([^\(\)]*\)"#, #"\[[^\[\]]*\]"#, #"\{[^\{\}]*\}"#]
        var changed = true
        while changed {
            changed = false
            for pattern in bracketPatterns {
                guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
                let ns = s as NSString
                let next = regex.stringByReplacingMatches(
                    in: s, range: NSRange(location: 0, length: ns.length), withTemplate: "")
                if next != s {
                    s = next
                    changed = true
                }
            }
        }
        // :::kategori-suffix bort (annars blir "ui" i `a:::ui --> b` en fantomnod)
        s = replacing(#":::\w+"#, in: s, with: "")
        // Normalisera äldre pil-skrivsätt till |label|-formen som kant-regexen förstår:
        // `a -- text --> b` → `a -->|text| b`, `a -. text .-> b`, `a == text ==> b`
        s = replacing(#"--\s+([^-<>|\n]+?)\s+-->"#, in: s, with: "-->|$1|")
        s = replacing(#"-\.\s+([^-<>|\n]+?)\s+\.->"#, in: s, with: "-.->|$1|")
        s = replacing(#"==\s+([^=<>|\n]+?)\s+==>"#, in: s, with: "==>|$1|")
        // Tjocka pilar (==>) → vanliga pilar — appen har ingen tjock-stil
        s = replacing(#"<=+>"#, in: s, with: "<-->")
        s = replacing(#"=+>"#, in: s, with: "-->")
        return s
    }

    static func replacing(_ pattern: String, in text: String, with template: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let ns = text as NSString
        return regex.stringByReplacingMatches(
            in: text, range: NSRange(location: 0, length: ns.length), withTemplate: template)
    }

    /// Kategori i fallback-läge: först :::klass-suffix, annars prefix i id (ui_xxx), annars .ui.
    static func categoryFor(mermaidId: String, classSuffixRange: NSRange, ns: NSString) -> ShapeCategory {
        if classSuffixRange.location != NSNotFound {
            let raw = ns.substring(with: classSuffixRange)
            if let cat = ShapeCategory(rawValue: raw) { return migrateDeprecated(cat) }
        }
        if let underscore = mermaidId.firstIndex(of: "_") {
            let prefix = String(mermaidId[..<underscore])
            if let cat = ShapeCategory(rawValue: prefix) { return migrateDeprecated(cat) }
        }
        return .ui
    }

    /// v31: deprecated kategorier (Roadmap/Architecture-pack) migreras till `.note`.
    /// Inga former tappas — bara färg/kategori byts ut.
    /// `.input`/`.agent`/`.tool`/`.router`/`.memory`/`.output` behålls eftersom de återanvänds
    /// av Prompt-Process-pack (delar SpecType.flow).
    static func migrateDeprecated(_ cat: ShapeCategory) -> ShapeCategory {
        switch cat {
        case .feat, .milestone, .blocker, .future,
             .folder, .file, .module, .service, .data:
            return .note
        default:
            return cat
        }
    }
}
