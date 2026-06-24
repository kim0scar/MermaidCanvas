import SwiftUI

/// v50.4 Cykel 2 — Storybook-stil katalog över alla visuella komponenter.
///
/// **Syfte:** Visa alla 11 form-typer som CHIP (toolbar-storlek) och som
/// CANVAS (full storlek) sida vid sida + alla badges + alla edge-typer
/// på en enda lång scroll-vy. Gör det möjligt att:
/// - VISUELLT bekräfta att chip-ikon matchar canvas-rendering
/// - Snapshot-testa hela vyn i en enda jämförelse
/// - Upptäcka inkonsistenser mellan former (rektangel r=10, square r=14, etc.)
///
/// **Åtkomst:** Lägg till en debug-knapp i LägenMenu eller starta direkt
/// via launch-arg `-uitest-component-gallery`.
struct ComponentGallery: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                section("Form-typer: Chip (toolbar) vs Canvas (faktisk rendering)") {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(galleryShapes, id: \.label) { entry in
                            shapeRow(entry)
                        }
                    }
                }

                section("Badges") {
                    HStack(spacing: 30) {
                        VStack(spacing: 4) {
                            EdgeStartCollapseBadge(
                                position: CGPoint(x: 25, y: 25),
                                canvasScale: 1.0,
                                onTap: {}
                            )
                            .frame(width: 50, height: 50)
                            Text("minus").font(.caption2)
                        }
                        VStack(spacing: 4) {
                            EdgeStubBadge(
                                position: CGPoint(x: 25, y: 25),
                                canvasScale: 1.0,
                                onTap: {}
                            )
                            .frame(width: 50, height: 50)
                            Text("stub-plus").font(.caption2)
                        }
                    }
                }

                section("Selection-ramar (cornerRadius per shape-typ)") {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(galleryShapes.filter { $0.shapeType != nil }, id: \.label) { entry in
                            selectionRow(entry)
                        }
                    }
                }

                section("Inkonsistens-larm") {
                    inconsistencyAudit
                }

                Spacer(minLength: 40)
            }
            .padding(20)
        }
        .background(Color.appGroupedBackground)
        .navigationTitle("Komponentgalleri")
        .accessibilityIdentifier("component.gallery")
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Visuali2e komponentgalleri")
                .font(.title2).bold()
            Text("Alla UI-komponenter i ett galleri. Använd för att verifiera att chip ≡ canvas och upptäcka inkonsistenser.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Sektion-helper

    @ViewBuilder
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            content()
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.appBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Shape-row

    private func shapeRow(_ entry: GalleryEntry) -> some View {
        HStack(spacing: 20) {
            // Label
            Text(entry.label)
                .font(.callout.monospaced())
                .frame(width: 100, alignment: .leading)
            // Chip
            ZStack {
                Circle()
                    .fill(Color.appGray6)
                    .frame(width: 44, height: 44)
                entry.chipView
            }
            // Canvas
            entry.canvasView
                .frame(width: 120, height: 80)
                .border(Color.appGray5, width: 0.5)
            Spacer()
        }
    }

    // MARK: - Selection-row

    private func selectionRow(_ entry: GalleryEntry) -> some View {
        HStack(spacing: 20) {
            Text(entry.label)
                .font(.callout.monospaced())
                .frame(width: 100, alignment: .leading)
            ZStack {
                entry.canvasView
                    .frame(width: 120, height: 80)
                if let cr = entry.selectionRadius {
                    RoundedRectangle(cornerRadius: cr)
                        .stroke(Color.accentColor,
                                style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                        .frame(width: 120, height: 80)
                }
            }
            if let cr = entry.selectionRadius {
                Text("r=\(Int(cr))")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    // MARK: - Inkonsistens-audit

    private var inconsistencyAudit: some View {
        VStack(alignment: .leading, spacing: 6) {
            auditLine("Diamond chip r=3, canvas r=8", warning: true,
                      reason: "Avsiktligt — chip behöver mindre radie pga liten storlek. Bör vara i Design Tokens.")
            auditLine("Rektangel chip r=10, canvas r=10", warning: false)
            auditLine("Square chip r=6, canvas r=14", warning: true,
                      reason: "INKONSISTENS — ska båda vara samma proportion?")
            auditLine("ProcessArrow chip r=8 (default), canvas r=8 (default)", warning: false)
            auditLine("Pill chip + canvas: full kapsel", warning: false)
        }
        .font(.caption)
    }

    private func auditLine(_ text: String, warning: Bool, reason: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                Image(systemName: warning ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .foregroundStyle(warning ? Color.orange : Color.green)
                Text(text)
            }
            if let reason {
                Text(reason)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 22)
            }
        }
    }

    // MARK: - Gallery-data

    private struct GalleryEntry {
        let label: String
        let shapeType: ShapeType?
        let selectionRadius: CGFloat?
        let chipView: AnyView
        let canvasView: AnyView
    }

    private var galleryShapes: [GalleryEntry] {
        [
            GalleryEntry(
                label: "octagon",
                shapeType: .octagon,
                selectionRadius: 0,
                chipView: AnyView(OctagonShape().stroke(Color.primary, lineWidth: DesignTokens.Shape.chipStrokeWidth).frame(width: DesignTokens.Chip.iconSize(for: .octagon).width, height: DesignTokens.Chip.iconSize(for: .octagon).height)),
                canvasView: AnyView(OctagonShape().stroke(Color.primary, lineWidth: DesignTokens.Shape.canvasStrokeWidth).frame(width: 56, height: 56))
            ),
            GalleryEntry(
                label: "circle",
                shapeType: .circle,
                selectionRadius: 40,
                chipView: AnyView(Image(systemName: "circle").font(.system(size: 24))),
                canvasView: AnyView(Circle().stroke(Color.primary, lineWidth: 2).frame(width: 80, height: 80))
            ),
            // v50.8: chip OCH canvas läser samma källa (iconSize + cornerRadius(for:height:)).
            // canvas-preview ritas vid 56pt höjd i canvas-proportion så jämförelsen är sann.
            GalleryEntry(
                label: "rectangle",
                shapeType: .rectangle,
                selectionRadius: DesignTokens.Shape.cornerRadius(for: .rectangle, height: 56),
                chipView: AnyView(RoundedRectangle(cornerRadius: DesignTokens.Shape.cornerRadius(for: .rectangle, height: DesignTokens.Chip.iconSize(for: .rectangle).height), style: .continuous).stroke(Color.primary, lineWidth: DesignTokens.Shape.chipStrokeWidth).frame(width: DesignTokens.Chip.iconSize(for: .rectangle).width, height: DesignTokens.Chip.iconSize(for: .rectangle).height)),
                canvasView: AnyView(RoundedRectangle(cornerRadius: DesignTokens.Shape.cornerRadius(for: .rectangle, height: 56), style: .continuous).stroke(Color.primary, lineWidth: DesignTokens.Shape.canvasStrokeWidth).frame(width: 84, height: 56))
            ),
            GalleryEntry(
                label: "square",
                shapeType: .square,
                selectionRadius: DesignTokens.Shape.cornerRadius(for: .square, height: 56),
                chipView: AnyView(SquareShape().stroke(Color.primary, lineWidth: DesignTokens.Shape.chipStrokeWidth).frame(width: DesignTokens.Chip.iconSize(for: .square).width, height: DesignTokens.Chip.iconSize(for: .square).height)),
                canvasView: AnyView(SquareShape().stroke(Color.primary, lineWidth: DesignTokens.Shape.canvasStrokeWidth).frame(width: 56, height: 56))
            ),
            GalleryEntry(
                label: "diamond",
                shapeType: .diamond,
                selectionRadius: 0,
                chipView: AnyView(DiamondShape().stroke(Color.primary, lineWidth: DesignTokens.Shape.chipStrokeWidth).frame(width: DesignTokens.Chip.iconSize(for: .diamond).width, height: DesignTokens.Chip.iconSize(for: .diamond).height)),
                canvasView: AnyView(DiamondShape().stroke(Color.primary, lineWidth: DesignTokens.Shape.canvasStrokeWidth).frame(width: 84, height: 56))
            ),
            GalleryEntry(
                label: "pill",
                shapeType: .pill,
                selectionRadius: 40,
                chipView: AnyView(Capsule(style: .continuous).stroke(Color.primary, lineWidth: DesignTokens.Shape.chipStrokeWidth).frame(width: DesignTokens.Chip.iconSize(for: .pill).width, height: DesignTokens.Chip.iconSize(for: .pill).height)),
                canvasView: AnyView(Capsule(style: .continuous).stroke(Color.primary, lineWidth: DesignTokens.Shape.canvasStrokeWidth).frame(width: 91, height: 56))
            ),
            GalleryEntry(
                label: "processArrow",
                shapeType: .processArrow,
                selectionRadius: 0,
                chipView: AnyView(ProcessArrowShape().stroke(Color.primary, lineWidth: DesignTokens.Shape.chipStrokeWidth).frame(width: DesignTokens.Chip.iconSize(for: .processArrow).width, height: DesignTokens.Chip.iconSize(for: .processArrow).height)),
                canvasView: AnyView(ProcessArrowShape().stroke(Color.primary, lineWidth: DesignTokens.Shape.canvasStrokeWidth).frame(width: 77, height: 56))
            ),
            GalleryEntry(
                label: "container",
                shapeType: .container,
                selectionRadius: DesignTokens.Shape.cornerRadius(for: .container, height: 56),
                chipView: AnyView(RoundedRectangle(cornerRadius: DesignTokens.Shape.cornerRadius(for: .container, height: DesignTokens.Chip.iconSize(for: .container).height), style: .continuous).stroke(Color.primary, style: StrokeStyle(lineWidth: DesignTokens.Shape.chipStrokeWidth, dash: [3, 2])).frame(width: DesignTokens.Chip.iconSize(for: .container).width, height: DesignTokens.Chip.iconSize(for: .container).height)),
                canvasView: AnyView(RoundedRectangle(cornerRadius: DesignTokens.Shape.cornerRadius(for: .container, height: 56), style: .continuous).stroke(Color.primary, style: StrokeStyle(lineWidth: DesignTokens.Shape.canvasStrokeWidth, dash: [6, 4])).frame(width: 78, height: 56))
            ),
            GalleryEntry(
                label: "table",
                shapeType: .table,
                selectionRadius: 10,
                chipView: AnyView(Image(systemName: "tablecells").font(.system(size: 24))),
                canvasView: AnyView(RoundedRectangle(cornerRadius: 10).stroke(Color.primary, lineWidth: 2))
            ),
            GalleryEntry(
                label: "link",
                shapeType: .link,
                selectionRadius: nil,
                chipView: AnyView(Image(systemName: "link").font(.system(size: 24))),
                canvasView: AnyView(Circle().stroke(Color.primary, lineWidth: 2).frame(width: 60, height: 60))
            ),
        ]
    }
}

#Preview {
    NavigationStack {
        ComponentGallery()
    }
}
