import SwiftUI
import UniformTypeIdentifiers

struct CanvasDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    let content: String

    init(shapes: [ShapeNode]) {
        let mermaid = MermaidGenerator.generate(from: shapes)
        let state = MermaidGenerator.canvasStateJSON(from: shapes)
        let timestamp = ISO8601DateFormatter().string(from: Date())
        self.content = """
        # Canvas — MermaidCanvas

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
