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
    /// v65: dokument-innehållet som det såg ut när filen öppnades — baslinje för
    /// "har Kim ändrat något?". Oförändrat → autospar rör ingenting alls.
    @State private var contentAtOpen: String?
    @State private var editingShapeId: UUID? = nil
    @State private var notingShapeId: UUID? = nil
    /// v66: öppna läs-lappar (flera samtidigt) — ersätter v63:s QuickReadSheet
    @State private var openCards: [UUID] = []
    /// v70: bekräftelse efter "Spara skill som fil".
    @State private var skillSavedMessage: String? = nil
    @State private var showCodeSheet: Bool = false
    @State private var showNewCanvasPrompt: Bool = false
    @State private var showNewCanvasSheet: Bool = false
    @State private var showRulesSheet: Bool = false
    @State private var zoomPercent: Int = 100
    @State private var resetZoomTrigger: Int = 0
    /// v61: be canvasen centrera på en punkt (sätts vid fil-öppning + jump-links)
    @State private var centerOnPoint: CGPoint? = nil
    @State private var showNotePopup: Bool = false
    /// v37: Mermaid-import från AI
    @State private var showMermaidImport: Bool = false
    /// v41: tabell-redigeraren
    @State private var tableEditingShapeId: UUID? = nil
    /// v50.4: visa Component Gallery (debug/visuell verifiering)
    @State private var showComponentGallery: Bool = false
    /// v66: legend-panelen på canvasen
    @State private var showLegend: Bool = false

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
            onCopyCode: copyMermaidCode,
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
            onToggleLegend: { showLegend.toggle() },
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
            onShapeQuickRead: { id in
                // v66: toggla lappen — flera kan vara öppna samtidigt
                if openCards.contains(id) {
                    openCards.removeAll { $0 == id }
                } else {
                    openCards.append(id)
                }
            },
            onTableEdit: { id in tableEditingShapeId = id },
            // v66: kopiera container + barn + memory-noder som skill-mermaid
            onCopySkill: { id in
                UIPasteboard.general.string = MermaidGenerator.generateForContainer(
                    containerId: id,
                    shapes: model.shapes,
                    edges: model.edges,
                    legend: model.legend)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            },
            // v70: spara containern (= en skill) som EGEN canvas-fil i iCloud,
            // bredvid pipeline-filen. Kim stannar kvar i helheten.
            onSaveSkillFile: { id in
                guard let container = model.shapes.first(where: { $0.id == id }) else { return }
                let subset = MermaidGenerator.containerSubset(
                    containerId: id, shapes: model.shapes, edges: model.edges)
                let doc = CanvasDocument(
                    title: container.label.isEmpty ? "skill" : container.label,
                    shapes: subset.shapes,
                    edges: subset.edges,
                    canvasSize: model.canvasSize,
                    specType: .flow,
                    platform: model.platform,
                    activeShapePacks: model.activeShapePacks,
                    collapsedEdgeIds: [],
                    legend: model.legend)
                if let url = fileManager.saveSkillFile(doc.content, named: container.label) {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    skillSavedMessage = "Sparad som \(url.lastPathComponent)"
                } else {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    skillSavedMessage = "Kunde inte spara skill-filen"
                }
            },
            openCards: $openCards,
            zoomPercent: $zoomPercent,
            resetZoomTrigger: resetZoomTrigger,
            centerOnPoint: $centerOnPoint
        )
        // v67: läs-lappar ritas nu PÅ canvasen (canvas-space) inuti CanvasView —
        // de panorerar med tavlan i stället för att sitta fast på skärmen (Kims fynd 2).
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

            // v66: legend-panel (nere till vänster) — togglas via Lägen-menyn
            if showLegend {
                VStack {
                    Spacer()
                    HStack {
                        LegendPanel(model: model, onClose: { showLegend = false })
                            .padding(.leading, 12)
                            .padding(.bottom, 18)
                        Spacer()
                    }
                }
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
        // v66: snabbläsning sker nu via läs-LAPPAR på canvasen (NoteCardsLayer)
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
        // v70: bekräftelse efter "Spara skill som fil"
        .alert("Skill sparad", isPresented: Binding(
            get: { skillSavedMessage != nil },
            set: { if !$0 { skillSavedMessage = nil } }
        )) {
            Button("OK", role: .cancel) { skillSavedMessage = nil }
        } message: {
            Text(skillSavedMessage ?? "")
        }
        .fileExporter(
            isPresented: $showExporter,
            document: pendingDocument,
            contentType: .plainText,
            defaultFilename: model.canvasTitle.isEmpty ? "canvas.md" : "\(model.canvasTitle).md"
        ) { result in
            switch result {
            case .success(let url):
                // v65: filen skapades av appen själv → autospar får skriva direkt
                _ = fileManager.open(url: url, asExisting: false)
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
                         collapsedEdgeIds: parsed.collapsedEdgeIds,
                         legend: parsed.legend)
        if let size = parsed.canvasSize { model.canvasSize = size }
        // v65: baslinje för ändrings-koll — genererat innehåll direkt efter öppning
        contentAtOpen = makeDocument().content
        // v61: centrera vyn på innehållet — annars kan en Claude-ritad fil se TOM ut
        // (formerna utanför skärmen medan vyn står på canvas-mitten).
        centerOnPoint = contentCenter(of: parsed.shapes)
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
                         collapsedEdgeIds: parsed.collapsedEdgeIds,
                         legend: parsed.legend)
        if let size = parsed.canvasSize { model.canvasSize = size }
        // v65: extern skrivning (Claude/iCloud) = ny baslinje för ändrings-kollen
        contentAtOpen = makeDocument().content
        // v61: hoppa BARA om inget av innehållet syns (stör inte Kim mitt i arbetet)
        if !isAnyContentVisible(parsed.shapes) {
            centerOnPoint = contentCenter(of: parsed.shapes)
        }
    }

    /// v61: mittpunkten av innehållets bounding-box. nil om canvasen är tom.
    private func contentCenter(of shapes: [ShapeNode]) -> CGPoint? {
        guard !shapes.isEmpty else { return nil }
        let xs = shapes.map { $0.position.x }
        let ys = shapes.map { $0.position.y }
        return CGPoint(x: (xs.min()! + xs.max()!) / 2,
                       y: (ys.min()! + ys.max()!) / 2)
    }

    /// v61: syns någon form i nuvarande viewport? (med 60pt marginal)
    private func isAnyContentVisible(_ shapes: [ShapeNode]) -> Bool {
        guard !shapes.isEmpty else { return true }
        let scale = viewportState.zoomScale
        guard scale > 0.001, viewportState.globalFrame.width > 0 else { return true }
        let visible = CGRect(
            x: viewportState.contentOffset.width / scale,
            y: viewportState.contentOffset.height / scale,
            width: viewportState.globalFrame.width / scale,
            height: viewportState.globalFrame.height / scale
        ).insetBy(dx: -60, dy: -60)
        return shapes.contains { visible.contains($0.position) }
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
        // v65: en ÖPPNAD befintlig fil skrivs aldrig över.
        // Oförändrat innehåll → spara ingenting. Ändrat → spara som kopia
        // ("namn 2.md") och fortsätt arbeta i kopian; originalet orört.
        if fileManager.openedExisting {
            if doc.content == contentAtOpen { return }
            if fileManager.saveAsCopy(doc.content) != nil {
                contentAtOpen = nil
                if let sidecar = PlatformRules.sidecarMarkdown(for: model.platform) {
                    fileManager.writeRulesSidecar(rulesText: sidecar)
                }
            }
            return
        }
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
            collapsedEdgeIds: model.collapsedEdgeIds,
            legend: model.legend
        )
    }

    private func showMermaidCode() {
        // v32: kod genereras live i sheet via @ObservedObject model
        showCodeSheet = true
    }

    /// v61: 1-tryck — hela dokumentet (frontmatter + mermaid + state-JSON)
    /// rakt till urklipp, redo att klistras in hos Claude Code.
    private func copyMermaidCode() {
        UIPasteboard.general.string = makeDocument().content
        UINotificationFeedbackGenerator().notificationOccurred(.success)
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
        case .phoneFrame:   return "iphone"
        case .triangle:     return "triangle"
        case .cylinder:     return "cylinder"
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
