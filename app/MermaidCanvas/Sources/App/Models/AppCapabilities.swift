import Foundation

/// SINGLE SOURCE OF TRUTH för "vad appen kan visa → vad en AI får använda i mermaid".
///
/// Två syften (V79-svep / Kims krav):
///  1. **AI-ramverket** (`frameworkText()`) — copy-paste till en AI: exakt vilka former +
///     funktioner appen kan rita och HUR var och en bärs i mermaid utan skada. Genereras
///     ur KODEN → kan aldrig bli inaktuellt (till skillnad från en handskriven lista).
///  2. **In-app-menyn** (MermaidVsAppSheet) läser samma data → Kim ser mermaid vs app-only.
///
/// **Currency tvingas:** `shape(_:)` är en UTTÖMMANDE switch över ShapeType → en ny form
/// kompilerar inte utan en rad här. `AppCapabilitiesCoverageTests` kräver dessutom en
/// BIJEKTION mellan generatorns faktiska `%%`-nycklar och `allCarrierKeys` (ingen
/// odokumenterad nyckel, ingen fantom-nyckel) + att menyn/ramverket täcker varje form.
/// Se CLAUDE.md regel 15.
enum AppCapabilities {

    /// Hur en form bärs i mermaid.
    struct ShapeCap {
        let displayName: String
        /// Hur den renderas i RIKTIG mermaid (mermaid.live).
        let mermaidForm: String
        /// true = egen form: visas som närmaste native-form, identiteten bärs av `%% shape-type`.
        let appOnly: Bool
    }

    /// Uttömmande → ny ShapeType tvingar en rad (kompileringsfel annars).
    static func shape(_ t: ShapeType) -> ShapeCap {
        switch t {
        case .circle:       return ShapeCap(displayName: "Cirkel",       mermaidForm: "((text)) — native", appOnly: false)
        case .rectangle:    return ShapeCap(displayName: "Rektangel",    mermaidForm: "[text] — native", appOnly: false)
        case .diamond:      return ShapeCap(displayName: "Romb (beslut)", mermaidForm: "{text} — native", appOnly: false)
        case .pill:         return ShapeCap(displayName: "Kapsel",       mermaidForm: "([text]) stadium — native", appOnly: false)
        case .cylinder:     return ShapeCap(displayName: "Cylinder",     mermaidForm: "[(text)] — native", appOnly: false)
        case .container:    return ShapeCap(displayName: "Container / Skill", mermaidForm: "subgraph … end — native", appOnly: false)
        case .square:       return ShapeCap(displayName: "Kvadrat",      mermaidForm: "rektangel + %% shape-type: square", appOnly: true)
        case .processArrow: return ShapeCap(displayName: "Processpil",   mermaidForm: "rektangel + %% shape-type: processArrow", appOnly: true)
        case .octagon:      return ShapeCap(displayName: "Oktagon",      mermaidForm: "rektangel + %% shape-type: octagon", appOnly: true)
        case .triangle:     return ShapeCap(displayName: "Triangel",     mermaidForm: "rektangel + %% shape-type: triangle", appOnly: true)
        case .phoneFrame:   return ShapeCap(displayName: "iPhone-ram",   mermaidForm: "rektangel + %% shape-type: phoneFrame", appOnly: true)
        case .table:        return ShapeCap(displayName: "Tabell",       mermaidForm: "rektangel + %% table-cells", appOnly: true)
        case .link:         return ShapeCap(displayName: "Hopplänk",     mermaidForm: "cirkel + %% link: N", appOnly: true)
        case .line:         return ShapeCap(displayName: "Lös linje",    mermaidForm: "nod + %% shape-type: line", appOnly: true)
        case .arrow:        return ShapeCap(displayName: "Lös pil",      mermaidForm: "nod + %% shape-type: arrow", appOnly: true)
        case .emoji:        return ShapeCap(displayName: "Emoji",        mermaidForm: "text-nod + %% shape-type: emoji", appOnly: true)
        }
    }

    /// App-egna FUNKTIONER (inte former) — bärs i mermaid utan att skada den.
    struct FeatureCap {
        let name: String
        /// Var den bärs (mermaid-syntax / `%%`-nyckel / state-JSON).
        let carrier: String
        /// Överlever den i REN mermaid (utan state-blocket — en väns vy)?
        let survivesPureMermaid: Bool
    }

    static let features: [FeatureCap] = [
        .init(name: "Position",            carrier: "%% pos: x,y + state-JSON",            survivesPureMermaid: true),
        .init(name: "Storlek (bredd/höjd)", carrier: "%% size/width/height + state-JSON",  survivesPureMermaid: true),
        .init(name: "Rotation",            carrier: "%% rot: N° + state-JSON",             survivesPureMermaid: true),
        .init(name: "Kategori-färg",       carrier: ":::klass + classDef — native",        survivesPureMermaid: true),
        .init(name: "Egen färg (override)", carrier: "%% color/stroke + state-JSON",        survivesPureMermaid: true),
        .init(name: "🔒 Lås",              carrier: "%% locked + state-JSON",              survivesPureMermaid: true),
        .init(name: "📚 Lager (z)",        carrier: "%% z: N + state-JSON",                survivesPureMermaid: true),
        .init(name: "Textjustering/listor/indrag", carrier: "%% align/bullets/numbered/indent", survivesPureMermaid: true),
        .init(name: "Prompt (skill-former)", carrier: "%% prompt + state-JSON",            survivesPureMermaid: true),
        .init(name: "Anteckning",          carrier: "%% note + state-JSON",                survivesPureMermaid: true),
        .init(name: "Kollaps (gren)",      carrier: "%% e<i> collapsed + state-JSON",      survivesPureMermaid: true),
        .init(name: "Pil-waypoints/böj",   carrier: "%% e<i> waypoint + state-JSON",       survivesPureMermaid: true),
        .init(name: "Pil-färg/sida/etikett-pos", carrier: "%% e<i> color/fromSide/labelPlacement", survivesPureMermaid: true),
        .init(name: "Pil-linjeform (rak/böjd/vinklad)", carrier: "%% e<i> lineShape + linkStyle interpolate + state-JSON", survivesPureMermaid: true),
        .init(name: "Visio hoppa-in (underflöde)", carrier: "subCanvas i state-JSON (inget %%-spår i ren mermaid)", survivesPureMermaid: false),
        .init(name: "Bakåtpil",            carrier: "skrivs som omvänd framåtpil (to-->from)", survivesPureMermaid: true),
        .init(name: "Container-förälder",  carrier: "subgraph-medlemskap + state-JSON",    survivesPureMermaid: true),
        .init(name: "phoneFrame-förälder", carrier: "BARA state-JSON (childOfContainerId)", survivesPureMermaid: false),
        .init(name: "Canvas-storlek",      carrier: "%% canvas-size: w,h + state-JSON",    survivesPureMermaid: true),
        .init(name: "Skill-nummer",        carrier: "%% skill-nr + state-JSON",            survivesPureMermaid: true),
    ]

    /// AI-RAMVERKET — copy-paste till en AI så den vet exakt vad den får rita i mermaid
    /// för att appen ska kunna importera det. Genereras ur koden (alltid aktuell).
    static func frameworkText() -> String {
        var s = "# MermaidCanvas — vad du får använda i mermaid (genererat \(AppVersion.version))\n\n"
        s += "Appen är ett TVÅ-LAGER-system: mermaid är transporten, appen lägger till ett eget lager via\n"
        s += "`%%`-kommentarer + ett `<!-- mermaidcanvas-state … -->`-block. Rita med vanlig flowchart-syntax.\n\n"
        s += "## NATIVE mermaid-former (renderas identiskt)\n"
        for t in ShapeType.allCases {
            let c = shape(t)
            if !c.appOnly { s += "- **\(c.displayName)** → `\(c.mermaidForm)`\n" }
        }
        s += "\n## EGNA former (ritas som närmaste native; identitet via `%% shape-type`)\n"
        for t in ShapeType.allCases {
            let c = shape(t)
            if c.appOnly { s += "- **\(c.displayName)** → \(c.mermaidForm)\n" }
        }
        s += "\n## Kanter\n- `A --> B` (pil) · `A -.-> B` (streckad) · `A <--> B` (dubbelriktad) · `A --- B` (ingen pil)\n"
        s += "- Bakåtpil finns INTE i mermaid → skriv `B --> A` (omvända noder).\n"
        s += "\n## APP-EGNA funktioner (bärs i mermaid utan skada)\n"
        for f in features {
            s += "- **\(f.name)** → `\(f.carrier)`\(f.survivesPureMermaid ? "" : "  ⚠️ bara i state-blocket")\n"
        }
        s += "\n> Lägger du till en form/funktion utan att uppdatera detta + round-trippa = brott mot CLAUDE.md regel 15.\n"
        return s
    }

    /// 1.0 (Kims fundament-krav): AI-ramverket som ett INBÄDDAT block i VARJE exportfil — så
    /// filen ensam är självförklarande för en främmande AI (spec:en följer alltid med, inte
    /// bara bakom in-app-knappar). Läggs SIST, EFTER `<!-- mermaidcanvas-state -->`, som SYNLIG
    /// markdown — INTE i en HTML-kommentar: ramverket innehåller `-->` och själva strängen
    /// `<!-- mermaidcanvas-state -->`, vilket skulle stänga kommentaren i förtid / krocka med
    /// state-parsningen. En vän som klistrar in i mermaid.live påverkas inte (bara ```mermaid-
    /// blocket ritas); en AI som läser hela filen får hela spec:en gratis.
    static func embeddedFrameworkBlock() -> String {
        return """
        ---

        > 🤖 **Till en AI som tar emot denna fil:** sektionen nedan beskriver appens två lager \
        (genereras ur appen → alltid aktuell). En vän som öppnar i mermaid.live påverkas inte — \
        bara mermaid-blocket ovan ritas.

        \(frameworkText())
        """
    }

    // MARK: - Maskinell currency (regel 15)

    /// ALLA `%%`-nyckel-tokens som generatorn KAN emittera. `AppCapabilitiesCoverageTests`
    /// kollar att generatorns FAKTISKA output bara använder nycklar härifrån (ingen
    /// odokumenterad nyckel kan smyga in). Lägger någon en ny `%%`-nyckel i MermaidGenerator
    /// utan att lägga den här → testet blir rött (regel 15).
    static let allCarrierKeys: Set<String> = [
        // nod + container
        "pos", "name", "size", "width", "height", "rot", "hidden-label",
        "color", "stroke", "link", "skill-nr", "table", "table-cells",
        "shape-type", "style", "align", "bullets", "numbered", "indent",
        "locked", "z", "pack", "line-end", "prompt", "note", "container-pos",
        // canvas-nivå + kant
        "canvas-size", "legend", "waypoint", "labelPlacement", "fromSide", "collapsed",
        "lineShape",   // v1.0: form på linjen (rak/böjd/vinklad)
    ]

    /// Överlevnads-nivå för facit-menyns färgkodning (🟢/🟡/🟠).
    enum SurvivalLevel { case nativeMermaid, appCarried, appOnlyState }

    static func level(forShape t: ShapeType) -> SurvivalLevel {
        shape(t).appOnly ? .appCarried : .nativeMermaid
    }
    static func level(forFeature f: FeatureCap) -> SurvivalLevel {
        f.survivesPureMermaid ? .appCarried : .appOnlyState
    }
}
