import SwiftUI
import UniformTypeIdentifiers
import UIKit
import os

/// v34: dragLog behålls (för diagnostik) men ShapeDragController är rivet.
let dragLog = Logger(subsystem: "com.kimlundqvist.mermaidcanvas", category: "drag")

struct ContentView: View {
    @StateObject private var model = CanvasModel()
    @StateObject private var fileManager = CanvasFileManager()
    /// v36: autosave vid bakgrundning.
    @Environment(\.scenePhase) private var scenePhase
    /// v60: landskap (compact höjd på iPhone) → vänster vertikal sidebar i stället för topp-bar.
    @Environment(\.verticalSizeClass) private var vSizeClass
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
    /// v50.4: visa Component Gallery (debug/visuell verifiering)
    @State private var showComponentGallery: Bool = false

    // v60: extraherade vyer för adaptiv layout (porträtt topp-bar / landskap vänster-sidebar).
    private func toolbarView(vertical: Bool) -> some View {
        ToolbarView(
            model: model,
            chipDragState: chipDragState,
            viewportState: viewportState,
            onDropShape: handleDrop,
            canvasCenter: canvasCenter,
            zoomPercent: zoomPercent,
            hasOpenFile: fileManager.hasOpenFile,
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
                if model.shapes.isEmpty { showNewCanvasSheet = true } else { showNewCanvasPrompt = true }
            },
            onResetZoom: { resetZoomTrigger &+= 1 },
            onShowNotePopup: { showNotePopup = true },
            onImportMermaid: { showMermaidImport = true },
            onDuplicateSelection: { model.duplicateSelection() },
            onDeleteSelection: { model.deleteSelection() },
            onAlignHorizontal: { model.alignSelectionHorizontally() },
            onAlignVertical: { model.alignSelectionVertically() },
            axis: vertical ? .vertical : .horizontal
        )
    }

    private var canvasView: some View {
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
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            if vSizeClass == .compact {
                // v60: landskap — canvas i fullskärm, toolbar som vänster sidebar (overlay).
                canvasView
                toolbarView(vertical: true)
                    .padding(.leading, 6)
                    .padding(.top, 6)
            } else {
                // Porträtt — toolbar som topp-bar ovanför canvas (som tidigare).
                VStack(spacing: 0) {
                    toolbarView(vertical: false)
                    canvasView
                }
            }

            // v50.7 UX-003: tomt-tillstånd-vägledning (centrerad). Blockerar inga gester.
            if model.shapes.isEmpty && chipDragState.activeType == nil {
                EmptyCanvasHint()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }

            // v34: flytande chip-preview vid finger under aktiv drag
            if let type = chipDragState.activeType {
                FloatingChipPreview(type: type)
                    .position(chipDragState.globalLocation)
                    .allowsHitTesting(false)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            applyUITestScenarioIfNeeded()
            // v50.4: launch-arg → visa Component Gallery direkt
            if ProcessInfo.processInfo.arguments.contains("-uitest-component-gallery") {
                showComponentGallery = true
            }
        }
        .sheet(isPresented: $showComponentGallery) {
            NavigationStack {
                ComponentGallery()
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Klar") { showComponentGallery = false }
                        }
                    }
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
                        hasBullets: shape.hasBullets,
                        prompt: shape.prompt
                    ),
                    onSave: { edit in
                        model.updateShape(
                            id: id,
                            label: edit.label,
                            showLabel: edit.showLabel,
                            note: edit.note,
                            textStyle: edit.textStyle,
                            textAlignment: edit.textAlignment,
                            hasBullets: edit.hasBullets,
                            prompt: edit.prompt
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
        // v60.1: UIKit-livscykeln (egen UIWindow i stället för WindowGroup) kan göra scenePhase
        // mindre pålitlig — lyssna även direkt på didEnterBackground så autospar garanterat sker.
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
            if fileManager.hasOpenFile { saveToOpenFile() }
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
        case .octagon:      return "octagon"
        }
    }

    /// Programmatic test-scenarios via launch-argument.
    /// XCUITest:s connection.handle-drag fungerar inte reliably i sim,
    /// så vi måste skapa scenarier direkt på modellen för visuell verifiering.
    ///
    /// Stödjer två generationer:
    ///  • `-uitest-v49-*` → äldre kompakt-scenarier (rect-circle-arrow / vertical / collapsed)
    ///  • `-uitest-place-NN-*` → v50 placerings-matris i UITestScenarios.swift
    private func applyUITestScenarioIfNeeded() {
        let args = ProcessInfo.processInfo.arguments
        let hasV49 = args.contains(where: { $0.hasPrefix("-uitest-v49-") })
        let hasV50 = args.contains(where: { $0.hasPrefix("-uitest-place-") })
        guard hasV49 || hasV50 else { return }

        // Vänta en frame så viewport hinner initieras
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let center = viewportState.visibleCenterInCanvas
            if hasV50 {
                _ = UITestScenarios.apply(args: args, model: model, center: center)
                return
            }
            // Legacy v49-scenarier behålls för bakåtkomp med befintliga tester.
            var rect = ShapeNode(type: .rectangle, position: CGPoint(x: center.x - 120, y: center.y))
            var circle = ShapeNode(type: .circle, position: CGPoint(x: center.x + 120, y: center.y))
            if args.contains("-uitest-v49-vertical-arrow") {
                rect.position = CGPoint(x: center.x, y: center.y - 120)
                circle.position = CGPoint(x: center.x, y: center.y + 120)
            }
            model.shapes.append(rect)
            model.shapes.append(circle)
            model.addEdge(from: rect.id, to: circle.id)
            model.selectedShapeId = rect.id
            if args.contains("-uitest-v49-collapsed") {
                model.toggleCollapse(id: rect.id)
            }
        }
    }
}

#Preview {
    ContentView()
}
