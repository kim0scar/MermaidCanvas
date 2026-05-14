import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var model = CanvasModel()
    @StateObject private var fileManager = CanvasFileManager()

    @State private var statusText: String = "Tom canvas — tryck eller dra en form"
    @State private var statusIsError: Bool = false
    @State private var canvasCenter: CGPoint = CGPoint(x: 200, y: 320)
    @State private var showImporter: Bool = false
    @State private var showExporter: Bool = false
    @State private var pendingDocument: CanvasDocument?
    @State private var editingShapeId: UUID? = nil

    var body: some View {
        VStack(spacing: 0) {
            ToolbarView(
                model: model,
                canvasCenter: canvasCenter,
                onStartEdgeMode: { mode in
                    model.startEdgeMode(mode)
                    updateStatusForEdgeMode()
                },
                onCancelEdgeMode: {
                    model.cancelEdgeMode()
                    updateIdleStatus()
                },
                onOpen: { showImporter = true },
                onSave: save
            )

            TextField("Rubrik", text: $model.canvasTitle)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(Color(.systemBackground))
            Divider()

            GeometryReader { geo in
                CanvasView(
                    model: model,
                    onShapeTap: handleShapeTap,
                    onShapeEdit: { id in editingShapeId = id }
                )
                .onAppear {
                    canvasCenter = CGPoint(x: geo.size.width / 2,
                                           y: geo.size.height / 2)
                    model.canvasSize = geo.size
                }
                .onChange(of: geo.size) { _, ns in
                    canvasCenter = CGPoint(x: ns.width / 2, y: ns.height / 2)
                    model.canvasSize = ns
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
        .sheet(isPresented: editingBinding) {
            if let id = editingShapeId,
               let shape = model.shapes.first(where: { $0.id == id }) {
                EditShapeSheet(
                    shapeId: id,
                    initial: ShapeEdit(
                        label: shape.label,
                        showLabel: shape.showLabel,
                        sizeMultiplier: shape.sizeMultiplier,
                        note: shape.note
                    ),
                    onSave: { edit in
                        model.updateShape(
                            id: id,
                            label: edit.label,
                            showLabel: edit.showLabel,
                            sizeMultiplier: edit.sizeMultiplier,
                            note: edit.note
                        )
                        editingShapeId = nil
                    },
                    onCancel: { editingShapeId = nil }
                )
            }
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.plainText, .text],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first { openFile(url) }
            case .failure(let err):
                statusText = "Öppna avbruten: \(err.localizedDescription)"
                statusIsError = true
            }
        }
        .fileExporter(
            isPresented: $showExporter,
            document: pendingDocument,
            contentType: .plainText,
            defaultFilename: model.canvasTitle.isEmpty ? "canvas.md" : "\(model.canvasTitle).md"
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

    private var editingBinding: Binding<Bool> {
        Binding(
            get: { editingShapeId != nil },
            set: { isShown in if !isShown { editingShapeId = nil } }
        )
    }

    private func handleShapeTap(_ id: UUID) {
        let created = model.handleEdgeTap(on: id)
        if created {
            statusText = "Pil skapad — \(model.edges.count) total"
            statusIsError = false
        } else if model.pendingEdgeFrom != nil {
            let kind = model.edgeCreationMode == .bidirectional ? "dubbel-pil" : "pil"
            statusText = "Tryck målform för \(kind)"
            statusIsError = false
        } else {
            updateIdleStatus()
        }
    }

    private func updateStatusForEdgeMode() {
        switch model.edgeCreationMode {
        case .directional:
            statusText = "Pil-mode: tryck startform"
        case .bidirectional:
            statusText = "Dubbel-pil-mode: tryck startform"
        case .off:
            updateIdleStatus()
        }
        statusIsError = false
    }

    private func openFile(_ url: URL) {
        guard let content = fileManager.open(url: url) else {
            statusText = "Kunde inte läsa filen"
            statusIsError = true
            return
        }
        let parsed = MermaidParser.parse(content)
        model.replaceAll(shapes: parsed.shapes, edges: parsed.edges, title: parsed.title)
        if let size = parsed.canvasSize { model.canvasSize = size }
        statusText = "Öppnad: \(url.lastPathComponent) — \(parsed.shapes.count) former, \(parsed.edges.count) pilar"
        statusIsError = false
    }

    private func reloadFromFile() {
        guard let content = fileManager.readCurrent() else { return }
        let parsed = MermaidParser.parse(content)
        model.replaceAll(shapes: parsed.shapes, edges: parsed.edges, title: parsed.title)
        if let size = parsed.canvasSize { model.canvasSize = size }
        statusText = "Uppdaterad från fil — \(parsed.shapes.count) former, \(parsed.edges.count) pilar"
        statusIsError = false
    }

    private func save() {
        if fileManager.hasOpenFile {
            saveToOpenFile()
        } else {
            pendingDocument = CanvasDocument(
                title: model.canvasTitle,
                shapes: model.shapes,
                edges: model.edges,
                canvasSize: model.canvasSize
            )
            statusText = "Välj plats…"
            statusIsError = false
            showExporter = true
        }
    }

    private func saveToOpenFile() {
        let doc = CanvasDocument(
            title: model.canvasTitle,
            shapes: model.shapes,
            edges: model.edges,
            canvasSize: model.canvasSize
        )
        do {
            try fileManager.write(doc.content)
            let name = fileManager.fileName ?? "fil"
            statusText = "Sparad i \(name) — \(model.shapes.count) former, \(model.edges.count) pilar"
            statusIsError = false
        } catch {
            statusText = "Fel: \(error.localizedDescription)"
            statusIsError = true
        }
    }

    private func updateIdleStatus() {
        if model.shapes.isEmpty {
            statusText = "Tom canvas — tryck eller dra en form"
        } else {
            statusText = "\(model.shapes.count) former, \(model.edges.count) pilar"
        }
        statusIsError = false
    }
}

#Preview {
    ContentView()
}
