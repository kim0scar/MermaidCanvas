import SwiftUI

struct ContentView: View {
    @StateObject private var model = CanvasModel()
    @State private var statusText: String = "Tom canvas"
    @State private var statusIsError: Bool = false
    @State private var canvasCenter: CGPoint = CGPoint(x: 200, y: 300)
    @State private var showExporter: Bool = false
    @State private var pendingDocument: CanvasDocument?

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
        .fileExporter(
            isPresented: $showExporter,
            document: pendingDocument,
            contentType: .plainText,
            defaultFilename: "canvas.md"
        ) { result in
            switch result {
            case .success(let url):
                statusText = "Sparad: \(url.lastPathComponent)"
                statusIsError = false
            case .failure(let err):
                statusText = "Avbruten eller fel: \(err.localizedDescription)"
                statusIsError = true
            }
        }
    }

    private func save() {
        let mermaid = MermaidGenerator.generate(from: model.shapes)
        pendingDocument = CanvasDocument(mermaid: mermaid)
        statusText = "Välj plats…"
        statusIsError = false
        showExporter = true
    }
}

#Preview {
    ContentView()
}
