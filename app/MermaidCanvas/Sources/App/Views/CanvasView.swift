import SwiftUI
import CoreTransferable

enum ShapeGeometry {
    static let baseWidth: CGFloat = 120
    static let baseHeight: CGFloat = 80

    /// v35.1/v36: typ-specifika basbredder/-höjder.
    static func typeBaseWidth(for type: ShapeType) -> CGFloat {
        switch type {
        case .pill:         return 130   // v50.5 (v2): smalare så proportionen matchar pill-chipet och rectangeln bredvid
        case .square:       return 80    // liksidig kvadrat
        case .processArrow: return 110   // kompakt pil (spets 40% av bredden)
        case .container:    return 280   // v44: grupperande container ska rymma flera former
        case .octagon:      return 80    // v51.1: symmetrisk åttahörning
        default:            return baseWidth
        }
    }
    static func typeBaseHeight(for type: ShapeType) -> CGFloat {
        switch type {
        case .square:    return 80    // liksidig kvadrat
        case .container: return 200   // v44: container — högre default-höjd
        case .octagon:   return 80    // v51.1: symmetrisk åttahörning
        default:         return baseHeight
        }
    }

    static func width(for shape: ShapeNode) -> CGFloat {
        typeBaseWidth(for: shape.type) * shape.effectiveWidth
    }
    static func height(for shape: ShapeNode) -> CGFloat {
        typeBaseHeight(for: shape.type) * shape.effectiveHeight
    }
    static func halfWidth(for shape: ShapeNode) -> CGFloat { width(for: shape) / 2 }
    static func halfHeight(for shape: ShapeNode) -> CGFloat { height(for: shape) / 2 }
    static func circleRadius(for shape: ShapeNode) -> CGFloat {
        min(width(for: shape), height(for: shape)) / 2
    }

    /// Hitta vilken form (om någon) som ligger under en canvas-punkt.
    static func hitTest(_ point: CGPoint, shapes: [ShapeNode], excludingId: UUID? = nil) -> ShapeNode? {
        for shape in shapes.reversed() {
            if let exc = excludingId, shape.id == exc { continue }
            let hw = halfWidth(for: shape)
            let hh = halfHeight(for: shape)
            if point.x >= shape.position.x - hw && point.x <= shape.position.x + hw &&
               point.y >= shape.position.y - hh && point.y <= shape.position.y + hh {
                return shape
            }
        }
        return nil
    }
}

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
    var onTableEdit: (UUID) -> Void

    /// v25: rapporterar zoom-procent uppåt till toolbar
    @Binding var zoomPercent: Int
    /// v25: trigger för Reset-zoom från toolbar (incrementeras → onChange → reset)
    var resetZoomTrigger: Int

    @State private var zoomScale: CGFloat = 1.0
    @State private var centerOnPoint: CGPoint? = nil
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

    /// v39: Auto-scroll när form dras nära viewport-kant. canvasPoint=nil = avsluta scroll.
    private func updateAutoScroll(at canvasPoint: CGPoint?) {
        guard let point = canvasPoint else {
            viewportState.autoScrollVelocity = .zero
            return
        }
        // Beräkna synlig viewport i canvas-koordinater
        let scale = viewportState.zoomScale
        guard scale > 0.001 else { return }
        let visLeft   = viewportState.contentOffset.width / scale
        let visTop    = viewportState.contentOffset.height / scale
        let visRight  = visLeft + viewportState.globalFrame.width / scale
        let visBottom = visTop  + viewportState.globalFrame.height / scale

        let threshold: CGFloat = 80 / scale   // 80 screen-pt tröskel
        let maxSpeed: CGFloat = 300            // scroll-koordinater/sek

        var vx: CGFloat = 0
        var vy: CGFloat = 0
        if point.x < visLeft + threshold   { vx = -maxSpeed * (1 - (point.x - visLeft) / threshold) }
        if point.x > visRight - threshold  { vx =  maxSpeed * (1 - (visRight - point.x) / threshold) }
        if point.y < visTop + threshold    { vy = -maxSpeed * (1 - (point.y - visTop) / threshold) }
        if point.y > visBottom - threshold { vy =  maxSpeed * (1 - (visBottom - point.y) / threshold) }

        viewportState.autoScrollVelocity = CGSize(width: vx, height: vy)
    }

    private func handleShapeSelect(id: UUID) {
        if let shape = model.shapes.first(where: { $0.id == id }),
           shape.type == .link,
           let partner = model.partnerLink(for: id) {
            // v34: be ZoomableCanvas centrera på partner-positionen
            centerOnPoint = partner.position
        } else {
            // v60.1: när en container väljs — "adoptera" alla former som ligger inom den
            // NU (explicit childOfContainerId). Annars matchas barn som lades till FÖRE
            // containern bara via position-fallback, och de tappas mitt i en flytt när de
            // hinner glida ut ur containerns (statiska) bounds → "följer inte allt med".
            if let shape = model.shapes.first(where: { $0.id == id }),
               shape.type == .container {
                model.claimChildren(forContainer: id)
            }
            onShapeSelect(id)
        }
    }

    // MARK: - Canvas-content

    private var canvasContent: some View {
        ZStack(alignment: .topLeading) {
            // v34: vit pappersyta
            Color.white
                .frame(width: model.contentSize.width,
                       height: model.contentSize.height)
                .allowsHitTesting(false)

            DotGridBackground()
                .frame(width: model.contentSize.width,
                       height: model.contentSize.height)
                .allowsHitTesting(false)

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
                      selectedShapeId: model.selectedShapeId,
                      onEdgeDelete: onEdgeDelete,
                      onEdgeSetDirection: { id, dir in model.setEdgeDirection(id: id, direction: dir) },
                      onEdgeSetStyle: { id, s in model.setEdgeStyle(id: id, s) },
                      onEdgeRename: { id, label in model.setEdgeLabel(id: id, label: label) },
                      onToggleCollapse: { id in model.toggleCollapse(id: id) })
                .frame(width: model.contentSize.width,
                       height: model.contentSize.height)

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
                        onTableEdit: { _ in onTableEdit(shape.id) },
                        onDragUpdate: { canvasPoint in
                            updateAutoScroll(at: canvasPoint)
                        },
                        onMoveMultiSelection: { delta in
                            model.moveSelection(by: delta)
                        },
                        isInMultiSelection: model.multiSelection.contains(shape.id),
                        onContainerMove: { delta in
                            // v44: när en container dras flyttas alla former inuti med
                            if shape.type == .container {
                                model.moveContainerChildren(containerId: shape.id, by: delta)
                            }
                        },
                        onDragEnded: { id in
                            // v47/v60: efter drag — en container "adopterar" former inom sig,
                            // en vanlig form tilldelas sin container.
                            if shape.type == .container {
                                model.claimChildren(forContainer: id)
                            } else {
                                model.assignContainerForShape(id)
                            }
                        }
                    )
                    // v60 D: containrar ritas UNDER övriga former (barn fångar då inte
                    // containerns tap → namnbyte funkar; barn ligger visuellt ovanpå).
                    .zIndex(shape.type == .container ? 0 : 1)
                }
            }

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

struct ConnectionRubberBand: View {
    let from: CGPoint
    let to: CGPoint

    var body: some View {
        ZStack {
            Path { p in
                p.move(to: from)
                p.addLine(to: to)
            }
            .stroke(Color.accentColor.opacity(0.85),
                    style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
            // Mål-prick
            Circle()
                .fill(Color.accentColor)
                .frame(width: 10, height: 10)
                .position(to)
        }
    }
}

// MARK: - ConnectionHandles

/// v50.2 F-3: FYRA connection-handtag (top/höger/botten/vänster) — alltid
/// synliga på vald form. Storlek matchar resize-handles (28pt) och de sitter
/// LITE LÄNGRE UT (gap 10pt) så de inte krockar med formens kant eller med
/// resize/rotation-handtag. Drag från handtag till annan form skapar pil.
struct ConnectionHandles: View {
    let shape: ShapeNode
    let canvasScale: CGFloat
    let onDragChanged: (CGPoint) -> Void
    let onDragEnded: (CGPoint) -> Void

    var body: some View {
        let w = ShapeGeometry.width(for: shape)
        let h = ShapeGeometry.height(for: shape)
        // v50.2 F-3: matcha resize-handles storlek (28pt) — tydligare och
        // mer touch-vänliga.
        let size: CGFloat = max(24, 28 / canvasScale)
        let gap: CGFloat = size / 2 + 10 / canvasScale
        ZStack {
            handle(offset: CGPoint(x:  w/2 + gap, y: 0),    icon: "arrow.right", accId: "connection.handle.right",  size: size)
            handle(offset: CGPoint(x: -w/2 - gap, y: 0),    icon: "arrow.left",  accId: "connection.handle.left",   size: size)
            handle(offset: CGPoint(x: 0, y: -h/2 - gap),    icon: "arrow.up",    accId: "connection.handle.top",    size: size)
            handle(offset: CGPoint(x: 0, y:  h/2 + gap),    icon: "arrow.down",  accId: "connection.handle.bottom", size: size)
        }
        .frame(width: w, height: h)
        .position(shape.position)
        .rotationEffect(.degrees(shape.rotation))
    }

    @ViewBuilder
    private func handle(offset: CGPoint, icon: String, accId: String, size: CGFloat) -> some View {
        ZStack {
            Circle().fill(Color.accentColor)
            Image(systemName: icon)
                .font(.system(size: size * 0.50, weight: .bold))
                .foregroundStyle(Color.white)
        }
        .frame(width: size, height: size)
        .overlay(Circle().stroke(Color.white, lineWidth: max(1.0, 1.5 / canvasScale)))
        .shadow(color: .black.opacity(0.18), radius: 2, y: 1)
        .offset(x: offset.x, y: offset.y)
        .gesture(
            DragGesture(coordinateSpace: .named("canvas"))
                .onChanged { v in onDragChanged(v.location) }
                .onEnded { v in onDragEnded(v.location) }
        )
        .accessibilityIdentifier(accId)
    }
}

// MARK: - ShapeView

struct ShapeView: View {
    @Binding var shape: ShapeNode
    let edgeMode: Bool
    let markerMode: Bool
    let canvasScale: CGFloat
    let isPendingFrom: Bool
    let onEdgeTap: () -> Void
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void
    let onShowNote: () -> Void
    /// v41: öppnar tabell-redigeraren vid dubbelklick på tabell-form.
    var onTableEdit: ((UUID) -> Void)? = nil
    /// v39: rapporterar drag-position (canvas-koord) för auto-scroll. nil = drag avslutad.
    var onDragUpdate: ((CGPoint?) -> Void)? = nil
    /// v40: callback för att flytta ALLA markerade former (multi-select drag).
    var onMoveMultiSelection: ((CGSize) -> Void)? = nil
    /// v40: sann om denna form ingår i multiSelection
    var isInMultiSelection: Bool = false
    /// v44: rapporterar drag-delta för container — så inneliggande former kan flyttas med.
    var onContainerMove: ((CGSize) -> Void)? = nil
    /// v47: rapporterar att en form har slutat dras (efter position-uppdatering).
    /// CanvasModel använder detta för att (om)tilldela `childOfContainerId` baserat på
    /// var formen landade.
    var onDragEnded: ((UUID) -> Void)? = nil

    @State private var dragOffset: CGSize = .zero
    @State private var lastMultiDragTranslation: CGSize? = nil
    @State private var lastContainerDragTranslation: CGSize = .zero
    /// v50.5 F4: egen popover-meny vid long-press — ersätter .contextMenu
    /// som triggade SwiftUI's snapshot-preview (svart blurred flash) innan
    /// menyn visades.
    @State private var showContextMenu: Bool = false

    private var pack: ColorPack { ColorPack.by(id: shape.colorPackId) }
    private var effectiveFill: Color { pack.fillColor }
    private var effectiveStroke: Color {
        pack.id != "none" ? pack.strokeColor : shape.category.strokeColor
    }
    private var effectiveTextColor: Color { pack.textColor }

    /// v39: formatterat label med bullets/numrering + indrag.
    private var formattedLabel: String {
        let indent = String(repeating: "  ", count: max(0, shape.indentLevel))
        let lines = shape.label.split(separator: "\n", omittingEmptySubsequences: false)
        if shape.hasNumberedList {
            return lines.enumerated()
                .map { "\(indent)\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
        } else if shape.hasBullets {
            return lines.map { "\(indent)• \($0)" }.joined(separator: "\n")
        } else if shape.indentLevel > 0 {
            return lines.map { "\(indent)\($0)" }.joined(separator: "\n")
        }
        return shape.label
    }

    private var textAlignment: TextAlignment {
        switch shape.textAlignment {
        case .leading:  return .leading
        case .trailing: return .trailing
        case .center:   return .center
        }
    }

    var body: some View {
        ZStack {
            background
            stroke
            highlight
            // v36: lös linje/pil ritas via FreeLineView (background ger EmptyView)
            if shape.type == .line || shape.type == .arrow {
                FreeLineView(shape: shape, stroke: effectiveStroke)
            }
            // v50.3 R3: Containers label hanteras via separat .overlay nedan
            // (Lucidchart-stil ovanför ramen). Andra former behåller centrerad
            // text inuti ZStack:en.
            if shape.showLabel && shape.type != .container {
                Text(formattedLabel)
                    .font(.system(size: shape.textStyle.fontSize * shape.sizeMultiplier,
                                  weight: shape.textStyle.fontWeight,
                                  design: .rounded))
                    .foregroundStyle(effectiveTextColor)
                    .multilineTextAlignment(textAlignment)
                    .lineLimit(6)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 8)
            }
        }
        .frame(width: ShapeGeometry.width(for: shape),
               height: ShapeGeometry.height(for: shape))
        .rotationEffect(.degrees(shape.rotation))
        .opacity(markerMode && !edgeMode ? 0.6 : 1.0)
        // v60: container-titeln bor nu i header-raden (se background) — ingen flytande tab.
        .overlay(alignment: .topTrailing) {
            if !shape.note.isEmpty && !markerMode {
                NoteBadge(canvasScale: canvasScale, onTap: onShowNote)
                    .offset(x: 8 / canvasScale, y: -8 / canvasScale)
                    .rotationEffect(.degrees(-shape.rotation))
            }
        }
        // v48 Fel #3+#4: CollapseBadge är flyttad från ShapeView till EdgesView
        // (renderas per utgående kant, vid kantens start). Se EdgeCollapseBadges.swift.
        .contentShape(Rectangle())
        .accessibilityIdentifier("shape.\(shape.type.rawValue)")
        .position(
            x: shape.position.x + dragOffset.width,
            y: shape.position.y + dragOffset.height
        )
        // v46: enkel- och dubbeltap i exakt-ordning. SwiftUI fördröjer count:1 om
        // count:2 ligger SENARE i kedjan, så dubbelklick måste ligga FÖRE och
        // enkeltap kvar — annars triggas både select OCH edit vid dubbelklick.
        .onTapGesture(count: 2) {
            if shape.type == .table {
                onTableEdit?(shape.id)
            } else {
                onEdit()
            }
        }
        .onTapGesture(count: 1) {
            if markerMode {
                onSelect()
                return
            }
            if edgeMode {
                onEdgeTap()
            } else {
                onSelect()
            }
        }
        // v44: long-press borttaget — ConnectionHandle ersätter mekanismen.
        // v40: drag aktiverat i markerMode OM formen ingår i multiSelection.
        // Utan mask .none läggs inget gesture-recognizer på (undviker UIScrollView-kollision).
        .gesture(unifiedDragGesture, including: gestureActive ? .all : .none)
        // v50.5 F4: explicit long-press → popover (utan SwiftUI's contextMenu-
        // snapshot-flash). simultaneousGesture så drag-gesten fortfarande
        // fungerar. 0.45s = standard iOS long-press-känsla.
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45)
                .onEnded { _ in
                    // v50.5 (v5) M3: i edge-mode betyder håll-in inget — popa
                    // inte redigera-menyn då (användaren siktar på pil-ände).
                    guard !edgeMode else { return }
                    // v50.5 (v5) F13: haptic feedback (gamla .contextMenu gav
                    // system-haptic gratis — popover gör inte det).
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    showContextMenu = true
                }
        )
        .popover(isPresented: $showContextMenu) {
            ShapeContextMenu(
                noteIsEmpty: shape.note.isEmpty,
                onEdit:      { showContextMenu = false; onEdit() },
                onDuplicate: { showContextMenu = false; onDuplicate() },
                onShowNote:  { showContextMenu = false; onShowNote() },
                onDelete:    { showContextMenu = false; onDelete() }
            )
            .presentationCompactAdaptation(.popover)
        }
    }

    /// Sann när drag-gesten ska vara aktiv: normalt läge, eller markeringsläge med multiSelection.
    private var gestureActive: Bool {
        !edgeMode && (!markerMode || isInMultiSelection)
    }

    /// v40: Enhetlig drag-gest — hanterar normal drag, multi-select drag och inaktivt läge.
    /// v44: rapporterar container-deltan live så inneliggande former följer med under drag.
    private var unifiedDragGesture: some Gesture {
        DragGesture(minimumDistance: isInMultiSelection ? 6 : 10,
                    coordinateSpace: .named("canvas"))
            .onChanged { v in
                if isInMultiSelection {
                    // Multi-select: flytta ALLA markerade former via delta
                    let prev = lastMultiDragTranslation ?? .zero
                    let delta = CGSize(
                        width: v.translation.width - prev.width,
                        height: v.translation.height - prev.height
                    )
                    lastMultiDragTranslation = v.translation
                    onMoveMultiSelection?(delta)
                    onDragUpdate?(v.location)
                } else if !markerMode {
                    // Normal drag: visa visuell offset
                    dragOffset = CGSize(
                        width: v.location.x - v.startLocation.x,
                        height: v.location.y - v.startLocation.y
                    )
                    // v44: container — flytta inneliggande former live med samma delta
                    if shape.type == .container {
                        let delta = CGSize(
                            width: dragOffset.width - lastContainerDragTranslation.width,
                            height: dragOffset.height - lastContainerDragTranslation.height
                        )
                        lastContainerDragTranslation = dragOffset
                        if delta.width != 0 || delta.height != 0 {
                            onContainerMove?(delta)
                        }
                    }
                    onDragUpdate?(v.location)
                }
                // markerMode utan multiSelection: ignorera drag (scrollview tar över)
            }
            .onEnded { v in
                if isInMultiSelection {
                    lastMultiDragTranslation = nil
                    onDragUpdate?(nil)
                } else if !markerMode {
                    shape.position.x += v.translation.width
                    shape.position.y += v.translation.height
                    dragOffset = .zero
                    lastContainerDragTranslation = .zero   // v44: reset för container-tracking
                    onDragUpdate?(nil)
                    // v47: efter position-uppdatering, om-tilldela container-förälder.
                    onDragEnded?(shape.id)
                }
            }
    }

    @ViewBuilder
    private var background: some View {
        switch shape.type {
        case .circle:
            Circle()
                .fill(effectiveFill)
                .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
        case .rectangle:
            RoundedRectangle(cornerRadius: DesignTokens.Shape.cornerRadius(for: .rectangle, height: ShapeGeometry.height(for: shape)), style: .continuous)
                .fill(effectiveFill)
                .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
        case .diamond:
            DiamondShape()
                .fill(effectiveFill)
                .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
        case .pill:
            Capsule(style: .continuous)
                .fill(effectiveFill)
                .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
        case .container:
            // v60: container i Lucidchart-stil — solid header-rad med titel + ljus kropp
            // + tunn solid ram. Titeln bor i headern (ej flytande tab).
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    Text(shape.label.isEmpty ? "Grupp" : formattedLabel)
                        .font(.system(size: 13 * min(shape.sizeMultiplier, 1.4), weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.white)
                        .lineLimit(1)
                        .padding(.horizontal, 10)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 28)
                .background(shape.category.strokeColor)
                Rectangle().fill(effectiveFill.opacity(0.04))
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Shape.cornerRadius(for: .container, height: ShapeGeometry.height(for: shape)), style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.Shape.cornerRadius(for: .container, height: ShapeGeometry.height(for: shape)), style: .continuous)
                    .stroke(shape.category.strokeColor.opacity(0.6), lineWidth: 1.5)
            )
        case .table:
            TableShapeBackground(rows: shape.tableRows ?? 3,
                                 cols: shape.tableCols ?? 3,
                                 cells: shape.tableCells ?? [],
                                 fill: effectiveFill,
                                 stroke: effectiveStroke)
        case .link:
            JumpLinkShapeBackground(number: shape.linkNumber ?? 0)
                .opacity(0.55)   // v40: halvt transparent
        case .square:
            SquareShape()
                .fill(effectiveFill)
                .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
        case .processArrow:
            ProcessArrowShape()
                .fill(effectiveFill)
                .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
        case .octagon:
            OctagonShape()
                .fill(effectiveFill)
                .shadow(color: .black.opacity(0.06), radius: 3, y: 1)
        case .line, .arrow:
            EmptyView()
        }
    }

    @ViewBuilder
    private var stroke: some View {
        switch shape.type {
        case .circle:
            Circle().stroke(effectiveStroke, lineWidth: DesignTokens.Shape.canvasStrokeWidth)
        case .rectangle:
            RoundedRectangle(cornerRadius: DesignTokens.Shape.cornerRadius(for: .rectangle, height: ShapeGeometry.height(for: shape)), style: .continuous).stroke(effectiveStroke, lineWidth: DesignTokens.Shape.canvasStrokeWidth)
        case .diamond:
            DiamondShape().stroke(effectiveStroke, lineWidth: DesignTokens.Shape.canvasStrokeWidth)
        case .pill:
            Capsule(style: .continuous).stroke(effectiveStroke, lineWidth: DesignTokens.Shape.canvasStrokeWidth)
        case .square:
            SquareShape().stroke(effectiveStroke, lineWidth: DesignTokens.Shape.canvasStrokeWidth)
        case .processArrow:
            ProcessArrowShape().stroke(effectiveStroke, lineWidth: DesignTokens.Shape.canvasStrokeWidth)
        case .octagon:
            OctagonShape().stroke(effectiveStroke, lineWidth: DesignTokens.Shape.canvasStrokeWidth)
        case .container:
            // v44: container — streckad ram redan ritad i background
            EmptyView()
        case .table, .link, .line, .arrow:
            EmptyView()
        }
    }

    @ViewBuilder
    private var highlight: some View {
        if isPendingFrom {
            switch shape.type {
            case .circle:
                Circle().stroke(Color.accentColor, lineWidth: 3.5)
            case .rectangle, .table:
                RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.accentColor, lineWidth: 3.5)
            case .diamond:
                DiamondShape().stroke(Color.accentColor, lineWidth: 3.5)
            case .pill:
                Capsule(style: .continuous).stroke(Color.accentColor, lineWidth: 3.5)
            case .square:
                SquareShape().stroke(Color.accentColor, lineWidth: 3.5)
            case .processArrow:
                ProcessArrowShape().stroke(Color.accentColor, lineWidth: 3.5)
            case .octagon:
                OctagonShape().stroke(Color.accentColor, lineWidth: 3.5)
            case .container:
                RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.accentColor, lineWidth: 3.5)
            case .link:
                Circle().stroke(Color.accentColor, lineWidth: 3.5)
            case .line, .arrow:
                EmptyView()
            }
        }
    }
}

// MARK: - Special shape backgrounds

private struct TableShapeBackground: View {
    var rows: Int
    var cols: Int
    var cells: [[String]]
    var fill: Color
    var stroke: Color

    var body: some View {
        GeometryReader { geo in
            // v50.5 (v5) H1/H2: tabell-data redigeras tvåvägs via markdown —
            // ett handredigerat 0 i rows/cols gav `1..<0` Range-krasch + div-by-zero.
            // Klampa till minst 1 här så formen alltid är ritbar.
            let rows = max(1, self.rows)
            let cols = max(1, self.cols)
            let cellW = geo.size.width / CGFloat(cols)
            let cellH = geo.size.height / CGFloat(rows)
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(fill.opacity(0.18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(stroke, lineWidth: 1.5)
                    )
                // Cellinnehåll
                ForEach(0..<rows, id: \.self) { row in
                    ForEach(0..<cols, id: \.self) { col in
                        let text = row < cells.count && col < cells[row].count ? cells[row][col] : ""
                        if !text.isEmpty {
                            Text(text)
                                .font(.system(size: max(8, min(cellH * 0.4, 12))))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .foregroundStyle(stroke)
                                .frame(width: cellW, height: cellH)
                                .position(x: cellW * (CGFloat(col) + 0.5),
                                          y: cellH * (CGFloat(row) + 0.5))
                                .allowsHitTesting(false)
                        }
                    }
                }
                // Gridlinjer
                Path { p in
                    for r in 1..<rows {
                        let y = cellH * CGFloat(r)
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: geo.size.width, y: y))
                    }
                    for c in 1..<cols {
                        let x = cellW * CGFloat(c)
                        p.move(to: CGPoint(x: x, y: 0))
                        p.addLine(to: CGPoint(x: x, y: geo.size.height))
                    }
                }
                .stroke(stroke.opacity(0.5), lineWidth: 1)
            }
        }
    }
}

/// v38: länk-bubbla — alltid accentfärg (tidigare vit-på-vit osynlig).
private struct JumpLinkShapeBackground: View {
    var number: Int

    var body: some View {
        ZStack {
            Circle().fill(Color.accentColor)
            Circle().stroke(Color.white.opacity(0.35), lineWidth: 1.5)
            VStack(spacing: 1) {
                Image(systemName: "link")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                Text("\(number)")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.white)
            }
        }
    }
}

// v42: DiamondShape, SquareShape och ProcessArrowShape är flyttade till
// Sources/App/Views/Shapes/CanvasShapes.swift så att ToolbarView kan rendera
// EXAKT samma former i chip-vyn. Inga duplicerade definitioner längre.

// MARK: - FreeLineView

/// v36: Ritar en lös linje eller pil på canvas.
/// Linjen går från formens centrum (0,0 i view-space) till lineEnd (relativ offset).
/// Används för ShapeType.line och .arrow — dessa renderas INTE av background/stroke.
struct FreeLineView: View {
    let shape: ShapeNode
    let stroke: Color

    var body: some View {
        Canvas { ctx, size in
            guard let end = shape.lineEnd else { return }
            let from = CGPoint(x: size.width / 2, y: size.height / 2)
            // v44: skala lineEnd direkt med effectiveWidth/effectiveHeight så att
            // fri-resize gör linjen längre/bredare även när bounding-boxen sträcks.
            // Tidigare logik (v36.1) hade samma effekt via size.width/2 men föll
            // ibland tillbaka när Canvas-storleken inte uppdaterades synkat.
            let scaledX = end.x * shape.effectiveWidth
            let scaledY = end.y * shape.effectiveHeight
            let to = CGPoint(x: size.width / 2 + scaledX, y: size.height / 2 + scaledY)

            // Linje — 1.5pt matchar EdgesView kant-linjer
            var path = Path()
            path.move(to: from)
            path.addLine(to: to)
            ctx.stroke(path, with: .color(stroke),
                       style: StrokeStyle(lineWidth: 1.5, lineCap: .round))

            // Pilhuvud (endast .arrow)
            if shape.type == .arrow {
                let angle = atan2(scaledY, scaledX)
                let headLen: CGFloat = 12
                let headAngle: CGFloat = .pi / 6   // 30°

                let a1 = CGPoint(
                    x: to.x - headLen * cos(angle - headAngle),
                    y: to.y - headLen * sin(angle - headAngle))
                let a2 = CGPoint(
                    x: to.x - headLen * cos(angle + headAngle),
                    y: to.y - headLen * sin(angle + headAngle))

                var head = Path()
                head.move(to: to)
                head.addLine(to: a1)
                head.move(to: to)
                head.addLine(to: a2)
                ctx.stroke(head, with: .color(stroke),
                           style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            }
        }
        .frame(width: ShapeGeometry.width(for: shape),
               height: ShapeGeometry.height(for: shape))
        .allowsHitTesting(false)
    }
}

// MARK: - EdgesView

struct EdgesView: View {
    @Binding var edges: [EdgeConnection]
    let shapes: [ShapeNode]
    let canvasScale: CGFloat
    let hiddenShapeIds: Set<UUID>
    /// v48: vilken form som är markerad — styr om minus-badges visas.
    let selectedShapeId: UUID?
    var onEdgeDelete: (UUID) -> Void
    var onEdgeSetDirection: (UUID, EdgeDirection) -> Void
    var onEdgeSetStyle: (UUID, EdgeStyle) -> Void
    var onEdgeRename: (UUID, String) -> Void
    /// v48: toggle-callback för collapse-badges. Tar shape-ID.
    var onToggleCollapse: (UUID) -> Void

    // v44: kant-namngivning via EdgeLabelSheet (ersätter v38-alerten).
    @State private var renamingEdgeId: UUID? = nil

    private func isVisible(_ edge: EdgeConnection) -> Bool {
        !hiddenShapeIds.contains(edge.from) && !hiddenShapeIds.contains(edge.to)
    }

    var body: some View {
        ZStack {
            Canvas { context, _ in
                // Normala kanter (båda ändar synliga)
                for edge in edges where isVisible(edge) {
                    guard let fromShape = shapes.first(where: { $0.id == edge.from }),
                          let toShape = shapes.first(where: { $0.id == edge.to })
                    else { continue }
                    drawEdge(context: context, edge: edge, fromShape: fromShape, toShape: toShape)
                }
                // v48 Fel #4: Stub-linjer för kollapsade kanter (from synlig, to gömd).
                // Visar att något är dolt även utan att forma vara markerad.
                for edge in edges where (!hiddenShapeIds.contains(edge.from)
                                         && hiddenShapeIds.contains(edge.to)) {
                    guard let fromShape = shapes.first(where: { $0.id == edge.from }),
                          let toShape   = shapes.first(where: { $0.id == edge.to })
                    else { continue }
                    let from = edgePoint(for: fromShape, towards: toShape.position)
                    let dx = toShape.position.x - fromShape.position.x
                    let dy = toShape.position.y - fromShape.position.y
                    let len = max(hypot(dx, dy), 1)
                    // v50.5 v3 F9: 50pt matchar plus-badge-position nedan.
                    let stubLen: CGFloat = 50
                    let stubEnd = CGPoint(x: from.x + stubLen * dx / len,
                                          y: from.y + stubLen * dy / len)
                    var stub = Path()
                    stub.move(to: from)
                    stub.addLine(to: stubEnd)
                    context.stroke(stub, with: .color(.primary.opacity(0.45)),
                                   style: StrokeStyle(lineWidth: 2, lineCap: .round,
                                                      dash: [4, 3]))
                }
            }
            .allowsHitTesting(false)

            ForEach($edges) { $edge in
                if isVisible(edge),
                   let fromShape = shapes.first(where: { $0.id == edge.from }),
                   let toShape = shapes.first(where: { $0.id == edge.to }) {
                    midpointHandle(edge: $edge, fromShape: fromShape, toShape: toShape)
                }
            }

            // v48 Fel #3+#4: Collapse-badges per kant.
            // Minus: vid utgående kants start, BARA när from är markerad.
            // Plus:  vid stub-änden, ALLTID synlig om to är gömd.
            ForEach(edges) { edge in
                if let fromShape = shapes.first(where: { $0.id == edge.from }),
                   let toShape   = shapes.first(where: { $0.id == edge.to }),
                   !hiddenShapeIds.contains(edge.from) {
                    let toHidden = hiddenShapeIds.contains(edge.to)
                    let isFromSelected = (selectedShapeId == edge.from)
                    let from = edgePoint(for: fromShape, towards: toShape.position)
                    if toHidden {
                        let dx = toShape.position.x - fromShape.position.x
                        let dy = toShape.position.y - fromShape.position.y
                        let len = max(hypot(dx, dy), 1)
                        // v50.5 v3 F9: 50pt (var 30) så plus-badge inte göms
                        // bakom from-shape:s right-arrow connection-handle
                        // när formen är markerad.
                        let stubLen: CGFloat = 50
                        let stubEnd = CGPoint(x: from.x + stubLen * dx / len,
                                              y: from.y + stubLen * dy / len)
                        EdgeStubBadge(position: stubEnd,
                                      canvasScale: canvasScale,
                                      onTap: { onToggleCollapse(edge.from) })
                    } else if isFromSelected {
                        // v50.5 (v2) F5: minus-badgen placeras FRAMÅT på pilen
                        // (in mot to-shape), 30pt från from-edge — INTE
                        // perpendikulärt (perpendikulärt hamnar precis på
                        // hörn-resize-handles eftersom edge-punkten sitter på
                        // shape-kanten där handles också är).
                        // Förra försöket med perpShift=45pt landade nedanför
                        // bottom-right-handle. Genom att flytta badgen IN på
                        // pilen kommer den mellan handle-zonen och midpoint-
                        // handle, tydligt synlig utan kollision.
                        let cdx = toShape.position.x - fromShape.position.x
                        let cdy = toShape.position.y - fromShape.position.y
                        let clen = hypot(cdx, cdy)
                        let badgePos: CGPoint = {
                            guard clen > 0.1 else { return from }
                            // v50.5 (v5) F11: 55pt min, 40% av pil-längd, cap 80pt.
                            // Connection-handle (← ↑ → ↓) i marker-mode sitter
                            // ~30pt utanför shape-kanten. På korta pilar (clen<140)
                            // hamnade 40%-offset (=56pt vid 140pt-pil) precis
                            // utanför handle-zonen — men kortare pilar krockade.
                            // 55pt minimum garanterar luft till handle-cirkeln.
                            let offset = max(55, min(80, clen * 0.40))
                            let dxU = cdx / clen
                            let dyU = cdy / clen
                            return CGPoint(x: from.x + dxU * offset,
                                           y: from.y + dyU * offset)
                        }()
                        EdgeStartCollapseBadge(position: badgePos,
                                               canvasScale: canvasScale,
                                               onTap: { onToggleCollapse(edge.from) })
                    }
                }
            }
        }
        // v44: byt alert mot EdgeLabelSheet — mer rymligt för längre etiketter.
        .sheet(isPresented: Binding(
            get: { renamingEdgeId != nil },
            set: { if !$0 { renamingEdgeId = nil } }
        )) {
            if let id = renamingEdgeId,
               let edge = edges.first(where: { $0.id == id }) {
                EdgeLabelSheet(
                    initial: edge.label,
                    onSave: { newLabel in
                        onEdgeRename(id, newLabel)
                        renamingEdgeId = nil
                    },
                    onCancel: { renamingEdgeId = nil }
                )
            }
        }
    }

    @ViewBuilder
    private func midpointHandle(edge: Binding<EdgeConnection>,
                                fromShape: ShapeNode,
                                toShape: ShapeNode) -> some View {
        let hasWaypoint = !edge.wrappedValue.waypoints.isEmpty
        let direction = edge.wrappedValue.direction
        // v37: ikon speglar aktuell riktning
        let icon: String = {
            switch direction {
            case .forward:       return "arrow.right"
            case .backward:      return "arrow.left"
            case .bidirectional: return "arrow.left.and.right"
            case .none:          return "minus"
            }
        }()
        // v48 Fel #2: positionera mid på den FAKTISKA synliga linjen (mellan
        // edgePoints, inte mellan shape-centra). Beräkna också linjens vinkel
        // så att ikonen kan roteras med linjens fortsättning.
        // v50 F-03: vid bezier-routing runt obstakel måste mid räknas PÅ
        // kurvan, annars hamnar handlen inuti obstaklet.
        let anchors = edgeAnchors(edge: edge.wrappedValue,
                                  fromShape: fromShape,
                                  toShape: toShape)
        let edgeStart = anchors.start
        let edgeEnd   = anchors.end
        let mid: CGPoint = {
            if hasWaypoint { return edge.wrappedValue.waypoints[0].point }
            return anchors.mid
        }()
        let lineAngle: Double = {
            if hasWaypoint {
                let wp = edge.wrappedValue.waypoints[0].point
                return atan2(Double(wp.y - edgeStart.y), Double(wp.x - edgeStart.x))
            }
            return anchors.midAngle
        }()
        let size: CGFloat = max(14, 18 / canvasScale)
        let label = edge.wrappedValue.label
        // Handle
        ZStack {
            Circle()
                .fill(hasWaypoint ? Color.accentColor : Color.white)
                .overlay(Circle().stroke(Color.accentColor,
                                         lineWidth: max(1.0, 1.5 / canvasScale)))
                .frame(width: size, height: size)
            Image(systemName: icon)
                .font(.system(size: size * 0.45, weight: .bold))
                .foregroundStyle(hasWaypoint ? Color.white : Color.accentColor)
                .rotationEffect(.radians(lineAngle)) // v48: roterar med linjen
        }
        .contentShape(Circle().inset(by: -size * 0.5))
        .position(mid)
        .gesture(midpointGesture(edge: edge))
        .contextMenu {
            // v44: redigera text på pilen via EdgeLabelSheet
            Button {
                renamingEdgeId = edge.wrappedValue.id
            } label: {
                Label("Redigera text", systemImage: "textformat")
            }
            Divider()
            // v37: 4 riktningsval
            Button {
                onEdgeSetDirection(edge.wrappedValue.id, .forward)
            } label: {
                Label("→ Pil åt höger", systemImage: "arrow.right")
            }
            Button {
                onEdgeSetDirection(edge.wrappedValue.id, .backward)
            } label: {
                Label("← Pil åt vänster", systemImage: "arrow.left")
            }
            Button {
                onEdgeSetDirection(edge.wrappedValue.id, .bidirectional)
            } label: {
                Label("↔ Båda hållen", systemImage: "arrow.left.arrow.right")
            }
            Button {
                onEdgeSetDirection(edge.wrappedValue.id, .none)
            } label: {
                Label("— Ingen pil", systemImage: "minus")
            }
            Divider()
            // v27: linje-stil
            Button {
                onEdgeSetStyle(edge.wrappedValue.id, .solid)
            } label: {
                Label("Hel linje", systemImage: "minus")
            }
            Button {
                onEdgeSetStyle(edge.wrappedValue.id, .dashed)
            } label: {
                Label("Streckad linje", systemImage: "ellipsis")
            }
            Divider()
            if hasWaypoint {
                Button {
                    edge.wrappedValue.waypoints = []
                } label: {
                    Label("Räta ut pil", systemImage: "minus")
                }
            }
            Button(role: .destructive) {
                onEdgeDelete(edge.wrappedValue.id)
            } label: {
                Label("Ta bort pil", systemImage: "trash")
            }
        }
        // v38: kant-etikett under midpoint
        if !label.isEmpty {
            Text(label)
                .font(.system(size: max(8, 10 / canvasScale), weight: .medium, design: .rounded))
                .foregroundStyle(Color.accentColor)
                .lineLimit(1)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color(.systemBackground).opacity(0.88))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .allowsHitTesting(false)
                .position(CGPoint(x: mid.x, y: mid.y + size * 0.85 + 8 / canvasScale))
        }
    }

    private func midpointGesture(edge: Binding<EdgeConnection>) -> some Gesture {
        DragGesture(coordinateSpace: .named("canvas"))
            .onChanged { v in
                let newPoint = v.location
                if edge.wrappedValue.waypoints.isEmpty {
                    edge.wrappedValue.waypoints = [EdgeWaypoint(newPoint)]
                } else {
                    edge.wrappedValue.waypoints[0] = EdgeWaypoint(newPoint)
                }
            }
    }

    // MARK: - Drawing

    /// v38: utåtriktad normalvektor för en forms yta vid en given kant-punkt.
    /// Avgör vilken yta (V/H/T/B) som är närmast och returnerar ortogonal riktning därifrån.
    private func outwardNormal(for shape: ShapeNode, at point: CGPoint) -> CGPoint {
        var dx = point.x - shape.position.x
        var dy = point.y - shape.position.y
        // v60: rotations-medveten — räkna normalen i formens LOKALA (oroterade) rum
        // och rotera tillbaka. Då blir cp + pilhuvud vinkelrätt mot den FAKTISKA
        // (roterade) sidan → pilen går in rakt även på roterade former.
        let rot = shape.rotation
        if abs(rot) > 0.5 {
            let a = -rot * .pi / 180
            let c = cos(a), s = sin(a)
            let lx = dx * c - dy * s
            let ly = dx * s + dy * c
            dx = lx; dy = ly
        }
        let localNormal: CGPoint
        switch shape.type {
        case .circle, .link:
            let len = hypot(dx, dy)
            localNormal = len > 0.01 ? CGPoint(x: dx / len, y: dy / len) : CGPoint(x: 1, y: 0)
        default:
            let hw = ShapeGeometry.halfWidth(for: shape)
            let hh = ShapeGeometry.halfHeight(for: shape)
            let tx = hw > 0.01 ? abs(dx) / hw : 0
            let ty = hh > 0.01 ? abs(dy) / hh : 0
            if tx >= ty {
                localNormal = dx > 0 ? CGPoint(x: 1, y: 0) : CGPoint(x: -1, y: 0)
            } else {
                localNormal = dy > 0 ? CGPoint(x: 0, y: 1) : CGPoint(x: 0, y: -1)
            }
        }
        guard abs(rot) > 0.5 else { return localNormal }
        let a = rot * .pi / 180
        let c = cos(a), s = sin(a)
        return CGPoint(x: localNormal.x * c - localNormal.y * s,
                       y: localNormal.x * s + localNormal.y * c)
    }

    /// v38: bezier-kurva för en kant — mjuk S-kurva utan waypoint, smidig böj med waypoint.
    private func drawEdge(context: GraphicsContext,
                          edge: EdgeConnection,
                          fromShape: ShapeNode,
                          toShape: ShapeNode) {
        let strokeStyle = Self.strokeStyle(for: edge.style)

        // Start-/slutpunkter på formernas ytor
        let start: CGPoint
        let end: CGPoint
        if let wp = edge.waypoints.first {
            start = edgePoint(for: fromShape, towards: wp.point)
            end   = edgePoint(for: toShape,   towards: wp.point)
        } else {
            start = edgePoint(for: fromShape, towards: toShape.position)
            end   = edgePoint(for: toShape,   towards: fromShape.position)
        }

        // Bezier-kontrollpunkter baserade på ytornas normalvektorer (Lucidchart-stil)
        let n1 = outwardNormal(for: fromShape, at: start)
        let n2 = outwardNormal(for: toShape,   at: end)
        let dist    = hypot(end.x - start.x, end.y - start.y)
        // v50 F-04: minskad från 0.42 → 0.18 så diagonala pilar blir mer raka.
        // Lucidchart-böjning kvar för horisontella/vertikala (där normal och dir
        // är parallella) men dämpad för diagonala (där normal är vinkelrät mot
        // dir → ger annars en kraftig S-kurva).
        let tension = min(dist * 0.18, 60)
        var cp1 = CGPoint(x: start.x + n1.x * tension, y: start.y + n1.y * tension)
        var cp2 = CGPoint(x: end.x   + n2.x * tension, y: end.y   + n2.y * tension)

        // v43: D5 — routa runt obstacles (andra former som ligger i vägen).
        // Bara aktivt när användaren inte själv satt waypoint (waypoint = manuell routing).
        // Behåller default normal-baserade Lucidchart-cps när ingen krock finns;
        // bytar ut till sid-pushade cps endast vid faktisk obstacle.
        if edge.waypoints.isEmpty {
            let obstacleBboxes: [CGRect] = shapes.compactMap { obstacle in
                // Hoppa över source och target själva
                guard obstacle.id != edge.from && obstacle.id != edge.to else { return nil }
                // Hoppa även dolda noder (de syns inte, ska inte routa runt)
                guard !hiddenShapeIds.contains(obstacle.id) else { return nil }
                // v50: hoppa över container när pilen går mellan dess egna barn.
                // Annars ser routing-algoritmen containern som obstakel och bezier-
                // kontrollpunkterna dras långt utanför viewport (F-02 i bug-rapport).
                if obstacle.type == .container,
                   fromShape.childOfContainerId == obstacle.id
                   || toShape.childOfContainerId == obstacle.id {
                    return nil
                }
                let w = ShapeGeometry.width(for: obstacle)
                let h = ShapeGeometry.height(for: obstacle)
                // Lägg till lite margin runt obstacle för andningsutrymme
                let margin: CGFloat = 12
                return CGRect(x: obstacle.position.x - w/2 - margin,
                              y: obstacle.position.y - h/2 - margin,
                              width: w + margin * 2,
                              height: h + margin * 2)
            }
            if EdgeRouting.hasObstacle(from: start, to: end, obstacles: obstacleBboxes) {
                let routed = EdgeRouting.controlPoints(from: start, to: end, obstacles: obstacleBboxes)
                cp1 = routed.cp1
                cp2 = routed.cp2
            }
        }

        // Pilhuvud-vinklar (bezier-tangent vid endpoint).
        // v50.2 F-1: tidigare användes atan2(end - cp2) som matematiskt är
        // exakt tangenten vid t=1, MEN när cp2 är nära end (kort pil eller
        // låg tension) blir vektorn liten och atan2 numeriskt känslig →
        // pilspetsen blir sned. Lösning: sampla bezier vid t=0.92 och peka
        // från den punkten mot end. Det ger en stabil "near-endpoint-tangent"
        // som matchar pilens visuella riktning även för korta pilar.
        // v60: pilhuvudet pekar längs sidans INÅT-normal (-n) → möter alltid sidan
        // VINKELRÄTT ("rakt in"). n1/n2 är enhetsvektorer och bezier-tangenten vid
        // t=1 är exakt -n (eftersom cp = endpoint + n·tension), så pilhuvudet ligger
        // i linje med kurvans faktiska slut — stabilt för korta/diagonala/roterade pilar.
        // (Ersätter tidigare t=0.92-tangent-sampling som gav snett möte.)
        let endAngle   = atan2(-n2.y, -n2.x)
        let startAngle = atan2(-n1.y, -n1.x)

        // v48 Fel #1: dra in linjens endpoint med lineWidth/2 i den änden där
        // pilspets ritas — så .round-cap inte sticker fram förbi spetsen
        // (det gjorde tidigare att pilspetsen såg sned/asymmetrisk ut).
        let halfLW = strokeStyle.lineWidth / 2
        let endHasHead   = (edge.direction == .forward  || edge.direction == .bidirectional)
        let startHasHead = (edge.direction == .backward || edge.direction == .bidirectional)
        let lineEnd: CGPoint = endHasHead
            ? CGPoint(x: end.x - halfLW * cos(endAngle),
                      y: end.y - halfLW * sin(endAngle))
            : end
        let lineStart: CGPoint = startHasHead
            ? CGPoint(x: start.x - halfLW * cos(startAngle),
                      y: start.y - halfLW * sin(startAngle))
            : start

        var path = Path()
        path.move(to: lineStart)
        if let wp = edge.waypoints.first {
            // Mjuk böj via waypoint (quadratic → quadratic)
            path.addQuadCurve(to: wp.point, control: cp1)
            path.addQuadCurve(to: lineEnd,  control: cp2)
        } else {
            // Klassisk S-kurva (cubic bezier)
            path.addCurve(to: lineEnd, control1: cp1, control2: cp2)
        }
        context.stroke(path, with: .color(.primary.opacity(0.7)), style: strokeStyle)

        // Pilhuvuden ritas vid ORIGINAL end/start (linjens cap har dragits in)
        switch edge.direction {
        case .forward:       drawArrowHead(context: context, tip: end,   angle: endAngle)
        case .backward:      drawArrowHead(context: context, tip: start, angle: startAngle)
        case .bidirectional:
            drawArrowHead(context: context, tip: end,   angle: endAngle)
            drawArrowHead(context: context, tip: start, angle: startAngle)
        case .none: break
        }
    }

    /// v27: hel eller streckad — tjockare pilar (2.5pt) för bättre läsbarhet på iPhone.
    private static func strokeStyle(for edgeStyle: EdgeStyle) -> StrokeStyle {
        switch edgeStyle {
        case .solid:  return StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
        case .dashed: return StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round, dash: [8, 6])
        }
    }

    /// v40: Kant-utgångspunkt med rotationsstöd.
    /// Roterar target-punkten bakåt (−rotation) för att beräkna sida i lokalt koordinatsystem,
    /// sedan roteras resultatet framåt (+rotation) till world-space.
    private func edgePoint(for shape: ShapeNode, towards target: CGPoint) -> CGPoint {
        let center = shape.position
        // Rotera target bakåt för att jobba i formens lokala koordinatsystem
        let unrotatedTarget = canvasRotatePoint(target, around: center, byDegrees: -shape.rotation)
        let dx = unrotatedTarget.x - center.x
        let dy = unrotatedTarget.y - center.y
        guard abs(dx) > 0.001 || abs(dy) > 0.001 else { return center }

        let localPoint: CGPoint
        switch shape.type {
        case .circle, .link:
            // Cirklar: rotation spelar ingen roll, men vi håller konsistens
            let r = ShapeGeometry.circleRadius(for: shape)
            let length = sqrt(dx * dx + dy * dy)
            localPoint = CGPoint(x: center.x + r * dx / length, y: center.y + r * dy / length)
        case .diamond:
            localPoint = diamondSideCenter(center: center, dx: dx, dy: dy, shape: shape)
        case .rectangle, .table, .pill, .square, .processArrow, .container, .octagon:
            localPoint = rectSideCenter(center: center, dx: dx, dy: dy, shape: shape)
        case .line, .arrow:
            return center
        }
        // Rotera resultatet tillbaka till world-space
        return canvasRotatePoint(localPoint, around: center, byDegrees: shape.rotation)
    }

    /// Hjälpfunktion: rotera en punkt runt ett center med grader.
    private func canvasRotatePoint(_ p: CGPoint, around c: CGPoint, byDegrees deg: Double) -> CGPoint {
        guard abs(deg) > 0.5 else { return p }
        let r = deg * .pi / 180
        let dx = p.x - c.x
        let dy = p.y - c.y
        return CGPoint(
            x: c.x + dx * cos(r) - dy * sin(r),
            y: c.y + dx * sin(r) + dy * cos(r)
        )
    }

    /// Mitten på närmaste sida för rektangulära former.
    private func rectSideCenter(center: CGPoint, dx: CGFloat, dy: CGFloat, shape: ShapeNode) -> CGPoint {
        let hw = ShapeGeometry.halfWidth(for: shape)
        let hh = ShapeGeometry.halfHeight(for: shape)
        // Bestäm om vi träffar vänster/höger eller topp/botten
        // Normalisera mot formen (dx/hw vs dy/hh) — störst normaliserad komponent vinner
        let normX = abs(dx) / hw
        let normY = abs(dy) / hh
        if normX >= normY {
            // Vänster eller höger sida
            return CGPoint(x: center.x + (dx > 0 ? hw : -hw), y: center.y)
        } else {
            // Topp eller botten
            return CGPoint(x: center.x, y: center.y + (dy > 0 ? hh : -hh))
        }
    }

    /// Närmaste diamant-spets (top/bottom/left/right).
    private func diamondSideCenter(center: CGPoint, dx: CGFloat, dy: CGFloat, shape: ShapeNode) -> CGPoint {
        let hw = ShapeGeometry.halfWidth(for: shape)
        let hh = ShapeGeometry.halfHeight(for: shape)
        let normX = abs(dx) / hw
        let normY = abs(dy) / hh
        if normX >= normY {
            return CGPoint(x: center.x + (dx > 0 ? hw : -hw), y: center.y)
        } else {
            return CGPoint(x: center.x, y: center.y + (dy > 0 ? hh : -hh))
        }
    }

    /// v50.2 F-1: cubic bezier-evaluering vid godtyckligt t.
    /// Används av drawEdge för pilspets-tangent vid t=0.92/0.08 (stabilare
    /// än atan2(end-cp2) för korta pilar).
    static func cubicBezier(t: CGFloat, p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint) -> CGPoint {
        let u = 1 - t
        let uu = u * u, uuu = uu * u
        let tt = t * t, ttt = tt * t
        return CGPoint(
            x: uuu * p0.x + 3 * uu * t * p1.x + 3 * u * tt * p2.x + ttt * p3.x,
            y: uuu * p0.y + 3 * uu * t * p1.y + 3 * u * tt * p2.y + ttt * p3.y
        )
    }

    /// v50 F-03: bezier-anchors för en edge — start, end, bezier-mid och tangent vid t=0.5.
    /// Använder samma routing-logik som `drawEdge` så midpoint-handle hamnar på den
    /// faktiska synliga kurvan, även när bezier böjer sig runt obstakel.
    private struct EdgeAnchors {
        let start: CGPoint
        let end: CGPoint
        let cp1: CGPoint
        let cp2: CGPoint
        let mid: CGPoint
        let midAngle: Double
    }

    private func edgeAnchors(edge: EdgeConnection,
                             fromShape: ShapeNode,
                             toShape: ShapeNode) -> EdgeAnchors {
        let start: CGPoint
        let end: CGPoint
        if let wp = edge.waypoints.first {
            start = edgePoint(for: fromShape, towards: wp.point)
            end   = edgePoint(for: toShape,   towards: wp.point)
        } else {
            start = edgePoint(for: fromShape, towards: toShape.position)
            end   = edgePoint(for: toShape,   towards: fromShape.position)
        }
        let n1 = outwardNormal(for: fromShape, at: start)
        let n2 = outwardNormal(for: toShape,   at: end)
        let dist    = hypot(end.x - start.x, end.y - start.y)
        // v50 F-04: minskad från 0.42 → 0.18 så diagonala pilar blir mer raka.
        // Lucidchart-böjning kvar för horisontella/vertikala (där normal och dir
        // är parallella) men dämpad för diagonala (där normal är vinkelrät mot
        // dir → ger annars en kraftig S-kurva).
        let tension = min(dist * 0.18, 60)
        var cp1 = CGPoint(x: start.x + n1.x * tension, y: start.y + n1.y * tension)
        var cp2 = CGPoint(x: end.x   + n2.x * tension, y: end.y   + n2.y * tension)
        if edge.waypoints.isEmpty {
            let obstacleBboxes: [CGRect] = shapes.compactMap { obstacle in
                guard obstacle.id != edge.from && obstacle.id != edge.to else { return nil }
                guard !hiddenShapeIds.contains(obstacle.id) else { return nil }
                if obstacle.type == .container,
                   fromShape.childOfContainerId == obstacle.id
                   || toShape.childOfContainerId == obstacle.id {
                    return nil
                }
                let w = ShapeGeometry.width(for: obstacle)
                let h = ShapeGeometry.height(for: obstacle)
                let margin: CGFloat = 12
                return CGRect(x: obstacle.position.x - w/2 - margin,
                              y: obstacle.position.y - h/2 - margin,
                              width: w + margin * 2,
                              height: h + margin * 2)
            }
            if EdgeRouting.hasObstacle(from: start, to: end, obstacles: obstacleBboxes) {
                let routed = EdgeRouting.controlPoints(from: start, to: end, obstacles: obstacleBboxes)
                cp1 = routed.cp1
                cp2 = routed.cp2
            }
        }
        // bezier vid t=0.5
        let u: CGFloat = 0.5
        let v: CGFloat = 1 - u
        let mid = CGPoint(
            x: v*v*v*start.x + 3*v*v*u*cp1.x + 3*v*u*u*cp2.x + u*u*u*end.x,
            y: v*v*v*start.y + 3*v*v*u*cp1.y + 3*v*u*u*cp2.y + u*u*u*end.y
        )
        // tangent (derivative) vid t=0.5 ger linjens lutning där
        let tx = 3*v*v*(cp1.x - start.x) + 6*v*u*(cp2.x - cp1.x) + 3*u*u*(end.x - cp2.x)
        let ty = 3*v*v*(cp1.y - start.y) + 6*v*u*(cp2.y - cp1.y) + 3*u*u*(end.y - cp2.y)
        let midAngle = atan2(Double(ty), Double(tx))
        return EdgeAnchors(start: start, end: end,
                           cp1: cp1, cp2: cp2,
                           mid: mid, midAngle: midAngle)
    }

    /// v28: pilhuvuden med rundade hörn — stroke + fyllning med lineJoin: .round
    /// så även spetsen är mjuk istället för vass.
    private func drawArrowHead(context: GraphicsContext, tip: CGPoint, angle: CGFloat) {
        let length: CGFloat = 14
        let spread: CGFloat = .pi / 7
        let a1 = CGPoint(
            x: tip.x - length * cos(angle - spread),
            y: tip.y - length * sin(angle - spread)
        )
        let a2 = CGPoint(
            x: tip.x - length * cos(angle + spread),
            y: tip.y - length * sin(angle + spread)
        )
        var head = Path()
        head.move(to: tip)
        head.addLine(to: a1)
        head.addLine(to: a2)
        head.closeSubpath()
        // v49 Fel #1 (Agent C 1/3-diagnos): bara fill, inte stroke. Stroke med
        // .round cap/join lade till ~0.75pt rundning på pilspets-sidorna som
        // kan ge subpixel-asymmetri vid diagonala vinklar. Ren fyllning ger
        // skarpare, mer symmetrisk pilspets.
        context.fill(head, with: .color(.primary.opacity(0.85)))
    }
}
