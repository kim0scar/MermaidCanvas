import SwiftUI
import UIKit

/// Canvas-vyn för ContentView (utbruten ur ContentView.swift för R5-ratchet, steg H).
/// Bara CanvasView-konfigurationen + dess callbacks — exakt samma beteende.
extension ContentView {
    var canvasView: some View {
        CanvasView(
            model: model,
            viewportState: viewportState,
            onShapeEdgeTap: { id in _ = model.handleEdgeTap(on: id) },
            onShapeEdit: { id in editingShapeId = id },
            onShapeDelete: { id in model.deleteShape(id: id) },
            onEdgeDelete: { id in model.deleteEdge(id: id) },
            onShapeSelect: { id in model.selectShape(id) },
            onShapeDuplicate: { id in model.duplicateShape(id: id) },
            onShapeShowNote: { id in notingShapeId = id },
            onShapeQuickRead: { id in
                // v66: toggla lappen — flera kan vara öppna samtidigt
                if openCards.contains(id) {
                    openCards.removeAll { $0 == id }
                } else {
                    openCards.append(id)
                }
            },
            onTableEdit: { id in tableEditingShapeId = id },
            // v66: kopiera container + barn + memory-noder som skill-mermaid
            onCopySkill: { id in
                UIPasteboard.general.string = MermaidGenerator.generateForContainer(
                    containerId: id,
                    shapes: model.shapes,
                    edges: model.edges,
                    legend: model.legend)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            },
            // v70: spara containern (= en skill) som EGEN canvas-fil i iCloud,
            // bredvid pipeline-filen. Kim stannar kvar i helheten.
            onSaveSkillFile: { id in
                guard let container = model.shapes.first(where: { $0.id == id }) else { return }
                // v73: utan riktigt namn → fråga Kim först (annars blir filen "skill.md")
                let name = container.label.trimmingCharacters(in: .whitespaces)
                if name.isEmpty || name == "Grupp" {
                    skillNameInput = ""
                    skillNameContainerId = id
                } else {
                    performSaveSkillFile(containerId: id, name: name)
                }
            },
            // V79-svep: spara container-innehåll som ren mermaid + lås + lager
            onSaveContainerMermaid: { id in saveContainerMermaid(containerId: id) },
            onShapeToggleLock: { id in
                if let s = model.shapes.first(where: { $0.id == id }) {
                    model.setLocked(id: id, !s.locked)
                }
            },
            onShapeSetZLayer: { id, z in model.setZLayer(id: id, z) },
            openCards: $openCards,
            zoomPercent: $zoomPercent,
            resetZoomTrigger: resetZoomTrigger,
            centerOnPoint: $centerOnPoint
        )
        // v67: läs-lappar ritas nu PÅ canvasen (canvas-space) inuti CanvasView —
        // de panorerar med tavlan i stället för att sitta fast på skärmen (Kims fynd 2).
    }
}
