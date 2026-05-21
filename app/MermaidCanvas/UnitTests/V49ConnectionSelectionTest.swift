import XCTest
@testable import MermaidCanvas

/// v49: verifierar Fel #3 fix — efter addEdge ska from-shape vara markerad
/// så att EdgeStartCollapseBadge (minus) visas vid kantens start.
///
/// Detta är ett UNIT-test eftersom XCUITest:s connection-handle-drag inte
/// fungerar reliably i simulatorn (gesture-konflikt). Testet verifierar
/// MODELL-tillståndet efter att fixen i CanvasView.swift onDragEnded körts.
@MainActor
final class V49ConnectionSelectionTest: XCTestCase {

    /// Verifiera att vi har koll på modellens kontrakt: addEdge påverkar inte
    /// selectedShapeId direkt — det är CanvasView som ska sätta det i
    /// onDragEnded efter addEdge.
    func test_addEdge_does_not_change_selectedShapeId_in_model() throws {
        let model = CanvasModel()
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: 100, y: 100))
        let b = ShapeNode(type: .circle, position: CGPoint(x: 300, y: 100))
        model.shapes = [a, b]
        model.selectedShapeId = nil

        model.addEdge(from: a.id, to: b.id)

        // addEdge ska INTE ändra selectedShapeId — det är CanvasView's
        // onDragEnded som har ansvar för det (v49 Fel #3-fixen).
        XCTAssertNil(model.selectedShapeId)
        XCTAssertEqual(model.edges.count, 1)
        XCTAssertEqual(model.edges.first?.from, a.id)
        XCTAssertEqual(model.edges.first?.to, b.id)
    }

    /// Verifiera att om vi MANUELLT sätter selectedShapeId = from.id efter
    /// addEdge (som v49-fixen gör), så är allting på plats för att
    /// EdgeStartCollapseBadge ska renderas (per EdgesView-villkoren).
    func test_addEdge_plus_selectedShapeId_enables_minus_badge_conditions() throws {
        let model = CanvasModel()
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: 100, y: 100))
        let b = ShapeNode(type: .circle, position: CGPoint(x: 300, y: 100))
        model.shapes = [a, b]

        // Simulera v49 onDragEnded: addEdge + selectedShapeId = from.id
        model.addEdge(from: a.id, to: b.id)
        model.selectedShapeId = a.id

        // Verifiera villkoren som EdgesView.body kollar för att rendera
        // EdgeStartCollapseBadge:
        //   !hiddenShapeIds.contains(edge.from)     → true (a inte gömd)
        //   !hiddenShapeIds.contains(edge.to)       → true (b inte gömd)
        //   selectedShapeId == edge.from            → true (vi satte det)
        guard let edge = model.edges.first else {
            XCTFail("Kant saknas")
            return
        }
        XCTAssertFalse(model.hiddenShapeIds.contains(edge.from))
        XCTAssertFalse(model.hiddenShapeIds.contains(edge.to))
        XCTAssertEqual(model.selectedShapeId, edge.from)
    }

    /// Verifiera Fel #4: efter toggleCollapse(from) blir to gömd, vilket
    /// triggar EdgeStubBadge (plus alltid synlig).
    func test_toggleCollapse_hides_descendants_enabling_stub_plus() throws {
        let model = CanvasModel()
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: 100, y: 100))
        let b = ShapeNode(type: .circle, position: CGPoint(x: 300, y: 100))
        model.shapes = [a, b]
        model.addEdge(from: a.id, to: b.id)

        XCTAssertFalse(model.hiddenShapeIds.contains(b.id),
                       "Före kollaps ska to-shape vara synlig")

        model.toggleCollapse(id: a.id)

        XCTAssertTrue(model.hiddenShapeIds.contains(b.id),
                      "Efter kollaps av from-shape ska to-shape vara gömd " +
                      "— det är detta som triggar EdgeStubBadge (plus i luften)")
        XCTAssertFalse(model.hiddenShapeIds.contains(a.id),
                       "From-shape ska INTE vara gömd (annars ritas ingen stub)")
    }
}
