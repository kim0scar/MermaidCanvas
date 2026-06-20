import Foundation
import CoreGraphics

/// v1.0+ Visio "hoppa in": drill in/out i en forms ägda underflöde. Array-swap-modell —
/// `shapes`/`edges` är ALLTID den aktiva nivån; föräldranivåerna ligger på `drillStack`.
/// Sparandet viker stacken NON-destruktivt till roten (rootForSave) så autosave aldrig
/// råkar skriva ett underflöde som rotdokument.
struct DrillFrame {
    let parentShapeId: UUID
    let parentLabel: String
    let savedShapes: [ShapeNode]
    let savedEdges: [EdgeConnection]
}

extension CanvasModel {
    var isDrilledIn: Bool { !drillStack.isEmpty }

    /// Brödsmulor: rot → … → nuvarande nivå (för "du är här", anti-vilse för 2e).
    var drillBreadcrumb: [String] {
        ["Huvudflöde"] + drillStack.map { $0.parentLabel.isEmpty ? "Underflöde" : $0.parentLabel }
    }

    /// Hoppa IN i en forms underflöde (skapar ett tomt om det saknas).
    func enterSubprocess(_ shapeId: UUID) {
        guard let shape = shapes.first(where: { $0.id == shapeId }) else { return }
        let sub = shape.subCanvas ?? SubCanvas(canvasWidth: Double(canvasSize.width),
                                               canvasHeight: Double(canvasSize.height))
        drillStack.append(DrillFrame(parentShapeId: shapeId, parentLabel: shape.label,
                                     savedShapes: shapes, savedEdges: edges))
        shapes = sub.shapes
        edges = sub.edges
        selectedShapeId = nil
        multiSelection = []
        undoStack = []; redoStack = []   // undo är per-nivå (enkelt + säkert)
    }

    /// Hoppa UT en nivå — viker tillbaka nuvarande innehåll i förälderns subCanvas.
    func exitSubprocess() {
        guard let frame = drillStack.popLast() else { return }
        var restored = frame.savedShapes
        if let idx = restored.firstIndex(where: { $0.id == frame.parentShapeId }) {
            restored[idx].subCanvas = SubCanvas(shapes: shapes, edges: edges,
                                                canvasWidth: Double(canvasSize.width),
                                                canvasHeight: Double(canvasSize.height))
        }
        shapes = restored
        edges = frame.savedEdges
        selectedShapeId = frame.parentShapeId
        multiSelection = []
        undoStack = []; redoStack = []
    }

    /// Hela vägen ut till roten (brödsmule-tap på "Huvudflöde").
    func exitToRoot() { while isDrilledIn { exitSubprocess() } }

    /// Hoppa till en specifik brödsmule-nivå (index 0 = rot).
    func drillTo(level: Int) {
        while drillStack.count > level { exitSubprocess() }
    }

    /// Rot-innehåll för SPARANDE — viker stacken NON-destruktivt (ändrar inte live-vyn).
    func rootForSave() -> (shapes: [ShapeNode], edges: [EdgeConnection]) {
        if drillStack.isEmpty { return (shapes, edges) }
        var curShapes = shapes, curEdges = edges
        for frame in drillStack.reversed() {
            var parentLevel = frame.savedShapes
            if let idx = parentLevel.firstIndex(where: { $0.id == frame.parentShapeId }) {
                parentLevel[idx].subCanvas = SubCanvas(shapes: curShapes, edges: curEdges,
                                                       canvasWidth: Double(canvasSize.width),
                                                       canvasHeight: Double(canvasSize.height))
            }
            curShapes = parentLevel
            curEdges = frame.savedEdges
        }
        return (curShapes, curEdges)
    }
}
