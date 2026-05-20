import Foundation
import CoreGraphics
import CoreTransferable

/// v37: textjustering per form. Lagras som sträng-enum (Foundation-only, ej SwiftUI-beroende).
enum TextAlignMode: String, Codable, CaseIterable {
    case leading
    case center
    case trailing
}

enum ShapeType: String, Codable, CaseIterable {
    case circle
    case rectangle
    case diamond
    case text
    case table
    case link
    /// v31: avlång rektangel med fullständigt rundade ändar (Capsule).
    case pill
    /// v31: lös linje utan form-koppling. Endpoints i `lineEnd` (relativ position från center).
    case line
    /// v31: lös pil — som line med pilhuvud på linjeslutet.
    case arrow
    // v35.1/v36: grundformer
    /// Liksidig kvadrat med rundade hörn.
    case square
    /// Processsteg-pil (pentagon) — rektangel med spetsig högerände. Kan ha label.
    case processArrow
}

extension ShapeType: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation { $0.rawValue }
    }
}

struct ShapeNode: Identifiable, Codable {
    let id: UUID
    var type: ShapeType
    var position: CGPoint
    var label: String
    var showLabel: Bool
    /// Behålls för bakåtkompatibilitet — används om widthMultiplier/heightMultiplier saknas.
    var sizeMultiplier: CGFloat
    /// v31: separat bredd-skalning (för fri resize). Default = sizeMultiplier vid läsning.
    var widthMultiplier: CGFloat?
    /// v31: separat höjd-skalning.
    var heightMultiplier: CGFloat?
    var note: String
    var category: ShapeCategory
    var rotation: CGFloat
    /// v19: överskrid kategori-färg per form. Hex-sträng "#rrggbb" eller nil = använd kategori.
    var colorOverride: String?
    /// v19: jump-link parnummer. nil för icke-link-former.
    var linkNumber: Int?
    /// v19: tabell-rader (för type=.table). nil = default 3.
    var tableRows: Int?
    /// v19: tabell-kolumner (för type=.table). nil = default 3.
    var tableCols: Int?
    /// v23: textstil för label (Rubrik 1/2/3 eller brödtext).
    var textStyle: TextStyle
    /// v23: färg-paket-id (ColorPack.id) eller nil = ingen färg = vit + kategori-ram.
    var colorPackId: String?
    /// v31: endpoint för lösa linjer/pilar (relativ från `position`). nil för icke-line.
    var lineEnd: CGPoint?
    /// v37: textjustering (L/C/R) per form. Default = .center.
    var textAlignment: TextAlignMode
    /// v37: visa text med • per rad. Default = false.
    var hasBullets: Bool
    /// v39: visa text med 1. 2. 3. per rad. Default = false.
    var hasNumberedList: Bool
    /// v39: indragsnivå (0 = ingen, 1 = ett steg, 2 = två steg). Default = 0.
    var indentLevel: Int

    init(id: UUID = UUID(),
         type: ShapeType,
         position: CGPoint,
         label: String = "",
         showLabel: Bool = true,
         sizeMultiplier: CGFloat = 1.0,
         widthMultiplier: CGFloat? = nil,
         heightMultiplier: CGFloat? = nil,
         note: String = "",
         category: ShapeCategory = .ui,
         rotation: CGFloat = 0,
         colorOverride: String? = nil,
         linkNumber: Int? = nil,
         tableRows: Int? = nil,
         tableCols: Int? = nil,
         textStyle: TextStyle = .body,
         colorPackId: String? = nil,
         lineEnd: CGPoint? = nil,
         textAlignment: TextAlignMode = .center,
         hasBullets: Bool = false,
         hasNumberedList: Bool = false,
         indentLevel: Int = 0) {
        self.id = id
        self.type = type
        self.position = position
        self.label = label
        self.showLabel = showLabel
        self.sizeMultiplier = sizeMultiplier
        self.widthMultiplier = widthMultiplier
        self.heightMultiplier = heightMultiplier
        self.note = note
        self.category = category
        self.rotation = rotation
        self.colorOverride = colorOverride
        self.linkNumber = linkNumber
        self.tableRows = tableRows
        self.tableCols = tableCols
        self.textStyle = textStyle
        self.colorPackId = colorPackId
        self.lineEnd = lineEnd
        self.textAlignment = textAlignment
        self.hasBullets = hasBullets
        self.hasNumberedList = hasNumberedList
        self.indentLevel = indentLevel
    }

    /// v31: effective width-multiplier (fallback till sizeMultiplier).
    var effectiveWidth: CGFloat { widthMultiplier ?? sizeMultiplier }
    /// v31: effective height-multiplier (fallback till sizeMultiplier).
    var effectiveHeight: CGFloat { heightMultiplier ?? sizeMultiplier }
}

// MARK: - Bakåtkompatibel Decodable

extension ShapeNode {
    private enum CodingKeys: String, CodingKey {
        case id, type, position, label, showLabel, sizeMultiplier
        case widthMultiplier, heightMultiplier, note, category, rotation
        case colorOverride, linkNumber, tableRows, tableCols, textStyle
        case colorPackId, lineEnd, textAlignment, hasBullets
        case hasNumberedList, indentLevel
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id              = try c.decode(UUID.self, forKey: .id)
        type            = try c.decode(ShapeType.self, forKey: .type)
        position        = try c.decode(CGPoint.self, forKey: .position)
        label           = try c.decode(String.self, forKey: .label)
        showLabel       = try c.decodeIfPresent(Bool.self, forKey: .showLabel) ?? true
        sizeMultiplier  = try c.decodeIfPresent(CGFloat.self, forKey: .sizeMultiplier) ?? 1.0
        widthMultiplier = try c.decodeIfPresent(CGFloat.self, forKey: .widthMultiplier)
        heightMultiplier = try c.decodeIfPresent(CGFloat.self, forKey: .heightMultiplier)
        note            = try c.decodeIfPresent(String.self, forKey: .note) ?? ""
        category        = try c.decodeIfPresent(ShapeCategory.self, forKey: .category) ?? .ui
        rotation        = try c.decodeIfPresent(CGFloat.self, forKey: .rotation) ?? 0
        colorOverride   = try c.decodeIfPresent(String.self, forKey: .colorOverride)
        linkNumber      = try c.decodeIfPresent(Int.self, forKey: .linkNumber)
        tableRows       = try c.decodeIfPresent(Int.self, forKey: .tableRows)
        tableCols       = try c.decodeIfPresent(Int.self, forKey: .tableCols)
        textStyle       = try c.decodeIfPresent(TextStyle.self, forKey: .textStyle) ?? .body
        colorPackId     = try c.decodeIfPresent(String.self, forKey: .colorPackId)
        lineEnd         = try c.decodeIfPresent(CGPoint.self, forKey: .lineEnd)
        textAlignment   = try c.decodeIfPresent(TextAlignMode.self, forKey: .textAlignment) ?? .center
        hasBullets      = try c.decodeIfPresent(Bool.self, forKey: .hasBullets) ?? false
        hasNumberedList = try c.decodeIfPresent(Bool.self, forKey: .hasNumberedList) ?? false
        indentLevel     = try c.decodeIfPresent(Int.self, forKey: .indentLevel) ?? 0
    }
}
