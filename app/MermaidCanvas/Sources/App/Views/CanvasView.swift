import SwiftUI
import CoreTransferable

enum ShapeGeometry {
    static let baseWidth: CGFloat = 120
    static let baseHeight: CGFloat = 80

    /// v35.1/v36: typ-specifika basbredder/-höjder.
    static func typeBaseWidth(for type: ShapeType) -> CGFloat {
        switch type {
        case .pill:         return 150   // 25% bredare oval
        case .square:       return 80    // liksidig kvadrat
        case .processArrow: return 110   // kompakt pil (spets 40% av bredden)
        default:            return baseWidth
        }
    }
    static func typeBaseHeight(for type: ShapeType) -> CGFloat {
        switch type {
        case .square: return 80   // liksidig kvadrat
        default:      return baseHeight
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
    /// v42: när användaren long-pressar en vald form aktiveras edge-läget bara för den
    @State private var edgeIntentShapeId: UUID? = nil

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
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.primary.opacity(0.18), lineWidth: 1)
                )
                .coordinateSpace(name: "canvas")
                // v42: rensa edge-intent när användaren byter vald form
                .onChange(of: model.selectedShapeId) { _, newId in
                    if newId != edgeIntentShapeId {
                        edgeIntentShapeId = nil
                    }
                }
        }
        .ignoresSafeArea()
        .accessibilityIdentifier("canvas")
        .simultaneousGesture(
            TapGesture().onEnded {
                model.deselect()
                if model.isEdgeMode { model.cancelEdgeMode() }
            }
        )
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
                      onEdgeDelete: onEdgeDelete,
                      onEdgeSetDirection: { id, dir in model.setEdgeDirection(id: id, direction: dir) },
                      onEdgeSetStyle: { id, s in model.setEdgeStyle(id: id, s) },
                      onEdgeRename: { id, label in model.setEdgeLabel(id: id, label: label) })
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
                        isCollapsed: model.collapsedIds.contains(shape.id),
                        showCollapseBadge: model.hasOutgoingEdges(id: shape.id),
                        isPendingFrom: model.pendingEdgeFrom == shape.id,
                        onEdgeTap: { onShapeEdgeTap(shape.id) },
                        onSelect: { handleShapeSelect(id: shape.id) },
                        onEdit: { onShapeEdit(shape.id) },
                        onDelete: { onShapeDelete(shape.id) },
                        onDuplicate: { onShapeDuplicate(shape.id) },
                        onShowNote: { onShapeShowNote(shape.id) },
                        onToggleCollapse: { model.toggleCollapse(id: shape.id) },
                        onTableEdit: { _ in onTableEdit(shape.id) },
                        onDragUpdate: { canvasPoint in
                            updateAutoScroll(at: canvasPoint)
                        },
                        onMoveMultiSelection: { delta in
                            model.moveSelection(by: delta)
                        },
                        isInMultiSelection: model.multiSelection.contains(shape.id),
                        outgoingDirection: model.averageOutgoingDirection(from: shape.id),
                        onLongPress: {
                            if model.selectedShapeId == shape.id {
                                // togglar edge-intent för den valda formen
                                edgeIntentShapeId = (edgeIntentShapeId == shape.id) ? nil : shape.id
                            } else {
                                // välj formen OCH aktivera edge-mode i en gest
                                model.selectShape(shape.id)
                                edgeIntentShapeId = shape.id
                            }
                        }
                    )
                }
            }

            ForEach(model.shapes.filter { model.multiSelection.contains($0.id) }) { s in
                Rectangle()
                    .stroke(Color.accentColor,
                            style: StrokeStyle(lineWidth: 2 / zoomScale,
                                               dash: [5 / zoomScale, 4 / zoomScale]))
                    .frame(width: ShapeGeometry.width(for: s) + 8,
                           height: ShapeGeometry.height(for: s) + 8)
                    .position(s.position)
                    .allowsHitTesting(false)
            }

            // Connection-handtag + selection-handtag på vald form
            if model.multiSelection.isEmpty,
               let selectedId = model.selectedShapeId,
               let idx = model.shapes.firstIndex(where: { $0.id == selectedId }) {
                let s = model.shapes[idx]
                SelectionHandles(
                    shape: $model.shapes[idx],
                    canvasScale: zoomScale
                )
                // v42: ConnectionHandles bara om användaren signalerat edge-intent (long-press)
                if edgeIntentShapeId == selectedId || model.pendingEdgeFrom == selectedId {
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
                            }
                            connectionDrag = nil
                            edgeIntentShapeId = nil   // ut ur edge-läget när pilen ritats
                        }
                    )
                }
            }

            if model.markerMode && model.multiSelection.isEmpty {
                // Marquee-selection overlay (bara aktiv när inget är markerat)
                MarkerOverlay(model: model, canvasContentSize: model.contentSize)
            } else if model.markerMode && !model.multiSelection.isEmpty {
                // Bakgrunds-tap rensar urval (så man kan starta ny marquee-selektion)
                Color.clear
                    .contentShape(Rectangle())
                    .frame(width: model.contentSize.width, height: model.contentSize.height)
                    .onTapGesture {
                        model.multiSelection.removeAll()
                    }
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

/// v25: 4 små handtag som syns på vald form. Drag drar en pil till annan form.
struct ConnectionHandles: View {
    let shape: ShapeNode
    let canvasScale: CGFloat
    let onDragChanged: (CGPoint) -> Void
    let onDragEnded: (CGPoint) -> Void

    var body: some View {
        let w = ShapeGeometry.width(for: shape)
        let h = ShapeGeometry.height(for: shape)
        let size: CGFloat = max(16, 18 / canvasScale)
        ZStack {
            handle(offset: CGPoint(x: 0,     y: -h/2 - size/2 - 4 / canvasScale), size: size)
            handle(offset: CGPoint(x: w/2 + size/2 + 4 / canvasScale, y: 0),       size: size)
            handle(offset: CGPoint(x: 0,     y:  h/2 + size/2 + 4 / canvasScale),  size: size)
            handle(offset: CGPoint(x: -w/2 - size/2 - 4 / canvasScale, y: 0),      size: size)
        }
        .frame(width: w, height: h)
        .position(shape.position)
        .rotationEffect(.degrees(shape.rotation))
    }

    /// v28: stilren beroendepil-ikon (link) istället för arrow.up.right.
    @ViewBuilder
    private func handle(offset: CGPoint, size: CGFloat) -> some View {
        ZStack {
            Circle().fill(Color.accentColor)
            Image(systemName: "link")
                .font(.system(size: size * 0.42, weight: .semibold))
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
    }
}

// MARK: - ShapeView

struct ShapeView: View {
    @Binding var shape: ShapeNode
    let edgeMode: Bool
    let markerMode: Bool
    let canvasScale: CGFloat
    let isCollapsed: Bool
    let showCollapseBadge: Bool
    let isPendingFrom: Bool
    let onEdgeTap: () -> Void
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void
    let onShowNote: () -> Void
    let onToggleCollapse: () -> Void
    /// v41: öppnar tabell-redigeraren vid dubbelklick på tabell-form.
    var onTableEdit: ((UUID) -> Void)? = nil
    /// v39: rapporterar drag-position (canvas-koord) för auto-scroll. nil = drag avslutad.
    var onDragUpdate: ((CGPoint?) -> Void)? = nil
    /// v40: callback för att flytta ALLA markerade former (multi-select drag).
    var onMoveMultiSelection: ((CGSize) -> Void)? = nil
    /// v40: sann om denna form ingår i multiSelection
    var isInMultiSelection: Bool = false
    /// v42: genomsnittlig riktning för utgående kanter — används för badge-position.
    var outgoingDirection: CGVector? = nil
    /// v42: long-press togglar edge-intent (kedje-handtagen) för formen.
    var onLongPress: (() -> Void)? = nil

    @State private var dragOffset: CGSize = .zero
    @State private var lastMultiDragTranslation: CGSize? = nil

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
            if shape.showLabel {
                Text(formattedLabel)
                    .font(.system(size: shape.textStyle.fontSize * shape.sizeMultiplier,
                                  weight: shape.textStyle.fontWeight,
                                  design: .rounded))
                    .foregroundStyle(effectiveTextColor)
                    .multilineTextAlignment(textAlignment)
                    .lineLimit(6)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, shape.type == .text ? 2 : 8)
            }
        }
        .frame(width: ShapeGeometry.width(for: shape),
               height: ShapeGeometry.height(for: shape))
        .rotationEffect(.degrees(shape.rotation))
        .opacity(markerMode && !edgeMode ? 0.6 : 1.0)
        .overlay(alignment: .topTrailing) {
            if !shape.note.isEmpty && !markerMode {
                NoteBadge(canvasScale: canvasScale, onTap: onShowNote)
                    .offset(x: 8 / canvasScale, y: -8 / canvasScale)
                    .rotationEffect(.degrees(-shape.rotation))
            }
        }
        // v42: collapse-badge vid kant-startpunkten (riktning mot utgående pilar)
        .overlay {
            if showCollapseBadge && !markerMode, let dir = outgoingDirection {
                let w = ShapeGeometry.width(for: shape)
                let h = ShapeGeometry.height(for: shape)
                // Placera badge precis innanför kanten i riktning mot pilen
                let badgeOffset: CGFloat = 18 / canvasScale
                let edgeX = dir.dx * (w / 2 - badgeOffset)
                let edgeY = dir.dy * (h / 2 - badgeOffset)
                CollapseBadge(collapsed: isCollapsed,
                              canvasScale: canvasScale,
                              onTap: onToggleCollapse)
                    .offset(x: edgeX, y: edgeY)
                    .rotationEffect(.degrees(-shape.rotation))
            }
        }
        .contentShape(Rectangle())
        .accessibilityIdentifier("shape.\(shape.type.rawValue)")
        .position(
            x: shape.position.x + dragOffset.width,
            y: shape.position.y + dragOffset.height
        )
        // v41: dubbelklick på tabell öppnar tabell-redigeraren.
        .onTapGesture(count: 2) {
            if shape.type == .table {
                onTableEdit?(shape.id)
            } else {
                onEdit()
            }
        }
        .onTapGesture(count: 1) {
            if markerMode {
                onSelect()   // v40: markerMode → toggla i multiSelection
                return
            }
            if edgeMode {
                onEdgeTap()
            } else {
                onSelect()
            }
        }
        // v42: long-press togglar edge-intent (visar kedje-handtagen)
        .onLongPressGesture(minimumDuration: 0.5) {
            onLongPress?()
        }
        // v40: drag aktiverat i markerMode OM formen ingår i multiSelection.
        // Utan mask .none läggs inget gesture-recognizer på (undviker UIScrollView-kollision).
        .gesture(unifiedDragGesture, including: gestureActive ? .all : .none)
        .contextMenu {
            Button { onEdit() } label: { Label("Redigera", systemImage: "pencil") }
            Button { onDuplicate() } label: { Label("Duplicera", systemImage: "plus.square.on.square") }
            Button { onShowNote() } label: {
                Label(shape.note.isEmpty ? "Lägg till anteckning" : "Visa anteckning",
                      systemImage: "note.text")
            }
            Divider()
            Button(role: .destructive) { onDelete() } label: { Label("Ta bort", systemImage: "trash") }
        }
    }

    /// Sann när drag-gesten ska vara aktiv: normalt läge, eller markeringsläge med multiSelection.
    private var gestureActive: Bool {
        !edgeMode && (!markerMode || isInMultiSelection)
    }

    /// v40: Enhetlig drag-gest — hanterar normal drag, multi-select drag och inaktivt läge.
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
                    onDragUpdate?(nil)
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
            RoundedRectangle(cornerRadius: 14, style: .continuous)
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
        case .text:
            EmptyView()
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
        case .line, .arrow:
            EmptyView()
        }
    }

    @ViewBuilder
    private var stroke: some View {
        switch shape.type {
        case .circle:
            Circle().stroke(effectiveStroke, lineWidth: 1.5)
        case .rectangle:
            RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(effectiveStroke, lineWidth: 1.5)
        case .diamond:
            DiamondShape().stroke(effectiveStroke, lineWidth: 1.5)
        case .pill:
            Capsule(style: .continuous).stroke(effectiveStroke, lineWidth: 1.5)
        case .square:
            SquareShape().stroke(effectiveStroke, lineWidth: 1.5)
        case .processArrow:
            ProcessArrowShape().stroke(effectiveStroke, lineWidth: 1.5)
        case .text, .table, .link, .line, .arrow:
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
            case .text:
                RoundedRectangle(cornerRadius: 8).stroke(Color.accentColor, lineWidth: 3.5)
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
            // v36.1: lineEnd normaliseras mot basvärdet 60pt → skalas med halv-bredden.
            // Effekt: resize-handtag ändrar linjens längd proportionellt.
            let scaledX = (end.x / 60.0) * (size.width  / 2.0)
            let scaledY = (end.y / 60.0) * (size.height / 2.0)
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
    var onEdgeDelete: (UUID) -> Void
    var onEdgeSetDirection: (UUID, EdgeDirection) -> Void
    var onEdgeSetStyle: (UUID, EdgeStyle) -> Void
    var onEdgeRename: (UUID, String) -> Void

    // v38: kant-namngivning via alert
    @State private var renamingEdgeId: UUID? = nil
    @State private var renameText: String = ""

    private func isVisible(_ edge: EdgeConnection) -> Bool {
        !hiddenShapeIds.contains(edge.from) && !hiddenShapeIds.contains(edge.to)
    }

    var body: some View {
        ZStack {
            Canvas { context, _ in
                for edge in edges where isVisible(edge) {
                    guard let fromShape = shapes.first(where: { $0.id == edge.from }),
                          let toShape = shapes.first(where: { $0.id == edge.to })
                    else { continue }
                    drawEdge(context: context, edge: edge, fromShape: fromShape, toShape: toShape)
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
        }
        .alert("Döp kant", isPresented: Binding(
            get: { renamingEdgeId != nil },
            set: { if !$0 { renamingEdgeId = nil } }
        )) {
            TextField("Namn på kanten", text: $renameText)
            Button("Spara") {
                if let id = renamingEdgeId { onEdgeRename(id, renameText) }
                renamingEdgeId = nil
            }
            Button("Avbryt", role: .cancel) { renamingEdgeId = nil }
        } message: {
            Text("Visas bredvid pilens mittpunkt.")
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
        let mid: CGPoint = {
            if hasWaypoint { return edge.wrappedValue.waypoints[0].point }
            return CGPoint(
                x: (fromShape.position.x + toShape.position.x) / 2,
                y: (fromShape.position.y + toShape.position.y) / 2
            )
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
        }
        .contentShape(Circle().inset(by: -size * 0.5))
        .position(mid)
        .gesture(midpointGesture(edge: edge))
        .contextMenu {
            // v38: döp kant
            Button {
                renamingEdgeId = edge.wrappedValue.id
                renameText = edge.wrappedValue.label
            } label: {
                Label("Döp kant", systemImage: "pencil")
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
        let dx = point.x - shape.position.x
        let dy = point.y - shape.position.y
        switch shape.type {
        case .circle, .link:
            let len = hypot(dx, dy)
            return len > 0.01 ? CGPoint(x: dx / len, y: dy / len) : CGPoint(x: 1, y: 0)
        default:
            let hw = ShapeGeometry.halfWidth(for: shape)
            let hh = ShapeGeometry.halfHeight(for: shape)
            let tx = hw > 0.01 ? abs(dx) / hw : 0
            let ty = hh > 0.01 ? abs(dy) / hh : 0
            if tx >= ty {
                return dx > 0 ? CGPoint(x: 1, y: 0) : CGPoint(x: -1, y: 0)
            } else {
                return dy > 0 ? CGPoint(x: 0, y: 1) : CGPoint(x: 0, y: -1)
            }
        }
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
        let tension = min(dist * 0.42, 95)
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

        var path = Path()
        path.move(to: start)
        if let wp = edge.waypoints.first {
            // Mjuk böj via waypoint (quadratic → quadratic)
            path.addQuadCurve(to: wp.point, control: cp1)
            path.addQuadCurve(to: end,      control: cp2)
        } else {
            // Klassisk S-kurva (cubic bezier)
            path.addCurve(to: end, control1: cp1, control2: cp2)
        }
        context.stroke(path, with: .color(.primary.opacity(0.7)), style: strokeStyle)

        // Pilhuvuden — vinkel från bezier-tangenten vid endpoint
        let endAngle: CGFloat
        let startAngle: CGFloat
        if let wp = edge.waypoints.first {
            endAngle   = atan2(end.y   - wp.point.y, end.x   - wp.point.x)
            startAngle = atan2(start.y - wp.point.y, start.x - wp.point.x)
        } else {
            endAngle   = atan2(end.y   - cp2.y, end.x   - cp2.x)
            startAngle = atan2(start.y - cp1.y, start.x - cp1.x)
        }
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
        case .rectangle, .text, .table, .pill, .square, .processArrow:
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
        context.fill(head, with: .color(.primary.opacity(0.78)))
        // Rita också en stroke runt huvudet med rundade join för att mjuka spetsarna
        context.stroke(head, with: .color(.primary.opacity(0.78)),
                       style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
    }
}
