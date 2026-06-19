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
    /// Steg H: exportera ritade ytan som bild (PNG) → delningsmeny.
    var onExportImage: () -> Void = {}
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
    func primaryControls(vertical: Bool) -> some View {
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
    var markerButton: some View {
        Button(action: onToggleMarker) {
            ToolbarIconButton(systemImage: "rectangle.dashed",
                              isActive: model.markerMode)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("toolbar.marker")
        .accessibilityLabel(a11yLabel(for: "toolbar.marker"))
    }

    @ViewBuilder
    var undoButton: some View {
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
    var zoomBadge: some View {
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
        .background(Color(.secondarySystemBackground))
    }
}
