import SwiftUI

/// Markerings- + handtags-lagret för CanvasView (utbrutet ur CanvasView.swift för
/// R5-ratchet, V79-svep). Multi-select-ramar, enkel-markeringens resize/rotate/
/// connection-handtag, marker-overlay och multi-resize. Beteende verbatim.
extension CanvasView {
    @ViewBuilder
    var selectionLayer: some View {
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
            // V79-svep: låst form visar markering men INGA resize/rotate-handtag.
            if !s.locked {
                SelectionHandles(
                    shape: $model.shapes[idx],
                    canvasScale: zoomScale
                )
                // v66: handtagen över formerna (zIndex 1) — annars kan en
                // grannforms bbox äta handtags-gesten.
                .zIndex(3)
            }
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
