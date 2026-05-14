import SwiftUI

struct ContentView: View {
    @StateObject private var model = CanvasModel()
    @State private var statusText: String = "Tom canvas"
    @State private var statusIsError: Bool = false

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                ToolbarView(
                    model: model,
                    canvasCenter: CGPoint(x: geo.size.width / 2,
                                          y: (geo.size.height - 80) / 2)
                ) {
                    save()
                }
                CanvasView(model: model)
                Text(statusText)
                    .font(.caption2)
                    .foregroundStyle(statusIsError ? .red : .secondary)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(.thinMaterial)
            }
        }
    }

    private func save() {
        let mermaid = MermaidGenerator.generate(from: model.shapes)
        do {
            try CanvasStore.shared.save(mermaid: mermaid)
            let count = model.shapes.count
            statusText = "Sparad — \(count) form\(count == 1 ? "" : "er")"
            statusIsError = false
        } catch {
            statusText = "Fel: \(error.localizedDescription)"
            statusIsError = true
        }
    }
}

#Preview {
    ContentView()
}
