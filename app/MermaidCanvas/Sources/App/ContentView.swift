import SwiftUI
import UniformTypeIdentifiers
import os

/// v34: dragLog behålls (för diagnostik) men ShapeDragController är rivet.
let dragLog = Logger(subsystem: "com.kimlundqvist.mermaidcanvas", category: "drag")

struct ContentView: View {
    @StateObject private var model = CanvasModel()
    @StateObject private var fileManager = CanvasFileManager()
    /// v36: autosave vid bakgrundning.
    @Environment(\.scenePhase) private var scenePhase
    /// v34: synkroniserad spegel av UIScrollView's pan/zoom-state.
    /// Speglat live i ZoomableCanvas delegate-callbacks (utan async). Manuell
    /// chip-drop läser detta synkront vid drag-end → ingen race-condition.
    @StateObject private var viewportState = CanvasViewportState()
    /// v34: aktivt chip-drag (ersätter Apple's .draggable/.dropDestination
    /// som inte fungerar pålitligt inuti UIViewRepresentable runt UIScrollView).
    @StateObject private var chipDragState = ChipDragState()

    /// v35: canvasCenter är nu DYNAMISK — räknas från viewportState's
    /// synliga viewport-mitt. När Kim panorerar/zoomar och sedan tappar
    /// en chip, läggs formen DÄR HAN TITTAR — inte vid statisk (2000,2000)
    /// som kan vara utanför skärm.
    private var canvasCenter: CGPoint { viewportState.visibleCenterInCanvas }
    @State private var showImporter: Bool = false
    @State private var showExporter: Bool = false
    @State private var pendingDocument: CanvasDocument?
    @State private var editingShapeId: UUID? = nil
    @State private var notingShapeId: UUID? = nil
    @State private var showCodeSheet: Bool = false
    @State private var showNewCanvasPrompt: Bool = false
    @State private var showNewCanvasSheet: Bool = false
    @State private var showRulesSheet: Bool = false
    @State private var zoomPercent: Int = 100
    @State private var resetZoomTrigger: Int = 0
    @State private var showNotePopup: Bool = false
    /// v37: Mermaid-import från AI
    @State private var showMermaidImport: Bool = false
    /// v41: tabell-redigeraren
    @State private var tableEditingShapeId: UUID? = nil

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                ToolbarView(
                    model: model,
                    chipDragState: chipDragState,
                    viewportState: viewportState,
                    onDropShape: handleDrop,
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
                    onShowNotePopup: { showNotePopup = true },
                    onImportMermaid: { showMermaidImport = true },
                    onDuplicateSelection: { model.duplicateSelection() },
                    onDeleteSelection: { model.deleteSelection() },
                    onAlignHorizontal: { model.alignSelectionHorizontally() },
                    onAlignVertical: { model.alignSelectionVertically() }
                )

                CanvasView(
                    model: model,
                    viewportState: viewportState,
                    onShapeEdgeTap: { id in _ = model.handleEdgeTap(on: id) },
                    onShapeEdit: { id in editingShapeId = id },
                    onShapeDelete: { id in model.deleteShape(id: id) },
                    onEdgeDelete: { id in model.deleteEdge(id: id) },
                    onShapeSelect: { id in model.selectShape(id) },
                    onShapeDuplicate: { id in model.duplicateShape(id: id) },
                    onShapeShowNote: { id in notingShapeId = id },
                    onTableEdit: { id in tableEditingShapeId = id },
                    zoomPercent: $zoomPercent,
                    resetZoomTrigger: resetZoomTrigger
                )

            // v35: canvasCenter är dynamisk via computed property från viewportState
            // — ingen .onAppear / .onChange behövs.
            }

            // v34: flytande chip-preview vid finger under aktiv drag
            if let type = chipDragState.activeType {
                FloatingChipPreview(type: type)
                    .position(chipDragState.globalLocation)
                    .allowsHitTesting(false)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: editingBinding) {
            if let id = editingShapeId,
               let shape = model.shapes.first(where: { $0.id == id }) {
                EditShapeSheet(
                    shapeId: id,
                    initial: ShapeEdit(
                        label: shape.label,
                        showLabel: shape.showLabel,
                        note: shape.note,
                        textStyle: shape.textStyle,
                        textAlignment: shape.textAlignment,
                        hasBullets: shape.hasBullets
                    ),
                    onSave: { edit in
                        model.updateShape(
                            id: id,
                            label: edit.label,
                            showLabel: edit.showLabel,
                            note: edit.note,
                            textStyle: edit.textStyle,
                            textAlignment: edit.textAlignment,
                            hasBullets: edit.hasBullets
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
            // v32: live från model (inte cached string)
            MermaidCodeSheet(model: model) {
                showCodeSheet = false
            }
        }
        .sheet(isPresented: $showNotePopup) {
            NotePopupSheet(
                shapes: model.shapes,
                onClose: { showNotePopup = false }
            )
        }
        .sheet(isPresented: $showNewCanvasSheet) {
            NewCanvasSheet(
                onCreate: { platform in
                    model.clearCanvas(platform: platform)
                    showNewCanvasSheet = false
                },
                onCancel: { showNewCanvasSheet = false }
            )
        }
        .sheet(isPresented: $showRulesSheet) {
            PlatformRulesSheet(platform: model.platform,
                               onClose: { showRulesSheet = false })
        }
        // v37: Importera Mermaid från AI
        .sheet(isPresented: $showMermaidImport) {
            MermaidImportSheet(model: model) {
                showMermaidImport = false
            }
        }
        // v41: tabell-redigerare (dubbelklick på tabell-form)
        .sheet(isPresented: tableEditingBinding) {
            if let id = tableEditingShapeId,
               let shape = model.shapes.first(where: { $0.id == id }),
               shape.type == .table {
                TableEditorSheet(
                    shapeId: id,
                    initialRows: shape.tableRows ?? 3,
                    initialCols: shape.tableCols ?? 3,
                    initialCells: shape.tableCells ?? [],
                    initialLabel: shape.label,
                    onSave: { label, rows, cols, cells in
                        model.updateTableShape(id: id, label: label, rows: rows, cols: cols, cells: cells)
                        tableEditingShapeId = nil
                    },
                    onCancel: { tableEditingShapeId = nil }
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
                if let sidecar = PlatformRules.sidecarMarkdown(for: model.platform) {
                    fileManager.writeRulesSidecar(rulesText: sidecar)
                }
            case .failure: break
            }
        }
        .onChange(of: fileManager.reloadTick) { _, _ in
            reloadFromFile()
        }
        // v36: autospara när appen bakgrundas (inga data försvinner)
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background, fileManager.hasOpenFile {
                saveToOpenFile()
            }
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

    private var tableEditingBinding: Binding<Bool> {
        Binding(get: { tableEditingShapeId != nil },
                set: { if !$0 { tableEditingShapeId = nil } })
    }

    // MARK: - Filhantering

    private func openFile(_ url: URL) {
        guard let content = fileManager.open(url: url) else { return }
        let parsed = MermaidParser.parse(content)
        model.replaceAll(shapes: parsed.shapes,
                         edges: parsed.edges,
                         title: parsed.title,
                         specType: parsed.specType,
                         platform: parsed.platform,
                         activeShapePacks: parsed.activeShapePacks,
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
                         platform: parsed.platform,
                         activeShapePacks: parsed.activeShapePacks,
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
        // v27: skriv sidecar med regler bredvid canvas-filen — bara om Godot
        if let sidecar = PlatformRules.sidecarMarkdown(for: model.platform) {
            fileManager.writeRulesSidecar(rulesText: sidecar)
        }
    }

    private func makeDocument() -> CanvasDocument {
        CanvasDocument(
            title: model.canvasTitle,
            shapes: model.shapes,
            edges: model.edges,
            canvasSize: model.canvasSize,
            specType: model.specType,
            platform: model.platform,
            activeShapePacks: model.activeShapePacks,
            collapsedIds: model.collapsedIds
        )
    }

    private func showMermaidCode() {
        // v32: kod genereras live i sheet via @ObservedObject model
        showCodeSheet = true
    }

    // MARK: - Drop-handler (v34)

    /// v34: drop-handler. Får canvas-lokala koordinater direkt från
    /// CanvasView's .dropDestination — ingen översättning behövs.
    private func handleDrop(_ type: ShapeType, _ canvasPoint: CGPoint) {
        dragLog.info("handleDrop type=\(type.rawValue) canvasPoint=(\(canvasPoint.x),\(canvasPoint.y))")
        switch type {
        case .table:
            model.addTable(at: canvasPoint)
        case .line:
            model.addFreeLine(at: canvasPoint, withArrow: false)
        case .arrow:
            model.addFreeLine(at: canvasPoint, withArrow: true)
        case .link:
            model.addJumpLinkPair(near: canvasPoint)
        default:
            model.addShape(type, at: canvasPoint)
        }
        // v33 Apple-nivå: medium haptic-bekräftelse på drop — formen "landade",
        // användaren känner det utan att titta. Klassisk iOS-feedback (jfr Photos drag).
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    static func chipSystemImage(for type: ShapeType) -> String {
        switch type {
        case .circle:       return "circle"
        case .rectangle:    return "rectangle"
        case .diamond:      return "diamond"
        case .table:        return "tablecells"
        case .link:         return "link"
        case .pill:         return "capsule"
        case .line:         return "minus"
        case .arrow:        return "arrow.right"
        case .square:       return "square"
        case .processArrow: return "arrowshape.right"
        // v44
        case .container:    return "rectangle.dashed"
        }
    }
}

#Preview {
    ContentView()
}
