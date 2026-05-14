import Foundation

struct EdgeConnection: Identifiable, Codable {
    let id: UUID
    var from: UUID
    var to: UUID
    var label: String

    init(id: UUID = UUID(), from: UUID, to: UUID, label: String = "") {
        self.id = id
        self.from = from
        self.to = to
        self.label = label
    }
}
