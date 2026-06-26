import SwiftUI
import UniformTypeIdentifiers
import os
import Combine

/// v34: dragLog behålls (för diagnostik) men ShapeDragController är rivet.
let dragLog = Logger(subsystem: "com.kimlundqvist.mermaidcanvas", category: "drag")

struct ContentView: View {
    @StateObject var model = CanvasModel()
    @StateObject var fileManager = CanvasFileManager()
    /// v36: autosave vid bakgrundning.
    @Environment(\.scenePhase) var scenePhase
    /// v60: landskap (compact höjd på iPhone) → vänster vertikal sidebar i stället för topp-bar.
    #if os(iOS)
    @Environment(\.verticalSizeClass) var vSizeClass
    #endif
    /// v34: synkad spegel av pan/zoom-state (chip-drop läser synkront vid drag-end, ingen race).
    @StateObject var viewportState = CanvasViewportState()
    /// v34: aktivt chip-drag (Apple's .draggable/.dropDestination opålitligt i UIScrollView).
    @StateObject var chipDragState = ChipDragState()
    /// v35: canvasCenter är nu DYNAMISK — räknas från viewportState's
    /// synliga viewport-mitt. När Kim panorerar/zoomar och sedan tappar
    /// en chip, läggs formen DÄR HAN TITTAR — inte vid statisk (2000,2000)
    /// som kan vara utanför skärm.
    var canvasCenter: CGPoint { viewportState.visibleCenterInCanvas }
    @State var showImporter = false
    @State var showMultiImporter = false   // v1.1: flera filer som containrar
    @State var showExporter: Bool = false
    @State var pendingDocument: CanvasDocument?
    /// v65: dokument-innehållet som det såg ut när filen öppnades — baslinje för
    /// "har Kim ändrat något?". Oförändrat → autospar rör ingenting alls.
    @State var contentAtOpen: String?
    @State var editingShapeId: UUID? = nil
    /// v66: öppna läs-lappar (flera samtidigt) — ersätter v63:s QuickReadSheet
    @State var openCards: [UUID] = []
    /// v70: bekräftelse efter "Spara skill som fil".
    @State var skillSavedMessage: String? = nil
    /// v75: skill-exporten går via riktig "Spara som"-dialog (Files). Tyst skrivning
    /// bredvid originalet nekas av sandlådan när filen öppnats via Filer-väljaren —
    /// exporten hamnade osynligt i appens egen mapp (Kims fynd på iPhone).
    /// Återanvänder den befintliga fileExportern (en extra krockar — visas aldrig).
    @State var skillExportMode: Bool = false
    @State var skillExportFileName: String = "skill.md"
    /// v73: namn-fråga innan skill sparas (container utan riktigt namn → fråga Kim).
    @State var skillNameContainerId: UUID? = nil
    @State var skillNameInput: String = ""
    @State var showCodeSheet: Bool = false
    @State var showNewCanvasPrompt: Bool = false
    @State var showNewCanvasSheet: Bool = false
    @State var showRulesSheet: Bool = false
    @State var zoomPercent: Int = 100
    @State var resetZoomTrigger: Int = 0
    /// v61: be canvasen centrera på en punkt (sätts vid fil-öppning + jump-links)
    @State var centerOnPoint: CGPoint? = nil
    /// MA-spår C: prenumeration som skriver state-dump vid varje ändring (bara i testläge).
    @State var dumpCancellable: AnyCancellable? = nil
    @State var showNotePopup: Bool = false
    /// v37: Mermaid-import från AI
    @State var showMermaidImport: Bool = false
    /// v41: tabell-redigeraren
    @State var tableEditingShapeId: UUID? = nil
    /// v50.4: visa Component Gallery (debug/visuell verifiering)
    @State var showComponentGallery: Bool = false
    /// v66: legend-panelen på canvasen
    @State var showLegend: Bool = false
    /// Steg H: exporterad bild → delningsmeny.
    @State var exportImageItem: ExportImageItem? = nil
    @State var showCapabilities: Bool = false   // V79-svep: facit-vyn

    // v60: extraherade vyer för adaptiv layout (porträtt topp-bar / landskap vänster-sidebar).
    func toolbarView(vertical: Bool) -> some View {
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
            onRedo: { model.redo() },
            onShowCode: showMermaidCode,
            onCopyCode: copyMermaidCode,
            onExportImage: { jpeg in exportImage(jpeg: jpeg) },
            onShowCapabilities: { showCapabilities = true },
            onInsertTemplate: { kind in model.insertTemplate(kind, at: canvasCenter) },
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
            onImportMultiple: { showMultiImporter = true },
            onToggleLegend: { showLegend.toggle() },
            onDuplicateSelection: { model.duplicateSelection() },
            onDeleteSelection: { model.deleteSelection() },
            onAlignHorizontal: { model.alignSelectionHorizontally() },
            onAlignVertical: { model.alignSelectionVertically() },
            axis: vertical ? .vertical : .horizontal
        )
    }

    var body: some View {
        // v78/MA steg 13: sheet/alert/importer-kedjan ligger i ContentView+Sheets.swift
        // (attachSheets). Kärn-vyn + .onAppear stannar här.
        attachSheets(
        ZStack(alignment: .topLeading) {
            if isCompactHeight {
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
            // V79-svep: launch-arg → öppna "Mermaid vs app"-vyn för se-appen.
            if ProcessInfo.processInfo.arguments.contains("-uitest-capabilities") {
                showCapabilities = true
            }
            // Steg H: launch-arg → exportera bild automatiskt (efter att scenariot
            // hunnit appliceras) så "se-appen" kan hämta PNG:en för fidelity-koll.
            if ProcessInfo.processInfo.arguments.contains("-uitest-export-image") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { exportImage() }
            }
            // Fundament-koll: dumpa hela dokumentet (mermaid + state) så "se-appen"
            // kan rendera den exakta mermaiden och jämföra mot app-bilden.
            if ProcessInfo.processInfo.arguments.contains("-uitest-dump-doc"),
               let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                    try? makeDocument().content.write(
                        to: docs.appendingPathComponent("uitest-doc.md"), atomically: true, encoding: .utf8)
                }
            }
            // MA-spår C: skriv state-dump vid varje modelländring (bara med -uitest-dump-state).
            if StateDump.isEnabled {
                StateDump.writeIfEnabled(model, viewport: viewportState)
                dumpCancellable = model.objectWillChange
                    .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
                    .sink { StateDump.writeIfEnabled(model, viewport: viewportState) }
            }
        }
        // Steg H: delningsmeny för exporterad bild.
        .sheet(item: $exportImageItem) { item in
            ActivityView(items: [item.url])
        }
        // V79-svep: Mermaid vs app-funktioner.
        .sheet(isPresented: $showCapabilities) {
            MermaidVsAppSheet()
        }
        )
    }
}

#Preview {
    ContentView()
}
