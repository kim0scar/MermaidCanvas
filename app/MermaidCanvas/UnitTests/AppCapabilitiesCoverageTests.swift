import XCTest
import CoreGraphics
@testable import MermaidCanvas

/// REGEL 15-grinden (V79-svep / v0.9): bevisar att facit (AppCapabilities) och vad
/// generatorn FAKTISKT emitterar inte kan glida isär. Tidigare refererade regel 15 ett
/// test som inte fanns — detta är det testet.
///
/// Kärnan: generera mermaid som rör VARJE app-egen bärare, extrahera alla `%%`-nycklar ur
/// outputen, och kräv en BIJEKTION mot `AppCapabilities.allCarrierKeys`:
///  - ingen ODOKUMENTERAD nyckel (generatorn emitterar något facit inte känner till), och
///  - ingen FANTOM-nyckel (facit listar en bärare generatorn aldrig skriver).
@MainActor
final class AppCapabilitiesCoverageTests: XCTestCase {

    /// Plockar ut `%%`-nyckel-tokens ur generator-output (hoppar `%%{init…}`-direktivet).
    private func carrierKeys(in mermaid: String) -> Set<String> {
        var keys = Set<String>()
        for raw in mermaid.split(separator: "\n") {
            let t = raw.trimmingCharacters(in: .whitespaces)
            guard t.hasPrefix("%%"), !t.hasPrefix("%%{") else { continue }
            let body = String(t.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            let toks = body.split(separator: " ").map(String.init)
            guard let first = toks.first else { continue }
            let firstKey = first.replacingOccurrences(of: ":", with: "")
            if firstKey == "canvas-size" || firstKey == "legend" {
                keys.insert(firstKey)            // canvas-nivå: `%% <key>` utan id
            } else if toks.count >= 2 {
                keys.insert(toks[1].replacingOccurrences(of: ":", with: ""))  // `%% <id> <key>`
            }
        }
        return keys
    }

    /// Bygger ett dokument som rör (nästan) varje bärare och returnerar mermaid-kroppen.
    private func everyCarrierMermaid() -> String {
        // Rik nod: storlek/rotation/färg/lås/lager/listor/justering/indrag/stil/pack/dold etikett.
        var rich = ShapeNode(type: .rectangle, position: CGPoint(x: 300, y: 300), label: "Rik",
                             category: .skill)               // .skill ⇒ carriesPrompt ⇒ prompt-nyckeln
        rich.sizeMultiplier = 1.5; rich.widthMultiplier = 1.2; rich.heightMultiplier = 1.3
        rich.rotation = 30; rich.colorOverride = "#112233"; rich.strokeColorOverride = "#445566"
        rich.note = "anteckning"; rich.prompt = "prompt-text"
        rich.textAlignment = .leading; rich.hasBullets = true; rich.indentLevel = 1
        rich.textStyle = .r1; rich.colorPackId = "blå"; rich.showLabel = false
        rich.locked = true; rich.zLayer = 1

        var numbered = ShapeNode(type: .rectangle, position: CGPoint(x: 500, y: 300), label: "Num")
        numbered.hasNumberedList = true

        var link = ShapeNode(type: .link, position: CGPoint(x: 700, y: 300), label: "L")
        link.linkNumber = 1

        var table = ShapeNode(type: .table, position: CGPoint(x: 300, y: 500), label: "Tab")
        table.tableRows = 2; table.tableCols = 2; table.tableCells = [["a", "b"], ["c", "d"]]

        var line = ShapeNode(type: .line, position: CGPoint(x: 500, y: 500), label: "")
        line.lineEnd = CGPoint(x: 60, y: 0)

        let phone = ShapeNode(type: .phoneFrame, position: CGPoint(x: 700, y: 500), label: "iPhone")

        var container = ShapeNode(type: .container, position: CGPoint(x: 400, y: 700), label: "Skill")
        container.skillNumber = 2
        let child = ShapeNode(type: .rectangle, position: CGPoint(x: 390, y: 720),
                              label: "barn", childOfContainerId: container.id)

        // Kant med waypoint + etikett-placering + färg + utgångssida + kollaps.
        var edge = EdgeConnection(from: rich.id, to: numbered.id, label: "x",
                                  direction: .forward, style: .solid)
        edge.waypoints = [EdgeWaypoint(x: 400, y: 360)]
        edge.labelPlacement = .above
        edge.colorHex = "#998877"
        edge.fromSide = .right
        edge.toSide = .left            // 1.3: så "toSide"-nyckeln emitteras (bijektion)
        edge.lineShape = .orthogonal   // v1.0: så "lineShape"-nyckeln emitteras (bijektion)

        let shapes = [rich, numbered, link, table, line, phone, container, child]
        let doc = MermaidGenerator.generate(
            shapes: shapes, edges: [edge],
            canvasSize: CGSize(width: 2200, height: 1700),
            specType: .ui,
            collapsedEdgeIds: [edge.id],
            legend: ["skill": "en skill"])
        return doc
    }

    func test_noUndocumentedCarrierKey() {
        let emitted = carrierKeys(in: everyCarrierMermaid())
        let undocumented = emitted.subtracting(AppCapabilities.allCarrierKeys)
        XCTAssertTrue(undocumented.isEmpty,
                      "Generatorn emitterar `%%`-nycklar som facit (AppCapabilities.allCarrierKeys) inte känner till: \(undocumented.sorted()). Lägg till dem (CLAUDE.md regel 15).")
    }

    func test_noPhantomCarrierKey() {
        let emitted = carrierKeys(in: everyCarrierMermaid())
        let phantom = AppCapabilities.allCarrierKeys.subtracting(emitted)
        XCTAssertTrue(phantom.isEmpty,
                      "Facit listar bärare som generatorn aldrig emitterar (fantom-nycklar): \(phantom.sorted()). Ta bort dem eller rör dem i test-scenariot.")
    }

    /// Facit-menyn + AI-legenden täcker varje form (regel 15 (e)).
    func test_menuAndLegendCoverEveryShape() {
        let fw = AppCapabilities.frameworkText()
        for t in ShapeType.allCases {
            XCTAssertFalse(AppCapabilities.shape(t).displayName.isEmpty)
            XCTAssertTrue(fw.contains(AppCapabilities.shape(t).displayName), "AI-legend saknar \(t.rawValue)")
            _ = AppCapabilities.level(forShape: t)   // uttömmande → ny form utan färg = kompileringsfel
        }
        XCTAssertFalse(AppCapabilities.features.isEmpty)
    }

    /// 1.0 (Kims fundament-krav, regel 15-anda): AI-ramverket MÅSTE bäddas in i VARJE
    /// exportfil, och inbäddningen får inte störa state-round-trippen. Annars kan
    /// "spec:en följer alltid med" tyst falla bort — gaten gör det maskinellt tvingat.
    func test_exportEmbedsFrameworkAndStillRoundTrips() {
        let n = ShapeNode(type: .diamond, position: CGPoint(x: 321, y: 88), label: "Beslut")
        let doc = CanvasDocument(title: "T", shapes: [n], edges: [],
                                 canvasSize: CGSize(width: 1200, height: 900),
                                 specType: .flow)
        // (a) ramverket finns inbäddat i normal export
        XCTAssertTrue(doc.content.contains("Till en AI som tar emot denna fil"),
                      "Exportfilen saknar inbäddat AI-ramverk (regel 15: spec:en ska alltid följa med).")
        XCTAssertTrue(doc.content.contains("TVÅ-LAGER-system"))
        XCTAssertTrue(doc.content.contains("## Kanter"))
        // (b) inbäddningen bryter inte state-round-trippen — formen överlever exakt
        let parsed = MermaidParser.parse(doc.content)
        XCTAssertEqual(parsed.shapes.count, 1, "State-blocket gick inte att läsa efter inbäddning.")
        XCTAssertEqual(parsed.shapes.first?.type, .diamond)
        XCTAssertEqual(parsed.shapes.first.map { Int($0.position.x.rounded()) }, 321)
        // (c) skill-exporten bär också ramverket
        let skill = SkillFileComposer.compose(
            skillName: "S", skillNumber: 1, shapes: [n], edges: [],
            canvasSize: CGSize(width: 1200, height: 900),
            platform: .blank, activeShapePacks: [.basic], legend: [:])
        XCTAssertTrue(skill.contains("Till en AI som tar emot denna fil"),
                      "Skill-exporten saknar inbäddat AI-ramverk.")
    }
}
