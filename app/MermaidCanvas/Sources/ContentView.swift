import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var model = CanvasModel()
    @StateObject private var fileManager = CanvasFileManager()

    @State private var statusText: String = "Tom canvas — tryck Cirkel eller Öppna"
    @State private var statusIsError: Bool = false
    @State private var canvasCenter: CGPoint = CGPoint(x: 200, y: 300)
    @State private var showImporter: Bool = false
    @State private var showExporter: Bool = false
    @State private var pendingDocument: CanvasDocument?

    var body: some View {
        VStack(spacing: 0) {
            ToolbarView(
                model: model,
                canvasCenter: canvasCenter,
                onOpen: { showImporter = true },
                onSave: { save() }
            )
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
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.plainText, .text],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    openFile(url)
                }
            case .failure(let err):
                statusText = "Öppna avbruten: \(err.localizedDescription)"
                statusIsError = true
            }
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
                _ = fileManager.open(url: url)
            case .failure(let err):
                statusText = "Spar avbruten: \(err.localizedDescription)"
                statusIsError = true
            }
        }
        .onChange(of: fileManager.reloadTick) { _, _ in
            reloadFromFile()
        }
    }

    private func openFile(_ url: URL) {
        guard let content = fileManager.open(url: url) else {
            statusText = "Kunde inte läsa filen"
            statusIsError = true
            return
        }
        let shapes = MermaidParser.parse(content)
        model.replaceAll(with: shapes)
        statusText = "Öppnad: \(url.lastPathComponent) — \(shapes.count) form\(shapes.count == 1 ? "" : "er")"
        statusIsError = false
    }

    private func reloadFromFile() {
        guard let content = fileManager.readCurrent() else { return }
        let shapes = MermaidParser.parse(content)
        model.replaceAll(with: shapes)
        statusText = "Uppdaterad från fil — \(shapes.count) form\(shapes.count == 1 ? "" : "er")"
        statusIsError = false
    }

    private func save() {
        if fileManager.hasOpenFile {
            saveToOpenFile()
        } else {
            pendingDocument = CanvasDocument(shapes: model.shapes)
            statusText = "Välj plats…"
            statusIsError = false
            showExporter = true
        }
    }

    private func saveToOpenFile() {
        let doc = CanvasDocument(shapes: model.shapes)
        do {
            try fileManager.write(doc.content)
            let count = model.shapes.count
            let name = fileManager.fileName ?? "fil"
            statusText = "Sparad i \(name) — \(count) form\(count == 1 ? "" : "er")"
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
