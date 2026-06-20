import Foundation
import CoreGraphics

extension CanvasModel {
    /// V79-svep: snabb-mallar (Kims "Mall: AI-Skill / UI / Arkitektur") — lägger en
    /// färdig start-grupp vid given punkt så man slipper rita från noll.
    enum TemplateKind: String, CaseIterable {
        case aiSkill, uiScreen, arkitektur
        var title: String {
            switch self {
            case .aiSkill:    return "AI-Skill"
            case .uiScreen:   return "UI-skärm"
            case .arkitektur: return "Arkitektur"
            }
        }
        var systemImage: String {
            switch self {
            case .aiSkill:    return "hexagon"
            case .uiScreen:   return "iphone"
            case .arkitektur: return "square.stack.3d.up"
            }
        }
    }

    func insertTemplate(_ kind: TemplateKind, at p: CGPoint) {
        snapshotForUndo()
        var newShapes: [ShapeNode] = []
        var newEdges: [EdgeConnection] = []
        switch kind {
        case .aiSkill:
            // Skill-container med input → subagent → output (Kims skill-flöde-vokabulär).
            var box = ShapeNode(type: .container, position: p, label: "Skill 1", category: .skill)
            box.skillNumber = 1
            let inp = ShapeNode(type: .pill, position: CGPoint(x: p.x - 100, y: p.y),
                                label: "Input", category: .input, childOfContainerId: box.id)
            let sub = ShapeNode(type: .rectangle, position: p,
                                label: "Subagent", category: .subagent, childOfContainerId: box.id)
            let out = ShapeNode(type: .pill, position: CGPoint(x: p.x + 100, y: p.y),
                                label: "Output", category: .output, childOfContainerId: box.id)
            newShapes = [box, inp, sub, out]
            newEdges = [EdgeConnection(from: inp.id, to: sub.id),
                        EdgeConnection(from: sub.id, to: out.id)]
        case .uiScreen:
            newShapes = [ShapeNode(type: .phoneFrame, position: p, label: "iPhone 16 Pro")]
        case .arkitektur:
            let mod = ShapeNode(type: .rectangle, position: CGPoint(x: p.x - 100, y: p.y),
                                label: "Modul", category: .feat)
            let doc = ShapeNode(type: .rectangle, position: CGPoint(x: p.x + 100, y: p.y),
                                label: "dok.md", category: .fileMarkdown)
            newShapes = [mod, doc]
            newEdges = [EdgeConnection(from: mod.id, to: doc.id)]
        }
        shapes.append(contentsOf: newShapes)
        edges.append(contentsOf: newEdges)
        expandCanvasIfNeeded(near: p)
    }
}
