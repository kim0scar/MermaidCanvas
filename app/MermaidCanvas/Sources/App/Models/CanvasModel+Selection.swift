// Selection + multi-select + resize — utbruten ur CanvasModel (MA spår A steg 14–18). @Published-fasaden ligger kvar i CanvasModel.swift → rerender oförändrad. Beteende verbatim.
import Foundation
import SwiftUI

extension CanvasModel {
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
}
