import Foundation
import CoreGraphics

/// State-JSON-serialisering (det förlustfria lagret bakom `<!-- mermaidcanvas-state -->`).
/// Utbruten ur MermaidGenerator.swift (R5-ratchet): egen ansvarsdomän — bygger en
/// JSON-dict per nod/kant med ALLA fält (lager 1), medan MermaidGenerator skriver den
/// renderbara mermaid-kroppen (lager 2). Tillsammans = round-trip utan avvikelse.
extension MermaidGenerator {

    static func canvasStateJSON(shapes: [ShapeNode],
                                edges: [EdgeConnection],
                                canvasSize: CGSize,
                                specType: SpecType = .ui,
                                platform: Platform = .blank,
                                activeShapePacks: Set<ShapePack> = [.basic],
                                collapsedEdgeIds: Set<UUID> = [],
                                legend: [String: String] = [:]) -> String {
        let mermaidIds = makeMermaidIds(for: shapes)
        let nodes: [[String: Any]] = shapes.map { shape in
            var n: [String: Any] = [
                "id": mermaidIds[shape.id]!,
                // F1: exakt Double-position i state-JSON (inte avrundad) → Kims
                // round-trip (kopiera→klistra) blir bokstavligt noll avvikelse.
                // `%% pos:` förblir heltal för läsbarhet i ren mermaid.
                "x": Double(shape.position.x),
                "y": Double(shape.position.y),
                "label": shape.label,
                "type": shape.type.rawValue,
                "category": shape.category.rawValue,
                "showLabel": shape.showLabel,
                "size": Double(shape.sizeMultiplier),
                "rotation": Double(shape.rotation),
                "note": shape.note
            ]
            if let color = shape.colorOverride { n["color"] = color }
            if let stroke = shape.strokeColorOverride { n["strokeColor"] = stroke }  // v62
            if let link = shape.linkNumber { n["linkNumber"] = link }
            if let nr = shape.skillNumber { n["skillNumber"] = nr }  // v74
            // v46/F1: tabell-mått + celler round-trippas. Skrivs när FÄLTET är satt
            // (inte bara för .table-typ) så inget tappas om värden finns på annan form.
            if shape.type == .table || shape.tableRows != nil || shape.tableCols != nil || shape.tableCells != nil {
                n["tableRows"] = shape.tableRows ?? 3
                n["tableCols"] = shape.tableCols ?? 3
                if let cells = shape.tableCells, !cells.isEmpty {
                    n["tableCells"] = cells
                }
            }
            // v23: textstil + färg-paket
            if shape.textStyle != .body {
                n["textStyle"] = shape.textStyle.rawValue
            }
            if let packId = shape.colorPackId {
                n["colorPackId"] = packId
            }
            // v35.1: separat bredd/höjd-skalning
            if let w = shape.widthMultiplier  { n["widthMultiplier"]  = Double(w) }
            if let h = shape.heightMultiplier { n["heightMultiplier"] = Double(h) }
            // v35.1: endpoint för lösa linjer/pilar (relativ offset från position)
            if let end = shape.lineEnd {
                n["lineEnd"] = ["x": Double(end.x), "y": Double(end.y)]
            }
            // v37: textjustering + punktlista (sparas bara om ej default)
            if shape.textAlignment != .center {
                n["textAlignment"] = shape.textAlignment.rawValue
            }
            if shape.hasBullets {
                n["hasBullets"] = true
            }
            // v46: numrerad lista + indrag round-trippas
            if shape.hasNumberedList {
                n["hasNumberedList"] = true
            }
            if shape.indentLevel > 0 {
                n["indentLevel"] = shape.indentLevel
            }
            // V79-svep: lås + lager
            if shape.locked {
                n["locked"] = true
            }
            if shape.zLayer != 0 {
                n["zLayer"] = shape.zLayer
            }
            // v60: prompt-text (n8n) — round-trippas via state-JSON
            if !shape.prompt.isEmpty {
                n["prompt"] = shape.prompt
            }
            // v47: explicit container-förälder som mermaid-id (sträng)
            if let parentUUID = shape.childOfContainerId,
               let parentMid = mermaidIds[parentUUID] {
                n["childOfContainerId"] = parentMid
            }
            // v1.0+ Visio "hoppa in": ägt underflöde serialiseras via ShapeNodes egen Codable
            // (bevarar ALLT byte-exakt, inkl. nästlade UUID:n) som ett nästlat objekt.
            if let sub = shape.subCanvas,
               let data = try? JSONEncoder().encode(sub),
               let obj = try? JSONSerialization.jsonObject(with: data) {
                n["subCanvas"] = obj
            }
            return n
        }
        let edgeArr: [[String: Any]] = edges.compactMap { edge in
            guard let f = mermaidIds[edge.from], let t = mermaidIds[edge.to] else { return nil }
            var e: [String: Any] = [
                "from": f,
                "to": t,
                "label": edge.label,
                "direction": edge.direction.rawValue,
                "style": edge.style.rawValue
            ]
            if !edge.waypoints.isEmpty {
                e["waypoints"] = edge.waypoints.map { ["x": $0.x, "y": $0.y] }
            }
            // v62: etikett-placering round-trippas (bara icke-default)
            if edge.labelPlacement != .below {
                e["labelPlacement"] = edge.labelPlacement.rawValue
            }
            // v63: pilens färg
            if let hex = edge.colorHex {
                e["color"] = hex
            }
            // v64: vald utgångssida
            if let side = edge.fromSide {
                e["fromSide"] = side.rawValue
            }
            // 1.3: vald inkommande sida på mål-formen
            if let side = edge.toSide {
                e["toSide"] = side.rawValue
            }
            // v63: kollaps per gren — flagga PÅ kanten (ersätter "collapsed"-nod-arrayen)
            if collapsedEdgeIds.contains(edge.id) {
                e["collapsed"] = true
            }
            // v1.0: form på linjen (bara när den avviker från default .curved)
            if edge.lineShape != .curved {
                e["lineShape"] = edge.lineShape.rawValue
            }
            return e
        }
        // iPhone-frame inom canvasen — så Claude exakt kan översätta
        // canvas-position till iPhone-screen-position.
        let iphoneRect = iPhoneFrameMath.frame(in: canvasSize)
        let iphone: [String: Any] = [
            "x": Int(iphoneRect.origin.x.rounded()),
            "y": Int(iphoneRect.origin.y.rounded()),
            "width": Int(iphoneRect.width.rounded()),
            "height": Int(iphoneRect.height.rounded()),
            "designWidth": Int(iPhoneFrameMath.designSize.width),
            "designHeight": Int(iPhoneFrameMath.designSize.height)
        ]

        let canvas: [String: Any] = [
            "width": Int(canvasSize.width.rounded()),
            "height": Int(canvasSize.height.rounded()),
            "shapeBaseWidth": 120,
            "shapeBaseHeight": 80,
            "unit": "pt",
            "iphoneFrame": iphone
        ]
        let packsArr = ShapePack.allCases
            .filter { activeShapePacks.contains($0) }
            .map { $0.rawValue }
        var dict: [String: Any] = [
            "canvas": canvas,
            "specType": specType.rawValue,
            "platform": platform.rawValue,
            "shapePacks": packsArr,
            "nodes": nodes,
            "edges": edgeArr
        ]
        // v63: kollaps skrivs per kant ("collapsed": true på kant-dicten) —
        // den gamla "collapsed"-nod-arrayen skrivs inte längre (parsern
        // migrerar gamla filer vid läsning).
        // v66: legend (kategori → Kims betydelse-text)
        if !legend.isEmpty {
            dict["legend"] = legend
        }
        // .sortedKeys: deterministisk nyckel-ordning → byte-identisk serialisering
        // (annars varierar dict-ordningen per process/instans → flaky idempotens-test
        // + onödig diff i filen vid varje spar). Stärker Kims "byte-identisk"-krav.
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
              let str = String(data: data, encoding: .utf8) else { return "{}" }
        return str
    }
}
