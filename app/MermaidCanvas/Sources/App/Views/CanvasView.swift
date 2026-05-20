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
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.primary.opacity(0.18), lineWidth: 1)
                )
                .coordinateSpace(name: "canvas")
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
                      onEdgeSetStyle: { id, s in model.setEdgeStyle(id: id, s) })
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
                        onToggleCollapse: { model.toggleCollapse(id: shape.id) }
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
                    }
                )
            }

            if model.markerMode {
                MarkerOverlay(model: model, canvasContentSize: model.contentSize)
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

    @State private var dragOffset: CGSize = .zero

    private var pack: ColorPack { ColorPack.by(id: shape.colorPackId) }
    private var effectiveFill: Color { pack.fillColor }
    // v35.1: pack.strokeColor när pack är satt, annars kategori-stroke.
    // (Tidigare: alltid Color.primary = svart — ignorerade pack-färgen.)
    private var effectiveStroke: Color {
        pack.id != "none" ? pack.strokeColor : shape.category.strokeColor
    }
    private var effectiveTextColor: Color { pack.textColor }

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
                // v37: punktlista + textjustering
                let displayLabel: String = shape.hasBullets
                    ? shape.label.split(separator: "\n", omittingEmptySubsequences: false)
                        .map { "• \($0)" }.joined(separator: "\n")
                    : shape.label
                let multiAlign: TextAlignment = {
                    switch shape.textAlignment {
                    case .leading:  return .leading
                    case .trailing: return .trailing
                    case .center:   return .center
                    }
                }()
                Text(displayLabel)
                    .font(.system(size: shape.textStyle.fontSize * shape.sizeMultiplier,
                                  weight: shape.textStyle.fontWeight,
                                  design: .rounded))
                    .foregroundStyle(effectiveTextColor)
                    .multilineTextAlignment(multiAlign)
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
        .overlay(alignment: .bottomTrailing) {
            if showCollapseBadge && !markerMode {
                CollapseBadge(collapsed: isCollapsed,
                              canvasScale: canvasScale,
                              onTap: onToggleCollapse)
                    .offset(x: 8 / canvasScale, y: 8 / canvasScale)
                    .rotationEffect(.degrees(-shape.rotation))
            }
        }
        .contentShape(Rectangle())
        .accessibilityIdentifier("shape.\(shape.type.rawValue)")
        .position(
            x: shape.position.x + dragOffset.width,
            y: shape.position.y + dragOffset.height
        )
        // v28 Etapp 10: dubbeltap startar ALLTID edit (Kim's krav).
        .onTapGesture(count: 2) {
            onEdit()
        }
        .onTapGesture(count: 1) {
            if markerMode { return }
            if edgeMode {
                onEdgeTap()
            } else {
                onSelect()
            }
        }
        .gesture((edgeMode || markerMode) ? nil : dragGesture)
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

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { v in dragOffset = v.translation }
            .onEnded { v in
                shape.position.x += v.translation.width
                shape.position.y += v.translation.height
                dragOffset = .zero
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
                                 fill: effectiveFill,
                                 stroke: effectiveStroke)
        case .link:
            JumpLinkShapeBackground(number: shape.linkNumber ?? 0, fill: effectiveFill)
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

private struct JumpLinkShapeBackground: View {
    var number: Int
    var fill: Color

    var body: some View {
        ZStack {
            Circle().fill(fill)
            Circle().stroke(Color.white, lineWidth: 2)
            VStack(spacing: 0) {
                Image(systemName: "link")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                Text("\(number)")
                    .font(.callout.weight(.heavy))
                    .foregroundStyle(.white)
            }
        }
    }
}

/// v28: rundad romb/diamant — mjuka hörn istället för vassa spetsar.
/// v35.1: fyller hela ramen (120×80) → bredare-än-hög romb som matchar Mermaid's {} render.
struct DiamondShape: Shape {
    var cornerRadius: CGFloat = 8

    func path(in rect: CGRect) -> Path {
        let top    = CGPoint(x: rect.midX, y: rect.minY)
        let right  = CGPoint(x: rect.maxX, y: rect.midY)
        let bottom = CGPoint(x: rect.midX, y: rect.maxY)
        let left   = CGPoint(x: rect.minX, y: rect.midY)

        let r = min(cornerRadius, min(rect.width, rect.height) / 4)
        // För varje hörn: gå r-pt åt vardera håll längs kanten innan hörnet
        // och rita en quad-curve runt själva hörnet.
        let topToRightDir = unitVector(from: top, to: right)
        let rightToBottomDir = unitVector(from: right, to: bottom)
        let bottomToLeftDir = unitVector(from: bottom, to: left)
        let leftToTopDir = unitVector(from: left, to: top)

        var p = Path()
        p.move(to: offset(top, by: topToRightDir, amount: r))
        p.addLine(to: offset(right, by: topToRightDir, amount: -r))
        p.addQuadCurve(to: offset(right, by: rightToBottomDir, amount: r), control: right)
        p.addLine(to: offset(bottom, by: rightToBottomDir, amount: -r))
        p.addQuadCurve(to: offset(bottom, by: bottomToLeftDir, amount: r), control: bottom)
        p.addLine(to: offset(left, by: bottomToLeftDir, amount: -r))
        p.addQuadCurve(to: offset(left, by: leftToTopDir, amount: r), control: left)
        p.addLine(to: offset(top, by: leftToTopDir, amount: -r))
        p.addQuadCurve(to: offset(top, by: topToRightDir, amount: r), control: top)
        p.closeSubpath()
        return p
    }

    private func unitVector(from a: CGPoint, to b: CGPoint) -> CGVector {
        let dx = b.x - a.x
        let dy = b.y - a.y
        let len = sqrt(dx * dx + dy * dy)
        guard len > 0.001 else { return CGVector(dx: 0, dy: 0) }
        return CGVector(dx: dx / len, dy: dy / len)
    }

    private func offset(_ p: CGPoint, by v: CGVector, amount: CGFloat) -> CGPoint {
        CGPoint(x: p.x + v.dx * amount, y: p.y + v.dy * amount)
    }
}

// MARK: - Nya grundformer v35.1

/// Liksidig kvadrat med rundade hörn — identisk med RoundedRectangle men kvadratisk.
/// ShapeGeometry ger 80×80-ram; formen fyller den.
struct SquareShape: Shape {
    var cornerRadius: CGFloat = 14
    func path(in rect: CGRect) -> Path {
        Path(roundedRect: rect, cornerRadius: cornerRadius, style: .continuous)
    }
}

/// Processsteg-pil — pentagon med platt vänsterkant och spetsig högerände.
/// v36.1: spets = 40% av bredden → matchar SF-symbolen arrowshape.right visuellt.
/// Bredd 110×80 — kompakt nog att se ut som en "pil", inte ett "block".
struct ProcessArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        let tip: CGFloat = rect.width * 0.40   // 40% av bredden = tydlig spets

        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX - tip, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX - tip, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

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
            case .bidirectional: return "arrow.left.arrow.right"
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

    private func drawEdge(context: GraphicsContext,
                          edge: EdgeConnection,
                          fromShape: ShapeNode,
                          toShape: ShapeNode) {
        let strokeStyle = Self.strokeStyle(for: edge.style)
        if let wp = edge.waypoints.first {
            let firstSeg = edgePoint(for: fromShape, towards: wp.point)
            let lastSeg = edgePoint(for: toShape, towards: wp.point)

            var line = Path()
            line.move(to: firstSeg)
            line.addLine(to: wp.point)
            line.addLine(to: lastSeg)
            context.stroke(line, with: .color(.primary.opacity(0.7)), style: strokeStyle)

            // v37: pilhuvuden baserat på riktning
            let endAngle   = atan2(lastSeg.y  - wp.point.y, lastSeg.x  - wp.point.x)
            let startAngle = atan2(firstSeg.y - wp.point.y, firstSeg.x - wp.point.x)
            switch edge.direction {
            case .forward:       drawArrowHead(context: context, tip: lastSeg,  angle: endAngle)
            case .backward:      drawArrowHead(context: context, tip: firstSeg, angle: startAngle)
            case .bidirectional:
                drawArrowHead(context: context, tip: lastSeg,  angle: endAngle)
                drawArrowHead(context: context, tip: firstSeg, angle: startAngle)
            case .none: break
            }
        } else {
            let start = edgePoint(for: fromShape, towards: toShape.position)
            let end = edgePoint(for: toShape, towards: fromShape.position)
            drawArrow(context: context, from: start, to: end,
                      direction: edge.direction, style: strokeStyle)
        }
    }

    /// v27: hel eller streckad — tjockare pilar (2.5pt) för bättre läsbarhet på iPhone.
    private static func strokeStyle(for edgeStyle: EdgeStyle) -> StrokeStyle {
        switch edgeStyle {
        case .solid:  return StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
        case .dashed: return StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round, dash: [8, 6])
        }
    }

    private func edgePoint(for shape: ShapeNode, towards target: CGPoint) -> CGPoint {
        let center = shape.position
        let dx = target.x - center.x
        let dy = target.y - center.y
        let length = sqrt(dx * dx + dy * dy)
        guard length > 0.001 else { return center }

        switch shape.type {
        case .circle:
            let r = ShapeGeometry.circleRadius(for: shape)
            return CGPoint(x: center.x + r * dx / length, y: center.y + r * dy / length)
        case .rectangle:
            return rectEdge(center: center, dx: dx, dy: dy, shape: shape)
        case .diamond:
            let absX = abs(dx)
            let absY = abs(dy)
            let hw = ShapeGeometry.halfWidth(for: shape)
            let hh = ShapeGeometry.halfHeight(for: shape)
            let denom = absX / hw + absY / hh
            guard denom > 0.001 else { return center }
            let t = 1.0 / denom
            return CGPoint(x: center.x + t * dx, y: center.y + t * dy)
        case .text, .table, .pill, .square, .processArrow:
            return rectEdge(center: center, dx: dx, dy: dy, shape: shape)
        case .link:
            let r = ShapeGeometry.circleRadius(for: shape)
            return CGPoint(x: center.x + r * dx / length, y: center.y + r * dy / length)
        case .line, .arrow:
            // v31: lösa linjer/pilar är inte normala edge-targets — använd center.
            return center
        }
    }

    private func rectEdge(center: CGPoint, dx: CGFloat, dy: CGFloat, shape: ShapeNode) -> CGPoint {
        let absX = abs(dx)
        let absY = abs(dy)
        let hw = ShapeGeometry.halfWidth(for: shape)
        let hh = ShapeGeometry.halfHeight(for: shape)
        let tx = absX > 0.001 ? hw / absX : .greatestFiniteMagnitude
        let ty = absY > 0.001 ? hh / absY : .greatestFiniteMagnitude
        let t = min(tx, ty)
        return CGPoint(x: center.x + t * dx, y: center.y + t * dy)
    }

    private func drawArrow(context: GraphicsContext,
                           from: CGPoint,
                           to: CGPoint,
                           direction: EdgeDirection,
                           style: StrokeStyle) {
        var line = Path()
        line.move(to: from)
        line.addLine(to: to)
        context.stroke(line, with: .color(.primary.opacity(0.7)), style: style)

        let angle = atan2(to.y - from.y, to.x - from.x)
        // v37: pilhuvuden baserat på riktning
        switch direction {
        case .forward:       drawArrowHead(context: context, tip: to,   angle: angle)
        case .backward:      drawArrowHead(context: context, tip: from, angle: angle + .pi)
        case .bidirectional:
            drawArrowHead(context: context, tip: to,   angle: angle)
            drawArrowHead(context: context, tip: from, angle: angle + .pi)
        case .none: break
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
