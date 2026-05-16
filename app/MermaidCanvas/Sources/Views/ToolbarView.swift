import SwiftUI

/// v26 Toolbar — egen drag-controller istället för Apple's draggable/dropDestination.
/// Shape-chip-gesture är en manuell DragGesture(coordinateSpace: .global)
/// med tap-vs-drag-distinktion (translation-magnitude < 8pt = tap).

enum SecondaryToolbarRow: Equatable {
    case shapes
    case arrows
    case colors
    case textStyles
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
    var onShowPreview: () -> Void
    var onShowRules: () -> Void
    var onToggleMarker: () -> Void
    var onAddTable: () -> Void
    var onAddJumpLink: () -> Void
    var onNewCanvas: () -> Void
    var onResetZoom: () -> Void
    /// Drop-handler: anropas vid drag-end om global-punkten ligger inom canvas.
    var onDropShape: (ShapeType, CGPoint) -> Void

    @State private var secondaryRow: SecondaryToolbarRow? = nil

    var body: some View {
        VStack(spacing: 0) {
            primaryRow
            if let row = secondaryRow {
                secondaryRowView(row)
                    .transition(.identity)
            }
            Divider()
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Primary rad

    @ViewBuilder
    private var primaryRow: some View {
        HStack(spacing: 6) {
            toggleButton("square.on.circle", row: .shapes, accId: "toolbar.shapes")
            toggleButton("arrow.right", row: .arrows, disabled: model.isEdgeMode, accId: "toolbar.arrows")
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
                onShowPreview: onShowPreview,
                onShowRules: onShowRules
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
        .accessibilityValue("shapeCount=\(model.shapes.count)")
    }

    // MARK: - Sekundär rad

    @ViewBuilder
    private func secondaryRowView(_ row: SecondaryToolbarRow) -> some View {
        Divider()
        HStack(spacing: 8) {
            switch row {
            case .shapes:    shapesSecondary
            case .arrows:    arrowsSecondary
            case .colors:    colorsSecondary
            case .textStyles: textStylesSecondary
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
    }

    // MARK: - Former-rad (tap + drag-out via egen controller)

    /// v26: INGEN ScrollView — ScrollView's pan-gesture åt drag-eventen.
    /// Ingen acc-id på HStack heller — annars ärver special-chips (Button)
    /// den och täcker sin egen accessibilityIdentifier.
    @ViewBuilder
    private var shapesSecondary: some View {
        HStack(spacing: 10) {
            shapeChip(.circle,    "circle",            accId: "chip.circle") {
                model.addShape(.circle, at: canvasCenter)
            }
            shapeChip(.rectangle, "rectangle",         accId: "chip.rectangle") {
                model.addShape(.rectangle, at: canvasCenter)
            }
            shapeChip(.diamond,   "diamond",           accId: "chip.diamond") {
                model.addShape(.diamond, at: canvasCenter)
            }
            shapeChip(.text,      "character.textbox", accId: "chip.text") {
                model.addShape(.text, at: canvasCenter)
            }
            shapeChip(.table,     "tablecells",        accId: "chip.table",  onTap: onAddTable)
            shapeChip(.link,      "link",              accId: "chip.link",   onTap: onAddJumpLink)
        }
        .padding(.horizontal, 2)
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

    private func dragOutGesture(type: ShapeType) -> some Gesture {
        DragGesture(minimumDistance: 8, coordinateSpace: .global)
            .onChanged { value in
                if dragController.activeType != type {
                    dragController.activeType = type
                }
                dragController.globalLocation = value.location
            }
            .onEnded { value in
                if dragController.activeType != nil {
                    onDropShape(type, value.location)
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
            .frame(width: larger ? 56 : 44, height: larger ? 56 : 44)
            .background(Circle().fill(.ultraThinMaterial))
            .overlay(Circle().stroke(Color.primary.opacity(0.15), lineWidth: 0.5))
            .contentShape(Circle())
    }
}
