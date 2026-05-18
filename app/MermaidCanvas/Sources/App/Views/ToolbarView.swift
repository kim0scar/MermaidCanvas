import SwiftUI

/// v26 Toolbar — egen drag-controller istället för Apple's draggable/dropDestination.
/// Shape-chip-gesture är en manuell DragGesture(coordinateSpace: .global)
/// med tap-vs-drag-distinktion (translation-magnitude < 8pt = tap).

enum SecondaryToolbarRow: Equatable {
    case shapes
    case arrows
    case colors
    case textStyles
    /// v31: form-paket-rad (visar UI-pack + Prompt-Process-pack-toggles)
    case packs
}

struct ToolbarView: View {
    @ObservedObject var model: CanvasModel
    @ObservedObject var dragController: ShapeDragController
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
    /// Drop-handler: anropas vid drag-end om global-punkten ligger inom canvas.
    var onDropShape: (ShapeType, CGPoint) -> Void
    /// v31: visa anteckning-popup-sheet med all canvas-text.
    var onShowNotePopup: () -> Void

    @State private var secondaryRow: SecondaryToolbarRow? = nil

    var body: some View {
        VStack(spacing: 0) {
            primaryRow
            if let row = secondaryRow {
                secondaryRowView(row)
                    .transition(.identity)
            }
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Primary rad

    @ViewBuilder
    private var primaryRow: some View {
        HStack(spacing: 6) {
            toggleButton("square.on.circle", row: .shapes, accId: "toolbar.shapes")
            toggleButton("arrow.right", row: .arrows, disabled: model.isEdgeMode, accId: "toolbar.arrows")
            toggleButton("brain.head.profile", row: .packs, accId: "toolbar.packs")
            toggleButton("paintpalette", row: .colors, disabled: model.selectedShapeId == nil, accId: "toolbar.colors")
            toggleButton("textformat.size", row: .textStyles, disabled: model.selectedShapeId == nil, accId: "toolbar.textStyles")
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
                onShowRules: onShowRules
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func toggleButton(_ systemImage: String,
                              row: SecondaryToolbarRow,
                              disabled: Bool = false,
                              accId: String) -> some View {
        Button {
            if secondaryRow == row {
                secondaryRow = nil
            } else {
                secondaryRow = row
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
                .frame(minWidth: 48, minHeight: 28)
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
            case .shapes:    shapesSecondary
            case .arrows:    arrowsSecondary
            case .colors:    colorsSecondary
            case .textStyles: textStylesSecondary
            case .packs:     packsSecondary
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Former-rad (tap + drag-out via egen controller)

    /// v31: två rader — basformer + special-symboler.
    /// Rad A: circle, rectangle, diamond, pill (ny avlång capsule)
    /// Rad B: table, link, text, line (ny lös streck), arrow (ny lös pil), note-popup
    /// HStack (INTE ScrollView) eftersom ScrollView konsumerar tap-events på iPhone (v29-lärdom).
    @ViewBuilder
    private var shapesSecondary: some View {
        VStack(spacing: 8) {
            // Rad A — basformer
            HStack(spacing: 8) {
                shapeChip(.circle,    "circle",   accId: "chip.circle") {
                    model.addShape(.circle, at: canvasCenter)
                }
                shapeChip(.rectangle, "rectangle", accId: "chip.rectangle") {
                    model.addShape(.rectangle, at: canvasCenter)
                }
                shapeChip(.diamond,   "diamond",  accId: "chip.diamond") {
                    model.addShape(.diamond, at: canvasCenter)
                }
                shapeChip(.pill,      "capsule",  accId: "chip.pill") {
                    model.addShape(.pill, at: canvasCenter)
                }
            }
            // Rad B — special
            HStack(spacing: 8) {
                shapeChip(.text,  "character.textbox", accId: "chip.text") {
                    model.addShape(.text, at: canvasCenter)
                }
                shapeChip(.table, "tablecells",        accId: "chip.table",  onTap: onAddTable)
                shapeChip(.link,  "link",              accId: "chip.link",   onTap: onAddJumpLink)
                shapeChip(.line,  "minus",             accId: "chip.line") {
                    model.addFreeLine(at: canvasCenter, withArrow: false)
                }
                shapeChip(.arrow, "arrow.right",       accId: "chip.arrow") {
                    model.addFreeLine(at: canvasCenter, withArrow: true)
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

    /// v27: shapeChip är nu generaliserad — alla 6 form-typer använder samma mönster
    /// (tap + drag-out). Tap-aktionen injiceras så special-fallen (.table / .link)
    /// kan kalla model.addTable / model.addJumpLinkPair istället för addShape.
    @ViewBuilder
    private func shapeChip(_ type: ShapeType,
                           _ system: String,
                           accId: String,
                           onTap: @escaping () -> Void) -> some View {
        ChipFace(systemImage: system)
            .contentShape(Circle())
            .onTapGesture { onTap() }
            .highPriorityGesture(dragOutGesture(type: type))
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.isButton)
            .accessibilityLabel(Text(accId))
            .accessibilityIdentifier(accId)
    }

    /// v28 (rev): tillbaka till `value.location` i onEnded — på iPhone kan
    /// @Published-cached globalLocation vara fördröjd och bryta drag helt.
    /// value.location är alltid SwiftUI:s auktoritativa slutposition för gesten.
    /// För preview-konsistens uppdaterar vi även dragController.globalLocation
    /// med samma värde direkt innan vi anropar onDropShape, så preview hinner flytta dit.
    private func dragOutGesture(type: ShapeType) -> some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .global)
            .onChanged { value in
                if dragController.activeType != type {
                    dragLog.info("drag-start type=\(type.rawValue) at=(\(value.location.x),\(value.location.y))")
                    dragController.activeType = type
                }
                dragController.globalLocation = value.location
            }
            .onEnded { value in
                let frameStr = "frame=(\(Int(dragController.canvasGlobalFrame.minX)),\(Int(dragController.canvasGlobalFrame.minY)),\(Int(dragController.canvasGlobalFrame.width)),\(Int(dragController.canvasGlobalFrame.height)))"
                if dragController.activeType != nil {
                    // Synka preview till slutposition så formens landningspunkt visuellt = preview-pos
                    dragController.globalLocation = value.location
                    dragLog.info("drag-end type=\(type.rawValue) drop=(\(value.location.x),\(value.location.y)) \(frameStr)")
                    onDropShape(type, value.location)
                } else {
                    dragLog.error("drag-end men activeType=nil — drag aldrig startade!")
                }
                dragController.activeType = nil
            }
    }


    // MARK: - Pilar-rad

    @ViewBuilder
    private var arrowsSecondary: some View {
        HStack(spacing: 8) {
            arrowChip("arrow.right", mode: .directional, label: "Pil")
            arrowChip("arrow.left.arrow.right", mode: .bidirectional, label: "Dubbel")
            Text("Tips: dra från handtagen på en vald form")
                .font(.caption)
                .foregroundStyle(.secondary)
            if model.isEdgeMode {
                Button(action: onCancelEdgeMode) {
                    HStack(spacing: 4) {
                        Image(systemName: "xmark")
                        Text("Avbryt")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.red.opacity(0.1)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func arrowChip(_ system: String, mode: EdgeCreationMode, label: String) -> some View {
        Button {
            onStartEdgeMode(mode)
            secondaryRow = nil
        } label: {
            HStack(spacing: 5) {
                Image(systemName: system).font(.title3)
                Text(label).font(.subheadline.weight(.medium))
            }
            .foregroundStyle(model.edgeCreationMode == mode ? Color.white : Color.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(model.edgeCreationMode == mode
                               ? Color.accentColor
                               : Color(.systemBackground))
            )
            .overlay(Capsule().stroke(Color.primary.opacity(0.1), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
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

    // MARK: - Textstil-rad

    @ViewBuilder
    private var textStylesSecondary: some View {
        HStack(spacing: 8) {
            ForEach(TextStyle.allCases) { st in
                textStyleChip(st)
            }
        }
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
            .frame(width: larger ? 56 : 40, height: larger ? 56 : 40)
            .background(Circle().fill(.ultraThinMaterial))
            .overlay(Circle().stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
            .contentShape(Circle())
    }
}
