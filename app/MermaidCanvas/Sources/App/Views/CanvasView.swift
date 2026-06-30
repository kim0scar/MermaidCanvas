import SwiftUI
import CoreTransferable

// ShapeGeometry flyttad till Sources/App/Models/ShapeGeometry.swift (MA spår A steg 1).

/// v25: aktiv connection-drag (rubber band från shape till finger-position).
struct ConnectionDrag: Equatable {
    let fromShapeId: UUID
    var currentCanvasLocation: CGPoint
}

struct CanvasView: View {
    @ObservedObject var model: CanvasModel
    /// v34: synkroniserad spegel av UIScrollView's pan/zoom (chip-drop läser synkront).
    @ObservedObject var viewportState: CanvasViewportState
    var onShapeEdgeTap: (UUID) -> Void
    var onShapeEdit: (UUID) -> Void
    var onShapeDelete: (UUID) -> Void
    var onEdgeDelete: (UUID) -> Void
    var onShapeSelect: (UUID) -> Void
    var onShapeDuplicate: (UUID) -> Void
    var onShapeShowNote: (UUID) -> Void
    /// v63: snabbläsning (badges på formen)
    var onShapeQuickRead: (UUID) -> Void
    var onTableEdit: (UUID) -> Void
    /// v66: kopiera container som skill-mermaid till urklipp
    var onCopySkill: (UUID) -> Void = { _ in }
    var onSaveSkillFile: (UUID) -> Void = { _ in }
    /// V79-svep: spara container-innehåll som mermaid + lås + lager.
    var onSaveContainerMermaid: (UUID) -> Void = { _ in }
    var onShapeToggleLock: (UUID) -> Void = { _ in }
    var onShapeSetZLayer: (UUID, Int) -> Void = { _, _ in }
    var onShapeEnterSubprocess: (UUID) -> Void = { _ in }   // v1.0+ Visio
    /// v67: öppna läs-lappar — ligger PÅ canvasen (canvas-space), panorerar med tavlan.
    @Binding var openCards: [UUID]

    /// v25: rapporterar zoom-procent uppåt till toolbar
    @Binding var zoomPercent: Int
    /// v25: trigger för Reset-zoom från toolbar (incrementeras → onChange → reset)
    var resetZoomTrigger: Int
    /// v61: ägs nu av ContentView — så fil-öppning kan centrera vyn på innehållet
    /// (Claude-ritade filer kan ligga var som helst på 3000×3000-canvasen).
    /// Jump-links sätter den också (handleShapeSelect).
    @Binding var centerOnPoint: CGPoint?

    // internal (ej private): selectionLayer i CanvasView+Selection.swift läser/skriver dem.
    @State var zoomScale: CGFloat = 1.0
    @State var connectionDrag: ConnectionDrag? = nil

    var body: some View {
        ZoomableCanvas(
            contentSize: model.contentSize,
            zoomPercent: $zoomPercent,
            zoomScale: $zoomScale,
            viewportState: viewportState,
            resetTrigger: resetZoomTrigger,
            centerOnPoint: $centerOnPoint
        ) {
            canvasContent
                .frame(width: model.contentSize.width,
                       height: model.contentSize.height,
                       alignment: .topLeading)
                .background(
                    // v46: tap-deselect. 1.5.4 (Bug 1): dubbeltryck-toggle av markeringsläge borttaget — nås bara via knappen.
                    Color.white
                        .contentShape(Rectangle())
                        .onTapGesture {
                            model.deselect()
                            if model.isEdgeMode { model.cancelEdgeMode() }
                        }
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.primary.opacity(0.18), lineWidth: 1)
                        .allowsHitTesting(false)
                )
                .coordinateSpace(name: "canvas")
                // v51.0: FAST vitt ritbräde → tvinga light scheme på canvas-subträdet så
                // .primary (kanter/pilar/text) syns mörkt i dark mode. Toolbar utanför = adaptiv.
                .environment(\.colorScheme, .light)
        }
        .ignoresSafeArea()
        .accessibilityIdentifier("canvas")
    }

    // updateAutoScroll(at:) + handleShapeSelect(id:) → CanvasView+Helpers.swift (MA spår A steg 6b).

    // MARK: - Canvas-content

    private var canvasContent: some View {
        ZStack(alignment: .topLeading) {
            // v34: vit pappersyta. v66: lågt zIndex — containrar (-1) över papper/rutnät,
            // men under pilarna (0) och noderna (1).
            Color.white
                .frame(width: model.contentSize.width,
                       height: model.contentSize.height)
                .allowsHitTesting(false)
                .zIndex(-3)

            DotGridBackground()
                .frame(width: model.contentSize.width,
                       height: model.contentSize.height)
                .allowsHitTesting(false)
                .zIndex(-2)

            if model.specType == .ui {
                iPhoneFrameOverlay(canvasContentSize: model.contentSize)
                    .frame(width: model.contentSize.width,
                           height: model.contentSize.height)
            }

            let hiddenForEdges = model.hiddenShapeIds
            EdgesView(edges: $model.edges,
                      shapes: model.shapes,
                      canvasScale: zoomScale,
                      hiddenShapeIds: hiddenForEdges,
                      collapsedEdgeIds: model.collapsedEdgeIds,
                      selectedShapeId: model.selectedShapeId,
                      onEdgeDelete: onEdgeDelete,
                      onEdgeSetDirection: { id, dir in model.setEdgeDirection(id: id, direction: dir) },
                      onEdgeSetStyle: { id, s in model.setEdgeStyle(id: id, s) },
                      onEdgeSetLineShape: { id, ls in model.setEdgeLineShape(id: id, ls) },
                      onEdgeSetColor: { id, hex in model.setEdgeColor(id: id, hex: hex) },
                      onEdgeSetFromSide: { id, side in model.setEdgeFromSide(id: id, side: side) },
                      onEdgeSetToSide: { id, side in model.setEdgeToSide(id: id, side: side) },
                      onEdgeSnapshot: { _ in model.snapshotForUndo() },
                      onEdgeRename: { id, label, placement in
                          model.setEdgeLabel(id: id, label: label, placement: placement) },
                      onToggleCollapseEdge: { id in model.toggleCollapseEdge(id) })
                .frame(width: model.contentSize.width,
                       height: model.contentSize.height)
                // v66: pilarna ligger ÖVER containrar (zIndex -1) men UNDER noder (1)
                .zIndex(0)

            // Rubber-band-linje under aktiv connection-drag
            if let drag = connectionDrag,
               let fromShape = model.shapes.first(where: { $0.id == drag.fromShapeId }) {
                ConnectionRubberBand(from: fromShape.position,
                                     to: drag.currentCanvasLocation)
                    .allowsHitTesting(false)
            }

            let hidden = model.hiddenShapeIds
            ForEach($model.shapes) { $shape in
                if !hidden.contains(shape.id) {
                    ShapeView(
                        shape: $shape,
                        edgeMode: model.isEdgeMode,
                        markerMode: model.markerMode,
                        canvasScale: zoomScale,
                        isPendingFrom: model.pendingEdgeFrom == shape.id,
                        onEdgeTap: { onShapeEdgeTap(shape.id) },
                        onSelect: { handleShapeSelect(id: shape.id) },
                        onEdit: { onShapeEdit(shape.id) },
                        onDelete: { onShapeDelete(shape.id) },
                        onDuplicate: { onShapeDuplicate(shape.id) },
                        onShowNote: { onShapeShowNote(shape.id) },
                        onQuickRead: { onShapeQuickRead(shape.id) },
                        onTableEdit: { _ in onTableEdit(shape.id) },
                        onDragUpdate: { updateAutoScroll(at: $0) },
                        onMoveMultiSelection: { delta in
                            model.moveSelection(by: delta)
                        },
                        isInMultiSelection: model.multiSelection.contains(shape.id),
                        onContainerMove: { delta in
                            // v44/steg 9: container + phoneFrame drar inneliggande former
                            if shape.type.actsAsContainer {
                                model.moveContainerChildren(containerId: shape.id, by: delta)
                            }
                        },
                        onDragEnded: { id in
                            // v47/v60: efter drag — en container/phoneFrame "adopterar" former
                            // inom sig, en vanlig form tilldelas sin ägare.
                            if shape.type.actsAsContainer {
                                model.claimChildren(forContainer: id)
                            } else {
                                model.assignContainerForShape(id)
                            }
                        },
                        onCopySkill: { id in onCopySkill(id) },
                        onSaveSkillFile: { id in onSaveSkillFile(id) },
                        onSaveContainerMermaid: { id in onSaveContainerMermaid(id) },
                        onToggleLock: { id in onShapeToggleLock(id) },
                        onSetZLayer: { id, z in onShapeSetZLayer(id, z) },
                        onEnterSubprocess: { id in onShapeEnterSubprocess(id) },
                        isSelected: model.selectedShapeId == shape.id,
                        onBeginTextEdit: { _ in model.snapshotForUndo(); model.isEditingText = true },
                        onEndTextEdit: { model.isEditingText = false }
                    )
                    // zIndex-band: container -1,3..-0,7 < pilar 0 < former 0,7..1,3 < kollaps-badge 4.
                    .zIndex((shape.type == .container ? -1.0 : 1.0) + Double(shape.zLayer) * 0.3)
                }
            }

            // 1.3: kollaps-badges i EGET lager ÖVER former (zIndex 4) — minus-badgen doldes annars (Kims fynd).
            EdgeCollapseBadgesLayer(edges: model.edges, shapes: model.shapes, canvasScale: zoomScale,
                                    hiddenShapeIds: hidden, collapsedEdgeIds: model.collapsedEdgeIds,
                                    selectedShapeId: model.selectedShapeId,
                                    onToggleCollapseEdge: { id in model.toggleCollapseEdge(id) })
                .frame(width: model.contentSize.width, height: model.contentSize.height, alignment: .topLeading)
                .zIndex(4)

            // v67: läs-LAPPAR i canvas-space — panorerar/zoomar med tavlan (Kims fynd 2).
            NoteCardsLayer(model: model, openCards: $openCards)
                .frame(width: model.contentSize.width, height: model.contentSize.height, alignment: .topLeading)
                .zIndex(5)

            // V79-svep: markerings-/handtags-lagret → CanvasView+Selection.swift (R5-ratchet).
            selectionLayer
        }
    }
}

// MARK: - ConnectionRubberBand

// ConnectionRubberBand + ConnectionHandles → Views/Canvas/ConnectionOverlay.swift (MA spår A steg 2).

// MARK: - EdgesView

// EdgesView + midpoint-handtag + kant-geometri/ritning → Views/Canvas/{EdgesView,EdgeMidpointHandle,EdgeGeometry,EdgeDrawing}.swift (MA spår A steg 6).
