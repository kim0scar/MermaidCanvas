import SwiftUI
import UIKit

/// Sheets/alerts/importer-exporter för ContentView (MA spår A steg 13). Hela modifier-
/// kedjan från `body` flyttad verbatim till `attachSheets(_:)` (samma ordning → samma
/// beteende). Bindings som styr sheet-presentation ligger också här. View-kärnan +
/// .onAppear ligger kvar i ContentView.swift; fil-logiken i ContentView+Files.swift.
extension ContentView {

    // MARK: - Bindings

    var editingBinding: Binding<Bool> {
        Binding(
            get: { editingShapeId != nil },
            set: { if !$0 { editingShapeId = nil } }
        )
    }

    var notingBinding: Binding<Bool> {
        Binding(
            get: { notingShapeId != nil },
            set: { if !$0 { notingShapeId = nil } }
        )
    }

    var tableEditingBinding: Binding<Bool> {
        Binding(get: { tableEditingShapeId != nil },
                set: { if !$0 { tableEditingShapeId = nil } })
    }

    // MARK: - Sheets / alerts / fil-import-export

    /// Hela presentations-kedjan (sheets, alerts, fileImporter/Exporter, scenePhase-
    /// autospar, reload-on-change). Appliceras på body-kärnan. Ordningen är identisk
    /// med tidigare inline-kedja — rör den inte.
    @ViewBuilder
    func attachSheets<Content: View>(_ content: Content) -> some View {
        content
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
                        prompt: shape.prompt,
                        skillNumber: shape.skillNumber
                    ),
                    isSkillContainer: shape.type == .container && shape.category == .skill,
                    showsPrompt: shape.carriesPrompt,
                    onSave: { edit in
                        model.updateShape(
                            id: id,
                            label: edit.label,
                            showLabel: edit.showLabel,
                            note: edit.note,
                            textStyle: edit.textStyle,
                            textAlignment: edit.textAlignment,
                            hasBullets: edit.hasBullets,
                            prompt: edit.prompt,
                            skillNumber: edit.skillNumber
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
        // v1.1: importera FLERA filer — var och en i en container (jämför varianter).
        .fileImporter(
            isPresented: $showMultiImporter,
            allowedContentTypes: [.plainText, .text],
            allowsMultipleSelection: true
        ) { result in
            if case .success(let urls) = result { importFilesAsContainers(urls) }
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
        // v73: namn-fråga innan skill sparas (container hette inget / "Grupp")
        .alert("Vad heter skillen?", isPresented: Binding(
            get: { skillNameContainerId != nil },
            set: { if !$0 { skillNameContainerId = nil } }
        )) {
            TextField("t.ex. mfp-sortiment", text: $skillNameInput)
            Button("Spara") {
                if let id = skillNameContainerId {
                    let name = skillNameInput.trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty {
                        model.renameShape(id: id, label: name)
                        performSaveSkillFile(containerId: id, name: name)
                    }
                }
                skillNameContainerId = nil
            }
            Button("Avbryt", role: .cancel) { skillNameContainerId = nil }
        } message: {
            Text("Namnet blir filnamn och containerns namn på canvasen.")
        }
        .fileExporter(
            isPresented: $showExporter,
            document: pendingDocument,
            contentType: .plainText,
            defaultFilename: skillExportMode
                ? skillExportFileName
                : (model.canvasTitle.isEmpty ? "canvas.md" : "\(model.canvasTitle).md")
        ) { result in
            // v75: skill-läget — Kim valde mapp för den portabla skill-filen.
            // Aktuell fil byts ALDRIG (Kim stannar i pipeline-filen), ingen sidecar.
            if skillExportMode {
                switch result {
                case .success(let url):
                    Haptics.success()
                    skillSavedMessage = "Sparad som \(url.lastPathComponent)"
                case .failure:
                    Haptics.error()
                    skillSavedMessage = "Kunde inte spara skill-filen"
                }
                skillExportMode = false
                return
            }
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
}
