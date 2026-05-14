import Foundation

final class CanvasStore {
    static let shared = CanvasStore()
    private let fileManager = FileManager.default

    var canvasURL: URL {
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("canvas.md")
    }

    func save(mermaid: String) throws {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let content = """
        # Canvas — MermaidCanvas

        Genererad av MermaidCanvas-appen \(timestamp).

        ```mermaid
        \(mermaid)
        ```
        """
        try content.write(to: canvasURL, atomically: true, encoding: .utf8)
    }
}
