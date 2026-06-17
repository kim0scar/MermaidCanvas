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
    /// v63: snabbläsning av anteckning+prompt (read-only QuickReadSheet)
    let onQuickRead: () -> Void
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
    /// v66: kopiera container som skill-mermaid (bara containrar visar valet).
    var onCopySkill: ((UUID) -> Void)? = nil
    /// v70: spara container som egen skill-fil (bara containrar visar valet).
    var onSaveSkillFile: ((UUID) -> Void)? = nil

    @State private var dragOffset: CGSize = .zero
    @State private var lastMultiDragTranslation: CGSize? = nil
    @State private var lastContainerDragTranslation: CGSize = .zero
    /// v50.5 F4: egen popover-meny vid long-press — ersätter .contextMenu
    /// som triggade SwiftUI's snapshot-preview (svart blurred flash) innan
    /// menyn visades.
    @State private var showContextMenu: Bool = false

    private var pack: ColorPack { ColorPack.by(id: shape.colorPackId) }
    // v62: egna färger (fyllning + ram separat) går före paket/kategori.
    private var effectiveFill: Color {
        if let hex = shape.colorOverride, let c = Color(hexString: hex) { return c }
        return pack.fillColor
    }
    private var effectiveStroke: Color {
        if let hex = shape.strokeColorOverride, let c = Color(hexString: hex) { return c }
        return pack.id != "none" ? pack.strokeColor : shape.category.strokeColor
    }
    private var effectiveTextColor: Color {
        // Egen fyllning → välj svart/vit på luminans så texten alltid syns.
        if let hex = shape.colorOverride, Color(hexString: hex) != nil {
            return Color.isDarkHex(hex) ? .white : Color(hex: 0x111827)
        }
        return pack.textColor
    }

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

    /// v74: container-rubrik — skill-containrar visar kedjenumret ("Skill 2 · namn").
    private var containerHeaderTitle: String {
        let name = shape.label.isEmpty ? "Grupp" : formattedLabel
        guard shape.category == .skill else { return name }
        if let nr = shape.skillNumber { return "Skill \(nr) · \(name)" }
        return name
    }

    var body: some View {
        ZStack {
            ShapeRenderer(shape: shape, fill: effectiveFill, stroke: effectiveStroke,
                          containerTitle: containerHeaderTitle, isPendingFrom: isPendingFrom)
            // v36: lös linje/pil ritas via FreeLineView (background ger EmptyView)
            if shape.type == .line || shape.type == .arrow {
                FreeLineView(shape: shape, stroke: effectiveStroke)
            }
            // v50.3 R3: Containers label hanteras via separat .overlay nedan
            // (Lucidchart-stil ovanför ramen). Andra former behåller centrerad
            // text inuti ZStack:en.
            if shape.showLabel && shape.type != .container && shape.type != .phoneFrame {
                // v73: tom nod visar sin typ som svag platshållare (P4: "bara form+färg
                // skiljer Script från Bevis") — försvinner så fort Kim skriver eget namn.
                // Bara visning; exporten påverkas inte.
                Text(shape.label.isEmpty ? shape.category.displayName : formattedLabel)
                    .font(.system(size: shape.textStyle.fontSize * shape.sizeMultiplier,
                                  weight: shape.textStyle.fontWeight,
                                  design: .rounded))
                    .foregroundStyle(shape.label.isEmpty
                        ? effectiveTextColor.opacity(0.35)
                        : effectiveTextColor)
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
        // v63: badge-tap → snabbläsning (read-only), inte redigering.
        // v66: badges ligger PÅ formen (ingen utstickande offset — Kims fynd:
        // "i vägen"); på container UNDER den 28pt höga headern så namnet syns.
        .overlay(alignment: .topTrailing) {
            if !shape.note.isEmpty && !markerMode {
                NoteBadge(canvasScale: canvasScale, onTap: onQuickRead)
                    .offset(x: -3, y: shape.type == .container ? 31 : 3)
                    .rotationEffect(.degrees(-shape.rotation))
            }
        }
        // v63: prompt-badge (indigo hjärna) i toppvänstra hörnet → snabbläsning.
        .overlay(alignment: .topLeading) {
            if !shape.prompt.isEmpty && !markerMode {
                PromptBadge(canvasScale: canvasScale, onTap: onQuickRead)
                    .offset(x: 3, y: shape.type == .container ? 31 : 3)
                    .rotationEffect(.degrees(-shape.rotation))
            }
        }
        // v48 Fel #3+#4: CollapseBadge är flyttad från ShapeView till EdgesView
        // (renderas per utgående kant, vid kantens start). Se EdgeCollapseBadges.swift.
        .contentShape(Rectangle())
        // v73: formen som ETT a11y-element med begriplig svensk label —
        // för VoiceOver och för AI-agenter som läser a11y-trädet.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(shape.label.isEmpty
            ? shape.category.displayName
            : "\(shape.category.displayName): \(shape.label)")
        .accessibilityAddTraits(.isButton)
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
                onDelete:    { showContextMenu = false; onDelete() },
                // v66: containrar kan kopieras som skill-mermaid
                onCopySkill: shape.type == .container && onCopySkill != nil
                    ? { showContextMenu = false; onCopySkill?(shape.id) }
                    : nil,
                onSaveSkillFile: shape.type == .container && onSaveSkillFile != nil
                    ? { showContextMenu = false; onSaveSkillFile?(shape.id) }
                    : nil
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

    // background / stroke / highlight → Views/Canvas/ShapeRenderer.swift (MA spår A steg 5).
}

// MARK: - Special shape backgrounds

// TableShapeBackground + JumpLinkShapeBackground → Views/Canvas/ShapeBackgrounds.swift (MA spår A steg 4).

// v42: DiamondShape, SquareShape och ProcessArrowShape är flyttade till
// Sources/App/Views/Shapes/CanvasShapes.swift så att ToolbarView kan rendera
// EXAKT samma former i chip-vyn. Inga duplicerade definitioner längre.

// FreeLineView → Views/Canvas/FreeLineView.swift (MA spår A steg 3).

// MARK: - EdgesView

struct EdgesView: View {
    @Binding var edges: [EdgeConnection]
    let shapes: [ShapeNode]
    let canvasScale: CGFloat
    let hiddenShapeIds: Set<UUID>
    /// v63: kollapsade GRENAR (kant-id) — styr stubbar/badges per gren.
    let collapsedEdgeIds: Set<UUID>
    /// v48: vilken form som är markerad — styr om minus-badges visas.
    let selectedShapeId: UUID?
    var onEdgeDelete: (UUID) -> Void
    var onEdgeSetDirection: (UUID, EdgeDirection) -> Void
    var onEdgeSetStyle: (UUID, EdgeStyle) -> Void
    /// v63: färg på pilen (hex eller nil = standard)
    var onEdgeSetColor: (UUID, String?) -> Void
    /// v64: byt utgångssida på pilen (nil = automatisk)
    var onEdgeSetFromSide: (UUID, EdgeSide?) -> Void
    var onEdgeRename: (UUID, String, EdgeLabelPlacement) -> Void
    /// v48: toggle-callback för collapse-badges. Tar shape-ID.
    /// v63: kollapsa/expandera EN gren (kant-id).
    var onToggleCollapseEdge: (UUID) -> Void

    // v44: kant-namngivning via EdgeLabelSheet (ersätter v38-alerten).
    @State private var renamingEdgeId: UUID? = nil

    private func isVisible(_ edge: EdgeConnection) -> Bool {
        !hiddenShapeIds.contains(edge.from) && !hiddenShapeIds.contains(edge.to)
    }

    /// v63: stub-linjens geometri för en kollapsad gren. Solfjäder-spridning
    /// (±0.5 rad/steg) när flera kollapsade grenar delar samma from-nod —
    /// annars hamnar plus-badges ovanpå varandra. Stub-linje och plus-badge
    /// använder SAMMA geometri så de alltid linjerar.
    private func stubGeometry(for edge: EdgeConnection,
                              fromShape: ShapeNode,
                              toShape: ShapeNode) -> (start: CGPoint, end: CGPoint) {
        let siblings = edges.filter {
            $0.from == edge.from && collapsedEdgeIds.contains($0.id)
        }
        let idx = siblings.firstIndex(where: { $0.id == edge.id }) ?? 0
        let count = max(siblings.count, 1)
        let dx = toShape.position.x - fromShape.position.x
        let dy = toShape.position.y - fromShape.position.y
        let baseAngle = atan2(dy, dx)
        let spreadStep: CGFloat = 0.5
        let angle = baseAngle + (CGFloat(idx) - CGFloat(count - 1) / 2) * spreadStep
        let start = edgePoint(for: fromShape, towards: toShape.position)
        let stubLen: CGFloat = 62
        let end = CGPoint(x: start.x + stubLen * cos(angle),
                          y: start.y + stubLen * sin(angle))
        return (start, end)
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
                // v48 Fel #4 / v63: Stub-linjer per KOLLAPSAD GREN (kant i
                // collapsedEdgeIds, from synlig). Solfjäder-spridning när flera
                // grenar från samma nod är kollapsade (Kims fynd: badges på varandra).
                for edge in edges where (collapsedEdgeIds.contains(edge.id)
                                         && !hiddenShapeIds.contains(edge.from)) {
                    guard let fromShape = shapes.first(where: { $0.id == edge.from }),
                          let toShape   = shapes.first(where: { $0.id == edge.to })
                    else { continue }
                    let geo = stubGeometry(for: edge, fromShape: fromShape, toShape: toShape)
                    let stubColor: Color = edge.colorHex.flatMap { Color(hexString: $0) }
                        ?? Color(hex: 0x3a3f47)
                    var stub = Path()
                    stub.move(to: geo.start)
                    stub.addLine(to: geo.end)
                    context.stroke(stub, with: .color(stubColor.opacity(0.5)),
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

            // v48 Fel #3+#4 / v63: Collapse-badges PER GREN.
            // Minus: på utgående o-kollapsad kant, BARA när from är markerad —
            //        kollapsar bara DEN grenen. Förskjuten vinkelrätt från linjen
            //        (Kims fynd: låg ihop med midpoint-ikonen).
            // Plus:  vid stub-änden för varje kollapsad gren, alltid synlig.
            ForEach(edges) { edge in
                if let fromShape = shapes.first(where: { $0.id == edge.from }),
                   let toShape   = shapes.first(where: { $0.id == edge.to }),
                   !hiddenShapeIds.contains(edge.from) {
                    let isCollapsed = collapsedEdgeIds.contains(edge.id)
                    let isFromSelected = (selectedShapeId == edge.from)
                    if isCollapsed {
                        let geo = stubGeometry(for: edge, fromShape: fromShape, toShape: toShape)
                        EdgeStubBadge(position: geo.end,
                                      canvasScale: canvasScale,
                                      onTap: { onToggleCollapseEdge(edge.id) })
                    } else if isFromSelected, !hiddenShapeIds.contains(edge.to) {
                        // v67: minus-badgen sitter vid pilens UTGÅNGSPUNKT på
                        // källnodens kant (inte mitt på pilen) och bara när noden
                        // är markerad — Kims fynd 3. Pilen blir ren i normalläge.
                        EdgeStartCollapseBadge(
                            position: minusBadgePosition(edge: edge,
                                                         fromShape: fromShape,
                                                         toShape: toShape),
                            canvasScale: canvasScale,
                            onTap: { onToggleCollapseEdge(edge.id) })
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
                    initialPlacement: edge.labelPlacement,
                    onSave: { newLabel, newPlacement in
                        onEdgeRename(id, newLabel, newPlacement)
                        renamingEdgeId = nil
                    },
                    onCancel: { renamingEdgeId = nil }
                )
            }
        }
    }

    /// v67: minus-badgens position — vid pilens UTGÅNGSPUNKT på källnodens kant
    /// (inte mitt på pilen). Liten radiell knuff utåt + vinkelrätt så den ligger
    /// på kanten utan att täcka linjen. Flera grenar lämnar olika perimeter-
    /// punkter → badges hamnar naturligt isär (Kims fynd 3).
    private func minusBadgePosition(edge: EdgeConnection,
                                    fromShape: ShapeNode,
                                    toShape: ShapeNode) -> CGPoint {
        let anchors = edgeAnchors(edge: edge, fromShape: fromShape, toShape: toShape)
        let dx = anchors.start.x - fromShape.position.x
        let dy = anchors.start.y - fromShape.position.y
        let len = max(hypot(dx, dy), 0.001)
        let tx = dx / len, ty = dy / len                 // radiell riktning utåt från noden
        var px = -ty, py = tx                             // vinkelrät mot utgångsriktningen
        if py > 0 { px = -px; py = -py }                 // peka uppåt på skärmen
        return CGPoint(x: anchors.start.x + tx * 6 + px * 16,
                       y: anchors.start.y + ty * 6 + py * 16)
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
        let size: CGFloat = DesignTokens.screenPt(16, scale: canvasScale)
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
            // v63: färg på pilen — emoji syns i iOS-menyer (ikoner blir mallfärgade)
            Menu {
                Button("⚫️ Standard") { onEdgeSetColor(edge.wrappedValue.id, nil) }
                Button("🔴 Röd")      { onEdgeSetColor(edge.wrappedValue.id, "#b91c1c") }
                Button("🔵 Blå")      { onEdgeSetColor(edge.wrappedValue.id, "#1d4ed8") }
                Button("🟢 Grön")     { onEdgeSetColor(edge.wrappedValue.id, "#15803d") }
                Button("🟠 Orange")   { onEdgeSetColor(edge.wrappedValue.id, "#c2410c") }
                Button("🟣 Lila")     { onEdgeSetColor(edge.wrappedValue.id, "#6d28d9") }
                Button("🟡 Gul")      { onEdgeSetColor(edge.wrappedValue.id, "#a16207") }
                Button("⚪️ Grå")      { onEdgeSetColor(edge.wrappedValue.id, "#6b7280") }
            } label: {
                Label("Färg på pilen", systemImage: "paintpalette")
            }
            // v64: välj vilken sida pilen går ut från (ersätter de fyra handtagen)
            Menu {
                Button { onEdgeSetFromSide(edge.wrappedValue.id, nil) } label: {
                    Label("Automatisk (närmaste sida)", systemImage: "sparkles")
                }
                Button { onEdgeSetFromSide(edge.wrappedValue.id, .top) } label: {
                    Label("Uppåt", systemImage: "arrow.up")
                }
                Button { onEdgeSetFromSide(edge.wrappedValue.id, .right) } label: {
                    Label("Höger", systemImage: "arrow.right")
                }
                Button { onEdgeSetFromSide(edge.wrappedValue.id, .bottom) } label: {
                    Label("Neråt", systemImage: "arrow.down")
                }
                Button { onEdgeSetFromSide(edge.wrappedValue.id, .left) } label: {
                    Label("Vänster", systemImage: "arrow.left")
                }
            } label: {
                Label("Går ut från", systemImage: "arrow.up.right.square")
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
        // v38: kant-etikett vid midpoint. v62: ovanför/under enligt labelPlacement.
        if !label.isEmpty {
            let labelOffset = size * 0.85 + 8 / canvasScale
            let labelY = edge.wrappedValue.labelPlacement == .above
                ? mid.y - labelOffset
                : mid.y + labelOffset
            Text(label)
                .font(.system(size: max(8, 10 / canvasScale), weight: .medium, design: .rounded))
                .foregroundStyle(Color.accentColor)
                .lineLimit(1)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(Color(.systemBackground).opacity(0.88))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .allowsHitTesting(false)
                .position(CGPoint(x: mid.x, y: labelY))
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

        // Start-/slutpunkter på formernas ytor.
        // v64: vald utgångssida (fromSide) vinner över automatiken.
        let start: CGPoint
        let end: CGPoint
        if let wp = edge.waypoints.first {
            start = edge.fromSide.map { sidePoint(for: fromShape, side: $0) }
                ?? edgePoint(for: fromShape, towards: wp.point)
            end   = edgePoint(for: toShape,   towards: wp.point)
        } else {
            start = edge.fromSide.map { sidePoint(for: fromShape, side: $0) }
                ?? edgePoint(for: fromShape, towards: toShape.position)
            end   = edgePoint(for: toShape,   towards: fromShape.position)
        }

        // Bezier-kontrollpunkter baserade på ytornas normalvektorer (Lucidchart-stil).
        // v66: delad vinkelmedveten matte (EdgeMath) — rund båge även när
        // fromSide-normalen pekar bort från målet.
        let n1 = outwardNormal(for: fromShape, at: start)
        let n2 = outwardNormal(for: toShape,   at: end)
        let cps = EdgeMath.controlPoints(start: start, end: end, n1: n1, n2: n2)
        var cp1 = cps.cp1
        var cp2 = cps.cp2

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

        // Pilhuvud-vinklar.
        // v62: spetsen följer den SYNLIGA linjens riktning vid änden — sampla kurvan
        // nära spetsen (t=0.92/0.08) med de FAKTISKA kontrollpunkterna (inkl. routade).
        // v60 låste vinkeln till sidans inåt-normal, vilket gjorde spetsen skev när
        // linjen kom in diagonalt (Kims fynd i v61.2): linje och spets pekade åt olika
        // håll. Near-endpoint-sampling är numeriskt stabil även för korta pilar
        // (v50.2-resonemanget); normal-vinkeln behålls bara som fallback om samplet
        // degenererar (sammanfallande punkter).
        let nearEnd: CGPoint
        let nearStart: CGPoint
        if let wp = edge.waypoints.first {
            nearEnd   = Self.quadBezier(t: 0.92, p0: wp.point, p1: cp2, p2: end)
            nearStart = Self.quadBezier(t: 0.08, p0: start, p1: cp1, p2: wp.point)
        } else {
            nearEnd   = Self.cubicBezier(t: 0.92, p0: start, p1: cp1, p2: cp2, p3: end)
            nearStart = Self.cubicBezier(t: 0.08, p0: start, p1: cp1, p2: cp2, p3: end)
        }
        let endVec   = CGPoint(x: end.x - nearEnd.x,     y: end.y - nearEnd.y)
        let startVec = CGPoint(x: start.x - nearStart.x, y: start.y - nearStart.y)
        let endAngle   = hypot(endVec.x, endVec.y) > 0.01
            ? atan2(endVec.y, endVec.x)   : atan2(-n2.y, -n2.x)
        let startAngle = hypot(startVec.x, startVec.y) > 0.01
            ? atan2(startVec.y, startVec.x) : atan2(-n1.y, -n1.x)

        // v63: linjen slutar BAKOM spetsens bas (11pt från tip; basen ligger ~12.6pt
        // från tip) — så varken .round-cap eller strecket syns genom spetsen.
        // Allt ritas i SAMMA solida färg → ser ut som EN pil. (Ersätter v48:s
        // halfLW-indrag som lät strecket lysa igenom den halvtransparenta spetsen.)
        let headInset: CGFloat = 11
        let endHasHead   = (edge.direction == .forward  || edge.direction == .bidirectional)
        let startHasHead = (edge.direction == .backward || edge.direction == .bidirectional)
        let lineEnd: CGPoint = endHasHead
            ? CGPoint(x: end.x - headInset * cos(endAngle),
                      y: end.y - headInset * sin(endAngle))
            : end
        let lineStart: CGPoint = startHasHead
            ? CGPoint(x: start.x - headInset * cos(startAngle),
                      y: start.y - headInset * sin(startAngle))
            : start

        // v63: pilens färg — egen hex eller standard. Solid (ingen opacity).
        let edgeColor: Color = edge.colorHex.flatMap { Color(hexString: $0) }
            ?? Color(hex: 0x3a3f47)

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
        context.stroke(path, with: .color(edgeColor), style: strokeStyle)

        // Pilhuvuden ritas vid ORIGINAL end/start (linjen slutar vid spetsbasen)
        switch edge.direction {
        case .forward:       drawArrowHead(context: context, tip: end,   angle: endAngle, color: edgeColor)
        case .backward:      drawArrowHead(context: context, tip: start, angle: startAngle, color: edgeColor)
        case .bidirectional:
            drawArrowHead(context: context, tip: end,   angle: endAngle, color: edgeColor)
            drawArrowHead(context: context, tip: start, angle: startAngle, color: edgeColor)
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
        case .rectangle, .table, .pill, .square, .processArrow, .container, .octagon, .phoneFrame, .triangle, .cylinder:
            localPoint = rectSideCenter(center: center, dx: dx, dy: dy, shape: shape)
        case .line, .arrow:
            return center
        }
        // Rotera resultatet tillbaka till world-space
        return canvasRotatePoint(localPoint, around: center, byDegrees: shape.rotation)
    }

    /// v64: punkt mitt på en VALD sida (i stället för närmaste) — med rotationsstöd.
    /// Används när användaren valt utgångssida via pilens kontextmeny.
    private func sidePoint(for shape: ShapeNode, side: EdgeSide) -> CGPoint {
        let center = shape.position
        let hw: CGFloat
        let hh: CGFloat
        switch shape.type {
        case .circle, .link:
            let r = ShapeGeometry.circleRadius(for: shape)
            hw = r; hh = r
        case .line, .arrow:
            return center
        default:
            hw = ShapeGeometry.halfWidth(for: shape)
            hh = ShapeGeometry.halfHeight(for: shape)
        }
        let local: CGPoint
        switch side {
        case .top:    local = CGPoint(x: center.x,      y: center.y - hh)
        case .bottom: local = CGPoint(x: center.x,      y: center.y + hh)
        case .left:   local = CGPoint(x: center.x - hw, y: center.y)
        case .right:  local = CGPoint(x: center.x + hw, y: center.y)
        }
        return canvasRotatePoint(local, around: center, byDegrees: shape.rotation)
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

    /// v62: kvadratisk bezier — för pilspets-vinkeln på waypoint-kanter
    /// (de ritas som två quad-segment, se drawEdge).
    static func quadBezier(t: CGFloat, p0: CGPoint, p1: CGPoint, p2: CGPoint) -> CGPoint {
        let u = 1 - t
        return CGPoint(
            x: u * u * p0.x + 2 * u * t * p1.x + t * t * p2.x,
            y: u * u * p0.y + 2 * u * t * p1.y + t * t * p2.y
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
            start = edge.fromSide.map { sidePoint(for: fromShape, side: $0) }
                ?? edgePoint(for: fromShape, towards: wp.point)
            end   = edgePoint(for: toShape,   towards: wp.point)
        } else {
            start = edge.fromSide.map { sidePoint(for: fromShape, side: $0) }
                ?? edgePoint(for: fromShape, towards: toShape.position)
            end   = edgePoint(for: toShape,   towards: fromShape.position)
        }
        let n1 = outwardNormal(for: fromShape, at: start)
        let n2 = outwardNormal(for: toShape,   at: end)
        // v66: SAMMA delade matte som drawEdge — annars hamnar midpoint-handtaget
        // bredvid den synliga kurvan.
        let cps = EdgeMath.controlPoints(start: start, end: end, n1: n1, n2: n2)
        var cp1 = cps.cp1
        var cp2 = cps.cp2
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

    /// v28: pilhuvuden. v63: SOLID i samma färg som linjen (ingen opacity) —
    /// strecket kan inte lysa igenom; pil + linje ser ut som EN enhet.
    private func drawArrowHead(context: GraphicsContext, tip: CGPoint, angle: CGFloat,
                               color: Color) {
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
        context.fill(head, with: .color(color))
    }
}
