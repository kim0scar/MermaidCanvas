import Foundation
import CoreGraphics

/// v61: Läser `%% <id> nyckel: värde`-kommentarerna som MermaidGenerator skriver.
/// Gör mermaid-blocket självbärande — positioner, storlek, färg, prompt m.m.
/// överlever round-trip även UTAN state-JSON ("ren mermaid i backend").
enum MermaidMetaComments {

    struct NodeMeta {
        var position: CGPoint?
        var size: CGFloat?
        var rotation: CGFloat?
        var width: CGFloat?
        var height: CGFloat?
        var color: String?
        /// v62: separat ram-färg (`%% id stroke: #hex`)
        var stroke: String?
        var note: String?
        var prompt: String?
        var textStyleRaw: String?
        var packId: String?
        var hiddenLabel: Bool = false
        var collapsed: Bool = false
        var link: Int?
        var tableRows: Int?
        var tableCols: Int?
        /// Label från `%% name:` — återställer text när mermaid-kroppen visar " "
        /// (dold etikett skrivs som blank i nod-syntaxen).
        var name: String?
        /// Absolut slutpunkt för lösa linjer/pilar (generatorn skriver absolut;
        /// görs om till relativ offset när positionen är känd).
        var lineEndAbsolute: CGPoint?
        /// v67: explicit form-typ för former utan egen Mermaid-syntax (t.ex. phoneFrame).
        var shapeTypeRaw: String?
    }

    /// Skannar ett mermaid-block rad för rad. Returnerar metadata per mermaid-id.
    static func parse(_ block: String) -> [String: NodeMeta] {
        var result: [String: NodeMeta] = [:]

        for rawLine in block.split(separator: "\n", omittingEmptySubsequences: true) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard line.hasPrefix("%%"), !line.hasPrefix("%%{") else { continue }
            // Format: "%% <id> <nyckel>[: <värde>]"
            let body = line.dropFirst(2).trimmingCharacters(in: .whitespaces)
            guard let firstSpace = body.firstIndex(of: " ") else { continue }
            let id = String(body[..<firstSpace])
            let rest = body[body.index(after: firstSpace)...].trimmingCharacters(in: .whitespaces)
            guard !id.isEmpty, !rest.isEmpty else { continue }

            var meta = result[id] ?? NodeMeta()
            apply(rest, to: &meta)
            result[id] = meta
        }
        return result
    }

    /// Omvänd `MermaidGenerator.oneLine` — radbrytningar + %% återställs.
    static func multiLine(_ text: String) -> String {
        text.replacingOccurrences(of: " ⏎ ", with: "\n")
            .replacingOccurrences(of: "%-%", with: "%%")
    }

    // MARK: - Privat

    private static func apply(_ rest: String, to meta: inout NodeMeta) {
        // Flagg-nycklar utan värde
        if rest == "hidden-label" { meta.hiddenLabel = true; return }
        if rest == "collapsed"    { meta.collapsed = true; return }

        guard let colon = rest.firstIndex(of: ":") else { return }
        let key = String(rest[..<colon]).trimmingCharacters(in: .whitespaces)
        let value = String(rest[rest.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
        guard !value.isEmpty else { return }

        switch key {
        case "pos", "container-pos":
            if let p = point(value) { meta.position = p }
        case "size":
            if let d = Double(value) { meta.size = CGFloat(d) }
        case "rot":
            // Skrivs som "45°" — strippa gradtecknet
            let raw = value.replacingOccurrences(of: "°", with: "")
            if let d = Double(raw) { meta.rotation = CGFloat(d) }
        case "width":
            if let d = Double(value) { meta.width = CGFloat(d) }
        case "height":
            if let d = Double(value) { meta.height = CGFloat(d) }
        case "color":
            meta.color = value
        case "stroke":
            meta.stroke = value
        case "note":
            meta.note = multiLine(value)
        case "prompt":
            meta.prompt = multiLine(value)
        case "style":
            meta.textStyleRaw = value
        case "pack":
            meta.packId = value
        case "name":
            meta.name = multiLine(value)
        case "link":
            if let i = Int(value) { meta.link = i }
        case "table":
            // Skrivs som "3×4"
            let parts = value.split(separator: "×")
            if parts.count == 2, let r = Int(parts[0]), let c = Int(parts[1]) {
                meta.tableRows = r
                meta.tableCols = c
            }
        case "line-end":
            if let p = point(value) { meta.lineEndAbsolute = p }
        case "shape-type":
            meta.shapeTypeRaw = value
        default:
            break // okänd nyckel (t.ex. "name" — label kommer från nod-syntaxen) — ignorera
        }
    }

    /// "123,456" → CGPoint. Tål negativa värden.
    private static func point(_ value: String) -> CGPoint? {
        let parts = value.split(separator: ",")
        guard parts.count == 2,
              let x = Double(parts[0].trimmingCharacters(in: .whitespaces)),
              let y = Double(parts[1].trimmingCharacters(in: .whitespaces)) else { return nil }
        return CGPoint(x: x, y: y)
    }
}
