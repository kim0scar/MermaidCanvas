import Foundation

struct EdgeConnection: Identifiable, Codable {
    let id: UUID
    var from: UUID
    var to: UUID
    var label: String
    var bidirectional: Bool

    init(id: UUID = UUID(), from: UUID, to: UUID, label: String = "", bidirectional: Bool = false) {
        self.id = id
        self.from = from
        self.to = to
        self.label = label
        self.bidirectional = bidirectional
    }
}
