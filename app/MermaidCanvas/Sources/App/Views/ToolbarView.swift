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
    var onStartEdgeMode: (EdgeCreationMode) -> Void
    var onCancelEdgeMode: () -> Void
    var onOpen: () -> Void
    var onSave: () -> Void
    var onSaveAs: () -> Void
    var onUndo: () -> Void
    var onShowCode: () -> Void
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

    @State private var secondaryRow: SecondaryToolbarRow? = nil

    var body: some View {
        VStack(spacing: 0) {
            primaryRow
            // v39: visa multi-select-operationer automatiskt när markerMode är aktivt
            let activeRow: SecondaryToolbarRow? = model.markerMode ? .multiSelect : secondaryRow
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

    // MARK: - Primary rad

    @ViewBuilder
    private var primaryRow: some View {
        // v39: multi-select-knapp (rectangle.dashed) i primär toolbar.
        HStack(spacing: 4) {
            toggleButton("square.on.circle", row: .shapes, accId: "toolbar.shapes")
            toggleButton("swatchpalette", row: .packs, accId: "toolbar.packs")
            toggleButton("paintpalette", row: .colors, disabled: model.selectedShapeId == nil, accId: "toolbar.colors")
            toggleButton("textformat.size", row: .textStyles, disabled: model.selectedShapeId == nil, accId: "toolbar.textStyles")
            // v39: multi-select direkt i toolbar
            markerButton
            Spacer(minLength: 0)
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
                onShowRules: onShowRules,
                onToggleMarker: onToggleMarker,
                onImportMermaid: onImportMermaid
            )
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
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
    }

    @ViewBuilder
    private var markerButton: some View {
        Button(action: onToggleMarker) {
            ToolbarIconButton(systemImage: "rectangle.dashed",
                              isActive: model.markerMode)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("toolbar.marker")
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
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("toolbar.zoom")
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
            // Rad A — 7 grundformer
            HStack(spacing: 8) {
                shapeChip(.circle,       "circle",           accId: "chip.circle") {
                    model.addShape(.circle, at: canvasCenter)
                }
                shapeChip(.rectangle,    "rectangle",        accId: "chip.rectangle") {
                    model.addShape(.rectangle, at: canvasCenter)
                }
                shapeChip(.square,       "square",           accId: "chip.square") {
                    model.addShape(.square, at: canvasCenter)
                }
                shapeChip(.diamond,      "diamond",          accId: "chip.diamond") {
                    model.addShape(.diamond, at: canvasCenter)
                }
                shapeChip(.pill,         "capsule",          accId: "chip.pill") {
                    model.addShape(.pill, at: canvasCenter)
                }
                shapeChip(.processArrow, "arrowshape.right", accId: "chip.processArrow") {
                    model.addShape(.processArrow, at: canvasCenter)
                }
            }
            // Rad B — 5 special-typer + anteckning-popup
            HStack(spacing: 8) {
                shapeChip(.text,  "character.textbox", accId: "chip.text") {
                    model.addShape(.text, at: canvasCenter)
                }
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
            }
        }
        .padding(.horizontal, 2)
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
            .accessibilityLabel(Text(accId))
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

    // MARK: - Textstil-rad (v39 utökad)

    @ViewBuilder
    private var textStylesSecondary: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                // Storlek: R1 / R2 / R3 / Aa
                ForEach(TextStyle.allCases) { st in
                    textStyleChip(st)
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
