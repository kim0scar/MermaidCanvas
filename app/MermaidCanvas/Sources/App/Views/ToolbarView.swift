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
    var onRedo: () -> Void = {}   // V79-svep
    var onShowCode: () -> Void
    /// v61: kopiera hela dokumentet till urklipp utan sheet (1 tryck).
    var onCopyCode: () -> Void
    /// Steg H: exportera ritade ytan som bild → delningsmeny. Bool = JPG (annars PNG).
    var onExportImage: (Bool) -> Void = { _ in }
    var onShowCapabilities: () -> Void = {}   // V79-svep: facit-vyn
    var onInsertTemplate: (CanvasModel.TemplateKind) -> Void = { _ in }   // V79-svep: snabb-mall
    var onShowRules: () -> Void
    var onToggleMarker: () -> Void
    var onAddTable: () -> Void
    var onAddJumpLink: () -> Void
    var onNewCanvas: () -> Void
    var onResetZoom: () -> Void
    /// v31: visa anteckning-popup-sheet med all canvas-text.
    var onShowNotePopup: () -> Void
    var onImportMermaid: () -> Void   // v37: importera Mermaid från AI
    var onImportMultiple: () -> Void = {}   // v1.1: flera filer som containrar
    /// v66: visa/dölj legend-panelen
    var onToggleLegend: () -> Void = {}
    /// v39: multi-select-operationer
    var onDuplicateSelection: () -> Void
    var onDeleteSelection: () -> Void
    var onAlignHorizontal: () -> Void
    var onAlignVertical: () -> Void
    /// v60: layout-axel — .horizontal (porträtt: topp-bar) eller .vertical (landskap: vänster sidebar).
    var axis: Axis = .horizontal

    @State var secondaryRow: SecondaryToolbarRow? = nil
    @State var showSizePicker = false   // v40: textstorlek-popup
    /// v62: vad färg-valet ska gälla — flyttad hit (extensions kan ej ha stored properties).
    @State var colorTarget: ColorTarget = .pack

    var body: some View {
        // v39: visa multi-select-operationer automatiskt när markerMode är aktivt
        let activeRow: SecondaryToolbarRow? = model.markerMode ? .multiSelect : secondaryRow
        if axis == .vertical {
            // v60: landskap — vänster vertikal sidebar (ligger som overlay över canvas).
            // Primärkolumn till vänster; sekundär-panel öppnas till höger om den.
            HStack(alignment: .top, spacing: 6) {
                primaryControls(vertical: true)
                    .padding(8)
                    .background(Color.appBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.primary.opacity(0.08), lineWidth: 0.5))
                if let row = activeRow {
                    secondaryRowView(row)
                        .padding(8)
                        .background(Color.appBackground, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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
            .background(Color.appBackground)
        }
    }

    // MARK: - Primary rad

    /// v60: primärkontrollerna i axel-medveten layout (HStack i porträtt, VStack i landskap).
    @ViewBuilder
    func primaryControls(vertical: Bool) -> some View {
        let layout = vertical
            ? AnyLayout(VStackLayout(spacing: 6))
            : AnyLayout(HStackLayout(spacing: 4))
        layout {
            toggleButton("square.on.circle", row: .shapes, accId: "toolbar.shapes")
            toggleButton("swatchpalette", row: .packs, accId: "toolbar.packs")
            toggleButton("paintpalette", row: .colors, disabled: model.selectedShapeId == nil, accId: "toolbar.colors")
            toggleButton("textformat.size", row: .textStyles, disabled: model.selectedShapeId == nil, accId: "toolbar.textStyles")
            // 1.2: marker-knappen borttagen → markering via dubbelklick på tom yta (CanvasView).
            if !vertical { Spacer(minLength: 0) }
            zoomBadge
            undoButton
            redoButton   // V79-svep: ångra åt båda håll
            modesMenu   // LägenMenu → ToolbarView+Menu.swift (R5-ratchet, steg H)
        }
    }

    @ViewBuilder
    func toggleButton(_ systemImage: String,
                      row: SecondaryToolbarRow,
                      disabled: Bool = false,
                      accId: String) -> some View {
        Button {
            // v33 Apple-nivå: haptic feedback vid toggle (light impact = avslappnad känsla)
            Haptics.impact()
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
                              isActive: !model.markerMode && secondaryRow == row)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.35 : 1)
        .accessibilityIdentifier(accId)
        .accessibilityLabel(a11yLabel(for: accId))
    }

    // undoButton + redoButton → ToolbarView+History.swift (R5-ratchet, V79-svep)

    @ViewBuilder
    var zoomBadge: some View {
        // 1.2: zoom är INFO, inte knapp (Kims order). Behåller .isButton-trait +
        // diagnosticsValue så XCUITest (toolbar.zoom) ser den oförändrat. Reset → menyn.
        Text("\(zoomPercent)%")
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(Color.primary.opacity(0.7))
            .frame(minWidth: 40, minHeight: 28)
            .background(Capsule().fill(.ultraThinMaterial))
            .overlay(Capsule().stroke(Color.primary.opacity(0.08), lineWidth: 0.5))
            .frame(minHeight: 44)
            .accessibilityElement()
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("toolbar.zoom")
            .accessibilityLabel(a11yLabel(for: "toolbar.zoom"))
            .accessibilityValue(diagnosticsValue)
    }

    /// v27: testdiagnostik — rapporterar shape-count + position på senaste form
    /// så XCUITest kan verifiera att drag-ut placerar formen exakt rätt.
    var diagnosticsValue: String {
        let count = model.shapes.count
        if let last = model.shapes.last {
            return "shapeCount=\(count);lastX=\(Int(last.position.x));lastY=\(Int(last.position.y))"
        }
        return "shapeCount=\(count)"
    }

    // MARK: - Sekundär rad

    @ViewBuilder
    func secondaryRowView(_ row: SecondaryToolbarRow) -> some View {
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
        .background(Color.appSecondaryBackground)
    }
}
