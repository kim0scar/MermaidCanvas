import Foundation
import SwiftUI

enum EdgeCreationMode: Equatable {
    case off
    case directional
    case bidirectional
}

private struct CanvasSnapshot {
    let shapes: [ShapeNode]
    let edges: [EdgeConnection]
    let title: String
    let specType: SpecType
    let platform: Platform
    let activeShapePacks: Set<ShapePack>
}

@MainActor
final class CanvasModel: ObservableObject {
    @Published var shapes: [ShapeNode] = []
    @Published var edges: [EdgeConnection] = []
    @Published var edgeCreationMode: EdgeCreationMode = .off
    @Published var pendingEdgeFrom: UUID? = nil
    @Published var canvasTitle: String = ""
    @Published var canvasSize: CGSize = CGSize(width: 3000, height: 3000)
    @Published var specType: SpecType = .general
    /// v27: Platform = regelstyrt mål (Blank/Godot). Låses per canvas.
    @Published var platform: Platform = .blank
    /// v27: Form-paketer = oberoende av platform, kan toggle:as i farten.
    @Published var activeShapePacks: Set<ShapePack> = [.basic]

    // v23: pan/zoom-state hanteras nu som @State i CanvasView för perf
    // (60Hz @Published triggade hela hierarkin att rerendera)

    // v19: selection-state — bara UI
    @Published var selectedShapeId: UUID? = nil
    @Published var multiSelection: Set<UUID> = []
    @Published var markerMode: Bool = false
    @Published var collapsedIds: Set<UUID> = []

    // v34: canvas är fast 4000×4000 — kvadratisk vit yta. UIScrollView hanterar
    // pan/zoom symmetriskt. Inga dynamiska expansioner (Kim valde fast storlek).
    static let contentSize = CGSize(width: 4000, height: 4000)
    @Published var contentSize: CGSize = CGSize(width: 4000, height: 4000)

    /// v34: no-op. Canvas är fast 4000×4000; ingen dynamisk expansion behövs eftersom
    /// UIScrollView hanterar all panorering symmetriskt och Kim valde fast storlek.
    func expandCanvasIfNeeded(near point: CGPoint, margin: CGFloat = 100, expandBy: CGFloat = 600) {
        // intentionally no-op
    }

    private var undoStack: [CanvasSnapshot] = []
    private let undoLimit = 30

    var isEdgeMode: Bool { edgeCreationMode != .off }
    var canUndo: Bool { !undoStack.isEmpty }

    /// Noder som ska döljas pga någon av deras "föräldrar" är kollapsad.
    /// BFS från varje collapsed-nod via edges; collapsed noden själv visas alltid.
    var hiddenShapeIds: Set<UUID> {
        var hidden: Set<UUID> = []
        for cid in collapsedIds {
            var queue: [UUID] = []
            // Direct neighbors via edges (where collapsed is the source)
            for e in edges {
                if e.from == cid { queue.append(e.to) }
            }
            var visited: Set<UUID> = [cid]
            while let cur = queue.first {
                queue.removeFirst()
                if visited.contains(cur) { continue }
                visited.insert(cur)
                hidden.insert(cur)
                for e in edges where e.from == cur {
                    if !visited.contains(e.to) { queue.append(e.to) }
                }
            }
        }
        return hidden
    }

    /// Räkna outgoing edges för en form — används för att avgöra om collapse-badge ska visas.
    func hasOutgoingEdges(id: UUID) -> Bool {
        edges.contains { $0.from == id }
    }

    /// v42: returnerar genomsnittlig riktning från shape till alla utgående kant-targets.
    /// nil om inga utgående kanter. Används för att placera collapse-badge vid kant-startpunkten.
    func averageOutgoingDirection(from shapeId: UUID) -> CGVector? {
        guard let from = shapes.first(where: { $0.id == shapeId }) else { return nil }
        let outgoing = edges.filter { $0.from == shapeId }
        guard !outgoing.isEmpty else { return nil }
        var sumX: CGFloat = 0
        var sumY: CGFloat = 0
        for edge in outgoing {
            guard let to = shapes.first(where: { $0.id == edge.to }) else { continue }
            let dx = to.position.x - from.position.x
            let dy = to.position.y - from.position.y
            let len = sqrt(dx*dx + dy*dy)
            guard len > 0.001 else { continue }
            sumX += dx / len
            sumY += dy / len
        }
        let norm = sqrt(sumX*sumX + sumY*sumY)
        guard norm > 0.001 else { return nil }
        return CGVector(dx: sumX / norm, dy: sumY / norm)
    }

    // MARK: - Snapshot för undo

    private func snapshotForUndo() {
        let snap = CanvasSnapshot(
            shapes: shapes,
            edges: edges,
            title: canvasTitle,
            specType: specType,
            platform: platform,
            activeShapePacks: activeShapePacks
        )
        undoStack.append(snap)
        if undoStack.count > undoLimit { undoStack.removeFirst() }
    }

    func undo() {
        guard let last = undoStack.popLast() else { return }
        shapes = last.shapes
        edges = last.edges
        canvasTitle = last.title
        specType = last.specType
        platform = last.platform
        activeShapePacks = last.activeShapePacks
        pendingEdgeFrom = nil
        edgeCreationMode = .off
    }

    // MARK: - v27 Platform + form-paketer

    /// Sätt platform vid skapande av ny canvas. Synkar specType för bakåtkomp.
    func setPlatform(_ new: Platform) {
        guard new != platform else { return }
        snapshotForUndo()
        platform = new
        specType = new.legacySpecType
    }

    /// Toggle form-paket. Basic kan inte stängas av.
    func toggleShapePack(_ pack: ShapePack) {
        guard pack != .basic else { return }
        snapshotForUndo()
        if activeShapePacks.contains(pack) {
            activeShapePacks.remove(pack)
        } else {
            activeShapePacks.insert(pack)
        }
    }

    /// Alla kategorier tillgängliga för formgivning baserat på aktiva paketer.
    var availableCategories: [ShapeCategory] {
        var cats: [ShapeCategory] = []
        // Godot-platform: visa Godot-kategorier oavsett packs
        if platform == .godot {
            cats.append(contentsOf: [.godot_scene, .godot_control, .godot_container,
                                      .godot_panel, .godot_button, .godot_label,
                                      .godot_signal, .godot_script])
        }
        for pack in ShapePack.allCases where activeShapePacks.contains(pack) {
            cats.append(contentsOf: pack.categories)
        }
        if !cats.contains(.note) { cats.append(.note) }
        return cats
    }

    // MARK: - Mutationer

    /// v50.7 UX-004: nya former hamnade pixel-exakt på samma punkt → osynlig hög.
    /// Om en form redan ligger nära `position`, förskjut den nya i en kaskad
    /// (nedåt-höger) tills platsen är fri. Deterministiskt, ingen extra state.
    private func cascadedPosition(near position: CGPoint) -> CGPoint {
        let step: CGFloat = 28
        let threshold: CGFloat = 20
        var p = position
        var guardCount = 0
        while shapes.contains(where: { abs($0.position.x - p.x) < threshold && abs($0.position.y - p.y) < threshold }),
              guardCount < 40 {
            p.x += step
            p.y += step
            guardCount += 1
        }
        return p
    }

    func addShape(_ type: ShapeType, at position: CGPoint) {
        snapshotForUndo()
        let position = cascadedPosition(near: position)
        let cat = specType.defaultCategory
        // v23: tom label från start — Kim vill skriva själv
        // v44: container får default-label "Grupp" (Kim vet då vad formen är)
        let defaultLabel = type == .container ? "Grupp" : ""
        let node = ShapeNode(type: type, position: position, label: defaultLabel, category: cat)
        shapes.append(node)
        if type != .container { assignContainerForShape(node.id) }   // v60: in i container vid skapande
        expandCanvasIfNeeded(near: position)
    }

    /// v29: lägg form med en explicit kategori (används av form-pack-chips).
    func addShape(_ type: ShapeType, at position: CGPoint, category: ShapeCategory) {
        snapshotForUndo()
        let position = cascadedPosition(near: position)
        let node = ShapeNode(type: type, position: position, label: "", category: category)
        shapes.append(node)
        if type != .container { assignContainerForShape(node.id) }   // v60
        expandCanvasIfNeeded(near: position)
    }

    /// v31: lös linje eller pil — endpoint sätts 60pt åt höger om center som default.
    /// `withArrow=true` ger en lös pil med pilhuvud, false ger ett vanligt streck.
    func addFreeLine(at position: CGPoint, withArrow: Bool) {
        snapshotForUndo()
        let position = cascadedPosition(near: position)
        let cat = specType.defaultCategory
        let node = ShapeNode(
            type: withArrow ? .arrow : .line,
            position: position,
            label: "",
            showLabel: false,
            category: cat,
            lineEnd: CGPoint(x: 60, y: 0)
        )
        shapes.append(node)
        assignContainerForShape(node.id)   // v60: lös linje/pil in i container vid skapande
        expandCanvasIfNeeded(near: position)
    }

    /// Lägg en tabell-form (3×3) på canvas-mitten.
    func addTable(at position: CGPoint, rows: Int = 3, cols: Int = 3) {
        snapshotForUndo()
        let position = cascadedPosition(near: position)
        let node = ShapeNode(
            type: .table,
            position: position,
            label: "",
            sizeMultiplier: 1.5,
            category: specType.defaultCategory,
            tableRows: rows,
            tableCols: cols
        )
        shapes.append(node)
        assignContainerForShape(node.id)   // v60
        expandCanvasIfNeeded(near: position)
    }

    /// Lägg ett par jump-länkar med samma nummer.
    func addJumpLinkPair(near position: CGPoint) {
        snapshotForUndo()
        let usedNumbers = Set(shapes.compactMap { $0.linkNumber })
        var next = 1
        while usedNumbers.contains(next) { next += 1 }
        let a = ShapeNode(type: .link,
                          position: CGPoint(x: position.x - 80, y: position.y),
                          label: "",
                          sizeMultiplier: 0.55,   // v40: halverad storlek
                          category: .note,
                          linkNumber: next)
        let b = ShapeNode(type: .link,
                          position: CGPoint(x: position.x + 80, y: position.y),
                          label: "",
                          sizeMultiplier: 0.55,   // v40: halverad storlek
                          category: .note,
                          linkNumber: next)
        shapes.append(a)
        shapes.append(b)
        expandCanvasIfNeeded(near: a.position)
        expandCanvasIfNeeded(near: b.position)
    }

    /// Ny tom canvas (kallas efter spara-prompt).
    func clearCanvas() {
        snapshotForUndo()
        shapes.removeAll()
        edges.removeAll()
        selectedShapeId = nil
        multiSelection.removeAll()
        collapsedIds.removeAll()
        canvasTitle = ""
    }

    /// Duplicera en form med offset (+24, +24).
    @discardableResult
    func duplicateShape(id: UUID) -> UUID? {
        guard let o = shapes.first(where: { $0.id == id }) else { return nil }
        snapshotForUndo()
        // v46: kopiera ALLA fält så resize, line-endpoints, tabell-celler,
        // numrering och indrag inte tappas vid duplicering.
        let copy = ShapeNode(
            type: o.type,
            position: CGPoint(x: o.position.x + 24, y: o.position.y + 24),
            label: o.label,
            showLabel: o.showLabel,
            sizeMultiplier: o.sizeMultiplier,
            widthMultiplier: o.widthMultiplier,
            heightMultiplier: o.heightMultiplier,
            note: o.note,
            prompt: o.prompt,   // v60
            category: o.category,
            rotation: o.rotation,
            colorOverride: o.colorOverride,
            strokeColorOverride: o.strokeColorOverride,   // v62
            linkNumber: nil, // jump-link ska INTE dupliceras (skulle bli orphan-länk)
            tableRows: o.tableRows,
            tableCols: o.tableCols,
            tableCells: o.tableCells,
            textStyle: o.textStyle,
            colorPackId: o.colorPackId,
            lineEnd: o.lineEnd,
            textAlignment: o.textAlignment,
            hasBullets: o.hasBullets,
            hasNumberedList: o.hasNumberedList,
            indentLevel: o.indentLevel,
            childOfContainerId: o.childOfContainerId   // v47: kopiera container-koppling
        )
        shapes.append(copy)
        return copy.id
    }

    /// Beräkna alla noder som "hänger ihop" från en startnod (BFS via edges).
    /// Används vid kollaps.
    func descendantsFromBranch(startId: UUID, throughEdge edgeId: UUID) -> Set<UUID> {
        guard let edge = edges.first(where: { $0.id == edgeId }) else { return [] }
        let firstTarget = edge.from == startId ? edge.to : edge.from
        var visited: Set<UUID> = [startId]
        var queue: [UUID] = [firstTarget]
        var result: Set<UUID> = []
        while let cur = queue.first {
            queue.removeFirst()
            if visited.contains(cur) { continue }
            visited.insert(cur)
            result.insert(cur)
            for e in edges {
                if e.from == cur && !visited.contains(e.to) { queue.append(e.to) }
                if e.to == cur && !visited.contains(e.from) { queue.append(e.from) }
            }
        }
        return result
    }

    /// Toggle kollaps/expand för en form. Om expanderad: alla connected hide:as.
    func toggleCollapse(id: UUID) {
        snapshotForUndo()
        if collapsedIds.contains(id) {
            collapsedIds.remove(id)
        } else {
            collapsedIds.insert(id)
        }
    }

    /// Hitta partner-länken (samma linkNumber, annan id).
    func partnerLink(for id: UUID) -> ShapeNode? {
        guard let me = shapes.first(where: { $0.id == id }),
              let num = me.linkNumber else { return nil }
        return shapes.first { $0.id != id && $0.linkNumber == num && $0.type == .link }
    }

    func updatePosition(id: UUID, to position: CGPoint) {
        guard let index = shapes.firstIndex(where: { $0.id == id }) else { return }
        snapshotForUndo()
        shapes[index].position = position
        expandCanvasIfNeeded(near: position)
    }

    func updateShape(id: UUID,
                     label: String,
                     showLabel: Bool,
                     note: String,
                     textStyle: TextStyle,
                     textAlignment: TextAlignMode = .center,
                     hasBullets: Bool = false,
                     prompt: String = "") {
        guard let index = shapes.firstIndex(where: { $0.id == id }) else { return }
        snapshotForUndo()
        shapes[index].label = label
        shapes[index].showLabel = showLabel
        shapes[index].note = note
        shapes[index].textStyle = textStyle
        shapes[index].textAlignment = textAlignment
        shapes[index].hasBullets = hasBullets
        shapes[index].prompt = prompt   // v60
    }

    /// v41: uppdatera tabell-form med nytt innehåll (från TableEditorSheet).
    func updateTableShape(id: UUID, label: String, rows: Int, cols: Int, cells: [[String]]) {
        guard let i = shapes.firstIndex(where: { $0.id == id }) else { return }
        snapshotForUndo()
        shapes[i].label = label
        shapes[i].tableRows = rows
        shapes[i].tableCols = cols
        shapes[i].tableCells = cells
    }

    func deleteShape(id: UUID) {
        snapshotForUndo()
        edges.removeAll { $0.from == id || $0.to == id }
        shapes.removeAll { $0.id == id }
        if pendingEdgeFrom == id { pendingEdgeFrom = nil }
    }

    func deleteEdge(id: UUID) {
        snapshotForUndo()
        edges.removeAll { $0.id == id }
    }

    func selectShape(_ id: UUID) {
        if markerMode {
            // v40: markeringsläge — toggla formen i multiSelection
            if multiSelection.contains(id) {
                multiSelection.remove(id)
            } else {
                multiSelection.insert(id)
            }
        } else {
            selectedShapeId = id
            multiSelection.removeAll()
        }
    }

    /// v40: Flytta alla markerade former med ett delta (px i canvas-koordinater).
    /// v46: Om en container är med i selectionen följer dess barn med automatiskt,
    /// så hela grupperingen flyttas som en enhet.
    func moveSelection(by delta: CGSize) {
        guard !multiSelection.isEmpty else { return }
        // Beräkna alla shape-ids som ska flyttas: markeringen + barn till markerade containrar
        var idsToMove: Set<UUID> = multiSelection
        for shape in shapes where shape.type == .container && multiSelection.contains(shape.id) {
            for child in shapesInside(container: shape) {
                idsToMove.insert(child.id)
            }
        }
        for i in shapes.indices {
            if idsToMove.contains(shapes[i].id) {
                shapes[i].position.x += delta.width
                shapes[i].position.y += delta.height
            }
        }
    }

    /// v47: returnerar former som är barn till en container.
    /// **Explicit-först:** former vars `childOfContainerId` matchar räknas alltid med,
    /// oavsett position. Detta är robust mot att container drar barnen utanför sina
    /// bounds under flytt.
    /// **Fallback:** för bakåtkompatibilitet med v46-och-äldre data där fältet saknas
    /// (nil-värde), räknas också former vars position ligger innanför containerns
    /// bounds OCH som inte tillhör någon annan container.
    func shapesInside(container: ShapeNode) -> [ShapeNode] {
        let w = ShapeGeometry.width(for: container)
        let h = ShapeGeometry.height(for: container)
        let rect = CGRect(x: container.position.x - w/2,
                          y: container.position.y - h/2,
                          width: w, height: h)
        return shapes.filter { s in
            guard s.id != container.id, s.type != .container else { return false }
            // Explicit-först
            if let explicitParent = s.childOfContainerId {
                return explicitParent == container.id
            }
            // Fallback: position innanför + ingen annan explicit förälder
            return rect.contains(s.position)
        }
    }

    /// v47: detektera vilken container en form ska tillhöra baserat på sin position.
    /// Anropas typiskt efter att en form har flyttats (drag-end). Sätter eller tömmer
    /// `childOfContainerId` automatiskt. Vid överlappande containrar väljs den
    /// **senast tillagda** (visuellt på toppen i z-ordning).
    func assignContainerForShape(_ shapeId: UUID) {
        guard let shapeIdx = shapes.firstIndex(where: { $0.id == shapeId }) else { return }
        let shape = shapes[shapeIdx]
        // Containrar är inte själva barn av andra containrar.
        guard shape.type != .container else { return }
        let pos = shape.position
        // Iterera baklänges för att välja toppen vid överlapp.
        var newParent: UUID? = nil
        for cs in shapes.reversed() where cs.type == .container {
            let w = ShapeGeometry.width(for: cs)
            let h = ShapeGeometry.height(for: cs)
            let r = CGRect(x: cs.position.x - w/2,
                           y: cs.position.y - h/2,
                           width: w, height: h)
            if r.contains(pos) {
                newParent = cs.id
                break
            }
        }
        if shapes[shapeIdx].childOfContainerId != newParent {
            shapes[shapeIdx].childOfContainerId = newParent
        }
    }

    /// v60: container "adopterar" alla icke-container-former vars position ligger inom
    /// dess bounds → sätter childOfContainerId. Kallas vid container-drag-slut, så att
    /// dra containern ÖVER former gör dem till barn (de följer sedan med vid flytt).
    func claimChildren(forContainer containerId: UUID) {
        guard let container = shapes.first(where: { $0.id == containerId }),
              container.type == .container else { return }
        let w = ShapeGeometry.width(for: container)
        let h = ShapeGeometry.height(for: container)
        let rect = CGRect(x: container.position.x - w / 2,
                          y: container.position.y - h / 2,
                          width: w, height: h)
        for i in shapes.indices {
            guard shapes[i].id != containerId, shapes[i].type != .container else { continue }
            if rect.contains(shapes[i].position) {
                shapes[i].childOfContainerId = containerId
            }
        }
    }

    /// v44: flytta alla former inuti en container med givet delta.
    /// Anropas live under drag av container så inneliggande former följer med.
    func moveContainerChildren(containerId: UUID, by delta: CGSize) {
        guard let container = shapes.first(where: { $0.id == containerId }) else { return }
        let inside = shapesInside(container: container)
        for child in inside {
            if let i = shapes.firstIndex(where: { $0.id == child.id }) {
                shapes[i].position.x += delta.width
                shapes[i].position.y += delta.height
            }
        }
    }

    func deselect() {
        selectedShapeId = nil
        multiSelection.removeAll()
    }

    func toggleMarkerMode() {
        markerMode.toggle()
        if markerMode {
            selectedShapeId = nil
        }
    }

    func setSpecType(_ new: SpecType) {
        guard new != specType else { return }
        snapshotForUndo()
        specType = new
    }

    // MARK: - Edge-mode

    func startEdgeMode(_ mode: EdgeCreationMode) {
        edgeCreationMode = mode
        pendingEdgeFrom = nil
    }

    func cancelEdgeMode() {
        edgeCreationMode = .off
        pendingEdgeFrom = nil
    }

    /// v25: lägg pil direkt från drag-handtag (ej via tap-flow).
    func addEdge(from: UUID, to: UUID, direction: EdgeDirection = .forward) {
        guard from != to else { return }
        // Förhindra dubbletter åt samma håll
        if edges.contains(where: { $0.from == from && $0.to == to }) { return }
        snapshotForUndo()
        edges.append(EdgeConnection(from: from, to: to, direction: direction))
    }

    /// v37: sätt pilriktning (ersätter reverseEdge + setEdgeBidirectional).
    func setEdgeDirection(id: UUID, direction: EdgeDirection) {
        guard let idx = edges.firstIndex(where: { $0.id == id }) else { return }
        guard edges[idx].direction != direction else { return }
        snapshotForUndo()
        edges[idx].direction = direction
    }

    /// v62: egen fyllningsfärg på markerad form (nil = tillbaka till paket/kategori).
    func setFillColor(id: UUID, hex: String?) {
        guard let idx = shapes.firstIndex(where: { $0.id == id }) else { return }
        snapshotForUndo()
        shapes[idx].colorOverride = hex
    }

    /// v62: egen ram-färg på markerad form (nil = tillbaka till paket/kategori).
    func setStrokeColor(id: UUID, hex: String?) {
        guard let idx = shapes.firstIndex(where: { $0.id == id }) else { return }
        snapshotForUndo()
        shapes[idx].strokeColorOverride = hex
    }

    /// v38: sätt kant-etikett (visas bredvid midpoint-handtaget).
    /// v62: även placering (ovanför/under pilen).
    func setEdgeLabel(id: UUID, label: String, placement: EdgeLabelPlacement = .below) {
        guard let idx = edges.firstIndex(where: { $0.id == id }) else { return }
        snapshotForUndo()
        edges[idx].label = label
        edges[idx].labelPlacement = placement
    }

    /// v27: hel eller streckad linje.
    func setEdgeStyle(id: UUID, _ style: EdgeStyle) {
        guard let idx = edges.firstIndex(where: { $0.id == id }) else { return }
        guard edges[idx].style != style else { return }
        snapshotForUndo()
        edges[idx].style = style
    }

    @discardableResult
    func handleEdgeTap(on shapeId: UUID) -> Bool {
        guard edgeCreationMode != .off else { return false }
        if let from = pendingEdgeFrom {
            pendingEdgeFrom = nil
            guard from != shapeId else {
                edgeCreationMode = .off
                return false
            }
            let direction: EdgeDirection = edgeCreationMode == .bidirectional ? .bidirectional : .forward
            snapshotForUndo()
            edges.append(EdgeConnection(from: from, to: shapeId, direction: direction))
            edgeCreationMode = .off
            return true
        }
        pendingEdgeFrom = shapeId
        return false
    }

    // MARK: - v39 Multi-select operationer

    /// Duplicera alla markerade former. Kopiorna placeras 30pt nedåt-höger.
    func duplicateSelection() {
        guard !multiSelection.isEmpty else { return }
        snapshotForUndo()
        var newShapes: [ShapeNode] = []
        for shape in shapes where multiSelection.contains(shape.id) {
            var copy = shape
            // v46: kopiera ALLA fält (tableCells, hasNumberedList, indentLevel
            // saknades tidigare). linkNumber sätts till nil för att undvika orphan-länkar.
            copy = ShapeNode(
                id: UUID(),
                type: shape.type, position: CGPoint(x: shape.position.x + 30, y: shape.position.y + 30),
                label: shape.label, showLabel: shape.showLabel,
                sizeMultiplier: shape.sizeMultiplier, widthMultiplier: shape.widthMultiplier,
                heightMultiplier: shape.heightMultiplier, note: shape.note,
                prompt: shape.prompt,   // v60
                category: shape.category, rotation: shape.rotation,
                colorOverride: shape.colorOverride,
                strokeColorOverride: shape.strokeColorOverride,   // v62
                linkNumber: nil,
                tableRows: shape.tableRows, tableCols: shape.tableCols,
                tableCells: shape.tableCells,
                textStyle: shape.textStyle, colorPackId: shape.colorPackId,
                lineEnd: shape.lineEnd, textAlignment: shape.textAlignment,
                hasBullets: shape.hasBullets,
                hasNumberedList: shape.hasNumberedList,
                indentLevel: shape.indentLevel,
                childOfContainerId: shape.childOfContainerId   // v47
            )
            newShapes.append(copy)
        }
        let newIds = Set(newShapes.map { $0.id })
        shapes.append(contentsOf: newShapes)
        multiSelection = newIds
    }

    /// Ta bort alla markerade former och kanter som pekar på dem.
    func deleteSelection() {
        guard !multiSelection.isEmpty else { return }
        snapshotForUndo()
        shapes.removeAll { multiSelection.contains($0.id) }
        edges.removeAll { multiSelection.contains($0.from) || multiSelection.contains($0.to) }
        multiSelection.removeAll()
    }

    /// Align horisontellt: alla markerade former delar vertikal centrallinje (snäpp till median Y).
    func alignSelectionHorizontally() {
        guard multiSelection.count >= 2 else { return }
        let selected = shapes.filter { multiSelection.contains($0.id) }
        let medianY = selected.map { $0.position.y }.sorted()[selected.count / 2]
        snapshotForUndo()
        for i in shapes.indices where multiSelection.contains(shapes[i].id) {
            shapes[i].position.y = medianY
        }
    }

    /// Align vertikalt: alla markerade former delar horisontell centrallinje (snäpp till median X).
    func alignSelectionVertically() {
        guard multiSelection.count >= 2 else { return }
        let selected = shapes.filter { multiSelection.contains($0.id) }
        let medianX = selected.map { $0.position.x }.sorted()[selected.count / 2]
        snapshotForUndo()
        for i in shapes.indices where multiSelection.contains(shapes[i].id) {
            shapes[i].position.x = medianX
        }
    }

    // MARK: - v43 Proportionerlig resize av markerade former

    /// v43: skalar alla former i multiSelection proportionerligt runt selectionens centrum.
    /// `scale` = 1.0 = ingen ändring. <1 = mindre, >1 = större.
    /// Påverkar både sizeMultiplier OCH position relativt selectionens centrum.
    func resizeSelection(scale: CGFloat) {
        guard multiSelection.count >= 1, scale > 0.01 else { return }
        let selected = shapes.filter { multiSelection.contains($0.id) }
        guard !selected.isEmpty else { return }
        // Selection-centrum = medelvärdet av alla shape-positioner
        let cx = selected.reduce(0.0) { $0 + $1.position.x } / CGFloat(selected.count)
        let cy = selected.reduce(0.0) { $0 + $1.position.y } / CGFloat(selected.count)
        for i in shapes.indices where multiSelection.contains(shapes[i].id) {
            // Skala position relativt centrum
            shapes[i].position.x = cx + (shapes[i].position.x - cx) * scale
            shapes[i].position.y = cy + (shapes[i].position.y - cy) * scale
            // Skala storlek proportionerligt
            shapes[i].sizeMultiplier *= scale
            if let w = shapes[i].widthMultiplier { shapes[i].widthMultiplier = w * scale }
            if let h = shapes[i].heightMultiplier { shapes[i].heightMultiplier = h * scale }
        }
    }

    /// v43: returnerar bounding-box för alla markerade former (inkluderar shape-storlek).
    func selectionBoundingBox() -> CGRect? {
        let selected = shapes.filter { multiSelection.contains($0.id) }
        guard !selected.isEmpty else { return nil }
        var minX: CGFloat = .infinity
        var minY: CGFloat = .infinity
        var maxX: CGFloat = -.infinity
        var maxY: CGFloat = -.infinity
        for s in selected {
            let w = ShapeGeometry.width(for: s)
            let h = ShapeGeometry.height(for: s)
            minX = min(minX, s.position.x - w/2)
            minY = min(minY, s.position.y - h/2)
            maxX = max(maxX, s.position.x + w/2)
            maxY = max(maxY, s.position.y + h/2)
        }
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }

    // MARK: - Bulk replace (vid fil-öppning)

    func replaceAll(shapes: [ShapeNode],
                    edges: [EdgeConnection],
                    title: String = "",
                    specType: SpecType = .general,
                    platform: Platform? = nil,
                    activeShapePacks: Set<ShapePack>? = nil,
                    collapsedIds: Set<UUID> = []) {
        self.shapes = shapes
        self.edges = edges
        self.canvasTitle = title
        self.specType = specType
        // v27: härled platform + packs från fil, eller härled från legacy specType.
        if let p = platform {
            self.platform = p
        } else {
            self.platform = (specType == .godot) ? .godot : .blank
        }
        if let packs = activeShapePacks {
            self.activeShapePacks = packs
        } else {
            // Legacy migration: gamla spec_type → motsvarande pack auto-aktiverat
            var packs: Set<ShapePack> = [.basic]
            if let pack = ShapePack.from(legacySpecType: specType) {
                packs.insert(pack)
            }
            self.activeShapePacks = packs
        }
        self.collapsedIds = collapsedIds
        self.pendingEdgeFrom = nil
        self.edgeCreationMode = .off
        self.selectedShapeId = nil
        self.multiSelection.removeAll()
        self.markerMode = false
        self.undoStack.removeAll()
    }

    /// v27: nollställ till en specifik plattform (vid Ny canvas).
    func clearCanvas(platform: Platform) {
        snapshotForUndo()
        shapes.removeAll()
        edges.removeAll()
        collapsedIds.removeAll()
        canvasTitle = ""
        self.platform = platform
        self.specType = platform.legacySpecType
        self.activeShapePacks = [.basic]
        selectedShapeId = nil
        multiSelection.removeAll()
        pendingEdgeFrom = nil
        edgeCreationMode = .off
    }
}
