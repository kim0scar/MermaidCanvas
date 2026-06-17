import XCTest
import CoreGraphics
@testable import MermaidCanvas

/// MA spår A — A3: fryst beteendespec för CanvasModels mutationer.
///
/// Detta är skyddsnätet för model-dekompositionen (spår A steg 14–18): när logik
/// flyttas till value-services (CollapseOps, ContainerOps, …) måste exakt detta
/// beteende bestå. En refaktor som ändrar något här failar testet.
@MainActor
final class CanvasModelMutationTests: XCTestCase {

    private let c = CGPoint(x: 2000, y: 2000)

    // MARK: - addShape + kaskad

    func test_addShape_cascadesOnOverlap() {
        let m = CanvasModel()
        m.addShape(.rectangle, at: c)
        m.addShape(.rectangle, at: c)
        XCTAssertEqual(m.shapes.count, 2)
        XCTAssertEqual(m.shapes[0].position, c, "första formen hamnar på punkten")
        XCTAssertEqual(m.shapes[1].position, CGPoint(x: c.x + 96, y: c.y + 96),
                       "andra formen kaskadas 96pt diagonalt (ingen osynlig hög)")
    }

    func test_addContainer_doesNotCascade_andClaimsChild() {
        let m = CanvasModel()
        m.addShape(.circle, at: c)
        m.addShape(.container, at: c)
        let container = m.shapes.first { $0.type == .container }
        let circle = m.shapes.first { $0.type == .circle }
        XCTAssertEqual(container?.position, c, "container kaskadas inte — landar på punkten")
        XCTAssertEqual(circle?.childOfContainerId, container?.id,
                       "container adopterar formen inom sina gränser")
    }

    // MARK: - moveSelection

    func test_moveSelection_movesAllSelected() {
        let m = CanvasModel()
        let a = ShapeNode(type: .circle, position: CGPoint(x: 100, y: 100))
        let b = ShapeNode(type: .circle, position: CGPoint(x: 300, y: 100))
        m.shapes = [a, b]
        m.multiSelection = [a.id, b.id]
        m.moveSelection(by: CGSize(width: 50, height: 20))
        XCTAssertEqual(m.shapes[0].position, CGPoint(x: 150, y: 120))
        XCTAssertEqual(m.shapes[1].position, CGPoint(x: 350, y: 120))
    }

    func test_moveSelection_containerDragsChildren() {
        let m = CanvasModel()
        let box = ShapeNode(type: .container, position: CGPoint(x: 500, y: 500))
        let child = ShapeNode(type: .circle, position: CGPoint(x: 480, y: 500),
                              childOfContainerId: box.id)
        m.shapes = [box, child]
        m.multiSelection = [box.id]   // bara containern markerad
        m.moveSelection(by: CGSize(width: 40, height: 0))
        XCTAssertEqual(m.shapes[0].position.x, 540, "containern flyttas")
        XCTAssertEqual(m.shapes[1].position.x, 520, "barnet följer med containern")
    }

    // MARK: - undo

    func test_undo_restoresPreviousState_andEmptyIsNoop() {
        let m = CanvasModel()
        XCTAssertFalse(m.canUndo)
        m.addShape(.rectangle, at: c)
        XCTAssertEqual(m.shapes.count, 1)
        XCTAssertTrue(m.canUndo)
        m.undo()
        XCTAssertEqual(m.shapes.count, 0, "undo återställer till tomt")
        m.undo()   // no-op på tom stack
        XCTAssertEqual(m.shapes.count, 0)
    }

    func test_undo_cappedAt30() {
        let m = CanvasModel()
        for i in 0..<35 {
            m.addShape(.rectangle, at: CGPoint(x: 200 + i * 200, y: 400))
        }
        XCTAssertEqual(m.shapes.count, 35)
        for _ in 0..<30 { m.undo() }
        XCTAssertFalse(m.canUndo, "undo-stacken är capad till 30")
        XCTAssertEqual(m.shapes.count, 5, "äldsta 5 snapshots tappades — kan inte ångra förbi det")
    }

    // MARK: - collapse

    func test_toggleCollapseEdge() {
        let m = CanvasModel()
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: 100, y: 100))
        let b = ShapeNode(type: .circle, position: CGPoint(x: 300, y: 100))
        m.shapes = [a, b]
        m.addEdge(from: a.id, to: b.id)
        let edgeId = m.edges[0].id
        m.toggleCollapseEdge(edgeId)
        XCTAssertTrue(m.collapsedEdgeIds.contains(edgeId))
        m.toggleCollapseEdge(edgeId)
        XCTAssertFalse(m.collapsedEdgeIds.contains(edgeId))
    }

    func test_toggleCollapse_allOutgoingBranches() {
        let m = CanvasModel()
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: 100, y: 100))
        let b = ShapeNode(type: .circle, position: CGPoint(x: 300, y: 100))
        let d = ShapeNode(type: .circle, position: CGPoint(x: 300, y: 300))
        m.shapes = [a, b, d]
        m.addEdge(from: a.id, to: b.id)
        m.addEdge(from: a.id, to: d.id)
        m.toggleCollapse(id: a.id)
        XCTAssertEqual(m.collapsedEdgeIds.count, 2, "alla a:s utgående grenar kollapsas")
        m.toggleCollapse(id: a.id)
        XCTAssertEqual(m.collapsedEdgeIds.count, 0, "andra toggle fäller ut alla")
    }

    // MARK: - addEdge

    func test_addEdge_rejectsSelfLoopAndDuplicate() {
        let m = CanvasModel()
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: 100, y: 100))
        let b = ShapeNode(type: .circle, position: CGPoint(x: 300, y: 100))
        m.shapes = [a, b]
        m.addEdge(from: a.id, to: a.id)
        XCTAssertEqual(m.edges.count, 0, "självloop avvisas")
        m.addEdge(from: a.id, to: b.id)
        m.addEdge(from: a.id, to: b.id)
        XCTAssertEqual(m.edges.count, 1, "dubblett åt samma håll avvisas")
        m.addEdge(from: b.id, to: a.id)
        XCTAssertEqual(m.edges.count, 2, "motsatt riktning tillåts")
    }

    // MARK: - duplicate / delete selection

    func test_duplicateSelection_copiesFields_dropsLink_offsets() {
        let m = CanvasModel()
        var a = ShapeNode(type: .rectangle, position: CGPoint(x: 200, y: 200), label: "A")
        a.note = "n"; a.prompt = "p"; a.linkNumber = 7
        m.shapes = [a]
        m.multiSelection = [a.id]
        m.duplicateSelection()
        XCTAssertEqual(m.shapes.count, 2)
        let copy = m.shapes[1]
        XCTAssertEqual(copy.note, "n"); XCTAssertEqual(copy.prompt, "p")
        XCTAssertEqual(copy.label, "A")
        XCTAssertNil(copy.linkNumber, "linkNumber kopieras INTE (orphan-skydd)")
        XCTAssertEqual(copy.position, CGPoint(x: 230, y: 230), "kopian förskjuts +30")
        XCTAssertEqual(m.multiSelection, [copy.id], "markeringen flyttas till kopian")
    }

    func test_deleteSelection_removesShapesAndConnectedEdges() {
        let m = CanvasModel()
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: 100, y: 100))
        let b = ShapeNode(type: .circle, position: CGPoint(x: 300, y: 100))
        let d = ShapeNode(type: .circle, position: CGPoint(x: 500, y: 100))
        m.shapes = [a, b, d]
        m.addEdge(from: a.id, to: b.id)
        m.addEdge(from: b.id, to: d.id)
        m.multiSelection = [b.id]
        m.deleteSelection()
        XCTAssertEqual(m.shapes.map { $0.id }.sorted(by: { $0.uuidString < $1.uuidString }),
                       [a.id, d.id].sorted(by: { $0.uuidString < $1.uuidString }),
                       "bara b tas bort")
        XCTAssertEqual(m.edges.count, 0, "kanter som rör b försvinner")
        XCTAssertTrue(m.multiSelection.isEmpty)
    }

    func test_deleteShape_removesConnectedEdges() {
        let m = CanvasModel()
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: 100, y: 100))
        let b = ShapeNode(type: .circle, position: CGPoint(x: 300, y: 100))
        m.shapes = [a, b]
        m.addEdge(from: a.id, to: b.id)
        m.deleteShape(id: a.id)
        XCTAssertEqual(m.shapes.count, 1)
        XCTAssertEqual(m.edges.count, 0, "kant till borttagen form försvinner")
    }
}
