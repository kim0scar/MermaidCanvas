// Form-mutationer — utbruten ur CanvasModel (MA spår A steg 14–18). @Published-fasaden ligger kvar i CanvasModel.swift → rerender oförändrad. Beteende verbatim.
import Foundation
import SwiftUI

extension CanvasModel {
    /// v50.7 UX-004: nya former hamnade pixel-exakt på samma punkt → osynlig hög.
    /// Om en form redan ligger nära `position`, förskjut den nya i en kaskad
    /// (nedåt-höger) tills platsen är fri. Deterministiskt, ingen extra state.
    func cascadedPosition(near position: CGPoint) -> CGPoint {
        // v73: 28pt-steget var mindre än formerna (120×80) — högen bara gled isär lite.
        // 96pt diagonalt ger fri yta vertikalt (96 > basHöjd 80).
        let step: CGFloat = 96
        let threshold: CGFloat = 64
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
        // v73: containrar kaskadas inte — de ska landa i mitten och adoptera.
        let position = type == .container ? position : cascadedPosition(near: position)
        let cat = specType.defaultCategory
        // v23: tom label från start — Kim vill skriva själv
        // v44: container får default-label "Grupp" (Kim vet då vad formen är)
        let defaultLabel = type == .container ? "Grupp" : ""
        let node = ShapeNode(type: type, position: position, label: defaultLabel, category: cat)
        shapes.append(node)
        if type != .container { assignContainerForShape(node.id) }   // v60: in i container vid skapande
        else { claimChildren(forContainer: node.id) }                 // v73: adoptera direkt — inget inkonsekvent mellanläge
        expandCanvasIfNeeded(near: position)
    }

    /// v29: lägg form med en explicit kategori (används av form-pack-chips).
    func addShape(_ type: ShapeType, at position: CGPoint, category: ShapeCategory) {
        snapshotForUndo()
        // v73: containrar kaskadas inte (Skill-chipet ska wrappa mitten, inte fly fältet).
        let position = type == .container ? position : cascadedPosition(near: position)
        let node = ShapeNode(type: type, position: position, label: "", category: category)
        shapes.append(node)
        if type != .container { assignContainerForShape(node.id) }   // v60
        else { claimChildren(forContainer: node.id) }                 // v73
        expandCanvasIfNeeded(near: position)
    }

    /// v68: lägg en form med förvald label (Mallar-menyn — t.ex. iPhone-modellnamn).
    func addShape(_ type: ShapeType, at position: CGPoint, label: String) {
        snapshotForUndo()
        // v73: containrar/ramar kaskadas inte.
        let position = type == .container || type == .phoneFrame
            ? position : cascadedPosition(near: position)
        let cat = specType.defaultCategory
        let node = ShapeNode(type: type, position: position, label: label, category: cat)
        shapes.append(node)
        if type != .container { assignContainerForShape(node.id) }
        else { claimChildren(forContainer: node.id) }                 // v73
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
        collapsedEdgeIds.removeAll()
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
                     prompt: String = "",
                     skillNumber: Int? = nil) {
        guard let index = shapes.firstIndex(where: { $0.id == id }) else { return }
        snapshotForUndo()
        shapes[index].label = label
        shapes[index].showLabel = showLabel
        shapes[index].note = note
        shapes[index].textStyle = textStyle
        shapes[index].textAlignment = textAlignment
        shapes[index].hasBullets = hasBullets
        shapes[index].prompt = prompt   // v60
        // v74: skill-nummer skrivs bara på containrar — andra former rörs inte.
        if shapes[index].type == .container {
            shapes[index].skillNumber = skillNumber
        }
    }

    /// v73: byt bara namn (skill-spara-namnfrågan döper containern).
    func renameShape(id: UUID, label: String) {
        guard let i = shapes.firstIndex(where: { $0.id == id }) else { return }
        snapshotForUndo()
        shapes[i].label = label
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
}
