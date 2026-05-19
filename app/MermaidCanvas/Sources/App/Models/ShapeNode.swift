import Foundation
import CoreGraphics
import CoreTransferable

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
    // v35.1: nya grundformer
    /// Liksidig kvadrat med rundade hörn.
    case square
    /// Liksidig triangel med mjuka hörn.
    case triangle
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
         lineEnd: CGPoint? = nil) {
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
    }

    /// v31: effective width-multiplier (fallback till sizeMultiplier).
    var effectiveWidth: CGFloat { widthMultiplier ?? sizeMultiplier }
    /// v31: effective height-multiplier (fallback till sizeMultiplier).
    var effectiveHeight: CGFloat { heightMultiplier ?? sizeMultiplier }
}
