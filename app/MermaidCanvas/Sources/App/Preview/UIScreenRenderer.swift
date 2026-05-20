import SwiftUI

/// Renderar UI-spec som en simulerad iPhone-skärm.
/// Översättningsregler (Claudes kontrakt):
/// - category=.zone  → streckad container med titel
/// - category=.note  → renderas INTE (det är kommentar, inte UI)
/// - category=.overlay → element med material-bakgrund + skugga
/// - category=.ui:
///     - label innehåller "knapp"/"button"/"btn" → Button
///     - label innehåller "mätare"/"meter"/"gauge"/"progress" → ProgressView
///     - label innehåller "textfält"/"input"/"sök"/"search" → text-input-look
///     - label innehåller "titel"/"rubrik"/"heading"/"header" → bold Title
///     - label innehåller "ikon"/"icon" → SF Symbol
///     - annars → panel-box med text
/// v44: .text-formen är borttagen — UI-zone-text använder andra former.
struct UIScreenRenderer: View {
    let shapes: [ShapeNode]
    let canvasSize: CGSize

    var body: some View {
        GeometryReader { geo in
            let phone = phoneFrame(in: geo.size)
            let phoneOriginX = (geo.size.width - phone.width) / 2
            let phoneOriginY = (geo.size.height - phone.height) / 2

            ZStack(alignment: .topLeading) {
                // iPhone-chassi (centrerat)
                RoundedRectangle(cornerRadius: 42, style: .continuous)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 42, style: .continuous)
                            .stroke(Color.primary.opacity(0.5), lineWidth: 3)
                    )
                    .frame(width: phone.width, height: phone.height)
                    .offset(x: phoneOriginX, y: phoneOriginY)

                // Dynamic Island
                Capsule()
                    .fill(Color.black)
                    .frame(width: 100, height: 28)
                    .offset(x: phoneOriginX + phone.width / 2 - 50,
                            y: phoneOriginY + 14)

                // Komponenter — positioneras inom telefonramen efter (relX, relY)
                ForEach(visibleShapes) { shape in
                    componentView(for: shape)
                        .position(
                            x: phoneOriginX + phone.width * relX(shape),
                            y: phoneOriginY + phone.height * relY(shape)
                        )
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .background(Color(.systemGray5))
    }

    // MARK: - Filtering + positionering

    /// Note-noder skall INTE synas i UI. De är implementations-tips för Claude.
    private var visibleShapes: [ShapeNode] {
        shapes.filter { $0.category != .note }
    }

    private func relX(_ shape: ShapeNode) -> CGFloat {
        guard canvasSize.width > 0 else { return 0.5 }
        return min(max(shape.position.x / canvasSize.width, 0.0), 1.0)
    }

    private func relY(_ shape: ShapeNode) -> CGFloat {
        guard canvasSize.height > 0 else { return 0.5 }
        return min(max(shape.position.y / canvasSize.height, 0.0), 1.0)
    }

    private func phoneFrame(in container: CGSize) -> CGSize {
        // Aspect-fit för preview (skiljt från canvasens fasta storlek)
        iPhoneFrameMath.previewFrame(in: container).size
    }

    // MARK: - Komponent-mapping

    @ViewBuilder
    private func componentView(for shape: ShapeNode) -> some View {
        let label = shape.label
        let lower = label.lowercased()

        switch shape.category {
        case .zone:
            zoneContainer(label: label)
        case .overlay:
            overlayChip(label: label)
        case .ui:
            if matches(lower, any: ["knapp", "button", "btn"]) {
                Button(label) {}
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    .disabled(true)
            } else if matches(lower, any: ["mätare", "meter", "gauge", "progress"]) {
                meterView(label: label)
            } else if matches(lower, any: ["textfält", "input", "sök", "search", "fält"]) {
                textFieldLook(label: label)
            } else if matches(lower, any: ["titel", "rubrik", "heading", "header", "title"]) {
                Text(label).font(.title3.bold())
            } else if matches(lower, any: ["ikon", "icon"]) {
                Image(systemName: inferIconName(from: label))
                    .font(.title)
                    .foregroundStyle(Color.accentColor)
            } else {
                panelBox(label: label, color: shape.category.fillColor)
            }
        default:
            // Övriga kategorier (roadmap/arch/flow) visas också om någon mixat
            panelBox(label: label, color: shape.category.fillColor)
        }
    }

    private func matches(_ lower: String, any needles: [String]) -> Bool {
        needles.contains { lower.contains($0) }
    }

    private func inferIconName(from label: String) -> String {
        let l = label.lowercased()
        if l.contains("hem") || l.contains("home") { return "house" }
        if l.contains("sök") || l.contains("search") { return "magnifyingglass" }
        if l.contains("inställning") || l.contains("setting") { return "gearshape" }
        if l.contains("användare") || l.contains("user") || l.contains("profil") { return "person" }
        if l.contains("plus") || l.contains("lägg") { return "plus" }
        if l.contains("kamera") || l.contains("camera") { return "camera" }
        return "circle"
    }

    @ViewBuilder
    private func meterView(label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundStyle(.secondary)
            ProgressView(value: 0.66)
                .frame(width: 100)
        }
    }

    @ViewBuilder
    private func textFieldLook(label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            Text(label).foregroundStyle(.secondary)
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(width: 160)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func panelBox(label: String, color: Color) -> some View {
        Text(label)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    @ViewBuilder
    private func zoneContainer(label: String) -> some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.secondary.opacity(0.6),
                        style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                .frame(width: 220, height: 100)
            Text(label)
                .font(.caption2.bold())
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(.systemBackground))
                .padding(.leading, 10)
                .padding(.top, -8)
        }
    }

    @ViewBuilder
    private func overlayChip(label: String) -> some View {
        Text(label)
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
    }
}
