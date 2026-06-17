// Platform + form-paketer + bulk replace — utbruten ur CanvasModel (MA spår A steg 14–18). @Published-fasaden ligger kvar i CanvasModel.swift → rerender oförändrad. Beteende verbatim.
import Foundation
import SwiftUI

extension CanvasModel {
    /// v34: no-op. Canvas är fast 4000×4000; ingen dynamisk expansion behövs eftersom
    /// UIScrollView hanterar all panorering symmetriskt och Kim valde fast storlek.
    func expandCanvasIfNeeded(near point: CGPoint, margin: CGFloat = 100, expandBy: CGFloat = 600) {
        // intentionally no-op
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

    func setSpecType(_ new: SpecType) {
        guard new != specType else { return }
        snapshotForUndo()
        specType = new
    }

    // MARK: - Bulk replace (vid fil-öppning)

    func replaceAll(shapes: [ShapeNode],
                    edges: [EdgeConnection],
                    title: String = "",
                    specType: SpecType = .general,
                    platform: Platform? = nil,
                    activeShapePacks: Set<ShapePack>? = nil,
                    collapsedEdgeIds: Set<UUID> = [],
                    legend: [String: String] = [:]) {
        self.shapes = shapes
        self.edges = edges
        self.canvasTitle = title
        self.legend = legend
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
        self.collapsedEdgeIds = collapsedEdgeIds
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
        collapsedEdgeIds.removeAll()
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
