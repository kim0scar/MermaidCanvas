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
        .background(Color(.systemGroupedBackground))
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
                .background(Color(.systemBackground))
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
                    .fill(Color(.systemGray6))
                    .frame(width: 44, height: 44)
                entry.chipView
            }
            // Canvas
            entry.canvasView
                .frame(width: 120, height: 80)
                .border(Color(.systemGray5), width: 0.5)
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
                label: "circle",
                shapeType: .circle,
                selectionRadius: 40,
                chipView: AnyView(Image(systemName: "circle").font(.system(size: 24))),
                canvasView: AnyView(Circle().stroke(Color.primary, lineWidth: 2).frame(width: 80, height: 80))
            ),
            GalleryEntry(
                label: "rectangle",
                shapeType: .rectangle,
                selectionRadius: 10,
                chipView: AnyView(RoundedRectangle(cornerRadius: DesignTokens.Shape.rectangleCornerRadius * 0.25, style: .continuous).stroke(Color.primary, lineWidth: DesignTokens.Shape.chipStrokeWidth).frame(width: 28, height: 18)),
                canvasView: AnyView(RoundedRectangle(cornerRadius: DesignTokens.Shape.rectangleCornerRadius, style: .continuous).stroke(Color.primary, lineWidth: DesignTokens.Shape.canvasStrokeWidth))
            ),
            GalleryEntry(
                label: "square",
                shapeType: .square,
                selectionRadius: 14,
                chipView: AnyView(SquareShape().stroke(Color.primary, lineWidth: DesignTokens.Shape.chipStrokeWidth).frame(width: DesignTokens.Chip.squareIconSide, height: DesignTokens.Chip.squareIconSide)),
                // Square använder default cornerRadiusRatio (12.5%) → chip 22pt ger 2.75pt, canvas 80pt ger 10pt
                canvasView: AnyView(SquareShape().stroke(Color.primary, lineWidth: DesignTokens.Shape.canvasStrokeWidth).frame(width: 80, height: 80))
            ),
            GalleryEntry(
                label: "diamond",
                shapeType: .diamond,
                selectionRadius: 0,
                chipView: AnyView(DiamondShape(cornerRadius: DesignTokens.Shape.diamondCornerRadius).stroke(Color.primary, lineWidth: DesignTokens.Shape.chipStrokeWidth).frame(width: DesignTokens.Chip.diamondIconWidth, height: DesignTokens.Chip.diamondIconHeight)),
                canvasView: AnyView(DiamondShape().stroke(Color.primary, lineWidth: DesignTokens.Shape.canvasStrokeWidth))
            ),
            GalleryEntry(
                label: "pill",
                shapeType: .pill,
                selectionRadius: 40,
                chipView: AnyView(Capsule(style: .continuous).stroke(Color.primary, lineWidth: DesignTokens.Shape.chipStrokeWidth).frame(width: DesignTokens.Chip.pillIconWidth, height: DesignTokens.Chip.pillIconHeight)),
                canvasView: AnyView(Capsule(style: .continuous).stroke(Color.primary, lineWidth: DesignTokens.Shape.canvasStrokeWidth))
            ),
            GalleryEntry(
                label: "processArrow",
                shapeType: .processArrow,
                selectionRadius: 0,
                chipView: AnyView(ProcessArrowShape().stroke(Color.primary, lineWidth: DesignTokens.Shape.chipStrokeWidth).frame(width: DesignTokens.Chip.processArrowIconWidth, height: DesignTokens.Chip.processArrowIconHeight)),
                canvasView: AnyView(ProcessArrowShape().stroke(Color.primary, lineWidth: DesignTokens.Shape.canvasStrokeWidth))
            ),
            GalleryEntry(
                label: "container",
                shapeType: .container,
                selectionRadius: 10,
                chipView: AnyView(RoundedRectangle(cornerRadius: DesignTokens.Shape.rectangleCornerRadius * 0.25, style: .continuous).stroke(Color.primary, style: StrokeStyle(lineWidth: DesignTokens.Shape.chipStrokeWidth, dash: [3, 2])).frame(width: 30, height: 20)),
                canvasView: AnyView(RoundedRectangle(cornerRadius: DesignTokens.Shape.rectangleCornerRadius, style: .continuous).stroke(Color.primary, style: StrokeStyle(lineWidth: DesignTokens.Shape.canvasStrokeWidth, dash: [6, 4])))
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
