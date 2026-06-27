import XCTest
import CoreGraphics
@testable import MermaidCanvas

/// MA spår A — A2: per-fält symmetri mellan skriv (`MermaidGenerator.canvasStateJSON`)
/// och läs (`MermaidParser.parseStateJSON`).
///
/// Varje fält sätts ISOLERAT till ett icke-default-värde och måste överleva round-trip.
/// Detta fångar "fält-glidning" — den #1 historiska buggklassen, där filen och bilden
/// glider isär för att ett fält lagts på skriv-sidan men glömts på läs-sidan (eller tvärtom).
/// A1 testar alla fält tillsammans; A2 isolerar varje fält så ett brott pekas ut exakt.
final class StateJSONSymmetryTests: XCTestCase {

    private func roundTripFirst(_ s: ShapeNode) -> ShapeNode? {
        let doc = CanvasDocument(
            title: "Sym", shapes: [s], edges: [],
            canvasSize: CGSize(width: 4000, height: 4000), specType: .general,
            platform: .blank, activeShapePacks: [.basic], collapsedEdgeIds: [])
        return MermaidParser.parse(doc.content).shapes.first
    }

    private func rect() -> ShapeNode {
        ShapeNode(type: .rectangle, position: CGPoint(x: 400, y: 400), label: "Bas")
    }

    func test_showLabel() {
        var s = rect(); s.showLabel = false
        XCTAssertEqual(roundTripFirst(s)?.showLabel, false, "showLabel ska bevaras")
    }
    func test_sizeMultiplier() {
        var s = rect(); s.sizeMultiplier = 1.75
        XCTAssertEqual(roundTripFirst(s)?.sizeMultiplier, 1.75)
    }
    func test_widthMultiplier() {
        var s = rect(); s.widthMultiplier = 2.0
        XCTAssertEqual(roundTripFirst(s)?.widthMultiplier, 2.0)
    }
    func test_heightMultiplier() {
        var s = rect(); s.heightMultiplier = 1.5
        XCTAssertEqual(roundTripFirst(s)?.heightMultiplier, 1.5)
    }
    func test_note() {
        var s = rect(); s.note = "en notis"
        XCTAssertEqual(roundTripFirst(s)?.note, "en notis")
    }
    func test_prompt() {
        var s = rect(); s.prompt = "en prompt"
        XCTAssertEqual(roundTripFirst(s)?.prompt, "en prompt")
    }
    func test_rotation() {
        var s = rect(); s.rotation = 45
        XCTAssertEqual(roundTripFirst(s)?.rotation, 45)
    }
    func test_colorOverride() {
        var s = rect(); s.colorOverride = "#ff0000"
        XCTAssertEqual(roundTripFirst(s)?.colorOverride, "#ff0000")
    }
    func test_strokeColorOverride() {
        var s = rect(); s.strokeColorOverride = "#00aa00"
        XCTAssertEqual(roundTripFirst(s)?.strokeColorOverride, "#00aa00")
    }
    func test_colorPackId() {
        var s = rect(); s.colorPackId = "blue"
        XCTAssertEqual(roundTripFirst(s)?.colorPackId, "blue")
    }
    func test_textStyle() {
        var s = rect(); s.textStyle = .r1
        XCTAssertEqual(roundTripFirst(s)?.textStyle, .r1)
    }
    func test_textStyle_jatte() {   // 1.5: nya största nivån round-trippar
        var s = rect(); s.textStyle = .jatte
        XCTAssertEqual(roundTripFirst(s)?.textStyle, .jatte)
    }
    func test_textAlignment() {
        var s = rect(); s.textAlignment = .trailing
        XCTAssertEqual(roundTripFirst(s)?.textAlignment, .trailing)
    }
    func test_hasBullets() {
        var s = rect(); s.hasBullets = true
        XCTAssertEqual(roundTripFirst(s)?.hasBullets, true)
    }
    func test_hasNumberedList() {
        var s = rect(); s.hasNumberedList = true
        XCTAssertEqual(roundTripFirst(s)?.hasNumberedList, true)
    }
    func test_indentLevel() {
        var s = rect(); s.indentLevel = 2
        XCTAssertEqual(roundTripFirst(s)?.indentLevel, 2)
    }
    func test_skillNumber() {
        var s = ShapeNode(type: .container, position: CGPoint(x: 400, y: 400), label: "Skill")
        s.skillNumber = 3
        XCTAssertEqual(roundTripFirst(s)?.skillNumber, 3)
    }
    func test_linkNumber() {
        var s = ShapeNode(type: .link, position: CGPoint(x: 400, y: 400), label: "L")
        s.linkNumber = 5
        XCTAssertEqual(roundTripFirst(s)?.linkNumber, 5)
    }
    func test_lineEnd() {
        var s = ShapeNode(type: .line, position: CGPoint(x: 400, y: 400))
        s.lineEnd = CGPoint(x: 80, y: 60)
        let p = roundTripFirst(s)
        XCTAssertEqual(p?.lineEnd?.x, 80, "lineEnd.x ska bevaras")
        XCTAssertEqual(p?.lineEnd?.y, 60, "lineEnd.y ska bevaras")
    }
}
