import SwiftUI

/// Dispatcher som väljer rätt renderer baserat på SpecType.
/// **Detta är Claudes översättnings-kontrakt** — varje renderer bestämmer hur
/// kategorierna översätts till faktisk SwiftUI-vy. Om Kim ser fel: justera reglerna här.
struct UIRenderer: View {
    let shapes: [ShapeNode]
    let edges: [EdgeConnection]
    let canvasSize: CGSize
    let specType: SpecType

    var body: some View {
        switch specType {
        case .ui:
            UIScreenRenderer(shapes: shapes, canvasSize: canvasSize)
        case .roadmap:
            RoadmapRenderer(shapes: shapes)
        case .architecture:
            ArchitectureRenderer(shapes: shapes)
        case .flow:
            FlowRenderer(shapes: shapes, edges: edges)
        case .general:
            VStack(spacing: 12) {
                Text("Allmänt läge — ingen översättning ännu.")
                    .foregroundStyle(.secondary)
                Text("Sätt spec_type i toppen för att se en simulering.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
