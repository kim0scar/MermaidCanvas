import Foundation
import CoreGraphics

/// MA-spår C: skriver CanvasModels tillstånd som JSON till appens Documents-mapp,
/// så Claude Code kan läsa EXAKT vad canvasen innehåller (id, typ, position,
/// storlek, vald/ej, badges) parallellt med en skärmbild. Då går det att skilja
/// en "data-bugg" (fel i modellen) från en "ritnings-bugg" (rätt data, fel pixlar).
///
/// Aktiveras BARA av launch-argumentet `-uitest-dump-state` — aldrig i skarp drift.
/// Skrivs till <Documents>/uitest-state.json. Container-sökväg läses med:
///   xcrun simctl get_app_container <UDID> com.kimlundqvist.mermaidcanvas data
@MainActor
enum StateDump {
    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-uitest-dump-state")
    }

    static func writeIfEnabled(_ model: CanvasModel, viewport: CanvasViewportState) {
        guard isEnabled else { return }

        func selected(_ id: UUID) -> Bool {
            model.selectedShapeId == id || model.multiSelection.contains(id)
        }

        let shapes: [[String: Any]] = model.shapes.map { s in
            let childOf: Any = s.childOfContainerId.map { $0.uuidString as Any } ?? NSNull()
            return [
                "id": s.id.uuidString,
                "type": s.type.rawValue,
                "x": Int(s.position.x.rounded()),
                "y": Int(s.position.y.rounded()),
                "w": Int(ShapeGeometry.width(for: s).rounded()),
                "h": Int(ShapeGeometry.height(for: s).rounded()),
                "label": s.label,
                "hasNote": !s.note.isEmpty,
                "hasPrompt": !s.prompt.isEmpty,
                "selected": selected(s.id),
                "childOf": childOf
            ]
        }

        let edges: [[String: Any]] = model.edges.map { e in
            [
                "id": e.id.uuidString,
                "from": e.from.uuidString,
                "to": e.to.uuidString,
                "label": e.label,
                "direction": e.direction.rawValue,
                "style": e.style.rawValue,
                "collapsed": model.collapsedEdgeIds.contains(e.id)
            ]
        }

        let center = viewport.visibleCenterInCanvas
        let root: [String: Any] = [
            "title": model.canvasTitle,
            "shapeCount": model.shapes.count,
            "edgeCount": model.edges.count,
            "markerMode": model.markerMode,
            "viewport": [
                "zoom": Double((viewport.zoomScale * 100).rounded()) / 100,
                "centerX": Int(center.x.rounded()),
                "centerY": Int(center.y.rounded())
            ],
            "shapes": shapes,
            "edges": edges
        ]

        guard JSONSerialization.isValidJSONObject(root),
              let data = try? JSONSerialization.data(
                withJSONObject: root, options: [.prettyPrinted, .sortedKeys]) else { return }

        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("uitest-state.json")
        try? data.write(to: url)
    }
}
