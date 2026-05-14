import Foundation
import CoreGraphics
import CoreTransferable

enum ShapeType: String, Codable, CaseIterable {
    case circle
    case rectangle
    case diamond
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

    init(id: UUID = UUID(), type: ShapeType, position: CGPoint, label: String = "") {
        self.id = id
        self.type = type
        self.position = position
        self.label = label
    }
}
