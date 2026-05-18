import SwiftUI

/// Flow-läget renderas som en numrerad pipeline.
/// Ordning: kategorier i pipeline-ordning (input → router → agent → tool → memory → output),
/// inom samma kategori sorteras efter x-position (vänster till höger).
struct FlowRenderer: View {
    let shapes: [ShapeNode]
    let edges: [EdgeConnection]

    private let pipelineOrder: [ShapeCategory] = [.input, .router, .agent, .tool, .memory, .output]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("⚡ Flöde").font(.title3.bold())
                ForEach(Array(orderedShapes.enumerated()), id: \.element.id) { idx, shape in
                    flowStep(index: idx + 1, shape: shape)
                }
                if !notes.isEmpty {
                    Divider().padding(.vertical, 8)
                    Text("📝 Anteckningar").font(.headline)
                    ForEach(notes) { n in
                        Label(n.label, systemImage: "note.text").font(.callout)
                    }
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var orderedShapes: [ShapeNode] {
        shapes
            .filter { pipelineOrder.contains($0.category) }
            .sorted { a, b in
                let ia = pipelineOrder.firstIndex(of: a.category) ?? 99
                let ib = pipelineOrder.firstIndex(of: b.category) ?? 99
                if ia != ib { return ia < ib }
                return a.position.x < b.position.x
            }
    }

    private var notes: [ShapeNode] {
        shapes.filter { $0.category == .note }
    }

    @ViewBuilder
    private func flowStep(index: Int, shape: ShapeNode) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle().fill(shape.category.fillColor).frame(width: 32, height: 32)
                Text("\(index)")
                    .font(.callout.weight(.bold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: iconFor(shape.category))
                        .font(.caption)
                        .foregroundStyle(shape.category.fillColor)
                    Text(shape.category.displayName.uppercased())
                        .font(.caption2.bold())
                        .foregroundStyle(.secondary)
                }
                Text(shape.label).font(.body.weight(.medium))
                if !shape.note.isEmpty {
                    Text(shape.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func iconFor(_ cat: ShapeCategory) -> String {
        switch cat {
        case .input:  return "arrow.down.right.circle"
        case .agent:  return "brain"
        case .tool:   return "wrench.adjustable"
        case .router: return "arrow.triangle.branch"
        case .memory: return "externaldrive"
        case .output: return "arrow.up.right.circle"
        default:      return "circle"
        }
    }
}
