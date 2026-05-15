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
    @State private var justSaved: Bool = false
    @State private var showCodeSheet: Bool = false
    @State private var generatedCode: String = ""
    @State private var showPreviewSheet: Bool = false
    @State private var showColorSheet: Bool = false
    @State private var showNewCanvasPrompt: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            SpecTypePicker(specType: $model.specType) { new in
                model.setSpecType(new)
                updateIdleStatus()
            }
            Divider()

            ToolbarView(
                model: model,
                canvasCenter: canvasCenter,
                hasOpenFile: fileManager.hasOpenFile,
                onStartEdgeMode: { mode in
                    model.startEdgeMode(mode)
                    updateStatusForEdgeMode()
                },
                onCancelEdgeMode: {
                    model.cancelEdgeMode()
                    updateIdleStatus()
                },
                onOpen: { showImporter = true },
                onSave: save,
                onSaveAs: saveAs,
                onUndo: {
                    model.undo()
                    statusText = "Ångrade senaste ändring"
                    statusIsError = false
                },
                onShowCode: showMermaidCode,
                onShowPreview: { showPreviewSheet = true },
                onToggleMarker: {
                    model.toggleMarkerMode()
                    statusText = model.markerMode
                        ? "Markeringsläge — dra en rektangel för att välja flera"
                        : "Markeringsläge av"
                    statusIsError = false
                },
                onShowColor: { showColorSheet = true },
                onAddTable: {
                    model.addTable(at: canvasCenter)
                    statusText = "Tabell tillagd"
                    statusIsError = false
                },
                onAddJumpLink: {
                    model.addJumpLinkPair(near: canvasCenter)
                    statusText = "Jump-link-par tillagt"
                    statusIsError = false
                },
                onNewCanvas: {
                    if model.shapes.isEmpty {
                        model.clearCanvas()
                        statusText = "Ny canvas"
                        statusIsError = false
                    } else {
                        showNewCanvasPrompt = true
                    }
                }
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
                    onShapeEdgeTap: handleShapeTap,
                    onShapeEdit: { id in editingShapeId = id },
                    onShapeDelete: { id in
                        model.deleteShape(id: id)
                        statusText = "Formen borttagen"
                        statusIsError = false
                    },
                    onEdgeDelete: { id in
                        model.deleteEdge(id: id)
                        statusText = "Pilen borttagen"
                        statusIsError = false
                    },
                    onShapeSelect: { id in
                        if let shape = model.shapes.first(where: { $0.id == id }),
                           shape.type == .link,
                           let partner = model.partnerLink(for: id) {
                            // Jump-link: panorera till partner
                            jumpToPartner(partner: partner, viewportSize: geo.size)
                            statusText = "Hoppade till länk #\(partner.linkNumber ?? 0)"
                            statusIsError = false
                        } else {
                            model.selectShape(id)
                            statusText = "Form vald — dra hörn för storlek, topp för rotation, dubbeltap för meny"
                            statusIsError = false
                        }
                    }
                )
                .onAppear {
                    // canvasCenter ges i CANVAS-koordinater (inte viewport).
                    // Vi väljer mitten av canvasen som default-placering.
                    canvasCenter = CGPoint(
                        x: CanvasModel.contentSize.width / 2,
                        y: CanvasModel.contentSize.height / 2
                    )
                    centerViewOnCanvasCenter(viewportSize: geo.size)
                }
                .onChange(of: geo.size) { _, ns in
                    // Viewport ändrades — håll vyn centrerad på canvas-mitten om inte panad
                    if model.canvasOffset == .zero && model.canvasScale == 1.0 {
                        centerViewOnCanvasCenter(viewportSize: ns)
                    }
                }
            }

            statusBar
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
                        note: shape.note,
                        category: shape.category,
                        rotation: shape.rotation
                    ),
                    specType: model.specType,
                    onSave: { edit in
                        model.updateShape(
                            id: id,
                            label: edit.label,
                            showLabel: edit.showLabel,
                            sizeMultiplier: edit.sizeMultiplier,
                            note: edit.note,
                            category: edit.category,
                            rotation: edit.rotation
                        )
                        editingShapeId = nil
                    },
                    onCancel: { editingShapeId = nil },
                    onDelete: {
                        model.deleteShape(id: id)
                        editingShapeId = nil
                        statusText = "Formen borttagen"
                        statusIsError = false
                    }
                )
            }
        }
        .sheet(isPresented: $showCodeSheet) {
            MermaidCodeSheet(code: generatedCode) {
                showCodeSheet = false
            }
        }
        .sheet(isPresented: $showColorSheet) {
            if let id = model.selectedShapeId,
               let idx = model.shapes.firstIndex(where: { $0.id == id }) {
                ColorPickerPopover(
                    selectedHex: model.shapes[idx].colorOverride,
                    onPick: { hex in
                        model.shapes[idx].colorOverride = hex
                        showColorSheet = false
                    }
                )
                .presentationDetents([.height(360)])
            } else {
                VStack {
                    Text("Välj en form först (tap för att markera)")
                        .padding()
                    Button("Stäng") { showColorSheet = false }
                }
                .presentationDetents([.height(180)])
            }
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
                statusText = "✓ Sparad: \(url.lastPathComponent)"
                statusIsError = false
                _ = fileManager.open(url: url)
                flashSaved()
            case .failure(let err):
                statusText = "Spar avbruten: \(err.localizedDescription)"
                statusIsError = true
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
                model.clearCanvas()
                statusText = "Ny canvas (föregående sparad)"
                statusIsError = false
            }
            Button("Förkasta och börja om", role: .destructive) {
                model.clearCanvas()
                statusText = "Ny canvas"
                statusIsError = false
            }
            Button("Avbryt", role: .cancel) {}
        } message: {
            Text("Du håller på att rensa canvasen. Vill du spara först?")
        }
    }

    // MARK: - Substrukturer

    private var statusBar: some View {
        HStack(spacing: 8) {
            Text(AppVersion.current)
                .font(.footnote.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            Text(statusText)
                .font(.footnote.weight(.medium))
                .foregroundStyle(statusIsError ? .red : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .background(statusIsError ? Color.red.opacity(0.12) : Color.green.opacity(justSaved ? 0.18 : 0.0))
        .background(Color(.secondarySystemBackground))
    }

    private var editingBinding: Binding<Bool> {
        Binding(
            get: { editingShapeId != nil },
            set: { isShown in if !isShown { editingShapeId = nil } }
        )
    }

    // MARK: - Handlers

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
        model.replaceAll(shapes: parsed.shapes,
                         edges: parsed.edges,
                         title: parsed.title,
                         specType: parsed.specType)
        if let size = parsed.canvasSize { model.canvasSize = size }
        statusText = "Öppnad: \(url.lastPathComponent) — \(parsed.shapes.count) former, \(parsed.edges.count) pilar"
        statusIsError = false
    }

    private func reloadFromFile() {
        guard let content = fileManager.readCurrent() else { return }
        let parsed = MermaidParser.parse(content)
        model.replaceAll(shapes: parsed.shapes,
                         edges: parsed.edges,
                         title: parsed.title,
                         specType: parsed.specType)
        if let size = parsed.canvasSize { model.canvasSize = size }
        statusText = "Uppdaterad från fil — \(parsed.shapes.count) former, \(parsed.edges.count) pilar"
        statusIsError = false
    }

    private func save() {
        if fileManager.hasOpenFile {
            saveToOpenFile()
        } else {
            saveAs()
        }
    }

    private func saveAs() {
        pendingDocument = CanvasDocument(
            title: model.canvasTitle,
            shapes: model.shapes,
            edges: model.edges,
            canvasSize: model.canvasSize,
            specType: model.specType,
            collapsedIds: model.collapsedIds
        )
        statusText = "Välj plats för fil…"
        statusIsError = false
        showExporter = true
    }

    private func saveToOpenFile() {
        let doc = CanvasDocument(
            title: model.canvasTitle,
            shapes: model.shapes,
            edges: model.edges,
            canvasSize: model.canvasSize,
            specType: model.specType,
            collapsedIds: model.collapsedIds
        )
        do {
            try fileManager.write(doc.content)
            let name = fileManager.fileName ?? "fil"
            statusText = "✓ Sparad i \(name) — \(model.shapes.count) former, \(model.edges.count) pilar"
            statusIsError = false
            flashSaved()
        } catch {
            statusText = "Fel vid sparning: \(error.localizedDescription)"
            statusIsError = true
        }
    }

    private func showMermaidCode() {
        let doc = CanvasDocument(
            title: model.canvasTitle,
            shapes: model.shapes,
            edges: model.edges,
            canvasSize: model.canvasSize,
            specType: model.specType,
            collapsedIds: model.collapsedIds
        )
        generatedCode = doc.content
        showCodeSheet = true
    }

    private func flashSaved() {
        withAnimation(.easeInOut(duration: 0.2)) { justSaved = true }
        Task {
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.5)) { justSaved = false }
            }
        }
    }

    /// Centrera viewport på canvas-mitten. Vid UI-läge: centrera på iPhone-ramen istället
    /// (så användaren ser ramen direkt vid start).
    private func centerViewOnCanvasCenter(viewportSize: CGSize) {
        let canvasCenter: CGPoint
        if model.specType == .ui {
            let frame = iPhoneFrameMath.canvasFrame(in: CanvasModel.contentSize)
            canvasCenter = CGPoint(x: frame.midX, y: frame.midY)
        } else {
            canvasCenter = CGPoint(
                x: CanvasModel.contentSize.width / 2,
                y: CanvasModel.contentSize.height / 2
            )
        }
        let scale: CGFloat = 1.0
        model.canvasScale = scale
        model.canvasOffset = CGSize(
            width: viewportSize.width / 2 - canvasCenter.x * scale,
            height: viewportSize.height / 2 - canvasCenter.y * scale
        )
    }

    /// Animera vyn till en partner-jump-link.
    private func jumpToPartner(partner: ShapeNode, viewportSize: CGSize) {
        let scale = model.canvasScale
        let newOffset = CGSize(
            width: viewportSize.width / 2 - partner.position.x * scale,
            height: viewportSize.height / 2 - partner.position.y * scale
        )
        withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
            model.canvasOffset = newOffset
        }
    }

    private func updateIdleStatus() {
        if model.shapes.isEmpty {
            statusText = "Tom canvas (\(model.specType.displayName)) — tryck eller dra en form"
        } else {
            statusText = "\(model.shapes.count) former, \(model.edges.count) pilar — \(model.specType.displayName)"
        }
        statusIsError = false
    }
}

#Preview {
    ContentView()
}
