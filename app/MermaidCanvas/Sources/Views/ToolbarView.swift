import SwiftUI

/// v25 Toolbar — primary rad (glas-bubblor) + sekundär rad som poppar upp UNDER
/// när Former / Pilar / Färg / Aa trycks. Blixtsnabbt, ingen animation.
/// FIX v25: Shape-chips är Button (inte Image+onTapGesture) — annars äter
/// .draggable upp tap-eventet i en ScrollView på iPhone.

enum SecondaryToolbarRow: Equatable {
    case shapes
    case arrows
    case colors
    case textStyles
}

struct ToolbarView: View {
    @ObservedObject var model: CanvasModel
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
            toggleButton("square.on.circle", row: .shapes)
            toggleButton("arrow.right", row: .arrows, disabled: model.isEdgeMode)
            toggleButton("paintpalette", row: .colors, disabled: model.selectedShapeId == nil)
            toggleButton("textformat.size", row: .textStyles, disabled: model.selectedShapeId == nil)
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
                              disabled: Bool = false) -> some View {
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
    }

    @ViewBuilder
    private var markerButton: some View {
        Button(action: onToggleMarker) {
            ToolbarIconButton(systemImage: "rectangle.dashed",
                              isActive: model.markerMode)
        }
        .buttonStyle(.plain)
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
    }

    /// v25: Visa zoom-procent så Kim ser att zoom svarar.
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

    // MARK: - Former-rad (tap + drag-out)

    @ViewBuilder
    private var shapesSecondary: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                shapeChip(.circle,   "circle")
                shapeChip(.rectangle, "rectangle")
                shapeChip(.diamond,   "diamond")
                shapeChip(.text,      "character.textbox")
                tableChip
                linkChip
            }
            .padding(.horizontal, 2)
        }
    }

    /// v25 fix: Button istället för Image+onTapGesture så tap fungerar
    /// tillsammans med .draggable i ScrollView på iPhone.
    @ViewBuilder
    private func shapeChip(_ type: ShapeType, _ system: String) -> some View {
        Button {
            model.addShape(type, at: canvasCenter)
        } label: {
            ChipFace(systemImage: system)
        }
        .buttonStyle(.plain)
        .draggable(type) {
            ChipFace(systemImage: system, larger: true)
        }
    }

    @ViewBuilder
    private var tableChip: some View {
        Button {
            onAddTable()
        } label: {
            ChipFace(systemImage: "tablecells")
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var linkChip: some View {
        Button {
            onAddJumpLink()
        } label: {
            ChipFace(systemImage: "link")
        }
        .buttonStyle(.plain)
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

    // MARK: - Färg-rad (7 paket inline)

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

    // MARK: - Textstil-rad (R1/R2/R3/Brödtext)

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
