import SwiftUI

/// v26 Toolbar — egen drag-controller istället för Apple's draggable/dropDestination.
/// Shape-chip-gesture är en manuell DragGesture(coordinateSpace: .global)
/// med tap-vs-drag-distinktion (translation-magnitude < 8pt = tap).

enum SecondaryToolbarRow: Equatable {
    case shapes
    case colors
    case textStyles
    /// v31: form-paket-rad (visar UI-pack + Prompt-Process-pack-toggles)
    case packs
    /// v39: multi-select-operationer (duplicera, ta bort, align)
    case multiSelect
}

struct ToolbarView: View {
    @ObservedObject var model: CanvasModel
    /// v34: aktivt chip-drag — uppdateras av manuell DragGesture på shape-chips.
    /// ContentView ritar flytande chip-preview vid `chipDragState.globalLocation`
    /// och konverterar global → canvas-koord vid drop-end via viewportState.
    @ObservedObject var chipDragState: ChipDragState
    /// v34: synkroniserad spegel av UIScrollView's pan/zoom — för att konvertera
    /// global drop-koord till canvas-koord SYNKRONT vid drag-end.
    @ObservedObject var viewportState: CanvasViewportState
    /// v34: drop-handler. Anropas i chip.DragGesture.onEnded med (type, canvasPoint).
    var onDropShape: (ShapeType, CGPoint) -> Void
    let canvasCenter: CGPoint
    let zoomPercent: Int
    var hasOpenFile: Bool
    // v46: onStartEdgeMode/onCancelEdgeMode borttagna — anropades aldrig
    // efter att long-press ersattes av ConnectionHandle i v44.
    var onOpen: () -> Void
    var onSave: () -> Void
    var onSaveAs: () -> Void
    var onUndo: () -> Void
    var onShowCode: () -> Void
    /// v61: kopiera hela dokumentet till urklipp utan sheet (1 tryck).
    var onCopyCode: () -> Void
    var onShowRules: () -> Void
    var onToggleMarker: () -> Void
    var onAddTable: () -> Void
    var onAddJumpLink: () -> Void
    var onNewCanvas: () -> Void
    var onResetZoom: () -> Void
    /// v31: visa anteckning-popup-sheet med all canvas-text.
    var onShowNotePopup: () -> Void
    /// v37: importera Mermaid från AI.
    var onImportMermaid: () -> Void
    /// v39: multi-select-operationer
    var onDuplicateSelection: () -> Void
    var onDeleteSelection: () -> Void
    var onAlignHorizontal: () -> Void
    var onAlignVertical: () -> Void
    /// v60: layout-axel — .horizontal (porträtt: topp-bar) eller .vertical (landskap: vänster sidebar).
    var axis: Axis = .horizontal

    @State private var secondaryRow: SecondaryToolbarRow? = nil
    @State private var showSizePicker = false   // v40: textstorlek-popup

    var body: some View {
        // v39: visa multi-select-operationer automatiskt när markerMode är aktivt
        let activeRow: SecondaryToolbarRow? = model.markerMode ? .multiSelect : secondaryRow
        if axis == .vertical {
            // v60: landskap — vänster vertikal sidebar (ligger som overlay över canvas).
            // Primärkolumn till vänster; sekundär-panel öppnas till höger om den.
            HStack(alignment: .top, spacing: 6) {
                primaryControls(vertical: true)
                    .padding(8)
                    .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.primary.opacity(0.08), lineWidth: 0.5))
                if let row = activeRow {
                    secondaryRowView(row)
                        .padding(8)
                        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.primary.opacity(0.08), lineWidth: 0.5))
                }
            }
        } else {
            VStack(spacing: 0) {
                primaryControls(vertical: false)
                    .padding(.horizontal, 10).padding(.vertical, 8)
                if let row = activeRow {
                    secondaryRowView(row)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .move(edge: .top))
                        ))
                }
            }
            .background(Color(.systemBackground))
        }
    }

    // MARK: - Primary rad

    /// v60: primärkontrollerna i axel-medveten layout (HStack i porträtt, VStack i landskap).
    @ViewBuilder
    private func primaryControls(vertical: Bool) -> some View {
        let layout = vertical
            ? AnyLayout(VStackLayout(spacing: 6))
            : AnyLayout(HStackLayout(spacing: 4))
        layout {
            toggleButton("square.on.circle", row: .shapes, accId: "toolbar.shapes")
            toggleButton("swatchpalette", row: .packs, accId: "toolbar.packs")
            toggleButton("paintpalette", row: .colors, disabled: model.selectedShapeId == nil, accId: "toolbar.colors")
            toggleButton("textformat.size", row: .textStyles, disabled: model.selectedShapeId == nil, accId: "toolbar.textStyles")
            // v39: multi-select direkt i toolbar
            markerButton
            if !vertical { Spacer(minLength: 0) }
            zoomBadge
            undoButton
            LägenMenu(
                model: model,
                hasOpenFile: hasOpenFile,
                onSave: onSave,
                onSaveAs: onSaveAs,
                onOpen: onOpen,
                onNewCanvas: onNewCanvas,
                onShowCode: onShowCode,
                onCopyCode: onCopyCode,
                onShowRules: onShowRules,
                onToggleMarker: onToggleMarker,
                onImportMermaid: onImportMermaid
            )
        }
    }

    @ViewBuilder
    private func toggleButton(_ systemImage: String,
                              row: SecondaryToolbarRow,
                              disabled: Bool = false,
                              accId: String) -> some View {
        Button {
            // v33 Apple-nivå: haptic feedback vid toggle (light impact = avslappnad känsla)
            #if canImport(UIKit)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
            // v33 Apple-nivå: smooth spring-animation vid expand/collapse
            withAnimation(.smooth(duration: 0.25)) {
                if secondaryRow == row {
                    secondaryRow = nil
                } else {
                    secondaryRow = row
                }
            }
        } label: {
            ToolbarIconButton(systemImage: systemImage,
                              isActive: secondaryRow == row)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.35 : 1)
        .accessibilityIdentifier(accId)
        .accessibilityLabel(a11yLabel(for: accId))
    }

    @ViewBuilder
    private var markerButton: some View {
        Button(action: onToggleMarker) {
            ToolbarIconButton(systemImage: "rectangle.dashed",
                              isActive: model.markerMode)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("toolbar.marker")
        .accessibilityLabel(a11yLabel(for: "toolbar.marker"))
    }

    @ViewBuilder
    private var undoButton: some View {
        Button(action: onUndo) {
            ToolbarIconButton(systemImage: "arrow.uturn.backward",
                              isActive: false,
                              foregroundColor: model.canUndo ? .primary : .secondary.opacity(0.4))
        }
        .buttonStyle(.plain)
        .disabled(!model.canUndo)
        .accessibilityIdentifier("toolbar.undo")
        .accessibilityLabel(a11yLabel(for: "toolbar.undo"))
    }

    @ViewBuilder
    private var zoomBadge: some View {
        Button(action: onResetZoom) {
            Text("\(zoomPercent)%")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color.primary.opacity(0.7))
                // v33 polish: 48→40 så zoom-badge tar mindre plats i primary-raden
                .frame(minWidth: 40, minHeight: 28)
                .background(Capsule().fill(.ultraThinMaterial))
                .overlay(Capsule().stroke(Color.primary.opacity(0.08), lineWidth: 0.5))
                // v50.7 UX-006: tap-ytan ≥44pt (Apple-minimum) — kapseln förblir
                // visuellt kompakt, men träffytan runt den är full 44×44.
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("toolbar.zoom")
        .accessibilityLabel(a11yLabel(for: "toolbar.zoom"))
        .accessibilityValue(diagnosticsValue)
    }

    /// v27: testdiagnostik — rapporterar shape-count + position på senaste form
    /// så XCUITest kan verifiera att drag-ut placerar formen exakt rätt.
    private var diagnosticsValue: String {
        let count = model.shapes.count
        if let last = model.shapes.last {
            return "shapeCount=\(count);lastX=\(Int(last.position.x));lastY=\(Int(last.position.y))"
        }
        return "shapeCount=\(count)"
    }

    // MARK: - Sekundär rad

    @ViewBuilder
    private func secondaryRowView(_ row: SecondaryToolbarRow) -> some View {
        HStack(spacing: 8) {
            switch row {
            case .shapes:      shapesSecondary
            case .colors:      colorsSecondary
            case .textStyles:  textStylesSecondary
            case .packs:       packsSecondary
            case .multiSelect: multiSelectSecondary
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Former-rad (tap + drag-out via egen controller)

    /// v36: två rader med alla 12 former.
    /// Rad A (7): circle, rectangle, square, diamond, pill, triangle, processArrow
    /// Rad B (5): text, table, link, line, notePopup
    /// HStack (INTE ScrollView) — ScrollView konsumerar tap-events på iPhone (v29-lärdom).
    @ViewBuilder
    private var shapesSecondary: some View {
        VStack(spacing: 8) {
            // v60: ALLA 8 geometriska former på ÖVERSTA raden (Kims önskemål).
            // 40pt-frame + 6pt mellanrum ryms i porträtt; tap-yta ≥44pt via contentShape-inset.
            HStack(spacing: 6) {
                geoChip(.circle, accId: "chip.circle", frame: 40) { model.addShape(.circle, at: canvasCenter) }
                geoChip(.pill, accId: "chip.pill", frame: 40) { model.addShape(.pill, at: canvasCenter) }
                geoChip(.rectangle, accId: "chip.rectangle", frame: 40) { model.addShape(.rectangle, at: canvasCenter) }
                geoChip(.square, accId: "chip.square", frame: 40) { model.addShape(.square, at: canvasCenter) }
                geoChip(.container, accId: "chip.container", frame: 40) { model.addShape(.container, at: canvasCenter) }
                geoChip(.diamond, accId: "chip.diamond", frame: 40) { model.addShape(.diamond, at: canvasCenter) }
                geoChip(.processArrow, accId: "chip.processArrow", frame: 40) { model.addShape(.processArrow, at: canvasCenter) }
                geoChip(.octagon, accId: "chip.octagon", frame: 40) { model.addShape(.octagon, at: canvasCenter) }
            }
            // Rad B — verktyg (tabell, länk, linje, anteckningar)
            HStack(spacing: 8) {
                shapeChip(.table, "tablecells",        accId: "chip.table", onTap: onAddTable)
                shapeChip(.link,  "link",              accId: "chip.link",  onTap: onAddJumpLink)
                shapeChip(.line,  "minus",             accId: "chip.line") {
                    model.addFreeLine(at: canvasCenter, withArrow: false)
                }
                Button {
                    onShowNotePopup()
                } label: {
                    ChipFace(systemImage: "bubble.left.and.text.bubble.right")
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("chip.notepopup")
                .accessibilityLabel(a11yLabel(for: "chip.notepopup"))
            }
        }
        .padding(.horizontal, 2)
    }

    /// v51.1: enhetlig geometri-chip. Storlek via `iconSize` (canvas-proportion) +
    /// rätt SwiftUI-form per typ. Gör chip-raderna kompakta och trivialt omordningsbara.
    @ViewBuilder
    private func geoChip(_ type: ShapeType, accId: String, frame: CGFloat = 44, onTap: @escaping () -> Void) -> some View {
        shapeChipGeneric(type: type, accId: accId, onTap: onTap) {
            let s = DesignTokens.Chip.iconSize(for: type)
            ZStack { geoChipShape(type, size: s) }
                .frame(width: frame, height: frame)
                .background(Circle().fill(.ultraThinMaterial))
                .overlay(Circle().stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
                // v60: behåll ≥44pt tap-yta även om frame krymps till 40 (8-på-rad).
                .contentShape(Circle().inset(by: min(0, (frame - 44) / 2)))
        }
    }

    @ViewBuilder
    private func geoChipShape(_ type: ShapeType, size s: CGSize) -> some View {
        let stroke = DesignTokens.Shape.chipStrokeWidth
        switch type {
        case .circle:
            Circle().stroke(Color.primary, lineWidth: stroke).frame(width: s.height, height: s.height)
        case .pill:
            Capsule(style: .continuous).stroke(Color.primary, lineWidth: stroke).frame(width: s.width, height: s.height)
        case .rectangle:
            RoundedRectangle(cornerRadius: DesignTokens.Shape.cornerRadius(for: .rectangle, height: s.height), style: .continuous)
                .stroke(Color.primary, lineWidth: stroke).frame(width: s.width, height: s.height)
        case .square:
            SquareShape().stroke(Color.primary, lineWidth: stroke).frame(width: s.width, height: s.height)
        case .container:
            // v60: mini Lucidchart-container — färgad header-remsa + ljus kropp + solid ram.
            VStack(spacing: 0) {
                Rectangle().fill(Color.primary).frame(height: max(4, s.height * 0.30))
                Rectangle().fill(Color.primary.opacity(0.06))
            }
            .frame(width: s.width, height: s.height)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.Shape.cornerRadius(for: .container, height: s.height), style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: DesignTokens.Shape.cornerRadius(for: .container, height: s.height), style: .continuous).stroke(Color.primary, lineWidth: stroke))
        case .diamond:
            DiamondShape().stroke(Color.primary, lineWidth: stroke).frame(width: s.width, height: s.height)
        case .processArrow:
            ProcessArrowShape().stroke(Color.primary, lineWidth: stroke).frame(width: s.width, height: s.height)
        case .octagon:
            OctagonShape().stroke(Color.primary, lineWidth: stroke).frame(width: s.width, height: s.height)
        default:
            EmptyView()
        }
    }

    /// v29: pack-chip — tap lägger rektangel med pack:s default-kategori.
    /// Stödjer inte drag-ut (drag är för basformer); pack-chips är ett snabbsätt
    /// att lägga form med rätt kategori vid canvas-mitten.
    @ViewBuilder
    private func packChip(pack: ShapePack, category: ShapeCategory) -> some View {
        Button {
            model.addShape(.rectangle, at: canvasCenter, category: category)
        } label: {
            ChipFace(systemImage: pack.systemImage)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("chip.pack.\(pack.rawValue)")
        .accessibilityLabel(a11yLabel(for: "chip.pack.\(pack.rawValue)"))
    }

    /// v31: Form-paket-rad — togglar för UI och Prompt-Process.
    @ViewBuilder
    private var packsSecondary: some View {
        HStack(spacing: 10) {
            ForEach(ShapePack.userToggleable, id: \.self) { pack in
                packToggle(pack)
            }
        }
        .padding(.horizontal, 2)
    }

    @ViewBuilder
    private func packToggle(_ pack: ShapePack) -> some View {
        let isActive = model.activeShapePacks.contains(pack)
        Button {
            model.toggleShapePack(pack)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: pack.systemImage).font(.subheadline)
                Text(pack.displayName).font(.subheadline.weight(.medium))
                if isActive {
                    Image(systemName: "checkmark").font(.caption.weight(.bold))
                }
            }
            .foregroundStyle(isActive ? Color.white : Color.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(isActive ? Color.accentColor : Color(.systemBackground))
            )
            .overlay(Capsule().stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("toggle.pack.\(pack.rawValue)")
    }

    // MARK: - Multi-select-rad (v39)

    /// Operationsrad som visas automatiskt när markerMode är aktivt.
    @ViewBuilder
    private var multiSelectSecondary: some View {
        let count = model.multiSelection.count
        HStack(spacing: 10) {
            // Räknare — hur många former är markerade
            Text("\(count) markerade")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(minWidth: 70)

            Divider().frame(height: 28)

            // Duplicera
            multiSelectButton("plus.square.on.square", label: "Duplicera",
                               disabled: count == 0) { onDuplicateSelection() }

            // Ta bort
            multiSelectButton("trash", label: "Ta bort",
                               disabled: count == 0, destructive: true) { onDeleteSelection() }

            Divider().frame(height: 28)

            // Align horisontellt (dela vertikalt centrallinje)
            multiSelectButton("align.horizontal.center", label: "Centrera H",
                               disabled: count < 2) { onAlignHorizontal() }

            // Align vertikalt (dela horisontellt centrallinje)
            multiSelectButton("align.vertical.center", label: "Centrera V",
                               disabled: count < 2) { onAlignVertical() }
        }
    }

    @ViewBuilder
    private func multiSelectButton(_ icon: String,
                                   label: String,
                                   disabled: Bool,
                                   destructive: Bool = false,
                                   action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                Text(label)
                    .font(.system(size: 9, weight: .medium))
            }
            .foregroundStyle(disabled ? .secondary.opacity(0.4) : (destructive ? .red : Color.primary))
            .frame(minWidth: 44, minHeight: 44)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    /// v34: shapeChip använder MANUELL DragGesture(coordinateSpace: .global)
    /// — Apple's .draggable + .dropDestination fungerar inte pålitligt inuti
    /// UIViewRepresentable runt UIScrollView (iOS drag-system kan inte alltid
    /// koppla draggable-source till dropDestination-target genom UIKit-wrappers).
    ///
    /// Flöde:
    /// 1. Chip's DragGesture.onChanged sätter chipDragState.activeType + location
    /// 2. ContentView ritar flytande chip-preview vid location
    /// 3. .onEnded: ContentView läser location, konverterar via viewportState
    ///    och anropar handleDrop. Eller chipsens egen onEnded gör det direkt.
    @ViewBuilder
    /// v50.7 UX-001/010/013: människo-läsbara VoiceOver-labels per accId.
    /// Utan dessa läste VoiceOver råa SF Symbol-namn ("swatchpalette") eller
    /// chip-id:t ("chip circle"). accId behålls separat för UI-tester.
    private func a11yLabel(for accId: String) -> String {
        switch accId {
        case "toolbar.shapes": return "Former"
        case "toolbar.packs": return "Formpaket"
        case "toolbar.colors": return "Färg"
        case "toolbar.textStyles": return "Textstil"
        case "toolbar.marker": return "Markera flera"
        case "toolbar.undo": return "Ångra"
        case "toolbar.zoom": return "Zooma till 100 procent"
        case "chip.circle": return "Cirkel"
        case "chip.rectangle": return "Rektangel"
        case "chip.square": return "Kvadrat"
        case "chip.diamond": return "Romb"
        case "chip.pill": return "Kapsel"
        case "chip.processArrow": return "Processpil"
        case "chip.container": return "Behållare"
        case "chip.table": return "Tabell"
        case "chip.link": return "Hopplänk"
        case "chip.line": return "Linje"
        case "chip.octagon": return "Åttahörning"
        case "chip.notepopup": return "Visa anteckningar"
        default:
            if accId.hasPrefix("chip.pack.") || accId.hasPrefix("toggle.pack.") { return "Formpaket" }
            return accId
        }
    }

    private func shapeChip(_ type: ShapeType,
                           _ system: String,
                           accId: String,
                           onTap: @escaping () -> Void) -> some View {
        ChipFace(systemImage: system)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 8, coordinateSpace: .global)
                    .onChanged { value in
                        if chipDragState.activeType != type {
                            chipDragState.activeType = type
                        }
                        chipDragState.globalLocation = value.location
                    }
                    .onEnded { value in
                        // SYNKRONT: läs viewportState (UIScrollView's offset/scale/frame)
                        // och konvertera global drop-position → canvas-koord. Eftersom
                        // viewportState uppdateras SYNKRONT i delegate-callbacks läser
                        // vi exakt det värde som scrollViewen visar just nu — ingen race.
                        let global = value.location
                        chipDragState.globalLocation = global
                        chipDragState.activeType = nil
                        // Släpp inom canvas → kalla onDropShape med canvas-koord.
                        // Släpp utanför → ingen åtgärd (drag avbryts).
                        if viewportState.isInsideCanvas(global),
                           let canvasPoint = viewportState.canvasPoint(forGlobal: global) {
                            onDropShape(type, canvasPoint)
                        }
                    }
            )
            .onTapGesture { onTap() }
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(Text(a11yLabel(for: accId)))
            .accessibilityIdentifier(accId)
    }

    /// Generic shapeChip som tar en valfri face-view (används t.ex. för diamant med custom-ritad form).
    @ViewBuilder
    private func shapeChipGeneric<F: View>(
        type: ShapeType,
        accId: String,
        onTap: @escaping () -> Void,
        @ViewBuilder face: () -> F
    ) -> some View {
        face()
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 8, coordinateSpace: .global)
                    .onChanged { value in
                        if chipDragState.activeType != type {
                            chipDragState.activeType = type
                        }
                        chipDragState.globalLocation = value.location
                    }
                    .onEnded { value in
                        let global = value.location
                        chipDragState.globalLocation = global
                        chipDragState.activeType = nil
                        if viewportState.isInsideCanvas(global),
                           let canvasPoint = viewportState.canvasPoint(forGlobal: global) {
                            onDropShape(type, canvasPoint)
                        }
                    }
            )
            .onTapGesture { onTap() }
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(Text(a11yLabel(for: accId)))
            .accessibilityIdentifier(accId)
    }


    // MARK: - Färg-rad

    @ViewBuilder
    private var colorsSecondary: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(ColorPack.all) { pack in
                    colorChip(pack)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    @ViewBuilder
    private func colorChip(_ pack: ColorPack) -> some View {
        let isCurrent: Bool = {
            guard let id = model.selectedShapeId,
                  let s = model.shapes.first(where: { $0.id == id }) else { return false }
            return (pack.id == "none" && s.colorPackId == nil) || pack.id == s.colorPackId
        }()
        Button {
            applyColorPack(pack)
        } label: {
            ZStack {
                Circle()
                    .fill(pack.fillColor)
                    .overlay(Circle().stroke(pack.strokeColor, lineWidth: 1.5))
                if isCurrent {
                    Circle().stroke(Color.accentColor, lineWidth: 2.5)
                }
                if pack.id == "none" {
                    Image(systemName: "slash.circle")
                        .font(.caption)
                        .foregroundStyle(Color.secondary)
                }
            }
            .frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
    }

    private func applyColorPack(_ pack: ColorPack) {
        guard let id = model.selectedShapeId,
              let idx = model.shapes.firstIndex(where: { $0.id == id }) else { return }
        model.shapes[idx].colorPackId = pack.id == "none" ? nil : pack.id
    }

    // MARK: - Textstil-rad (v40: storlek som popup + fet-knapp)

    @ViewBuilder
    private var textStylesSecondary: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                // v40: En storlek-knapp → popup med R1/R2/R3/Aa
                let currentStyle = selectedShape?.textStyle ?? .body
                Button { showSizePicker = true } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "textformat.size")
                            .font(.system(size: 15, weight: .medium))
                        Text(stylePreview(currentStyle))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .confirmationDialog("Textstorlek", isPresented: $showSizePicker, titleVisibility: .visible) {
                    ForEach(TextStyle.allCases) { st in
                        Button(st.displayName) { applyTextStyle(st) }
                    }
                    Button("Avbryt", role: .cancel) {}
                }

                // v40: Fet-knapp (togglar mellan r1 och body)
                textActionButton(
                    icon: "bold",
                    label: "Fet",
                    active: selectedShape?.textStyle == .r1
                ) {
                    guard let id = model.selectedShapeId,
                          let idx = model.shapes.firstIndex(where: { $0.id == id }) else { return }
                    let current = model.shapes[idx].textStyle
                    model.shapes[idx].textStyle = current == .r1 ? .body : .r1
                }

                Divider().frame(height: 28).padding(.horizontal, 2)

                // Punktlista
                textActionButton(
                    icon: "list.bullet",
                    label: "Punkter",
                    active: selectedShape?.hasBullets == true && selectedShape?.hasNumberedList == false
                ) {
                    guard let id = model.selectedShapeId,
                          let idx = model.shapes.firstIndex(where: { $0.id == id }) else { return }
                    let on = !(model.shapes[idx].hasBullets)
                    model.shapes[idx].hasBullets = on
                    if on { model.shapes[idx].hasNumberedList = false }
                }

                // Numrerad lista
                textActionButton(
                    icon: "list.number",
                    label: "Numrerad",
                    active: selectedShape?.hasNumberedList == true
                ) {
                    guard let id = model.selectedShapeId,
                          let idx = model.shapes.firstIndex(where: { $0.id == id }) else { return }
                    let on = !(model.shapes[idx].hasNumberedList)
                    model.shapes[idx].hasNumberedList = on
                    if on { model.shapes[idx].hasBullets = false }
                }

                Divider().frame(height: 28).padding(.horizontal, 2)

                // v46: Textjustering L/C/R
                textActionButton(
                    icon: "text.alignleft",
                    label: "Vänster",
                    active: selectedShape?.textAlignment == .leading
                ) {
                    guard let id = model.selectedShapeId,
                          let idx = model.shapes.firstIndex(where: { $0.id == id }) else { return }
                    model.shapes[idx].textAlignment = .leading
                }
                textActionButton(
                    icon: "text.aligncenter",
                    label: "Centrera",
                    active: selectedShape?.textAlignment == .center
                ) {
                    guard let id = model.selectedShapeId,
                          let idx = model.shapes.firstIndex(where: { $0.id == id }) else { return }
                    model.shapes[idx].textAlignment = .center
                }
                textActionButton(
                    icon: "text.alignright",
                    label: "Höger",
                    active: selectedShape?.textAlignment == .trailing
                ) {
                    guard let id = model.selectedShapeId,
                          let idx = model.shapes.firstIndex(where: { $0.id == id }) else { return }
                    model.shapes[idx].textAlignment = .trailing
                }

                Divider().frame(height: 28).padding(.horizontal, 2)

                // Indrag vänster (minska)
                textActionButton(icon: "decrease.indent", label: "Indrag–", active: false) {
                    guard let id = model.selectedShapeId,
                          let idx = model.shapes.firstIndex(where: { $0.id == id }) else { return }
                    model.shapes[idx].indentLevel = max(0, model.shapes[idx].indentLevel - 1)
                }

                // Indrag höger (öka)
                textActionButton(icon: "increase.indent", label: "Indrag+", active: false) {
                    guard let id = model.selectedShapeId,
                          let idx = model.shapes.firstIndex(where: { $0.id == id }) else { return }
                    model.shapes[idx].indentLevel = min(3, model.shapes[idx].indentLevel + 1)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var selectedShape: ShapeNode? {
        guard let id = model.selectedShapeId else { return nil }
        return model.shapes.first(where: { $0.id == id })
    }

    @ViewBuilder
    private func textStyleChip(_ st: TextStyle) -> some View {
        let isCurrent: Bool = {
            guard let id = model.selectedShapeId,
                  let s = model.shapes.first(where: { $0.id == id }) else { return false }
            return s.textStyle == st
        }()
        Button {
            applyTextStyle(st)
        } label: {
            Text(stylePreview(st))
                .font(.system(size: st.fontSize, weight: st.fontWeight, design: .rounded))
                .foregroundStyle(isCurrent ? Color.white : Color.primary)
                .frame(minWidth: 40)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Capsule().fill(isCurrent ? Color.accentColor : Color(.systemBackground)))
                .overlay(Capsule().stroke(Color.primary.opacity(0.1), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func textActionButton(icon: String,
                                  label: String,
                                  active: Bool,
                                  action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(active ? Color.white : Color.primary)
                .frame(width: 38, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(active ? Color.accentColor : Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }

    private func stylePreview(_ st: TextStyle) -> String {
        switch st {
        case .r1:   return "R1"
        case .r2:   return "R2"
        case .r3:   return "R3"
        case .body: return "Aa"
        }
    }

    private func applyTextStyle(_ st: TextStyle) {
        guard let id = model.selectedShapeId,
              let idx = model.shapes.firstIndex(where: { $0.id == id }) else { return }
        model.shapes[idx].textStyle = st
    }
}

/// Återanvänd chip-yta (glas-bubbla) för shape-chips.
struct ChipFace: View {
    let systemImage: String
    var larger: Bool = false

    var body: some View {
        Image(systemName: systemImage)
            .font(larger ? .title2 : .title3)
            .foregroundStyle(Color.primary)
            // v33 polish: small chip 40→44 så fingret träffar bättre på iPhone
            .frame(width: larger ? 56 : 44, height: larger ? 56 : 44)
            .background(Circle().fill(.ultraThinMaterial))
            .overlay(Circle().stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
            .contentShape(Circle())
    }
}
