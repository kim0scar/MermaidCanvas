import Foundation
import CoreGraphics

/// v50: scenario-router för visuell placerings-bugjakt.
/// Anropas från ContentView.applyUITestScenarioIfNeeded() vid app-start
/// när ett `-uitest-place-NN-*` launch-arg finns. Bygger upp en
/// deterministisk uppsättning shapes + edges direkt på modellen så
/// XCUITest kan ta en screenshot utan att förlita sig på drag-gester.
///
/// Scenariolista: se UITests/V50PlacementMatrix.md.
@MainActor
enum UITestScenarios {

    /// Returnerar true om något scenario byggdes.
    static func apply(args: [String], model: CanvasModel, center: CGPoint) -> Bool {
        guard let arg = args.first(where: { $0.hasPrefix("-uitest-place-") }) else {
            return false
        }
        let slug = String(arg.dropFirst("-uitest-place-".count))
        guard let builder = scenarios[slug] else { return false }
        builder(model, center)
        return true
    }

    private static let scenarios: [String: (CanvasModel, CGPoint) -> Void] = [
        "01-tight-horizontal":          place01TightHorizontal,
        "02-tight-vertical":            place02TightVertical,
        "03-diagonal":                  place03Diagonal,
        "04-very-close":                place04VeryClose,
        "05-arrowhead-8-directions":    place05Arrowhead8,
        "06-arrowhead-on-diamond":      place06ArrowheadDiamond,
        "07-arrowhead-on-pill":         place07ArrowheadPill,
        "08-arrow-each-shape-type":     place08ArrowEachShape,
        "09-processarrow-as-source":    place09ProcessArrowSource,
        "10-container-as-target":       place10ContainerTarget,
        "11-collapsed-single":          place11CollapsedSingle,
        "12-collapsed-chain":           place12CollapsedChain,
        "13-minus-badge-position":      place13MinusBadge,
        "14-bidir-with-label":          place14BidirLabel,
        "15-dashed-edge":               place15DashedEdge,
        "16-backward-edge":             place16BackwardEdge,
        "17-container-with-3-children": place17ContainerThreeChildren,
        "18-nested-containers":         place18NestedContainers,
        "19-child-outside-container":   place19ChildOutsideContainer,
        "20-multi-select-3-shapes":     place20MultiSelect3,
        "21-multi-select-with-edges":   place21MultiSelectEdges,
        "22-edge-after-resize":         place22EdgeAfterResize,
        "23-edge-with-label-curved":    place23EdgeLabelCurved,
        // v50.3 nya scenarier för exploratorisk täckning
        "29-container-with-label":      place29ContainerWithLabel,
        "30-marker-mode-active":        place30MarkerModeActive,
        "31-processarrow-isolated":     place31ProcessArrowIsolated,
        "32-arrowheads-8-dirs":         place32Arrowheads8DirsClean,
        "33-selected-pill":             place33SelectedPill,
        "34-selected-diamond":          place34SelectedDiamond,
        // v64: ett connection-handtag + vald utgångssida + tydliga badges
        "35-fromside-and-badges":       place35FromSideAndBadges,
        "36-all-base-shapes":           place36AllBaseShapes,
        "37-skill-flow-files":          place37SkillFlowFiles,
    ]

    // MARK: - Builders
    // (place01TightHorizontal ligger i UITestScenarios+FormReview.swift — R5-ratchet)

    private static func place02TightVertical(_ model: CanvasModel, _ c: CGPoint) {
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: c.x, y: c.y - 120))
        let b = ShapeNode(type: .rectangle, position: CGPoint(x: c.x, y: c.y + 120))
        model.shapes.append(contentsOf: [a, b])
        model.addEdge(from: a.id, to: b.id)
    }

    private static func place03Diagonal(_ model: CanvasModel, _ c: CGPoint) {
        let a = ShapeNode(type: .circle, position: CGPoint(x: c.x - 110, y: c.y - 110))
        let b = ShapeNode(type: .circle, position: CGPoint(x: c.x + 110, y: c.y + 110))
        model.shapes.append(contentsOf: [a, b])
        model.addEdge(from: a.id, to: b.id)
    }

    private static func place04VeryClose(_ model: CanvasModel, _ c: CGPoint) {
        let a = ShapeNode(type: .circle, position: CGPoint(x: c.x - 30, y: c.y))
        let b = ShapeNode(type: .circle, position: CGPoint(x: c.x + 30, y: c.y))
        model.shapes.append(contentsOf: [a, b])
        model.addEdge(from: a.id, to: b.id)
    }

    private static func place05Arrowhead8(_ model: CanvasModel, _ c: CGPoint) {
        let hub = ShapeNode(type: .rectangle, position: c)
        model.shapes.append(hub)
        let r: CGFloat = 180
        for i in 0..<8 {
            let angle = CGFloat(i) * .pi / 4
            let pos = CGPoint(x: c.x + cos(angle) * r, y: c.y + sin(angle) * r)
            let n = ShapeNode(type: .circle, position: pos, label: "\(i)")
            model.shapes.append(n)
            model.addEdge(from: hub.id, to: n.id)
        }
    }

    private static func place06ArrowheadDiamond(_ model: CanvasModel, _ c: CGPoint) {
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: c.x - 140, y: c.y))
        let b = ShapeNode(type: .diamond, position: CGPoint(x: c.x + 140, y: c.y))
        model.shapes.append(contentsOf: [a, b])
        model.addEdge(from: a.id, to: b.id)
    }

    private static func place07ArrowheadPill(_ model: CanvasModel, _ c: CGPoint) {
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: c.x - 140, y: c.y))
        let b = ShapeNode(type: .pill, position: CGPoint(x: c.x + 140, y: c.y), label: "Pill")
        model.shapes.append(contentsOf: [a, b])
        model.addEdge(from: a.id, to: b.id)
    }

    private static func place08ArrowEachShape(_ model: CanvasModel, _ c: CGPoint) {
        let hub = ShapeNode(type: .circle, position: c, label: "hub")
        model.shapes.append(hub)
        let types: [ShapeType] = [.rectangle, .diamond, .pill, .square,
                                  .processArrow, .table, .link, .container]
        let r: CGFloat = 220
        for (i, t) in types.enumerated() {
            let angle = CGFloat(i) * 2 * .pi / CGFloat(types.count)
            let pos = CGPoint(x: c.x + cos(angle) * r, y: c.y + sin(angle) * r)
            let n = ShapeNode(type: t, position: pos, label: t.rawValue)
            model.shapes.append(n)
            model.addEdge(from: hub.id, to: n.id)
        }
    }

    private static func place09ProcessArrowSource(_ model: CanvasModel, _ c: CGPoint) {
        let a = ShapeNode(type: .processArrow, position: CGPoint(x: c.x - 150, y: c.y), label: "Steg")
        let b = ShapeNode(type: .circle, position: CGPoint(x: c.x + 150, y: c.y))
        model.shapes.append(contentsOf: [a, b])
        model.addEdge(from: a.id, to: b.id)
    }

    private static func place10ContainerTarget(_ model: CanvasModel, _ c: CGPoint) {
        let extern = ShapeNode(type: .circle, position: CGPoint(x: c.x - 250, y: c.y))
        var box = ShapeNode(type: .container,
                            position: CGPoint(x: c.x + 100, y: c.y),
                            label: "Grupp",
                            sizeMultiplier: 1.5)
        box.widthMultiplier = 1.8
        box.heightMultiplier = 1.4
        model.shapes.append(contentsOf: [extern, box])
        model.addEdge(from: extern.id, to: box.id)
    }

    private static func place11CollapsedSingle(_ model: CanvasModel, _ c: CGPoint) {
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: c.x - 120, y: c.y))
        let b = ShapeNode(type: .circle, position: CGPoint(x: c.x + 120, y: c.y))
        model.shapes.append(contentsOf: [a, b])
        model.addEdge(from: a.id, to: b.id)
        model.selectedShapeId = a.id
        model.toggleCollapse(id: a.id)
    }

    private static func place12CollapsedChain(_ model: CanvasModel, _ c: CGPoint) {
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: c.x - 200, y: c.y), label: "A")
        let b = ShapeNode(type: .rectangle, position: CGPoint(x: c.x,       y: c.y), label: "B")
        let d = ShapeNode(type: .rectangle, position: CGPoint(x: c.x + 200, y: c.y), label: "C")
        model.shapes.append(contentsOf: [a, b, d])
        model.addEdge(from: a.id, to: b.id)
        model.addEdge(from: b.id, to: d.id)
        model.selectedShapeId = b.id
        model.toggleCollapse(id: b.id)
    }

    private static func place13MinusBadge(_ model: CanvasModel, _ c: CGPoint) {
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: c.x - 120, y: c.y))
        let b = ShapeNode(type: .circle, position: CGPoint(x: c.x + 120, y: c.y))
        model.shapes.append(contentsOf: [a, b])
        model.addEdge(from: a.id, to: b.id)
        model.selectedShapeId = a.id
    }

    private static func place14BidirLabel(_ model: CanvasModel, _ c: CGPoint) {
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: c.x - 140, y: c.y), label: "A")
        let b = ShapeNode(type: .rectangle, position: CGPoint(x: c.x + 140, y: c.y), label: "B")
        model.shapes.append(contentsOf: [a, b])
        model.addEdge(from: a.id, to: b.id, direction: .bidirectional)
        if let edge = model.edges.last {
            model.setEdgeLabel(id: edge.id, label: "kallar")
        }
    }

    private static func place15DashedEdge(_ model: CanvasModel, _ c: CGPoint) {
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: c.x - 140, y: c.y))
        let b = ShapeNode(type: .circle, position: CGPoint(x: c.x + 140, y: c.y))
        model.shapes.append(contentsOf: [a, b])
        model.addEdge(from: a.id, to: b.id)
        if let edge = model.edges.last {
            model.setEdgeStyle(id: edge.id, .dashed)
        }
    }

    private static func place16BackwardEdge(_ model: CanvasModel, _ c: CGPoint) {
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: c.x - 140, y: c.y), label: "A")
        let b = ShapeNode(type: .rectangle, position: CGPoint(x: c.x + 140, y: c.y), label: "B")
        model.shapes.append(contentsOf: [a, b])
        model.addEdge(from: a.id, to: b.id, direction: .backward)
    }

    private static func place17ContainerThreeChildren(_ model: CanvasModel, _ c: CGPoint) {
        var box = ShapeNode(type: .container, position: c, label: "Grupp")
        box.widthMultiplier = 2.4
        box.heightMultiplier = 1.6
        let containerId = box.id
        let child1 = ShapeNode(type: .circle,
                               position: CGPoint(x: c.x - 130, y: c.y),
                               childOfContainerId: containerId)
        let child2 = ShapeNode(type: .circle,
                               position: c,
                               childOfContainerId: containerId)
        let child3 = ShapeNode(type: .circle,
                               position: CGPoint(x: c.x + 130, y: c.y),
                               childOfContainerId: containerId)
        // OBS: container ska ligga FÖRST i z-ordning (under barnen)
        model.shapes.append(box)
        model.shapes.append(contentsOf: [child1, child2, child3])
        model.addEdge(from: child1.id, to: child2.id)
        model.addEdge(from: child2.id, to: child3.id)
    }

    private static func place18NestedContainers(_ model: CanvasModel, _ c: CGPoint) {
        var outer = ShapeNode(type: .container, position: c, label: "Yttre")
        outer.widthMultiplier = 3.0
        outer.heightMultiplier = 2.2
        var inner = ShapeNode(type: .container,
                              position: CGPoint(x: c.x + 60, y: c.y),
                              label: "Inre",
                              childOfContainerId: outer.id)
        inner.widthMultiplier = 1.6
        inner.heightMultiplier = 1.2
        let innerId = inner.id
        let cir1 = ShapeNode(type: .circle,
                             position: CGPoint(x: c.x + 30, y: c.y),
                             childOfContainerId: innerId)
        let cir2 = ShapeNode(type: .circle,
                             position: CGPoint(x: c.x + 110, y: c.y),
                             childOfContainerId: innerId)
        model.shapes.append(contentsOf: [outer, inner, cir1, cir2])
    }

    private static func place19ChildOutsideContainer(_ model: CanvasModel, _ c: CGPoint) {
        var box = ShapeNode(type: .container, position: c, label: "Grupp")
        box.widthMultiplier = 1.6
        box.heightMultiplier = 1.2
        let containerId = box.id
        // Cirkeln har container-relation men sitter LÅNGT utanför.
        let stranded = ShapeNode(type: .circle,
                                 position: CGPoint(x: c.x + 500, y: c.y + 200),
                                 label: "frikopplad",
                                 childOfContainerId: containerId)
        model.shapes.append(contentsOf: [box, stranded])
    }

    private static func place20MultiSelect3(_ model: CanvasModel, _ c: CGPoint) {
        let a = ShapeNode(type: .circle, position: CGPoint(x: c.x - 150, y: c.y))
        let b = ShapeNode(type: .circle, position: c)
        let d = ShapeNode(type: .circle, position: CGPoint(x: c.x + 150, y: c.y))
        model.shapes.append(contentsOf: [a, b, d])
        model.multiSelection = [a.id, b.id, d.id]
        model.moveSelection(by: CGSize(width: 50, height: 50))
    }

    private static func place21MultiSelectEdges(_ model: CanvasModel, _ c: CGPoint) {
        let a = ShapeNode(type: .circle, position: CGPoint(x: c.x - 150, y: c.y))
        let b = ShapeNode(type: .circle, position: c)
        let d = ShapeNode(type: .circle, position: CGPoint(x: c.x + 150, y: c.y))
        model.shapes.append(contentsOf: [a, b, d])
        model.addEdge(from: a.id, to: b.id)
        model.addEdge(from: b.id, to: d.id)
        model.multiSelection = [a.id, b.id, d.id]
        model.moveSelection(by: CGSize(width: 50, height: 0))
    }

    private static func place22EdgeAfterResize(_ model: CanvasModel, _ c: CGPoint) {
        var a = ShapeNode(type: .rectangle, position: CGPoint(x: c.x - 150, y: c.y))
        a.widthMultiplier = 2.0
        a.heightMultiplier = 1.5
        let b = ShapeNode(type: .rectangle, position: CGPoint(x: c.x + 150, y: c.y))
        model.shapes.append(contentsOf: [a, b])
        model.addEdge(from: a.id, to: b.id)
    }

    private static func place23EdgeLabelCurved(_ model: CanvasModel, _ c: CGPoint) {
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: c.x - 220, y: c.y))
        let obstacle = ShapeNode(type: .rectangle, position: c, label: "obstakel")
        let b = ShapeNode(type: .rectangle, position: CGPoint(x: c.x + 220, y: c.y))
        model.shapes.append(contentsOf: [a, obstacle, b])
        model.addEdge(from: a.id, to: b.id)
        if let edge = model.edges.last {
            model.setEdgeLabel(id: edge.id, label: "förbi")
        }
    }

    // MARK: - v50.3 nya scenarier för exploratorisk verifiering

    private static func place29ContainerWithLabel(_ model: CanvasModel, _ c: CGPoint) {
        var box = ShapeNode(type: .container, position: c, label: "Grupp")
        box.widthMultiplier = 2.0
        box.heightMultiplier = 1.5
        let containerId = box.id
        let child1 = ShapeNode(type: .circle,
                               position: CGPoint(x: c.x - 80, y: c.y),
                               childOfContainerId: containerId)
        let child2 = ShapeNode(type: .circle,
                               position: CGPoint(x: c.x + 80, y: c.y),
                               childOfContainerId: containerId)
        model.shapes.append(contentsOf: [box, child1, child2])
    }

    private static func place30MarkerModeActive(_ model: CanvasModel, _ c: CGPoint) {
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: c.x - 100, y: c.y - 80))
        let b = ShapeNode(type: .circle,    position: CGPoint(x: c.x + 100, y: c.y - 80))
        let d = ShapeNode(type: .diamond,   position: CGPoint(x: c.x,        y: c.y + 80))
        model.shapes.append(contentsOf: [a, b, d])
        // Simulera att marker-mode är på + att alla tre är markerade
        model.toggleMarkerMode()
        model.multiSelection = [a.id, b.id, d.id]
    }

    private static func place31ProcessArrowIsolated(_ model: CanvasModel, _ c: CGPoint) {
        let a = ShapeNode(type: .processArrow, position: c, label: "Steg 1")
        model.shapes.append(a)
    }

    private static func place32Arrowheads8DirsClean(_ model: CanvasModel, _ c: CGPoint) {
        let hub = ShapeNode(type: .circle, position: c, label: "hub")
        model.shapes.append(hub)
        let r: CGFloat = 200
        for i in 0..<8 {
            let angle = CGFloat(i) * .pi / 4
            let pos = CGPoint(x: c.x + cos(angle) * r, y: c.y + sin(angle) * r)
            let n = ShapeNode(type: .circle, position: pos)
            model.shapes.append(n)
            model.addEdge(from: hub.id, to: n.id)
        }
    }

    private static func place33SelectedPill(_ model: CanvasModel, _ c: CGPoint) {
        let p = ShapeNode(type: .pill, position: c, label: "Pill")
        model.shapes.append(p)
        model.selectedShapeId = p.id
    }

    private static func place34SelectedDiamond(_ model: CanvasModel, _ c: CGPoint) {
        let d = ShapeNode(type: .diamond, position: c, label: "Beslut")
        model.shapes.append(d)
        model.selectedShapeId = d.id
    }

    /// v64: A är markerad (ETT connection-handtag ska synas), pilen A→B går ut
    /// från A:s BOTTEN (fromSide), och C har både prompt och anteckning (badges).
    private static func place35FromSideAndBadges(_ model: CanvasModel, _ c: CGPoint) {
        let a = ShapeNode(type: .rectangle, position: CGPoint(x: c.x - 150, y: c.y - 80), label: "A")
        let b = ShapeNode(type: .rectangle, position: CGPoint(x: c.x + 150, y: c.y - 80), label: "B")
        var cShape = ShapeNode(type: .rectangle, position: CGPoint(x: c.x, y: c.y + 140), label: "C")
        cShape.note = "En anteckning"
        cShape.prompt = "En prompt"
        model.shapes.append(contentsOf: [a, b, cShape])
        model.addEdge(from: a.id, to: b.id)
        if let edge = model.edges.last {
            model.setEdgeFromSide(id: edge.id, side: .bottom)
        }
        model.selectedShapeId = a.id
    }
}
