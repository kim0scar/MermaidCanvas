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
    /// v34: synkroniserad spegel av UIScrollView's pan/zoom + global frame.
    /// Manuell chip-drop läser detta synkront — ingen race-condition.
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

    @State private var zoomScale: CGFloat = 1.0
    @State private var connectionDrag: ConnectionDrag? = nil

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
                    // v46: tap-to-deselect ligger på själva bakgrunden — så tap på
                    // shape inte triggar parent-simultaneousGesture som rensade selection.
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
                // v51.0: canvasen är ett FAST vitt ritbräde (ColorPack-färger + Mermaid-
                // export är ljusa). Tvinga light color scheme på hela canvas-subträdet så
                // kanter/pilar/etiketter (.primary) blir mörka och syns i iPhone dark mode.
                // Toolbar/menyer ligger utanför detta subträd → förblir adaptiva.
                .environment(\.colorScheme, .light)
        }
        .ignoresSafeArea()
        .accessibilityIdentifier("canvas")
    }

    // updateAutoScroll(at:) + handleShapeSelect(id:) → CanvasView+Helpers.swift (MA spår A steg 6b).

    // MARK: - Canvas-content

    private var canvasContent: some View {
        ZStack(alignment: .topLeading) {
            // v34: vit pappersyta
            // v66: explicit lågt zIndex — containrar (-1) ska ligga ÖVER
            // papper/rutnät men UNDER pilarna (0) och noderna (1).
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
                      onEdgeSetColor: { id, hex in model.setEdgeColor(id: id, hex: hex) },
                      onEdgeSetFromSide: { id, side in model.setEdgeFromSide(id: id, side: side) },
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
                        onDragUpdate: { canvasPoint in
                            updateAutoScroll(at: canvasPoint)
                        },
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
                        onSaveSkillFile: { id in onSaveSkillFile(id) }
                    )
                    // v60 D: containrar ritas UNDER övriga former (barn fångar då inte
                    // containerns tap → namnbyte funkar; barn ligger visuellt ovanpå).
                    // v66: container får NEGATIVT zIndex → hamnar även UNDER pilarna
                    // (EdgesView zIndex 0) — Kims fynd: containern åt pilar/etiketter.
                    .zIndex(shape.type == .container ? -1 : 1)
                }
            }

            // v67: läs-LAPPAR ligger PÅ canvasen (canvas-space) — de panorerar och
            // zoomar med tavlan och försvinner ur vy när Kim panorerar bort, i stället
            // för att sitta fast på skärmen och täcka saker (Kims fynd 2).
            NoteCardsLayer(model: model,
                           openCards: $openCards,
                           onEdit: { id in onShapeEdit(id) })
                .frame(width: model.contentSize.width,
                       height: model.contentSize.height,
                       alignment: .topLeading)
                .zIndex(5)

            // v50.5 v4 F10: multi-selection-ram följer formens egen geometri
            // (samma som SelectionHandles enkelmarkering). Tidigare alltid
            // Rectangle() → bbox runt circle/diamond/pill.
            ForEach(model.shapes.filter { model.multiSelection.contains($0.id) }) { s in
                SelectionOutline(
                    shapeType: s.type,
                    width: ShapeGeometry.width(for: s),
                    height: ShapeGeometry.height(for: s),
                    strokeWidth: 2 / zoomScale,
                    canvasScale: zoomScale
                )
                .rotationEffect(.degrees(s.rotation))
                .position(s.position)
                .allowsHitTesting(false)
            }

            // Connection-handtag + selection-handtag på vald form
            if model.multiSelection.isEmpty,
               let selectedId = model.selectedShapeId,
               let idx = model.shapes.firstIndex(where: { $0.id == selectedId }),
               model.shapes[idx].type == .line || model.shapes[idx].type == .arrow {
                // v66: linjer/pilar får ETT ändpunkts-handtag i stället för
                // resize-handtagen (bbox-skalning kunde aldrig förlänga strecket).
                // zIndex 3: över formerna (1) — annars äter linjens bbox gesten.
                LineEndpointHandle(shape: $model.shapes[idx], canvasScale: zoomScale)
                    .zIndex(3)
            } else if model.multiSelection.isEmpty,
               let selectedId = model.selectedShapeId,
               let idx = model.shapes.firstIndex(where: { $0.id == selectedId }) {
                let s = model.shapes[idx]
                // v50.7 UX-005: mjuk markerings-outline direkt vid tap (samma
                // streckade ram som multi-select). Tidigare syntes markeringen
                // först när man började dra — oklart vad som var valt.
                SelectionOutline(
                    shapeType: s.type,
                    width: ShapeGeometry.width(for: s),
                    height: ShapeGeometry.height(for: s),
                    strokeWidth: 2 / zoomScale,
                    canvasScale: zoomScale
                )
                .rotationEffect(.degrees(s.rotation))
                .position(s.position)
                .allowsHitTesting(false)
                SelectionHandles(
                    shape: $model.shapes[idx],
                    canvasScale: zoomScale
                )
                // v66: handtagen över formerna (zIndex 1) — annars kan en
                // grannforms bbox äta handtags-gesten.
                .zIndex(3)
                // v44: ConnectionHandle är ALLTID synlig på vald form — ett enskilt
                // handtag i högerkanten. Drag från det skapar en pil.
                ConnectionHandles(
                    shape: s,
                    canvasScale: zoomScale,
                    onDragChanged: { canvasPoint in
                        connectionDrag = ConnectionDrag(fromShapeId: s.id,
                                                       currentCanvasLocation: canvasPoint)
                    },
                    onDragEnded: { canvasPoint in
                        if let target = ShapeGeometry.hitTest(canvasPoint,
                                                              shapes: model.shapes,
                                                              excludingId: s.id) {
                            model.addEdge(from: s.id, to: target.id)
                            // v49 Fel #3 (Agent B 2/3-konsensus): säkerställ
                            // att from-shape är markerad efter pil skapats —
                            // annars syns inte minus-badgen vid kantens start.
                            model.selectedShapeId = s.id
                        }
                        connectionDrag = nil
                    }
                )
                .zIndex(3)
            }

            // v44: MarkerOverlay alltid synlig i markerMode — löser låsning vid
            // mid-drag selection-change (MarkerOverlay byttes ut mot Color.clear
            // när multiSelection blev non-empty, vilket dödade pågående drag).
            if model.markerMode {
                MarkerOverlay(model: model, canvasContentSize: model.contentSize)
            }

            // v43: Samlat resize-handtag när flera former är markerade.
            // Krav >= 2: en enskilt vald form har redan sina egna SelectionHandles.
            if model.multiSelection.count >= 2 {
                MultiSelectResizeHandle(model: model, canvasScale: zoomScale)
            }
        }
    }
}

// MARK: - ConnectionRubberBand

// ConnectionRubberBand + ConnectionHandles → Views/Canvas/ConnectionOverlay.swift (MA spår A steg 2).

// MARK: - EdgesView

// EdgesView + midpoint-handtag + kant-geometri/ritning → Views/Canvas/{EdgesView,EdgeMidpointHandle,EdgeGeometry,EdgeDrawing}.swift (MA spår A steg 6).
