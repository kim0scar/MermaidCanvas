import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var model = CanvasModel()
    @StateObject private var fileManager = CanvasFileManager()
    @StateObject private var dragController = ShapeDragController()

    @State private var canvasCenter: CGPoint = CGPoint(x: 1500, y: 1500)
    @State private var showImporter: Bool = false
    @State private var showExporter: Bool = false
    @State private var pendingDocument: CanvasDocument?
    @State private var editingShapeId: UUID? = nil
    @State private var notingShapeId: UUID? = nil
    @State private var showCodeSheet: Bool = false
    @State private var generatedCode: String = ""
    @State private var showPreviewSheet: Bool = false
    @State private var showNewCanvasPrompt: Bool = false
    @State private var showNewCanvasSheet: Bool = false
    @State private var showRulesSheet: Bool = false
    @State private var zoomPercent: Int = 100
    @State private var resetZoomTrigger: Int = 0

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ToolbarView(
                    model: model,
                    dragController: dragController,
                    canvasCenter: canvasCenter,
                    zoomPercent: zoomPercent,
                    hasOpenFile: fileManager.hasOpenFile,
                    onStartEdgeMode: { model.startEdgeMode($0) },
                    onCancelEdgeMode: { model.cancelEdgeMode() },
                    onOpen: { showImporter = true },
                    onSave: save,
                    onSaveAs: saveAs,
                    onUndo: { model.undo() },
                    onShowCode: showMermaidCode,
                    onShowPreview: { showPreviewSheet = true },
                    onShowRules: { showRulesSheet = true },
                    onToggleMarker: { model.toggleMarkerMode() },
                    onAddTable: { model.addTable(at: canvasCenter) },
                    onAddJumpLink: { model.addJumpLinkPair(near: canvasCenter) },
                    onNewCanvas: {
                        if model.shapes.isEmpty {
                            showNewCanvasSheet = true
                        } else {
                            showNewCanvasPrompt = true
                        }
                    },
                    onResetZoom: { resetZoomTrigger &+= 1 },
                    onDropShape: handleDrop
                )

                CanvasView(
                    model: model,
                    dragController: dragController,
                    onShapeEdgeTap: { id in _ = model.handleEdgeTap(on: id) },
                    onShapeEdit: { id in editingShapeId = id },
                    onShapeDelete: { id in model.deleteShape(id: id) },
                    onEdgeDelete: { id in model.deleteEdge(id: id) },
                    onShapeSelect: { id in model.selectShape(id) },
                    onShapeDuplicate: { id in model.duplicateShape(id: id) },
                    onShapeShowNote: { id in notingShapeId = id },
                    zoomPercent: $zoomPercent,
                    resetZoomTrigger: resetZoomTrigger
                )

            // canvasCenter pekas på canvas-mitten — används vid "lägg till form från meny"
            // (UI-läge: vi vill helst lägga former inom iPhone-frame, men canvas-mitten räcker)
            .onAppear {
                if model.specType == .ui {
                    let frame = iPhoneFrameMath.canvasFrame(in: CanvasModel.contentSize)
                    canvasCenter = CGPoint(x: frame.midX, y: frame.midY)
                } else {
                    canvasCenter = CGPoint(x: CanvasModel.contentSize.width / 2,
                                           y: CanvasModel.contentSize.height / 2)
                }
            }
            .onChange(of: model.specType) { _, new in
                if new == .ui {
                    let frame = iPhoneFrameMath.canvasFrame(in: CanvasModel.contentSize)
                    canvasCenter = CGPoint(x: frame.midX, y: frame.midY)
                } else {
                    canvasCenter = CGPoint(x: CanvasModel.contentSize.width / 2,
                                           y: CanvasModel.contentSize.height / 2)
                }
            }
            }

            // v26: floating chip-preview under drag-out
            if let type = dragController.activeType {
                ChipFace(systemImage: ContentView.chipSystemImage(for: type), larger: true)
                    .position(dragController.globalLocation)
                    .allowsHitTesting(false)
                    .ignoresSafeArea()
                    .transition(.identity)
                    .zIndex(999)
            }
        }
        .sheet(isPresented: editingBinding) {
            if let id = editingShapeId,
               let shape = model.shapes.first(where: { $0.id == id }) {
                EditShapeSheet(
                    shapeId: id,
                    initial: ShapeEdit(
                        label: shape.label,
                        showLabel: shape.showLabel,
                        note: shape.note,
                        textStyle: shape.textStyle
                    ),
                    onSave: { edit in
                        model.updateShape(
                            id: id,
                            label: edit.label,
                            showLabel: edit.showLabel,
                            note: edit.note,
                            textStyle: edit.textStyle
                        )
                        editingShapeId = nil
                    },
                    onCancel: { editingShapeId = nil },
                    onDelete: {
                        model.deleteShape(id: id)
                        editingShapeId = nil
                    }
                )
            }
        }
        .sheet(isPresented: notingBinding) {
            if let id = notingShapeId,
               let idx = model.shapes.firstIndex(where: { $0.id == id }) {
                NoteMiniSheet(
                    note: $model.shapes[idx].note,
                    onDone: { notingShapeId = nil }
                )
            }
        }
        .sheet(isPresented: $showCodeSheet) {
            MermaidCodeSheet(code: generatedCode) {
                showCodeSheet = false
            }
        }
        .sheet(isPresented: $showNewCanvasSheet) {
            NewCanvasSheet(
                onCreate: { st in
                    model.clearCanvas()
                    model.specType = st
                    showNewCanvasSheet = false
                },
                onCancel: { showNewCanvasSheet = false }
            )
        }
        .sheet(isPresented: $showRulesSheet) {
            PlatformRulesSheet(specType: model.specType,
                               onClose: { showRulesSheet = false })
        }
        .sheet(isPresented: $showPreviewSheet) {
            PreviewSheet(
                shapes: model.shapes,
                edges: model.edges,
                canvasSize: model.canvasSize,
                specType: model.specType,
                onClose: { showPreviewSheet = false }
            )
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.plainText, .text],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first { openFile(url) }
            case .failure: break
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
                _ = fileManager.open(url: url)
                // v25: skriv sidecar bredvid den nya filen
                let sidecar = PlatformRules.sidecarMarkdown(for: model.specType)
                fileManager.writeRulesSidecar(rulesText: sidecar)
            case .failure: break
            }
        }
        .onChange(of: fileManager.reloadTick) { _, _ in
            reloadFromFile()
        }
        .confirmationDialog("Spara nuvarande canvas först?",
                            isPresented: $showNewCanvasPrompt,
                            titleVisibility: .visible) {
            Button("Spara först") {
                save()
                showNewCanvasSheet = true
            }
            Button("Förkasta och börja om", role: .destructive) {
                showNewCanvasSheet = true
            }
            Button("Avbryt", role: .cancel) {}
        } message: {
            Text("Du måste välja plattform för en ny canvas. Vill du spara den nuvarande först?")
        }
    }

    // MARK: - Bindings

    private var editingBinding: Binding<Bool> {
        Binding(
            get: { editingShapeId != nil },
            set: { if !$0 { editingShapeId = nil } }
        )
    }

    private var notingBinding: Binding<Bool> {
        Binding(
            get: { notingShapeId != nil },
            set: { if !$0 { notingShapeId = nil } }
        )
    }

    // MARK: - Filhantering

    private func openFile(_ url: URL) {
        guard let content = fileManager.open(url: url) else { return }
        let parsed = MermaidParser.parse(content)
        model.replaceAll(shapes: parsed.shapes,
                         edges: parsed.edges,
                         title: parsed.title,
                         specType: parsed.specType,
                         collapsedIds: parsed.collapsedIds)
        if let size = parsed.canvasSize { model.canvasSize = size }
    }

    private func reloadFromFile() {
        guard let content = fileManager.readCurrent() else { return }
        let parsed = MermaidParser.parse(content)
        model.replaceAll(shapes: parsed.shapes,
                         edges: parsed.edges,
                         title: parsed.title,
                         specType: parsed.specType,
                         collapsedIds: parsed.collapsedIds)
        if let size = parsed.canvasSize { model.canvasSize = size }
    }

    private func save() {
        if fileManager.hasOpenFile {
            saveToOpenFile()
        } else {
            saveAs()
        }
    }

    private func saveAs() {
        pendingDocument = makeDocument()
        showExporter = true
    }

    private func saveToOpenFile() {
        let doc = makeDocument()
        try? fileManager.write(doc.content)
        // v25: skriv sidecar med regler bredvid canvas-filen
        let sidecar = PlatformRules.sidecarMarkdown(for: model.specType)
        fileManager.writeRulesSidecar(rulesText: sidecar)
    }

    private func makeDocument() -> CanvasDocument {
        CanvasDocument(
            title: model.canvasTitle,
            shapes: model.shapes,
            edges: model.edges,
            canvasSize: model.canvasSize,
            specType: model.specType,
            collapsedIds: model.collapsedIds
        )
    }

    private func showMermaidCode() {
        let doc = makeDocument()
        generatedCode = doc.content
        showCodeSheet = true
    }

    // MARK: - Drag-out drop-handler (v26)

    private func handleDrop(_ type: ShapeType, _ globalLocation: CGPoint) {
        guard dragController.isInsideCanvas(globalLocation) else { return }
        let canvasPoint = dragController.canvasPoint(forGlobal: globalLocation)
        switch type {
        case .table:
            model.addTable(at: canvasPoint)
        case .link:
            model.addJumpLinkPair(near: canvasPoint)
        default:
            model.addShape(type, at: canvasPoint)
        }
    }

    static func chipSystemImage(for type: ShapeType) -> String {
        switch type {
        case .circle: return "circle"
        case .rectangle: return "rectangle"
        case .diamond: return "diamond"
        case .text: return "character.textbox"
        case .table: return "tablecells"
        case .link: return "link"
        }
    }
}

#Preview {
    ContentView()
}
