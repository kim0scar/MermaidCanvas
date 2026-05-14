import Foundation
import CoreGraphics

enum ShapeType: String, Codable, CaseIterable {
    case circle
    case rectangle
    case diamond
}

struct ShapeNode: Identifiable, Codable {
    let id: UUID
    var type: ShapeType
    var position: CGPoint
    var label: String

    init(id: UUID = UUID(), type: ShapeType, position: CGPoint, label: String = "") {
        self.id = id
        self.type = type
        self.position = position
        self.label = label
    }
}
