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
    var sizeMultiplier: CGFloat
    var note: String
    var category: ShapeCategory
    var rotation: CGFloat
    /// v19: överskrid kategori-färg per form. Hex-sträng "#rrggbb" eller nil = använd kategori.
    var colorOverride: String?
    /// v19: jump-link parnummer. nil för icke-link-former.
    var linkNumber: Int?

    init(id: UUID = UUID(),
         type: ShapeType,
         position: CGPoint,
         label: String = "",
         showLabel: Bool = true,
         sizeMultiplier: CGFloat = 1.0,
         note: String = "",
         category: ShapeCategory = .ui,
         rotation: CGFloat = 0,
         colorOverride: String? = nil,
         linkNumber: Int? = nil) {
        self.id = id
        self.type = type
        self.position = position
        self.label = label
        self.showLabel = showLabel
        self.sizeMultiplier = sizeMultiplier
        self.note = note
        self.category = category
        self.rotation = rotation
        self.colorOverride = colorOverride
        self.linkNumber = linkNumber
    }
}
