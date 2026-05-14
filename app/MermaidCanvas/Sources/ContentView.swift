import SwiftUI

struct ContentView: View {
    @StateObject private var model = CanvasModel()
    @State private var statusText: String = "Tom canvas"
    @State private var statusIsError: Bool = false
    @State private var canvasCenter: CGPoint = CGPoint(x: 200, y: 300)

    var body: some View {
        VStack(spacing: 0) {
            ToolbarView(model: model, canvasCenter: canvasCenter) {
                save()
            }
            GeometryReader { geo in
                CanvasView(model: model)
                    .onAppear {
                        canvasCenter = CGPoint(x: geo.size.width / 2,
                                               y: geo.size.height / 2)
                    }
                    .onChange(of: geo.size) { _, newSize in
                        canvasCenter = CGPoint(x: newSize.width / 2,
                                               y: newSize.height / 2)
                    }
            }
            Text(statusText)
                .font(.caption)
                .foregroundStyle(statusIsError ? .red : .secondary)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
        }
    }

    private func save() {
        statusText = "Sparar…"
        statusIsError = false
        let mermaid = MermaidGenerator.generate(from: model.shapes)
        do {
            try CanvasStore.shared.save(mermaid: mermaid)
            let count = model.shapes.count
            statusText = "Sparad — \(count) form\(count == 1 ? "" : "er")"
        } catch {
            statusText = "Fel: \(error.localizedDescription)"
            statusIsError = true
        }
    }
}

#Preview {
    ContentView()
}
