import SwiftUI

/// Bottom sheet som visar genererad mermaid-kod för aktuell canvas.
/// v32: Live från CanvasModel — kod regenereras vid varje render om model.shapes ändras.
struct MermaidCodeSheet: View {
    @ObservedObject var model: CanvasModel
    var onClose: () -> Void

    @State private var copied = false

    /// Live-genererad mermaid-kod (computed varje render).
    private var code: String {
        let doc = CanvasDocument(
            title: model.canvasTitle,
            shapes: model.shapes,
            edges: model.edges,
            canvasSize: model.canvasSize,
            specType: model.specType,
            platform: model.platform,
            activeShapePacks: model.activeShapePacks,
            collapsedEdgeIds: model.collapsedEdgeIds
        )
        return doc.content
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: true) {
                // verbatim: stoppar SwiftUI från att tolka triple-backticks och # som markdown
                Text(verbatim: code)
                    .font(.system(.footnote, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .accessibilityIdentifier("sheet.codeContent")
            }
            .background(Color(.secondarySystemBackground))
            .navigationTitle("Mermaid-kod")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Stäng", action: onClose)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        UIPasteboard.general.string = code
                        withAnimation { copied = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation { copied = false }
                        }
                    } label: {
                        if copied {
                            Label("Kopierad", systemImage: "checkmark")
                        } else {
                            Label("Kopiera", systemImage: "doc.on.doc")
                        }
                    }
                    .bold()
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}
