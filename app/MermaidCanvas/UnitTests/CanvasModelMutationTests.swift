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

    /// Steg 9: phoneFrame äger sitt innehåll — en form på skärmen blir dess barn
    /// och förälder-länken överlever round-trip (state-JSON).
    func test_phoneFrame_actsAsContainer_claimsChildAndRoundTrips() {
        let m = CanvasModel()
        m.addShape(.circle, at: c)
        m.addShape(.phoneFrame, at: c, label: "iPhone 16 Pro")
        let phone = m.shapes.first { $0.type == .phoneFrame }
        let circle = m.shapes.first { $0.type == .circle }
        XCTAssertEqual(phone?.position, c, "phoneFrame kaskadas inte")
        XCTAssertEqual(circle?.childOfContainerId, phone?.id,
                       "phoneFrame adopterar formen på skärmen (steg 9)")
        // Round-trip via state-JSON: förälder-länken (childOfContainerId) överlever.
        let doc = CanvasDocument(title: "T", shapes: m.shapes, edges: [],
                                 canvasSize: CGSize(width: 2000, height: 2000),
                                 specType: .ui).content
        let parsed = MermaidParser.parse(doc)
        let pPhone = parsed.shapes.first { $0.type == .phoneFrame }
        let pCircle = parsed.shapes.first { $0.type == .circle }
        XCTAssertEqual(pCircle?.childOfContainerId, pPhone?.id,
                       "förälder-länken till phoneFrame överlever round-trip")
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

    /// Kontroll-genomgång K9: låst barn står still även när containern dras.
    func test_moveContainerChildren_skipsLockedChild() {
        let m = CanvasModel()
        let box = ShapeNode(type: .container, position: CGPoint(x: 500, y: 500))
        var lockedChild = ShapeNode(type: .circle, position: CGPoint(x: 480, y: 500),
                                    childOfContainerId: box.id)
        lockedChild.locked = true
        let freeChild = ShapeNode(type: .circle, position: CGPoint(x: 490, y: 500),
                                  childOfContainerId: box.id)
        m.shapes = [box, lockedChild, freeChild]
        m.moveContainerChildren(containerId: box.id, by: CGSize(width: 40, height: 0))
        XCTAssertEqual(m.shapes[1].position.x, 480, "låst barn står still vid container-drag")
        XCTAssertEqual(m.shapes[2].position.x, 530, "olåst barn följer med containern")
    }

    // MARK: - align (Centrera H/V)

    func test_alignSelectionHorizontally_snapsToMedianY() {
        let m = CanvasModel()
        let a = ShapeNode(type: .circle, position: CGPoint(x: 100, y: 100))
        let b = ShapeNode(type: .circle, position: CGPoint(x: 200, y: 200))
        let c3 = ShapeNode(type: .circle, position: CGPoint(x: 300, y: 300))
        m.shapes = [a, b, c3]
        m.multiSelection = [a.id, b.id, c3.id]
        m.alignSelectionHorizontally()
        XCTAssertEqual(m.shapes.map { $0.position.y }, [200, 200, 200],
                       "alla snäpper till median-Y (200)")
        XCTAssertEqual(m.shapes.map { $0.position.x }, [100, 200, 300], "X orörd")
    }

    func test_alignSelectionVertically_snapsToMedianX() {
        let m = CanvasModel()
        let a = ShapeNode(type: .circle, position: CGPoint(x: 100, y: 100))
        let b = ShapeNode(type: .circle, position: CGPoint(x: 200, y: 200))
        let c3 = ShapeNode(type: .circle, position: CGPoint(x: 300, y: 300))
        m.shapes = [a, b, c3]
        m.multiSelection = [a.id, b.id, c3.id]
        m.alignSelectionVertically()
        XCTAssertEqual(m.shapes.map { $0.position.x }, [200, 200, 200],
                       "alla snäpper till median-X (200)")
    }

    func test_alignSelection_noOpBelowTwo() {
        let m = CanvasModel()
        let a = ShapeNode(type: .circle, position: CGPoint(x: 100, y: 100))
        m.shapes = [a]
        m.multiSelection = [a.id]
        m.alignSelectionHorizontally()
        m.alignSelectionVertically()
        XCTAssertEqual(m.shapes[0].position, CGPoint(x: 100, y: 100),
                       "färre än 2 markerade → ingen ändring")
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

    /// V79-svep: snabb-mall AI-Skill bygger container + barn + kanter (en undo).
    func test_insertTemplate_aiSkill_buildsContainerWithChildrenAndEdges() {
        let m = CanvasModel()
        m.insertTemplate(.aiSkill, at: c)
        let container = m.shapes.first { $0.type == .container }
        XCTAssertEqual(container?.skillNumber, 1)
        let children = m.shapes.filter { $0.childOfContainerId == container?.id }
        XCTAssertEqual(children.count, 3, "input + subagent + output")
        XCTAssertEqual(m.edges.count, 2, "input→subagent→output")
        XCTAssertTrue(m.canUndo, "mallen är en undo-bar handling")
    }

    /// v1.0+ Visio: hoppa in → rita → hoppa ut bevarar underflödet på föräldern.
    func test_visioDrill_enterExitPreservesContent() {
        let m = CanvasModel()
        m.addShape(.rectangle, at: c)
        let parentId = m.shapes[0].id
        m.enterSubprocess(parentId)
        XCTAssertTrue(m.isDrilledIn)
        XCTAssertTrue(m.shapes.isEmpty, "nytt underflöde börjar tomt")
        m.addShape(.circle, at: c)
        m.exitSubprocess()
        XCTAssertFalse(m.isDrilledIn)
        XCTAssertEqual(m.shapes.count, 1, "tillbaka till roten")
        XCTAssertEqual(m.shapes.first?.subCanvas?.shapes.count, 1,
                       "underflödets innehåll bevarat på föräldern")
    }

    /// Genomgång (2026-06-24): flernivå-drill (Visio) + brödsmulor (anti-vilse för 2e) + exitToRoot.
    /// Bevisar att 2 nivåer djupt nästlas korrekt och att brödsmulan speglar nuvarande nivå.
    func test_visioDrill_multiLevel_breadcrumb_exitToRoot() {
        let m = CanvasModel()
        m.addShape(.rectangle, at: c); m.shapes[0].label = "Process A"
        let aId = m.shapes[0].id
        XCTAssertEqual(m.drillBreadcrumb, ["Huvudflöde"])

        m.enterSubprocess(aId)                                  // nivå 1
        XCTAssertEqual(m.drillBreadcrumb, ["Huvudflöde", "Process A"])
        m.addShape(.diamond, at: c); m.shapes[0].label = "Beslut B"
        let bId = m.shapes[0].id

        m.enterSubprocess(bId)                                  // nivå 2
        XCTAssertEqual(m.drillBreadcrumb, ["Huvudflöde", "Process A", "Beslut B"])
        m.addShape(.circle, at: c)

        m.exitToRoot()                                          // hela vägen ut (brödsmule-tap på roten)
        XCTAssertFalse(m.isDrilledIn)
        XCTAssertEqual(m.drillBreadcrumb, ["Huvudflöde"])
        let a = m.shapes.first { $0.id == aId }
        XCTAssertEqual(a?.subCanvas?.shapes.count, 1, "A har B i sitt underflöde")
        XCTAssertEqual(a?.subCanvas?.shapes.first?.subCanvas?.shapes.count, 1,
                       "B har cirkeln i SITT underflöde (2 nivåer nästlat)")
    }

    /// V79-svep: redo (ångra åt båda håll).
    func test_redo_reappliesAndIsClearedByNewEdit() {
        let m = CanvasModel()
        m.addShape(.rectangle, at: c)
        m.undo()
        XCTAssertEqual(m.shapes.count, 0)
        XCTAssertTrue(m.canRedo, "efter undo går det att göra om")
        m.redo()
        XCTAssertEqual(m.shapes.count, 1, "redo återskapar formen")
        m.undo()
        m.addShape(.circle, at: c)   // ny redigering
        XCTAssertFalse(m.canRedo, "ny redigering ogiltigförklarar redo-historiken")
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
