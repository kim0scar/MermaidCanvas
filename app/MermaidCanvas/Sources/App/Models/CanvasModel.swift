import Foundation
import SwiftUI

enum EdgeCreationMode: Equatable {
    case off
    case directional
    case bidirectional
}

struct CanvasSnapshot {
    let shapes: [ShapeNode]
    let edges: [EdgeConnection]
    let title: String
    let specType: SpecType
    let platform: Platform
    let activeShapePacks: Set<ShapePack>
}

@MainActor
final class CanvasModel: ObservableObject {
    @Published var shapes: [ShapeNode] = []
    @Published var edges: [EdgeConnection] = []
    @Published var edgeCreationMode: EdgeCreationMode = .off
    @Published var pendingEdgeFrom: UUID? = nil
    @Published var canvasTitle: String = ""
    @Published var canvasSize: CGSize = CGSize(width: 3000, height: 3000)
    @Published var specType: SpecType = .general
    /// v27: Platform = regelstyrt mål (Blank/Godot). Låses per canvas.
    @Published var platform: Platform = .blank
    /// v27: Form-paketer = oberoende av platform, kan toggle:as i farten.
    @Published var activeShapePacks: Set<ShapePack> = [.basic]

    // v23: pan/zoom-state är @State i CanvasView för perf (60Hz @Published rerenderade allt)

    // v19: selection-state — bara UI
    @Published var selectedShapeId: UUID? = nil
    @Published var multiSelection: Set<UUID> = []
    @Published var markerMode: Bool = false
    @Published var isEditingText: Bool = false   // 1.5: inline-redigering → göm topp-sekundärraden
    /// v63: kollaps är PER GREN (kant-id), inte per nod — Kims fynd: minus-badgen
    /// på en pil kollapsade alla beroendepilar från samma symbol.
    @Published var collapsedEdgeIds: Set<UUID> = []
    /// v66: legend — kategori-rawValue → Kims betydelse-text. Round-trippar via state-JSON + %% legend.
    @Published var legend: [String: String] = [:]

    // v34: canvas är fast 4000×4000 — kvadratisk vit yta. UIScrollView hanterar
    // pan/zoom symmetriskt. Inga dynamiska expansioner (Kim valde fast storlek).
    static let contentSize = CGSize(width: 4000, height: 4000)
    @Published var contentSize: CGSize = CGSize(width: 4000, height: 4000)

    var undoStack: [CanvasSnapshot] = []; var redoStack: [CanvasSnapshot] = []   // V79: ångra båda håll
    @Published var drillStack: [DrillFrame] = []   // v1.0+ Visio: aktiva "hoppa in"-nivåer
    let undoLimit = 30

    var isEdgeMode: Bool { edgeCreationMode != .off }
}
