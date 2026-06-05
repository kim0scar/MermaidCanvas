import Foundation
import CoreGraphics

/// v61: Lagrad auto-layout för rå mermaid utan positioner.
/// Ersätter den gamla cirkel-placeringen — Claude-skriven `flowchart TD/LR`
/// renderas nu som ett riktigt flödesschema: kanternas riktning ger nivåer,
/// diagrammets riktning (TD/LR/BT/RL) ger axeln.
enum MermaidAutoLayout {

    enum FlowDirection {
        case td  // top → down (även TB)
        case lr  // left → right
        case bt  // bottom → top
        case rl  // right → left
    }

    /// Läser riktningen från `flowchart XX` / `graph XX`. Default: TD.
    static func direction(in block: String) -> FlowDirection {
        for rawLine in block.split(separator: "\n", omittingEmptySubsequences: true) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            let lower = line.lowercased()
            guard lower.hasPrefix("flowchart") || lower.hasPrefix("graph") else { continue }
            let parts = line.split(separator: " ")
            guard parts.count >= 2 else { return .td }
            switch parts[1].uppercased() {
            case "LR": return .lr
            case "BT": return .bt
            case "RL": return .rl
            default:   return .td  // TD, TB och allt okänt
            }
        }
        return .td
    }

    /// Beräknar en position per nod-id. Noder utan kanter hamnar i nivå 0.
    /// Cykler hanteras genom att nivå-stegningen begränsas till antal noder.
    static func positions(nodeIds: [String],
                          edges: [(from: String, to: String)],
                          direction: FlowDirection) -> [String: CGPoint] {
        guard !nodeIds.isEmpty else { return [:] }

        // Longest-path-nivåer: B ligger alltid minst en nivå efter A för A-->B.
        var layer: [String: Int] = [:]
        for id in nodeIds { layer[id] = 0 }
        let known = Set(nodeIds)
        let relevant = edges.filter { known.contains($0.from) && known.contains($0.to) && $0.from != $0.to }
        // Itererar max nodeIds.count gånger — skyddar mot cykler (A-->B-->A).
        for _ in 0..<nodeIds.count {
            var changed = false
            for e in relevant {
                let want = layer[e.from]! + 1
                if layer[e.to]! < want && want < nodeIds.count {
                    layer[e.to] = want
                    changed = true
                }
            }
            if !changed { break }
        }

        // Gruppera per nivå, behåll deklarationsordningen inom nivån.
        var byLayer: [Int: [String]] = [:]
        for id in nodeIds {
            byLayer[layer[id]!, default: []].append(id)
        }
        let maxLayer = byLayer.keys.max() ?? 0

        // Avstånd valda för bas-former 120×80 pt med marginal.
        let mainGap: CGFloat = 170    // mellan nivåer (flödesriktningen)
        let crossGap: CGFloat = 170   // mellan syskon inom en nivå
        let origin = CGPoint(x: 200, y: 160)  // första nodens ungefärliga hemvist

        var result: [String: CGPoint] = [:]
        for (lvl, ids) in byLayer {
            // Spegla nivån för BT/RL så flödet går åt rätt håll.
            let effectiveLevel: CGFloat
            switch direction {
            case .td, .lr: effectiveLevel = CGFloat(lvl)
            case .bt, .rl: effectiveLevel = CGFloat(maxLayer - lvl)
            }
            for (i, id) in ids.enumerated() {
                // Centrera syskonen kring origin på tväraxeln.
                let crossOffset = (CGFloat(i) - CGFloat(ids.count - 1) / 2) * crossGap
                switch direction {
                case .td, .bt:
                    result[id] = CGPoint(x: origin.x + crossOffset,
                                         y: origin.y + effectiveLevel * mainGap)
                case .lr, .rl:
                    result[id] = CGPoint(x: origin.x + effectiveLevel * mainGap,
                                         y: origin.y + crossOffset)
                }
            }
        }
        return result
    }
}
