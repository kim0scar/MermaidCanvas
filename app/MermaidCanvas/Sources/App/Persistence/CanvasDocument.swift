import SwiftUI
import UniformTypeIdentifiers

struct CanvasDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText] }
    let content: String

    init(title: String,
         shapes: [ShapeNode],
         edges: [EdgeConnection],
         canvasSize: CGSize,
         specType: SpecType,
         platform: Platform = .blank,
         activeShapePacks: Set<ShapePack> = [.basic],
         collapsedEdgeIds: Set<UUID> = [],
         legend: [String: String] = [:]) {
        let mermaid = MermaidGenerator.generate(shapes: shapes, edges: edges, canvasSize: canvasSize, specType: specType, collapsedEdgeIds: collapsedEdgeIds, legend: legend)
        let state = MermaidGenerator.canvasStateJSON(shapes: shapes, edges: edges, canvasSize: canvasSize, specType: specType, platform: platform, activeShapePacks: activeShapePacks, collapsedEdgeIds: collapsedEdgeIds, legend: legend)
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let titleLine = title.isEmpty ? "Canvas — MermaidCanvas" : title
        let today = String(timestamp.prefix(10))
        let packsList = ShapePack.allCases
            .filter { activeShapePacks.contains($0) }
            .map { $0.rawValue }
            .joined(separator: ",")

        let frontmatter = """
        ---
        title: \(titleLine.replacingOccurrences(of: "\n", with: " "))
        spec_type: \(specType.rawValue)
        platform: \(platform.rawValue)
        shape_packs: \(packsList)
        last_updated: \(today)
        ---

        """

        self.content = """
        \(frontmatter)# \(titleLine)

        Genererad \(timestamp).

        ```mermaid
        \(mermaid)
        ```

        <!-- mermaidcanvas-state
        \(state)
        -->

        \(AppCapabilities.embeddedFrameworkBlock())
        """
    }

    /// v75: wrappa redan komponerat innehåll (t.ex. SkillFileComposer → fileExporter).
    init(content: String) {
        self.content = content
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
