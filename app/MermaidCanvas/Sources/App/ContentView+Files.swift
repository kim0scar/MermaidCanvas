import SwiftUI
import UIKit

/// Fil- & persistenslager för ContentView (MA spår A steg 12): öppna/spara/reload,
/// autospar-mål, skill-export, drop-handler och test-scenarier. Utbruten som extension
/// av SAMMA typ — exakt samma beteende (rör autosave/iCloud, oförändrat). View-body
/// ligger kvar i ContentView.swift; sheet/alert-kedjan i ContentView+Sheets.swift.
extension ContentView {

    // MARK: - Filhantering

    func openFile(_ url: URL) {
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

    func reloadFromFile() {
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
    func contentCenter(of shapes: [ShapeNode]) -> CGPoint? {
        guard !shapes.isEmpty else { return nil }
        let xs = shapes.map { $0.position.x }
        let ys = shapes.map { $0.position.y }
        return CGPoint(x: (xs.min()! + xs.max()!) / 2,
                       y: (ys.min()! + ys.max()!) / 2)
    }

    /// v61: syns någon form i nuvarande viewport? (med 60pt marginal)
    func isAnyContentVisible(_ shapes: [ShapeNode]) -> Bool {
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

    func save() {
        if fileManager.hasOpenFile {
            saveToOpenFile()
        } else {
            saveAs()
        }
    }

    func saveAs() {
        pendingDocument = makeDocument()
        showExporter = true
    }

    func saveToOpenFile() {
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

    func makeDocument() -> CanvasDocument {
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

    /// v73: själva skill-sparandet — körs direkt om containern har namn,
    /// annars efter namn-frågan (alerten ovan).
    /// v74: portabel fil via SkillFileComposer — kontrakt + skill-frontmatter inbäddat.
    func performSaveSkillFile(containerId: UUID, name: String) {
        let subset = MermaidGenerator.containerSubset(
            containerId: containerId, shapes: model.shapes, edges: model.edges)
        let skillNumber = model.shapes.first(where: { $0.id == containerId })?.skillNumber
        let content = SkillFileComposer.compose(
            skillName: name,
            skillNumber: skillNumber,
            shapes: subset.shapes,
            edges: subset.edges,
            canvasSize: model.canvasSize,
            platform: model.platform,
            activeShapePacks: model.activeShapePacks,
            legend: model.legend)
        // v75: alltid "Spara som"-dialog — Kim väljer mappen, inget hamnar osynligt.
        // v76: "skill-N-"-prefix så exporten aldrig krockar med (och skriver över)
        // själva ritningsfilen, som ofta heter samma som containern.
        // Liten fördröjning: long-press-menyns popover måste hinna stängas först.
        let prefix = skillNumber.map { "skill-\($0)-" } ?? "skill-"
        skillExportFileName = "\(prefix)\(CanvasFileManager.sanitizeFileName(name)).md"
        skillExportMode = true
        pendingDocument = CanvasDocument(content: content)
        // v76: 0,5 s räckte inte alltid (iOS 26) — popovern hann inte stängas
        // och dialogen uteblev tyst. 0,9 s ger marginal.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            showExporter = true
        }
    }

    /// V79-svep: spara formerna inom en container som REN mermaid-fil (frontmatter +
    /// mermaid + state) — inte skill-kontraktet. Återanvänder subset + samma exporter-
    /// dialog som skill-exporten (rör aldrig den öppna pipeline-filen).
    func saveContainerMermaid(containerId: UUID) {
        let subset = MermaidGenerator.containerSubset(
            containerId: containerId, shapes: model.shapes, edges: model.edges)
        let raw = (model.shapes.first { $0.id == containerId }?.label ?? "")
            .trimmingCharacters(in: .whitespaces)
        let baseName = (raw.isEmpty || raw == "Grupp") ? "container" : raw
        let doc = CanvasDocument(
            title: baseName,
            shapes: subset.shapes,
            edges: subset.edges,
            canvasSize: model.canvasSize,
            specType: model.specType,
            platform: model.platform,
            activeShapePacks: model.activeShapePacks,
            collapsedEdgeIds: model.collapsedEdgeIds,
            legend: model.legend)
        skillExportFileName = "\(CanvasFileManager.sanitizeFileName(baseName)).md"
        skillExportMode = true
        pendingDocument = doc
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { showExporter = true }
    }

    func showMermaidCode() {
        // v32: kod genereras live i sheet via @ObservedObject model
        showCodeSheet = true
    }

    /// Steg H: exportera RITADE ytan som PNG (samma render-väg som canvasen),
    /// spara i appens Documents och öppna delningsmenyn. Tom canvas → fel-haptik.
    func exportImage() {
        guard let data = CanvasImageExporter.renderPNG(model: model) else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        let base = model.canvasTitle.trimmingCharacters(in: .whitespaces)
        let name = base.isEmpty ? "ritning" : base
        guard let url = fileManager.saveImage(data, named: name) else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        exportImageItem = ExportImageItem(url: url)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// v61: 1-tryck — hela dokumentet (frontmatter + mermaid + state-JSON)
    /// rakt till urklipp, redo att klistras in hos Claude Code.
    func copyMermaidCode() {
        UIPasteboard.general.string = makeDocument().content
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // MARK: - Drop-handler (v34)

    /// v34: drop-handler. Får canvas-lokala koordinater direkt från
    /// CanvasView's .dropDestination — ingen översättning behövs.
    func handleDrop(_ type: ShapeType, _ canvasPoint: CGPoint) {
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
    func applyUITestScenarioIfNeeded() {
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
