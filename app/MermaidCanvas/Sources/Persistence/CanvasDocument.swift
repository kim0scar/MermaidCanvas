import SwiftUI
import UniformTypeIdentifiers

struct CanvasDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    let content: String

    init(title: String, shapes: [ShapeNode], edges: [EdgeConnection]) {
        let mermaid = MermaidGenerator.generate(shapes: shapes, edges: edges)
        let state = MermaidGenerator.canvasStateJSON(shapes: shapes, edges: edges)
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let titleLine = title.isEmpty ? "Canvas — MermaidCanvas" : title
        self.content = """
        # \(titleLine)

        Genererad \(timestamp).

        ```mermaid
        \(mermaid)
        ```

        <!-- mermaidcanvas-state
        \(state)
        -->
        """
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let text = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        self.content = text
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = content.data(using: .utf8) ?? Data()
        return FileWrapper(regularFileWithContents: data)
    }
}
