import SwiftUI

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
            onShapeShowNote: { id in
                // 1.3 S1.2: anteckning = EN väg — öppna NoteCard på canvasen (ej NoteMiniSheet).
                if !openCards.contains(id) { openCards.append(id) }
            },
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
                Clipboard.copy(MermaidGenerator.generateForContainer(
                    containerId: id,
                    shapes: model.shapes,
                    edges: model.edges,
                    legend: model.legend))
                Haptics.success()
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
            onShapeEnterSubprocess: { id in model.enterSubprocess(id) },   // v1.0+ Visio
            openCards: $openCards,
            zoomPercent: $zoomPercent,
            resetZoomTrigger: resetZoomTrigger,
            centerOnPoint: $centerOnPoint
        )
        // v67: läs-lappar ritas nu PÅ canvasen (canvas-space) inuti CanvasView —
        // de panorerar med tavlan i stället för att sitta fast på skärmen (Kims fynd 2).
        // V79-svep: alltid-synlig snabbknapp (nere höger) som centrerar vyn på innehållet —
        // Kims "snabb knapp vid sidan för navigering" på den stora canvasen.
        .overlay(alignment: .bottomTrailing) {
            if !model.shapes.isEmpty {
                Button { centerOnPoint = contentCenter(of: model.shapes) } label: {
                    Image(systemName: "scope")
                        .font(.title3).foregroundStyle(Color.primary)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(.ultraThinMaterial))
                        .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 0.5))
                }
                .padding(.trailing, 16).padding(.bottom, 30)
                .accessibilityIdentifier("canvas.recenter")
                .accessibilityLabel("Centrera på innehållet")
            }
        }
        // v1.0+ Visio: brödsmule-bar överst när man är nere i ett underflöde.
        .overlay(alignment: .top) {
            if model.isDrilledIn { DrillBreadcrumbBar(model: model) }
        }
        // Vid varje nivåbyte (hoppa in/ut): centrera vyn på den nya nivåns innehåll.
        .onChange(of: model.drillStack.count) { _, _ in
            centerOnPoint = model.shapes.isEmpty
                ? CGPoint(x: model.canvasSize.width / 2, y: model.canvasSize.height / 2)
                : contentCenter(of: model.shapes)
        }
    }
}
