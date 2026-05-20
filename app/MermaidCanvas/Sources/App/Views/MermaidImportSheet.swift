import SwiftUI

/// v37: Importera Mermaid-kod från Claude.ai eller annan AI.
///
/// Flöde:
/// 1. Kim kopierar mallen → ger till sin AI → ber om ett flödesschema
/// 2. Kim klistrar in koden AI:n genererar → trycker Importera
/// 3. Appen parsar och ersätter canvasen — Kim kan sedan iterera
struct MermaidImportSheet: View {
    @ObservedObject var model: CanvasModel
    var onClose: () -> Void

    @State private var step: Int = 1
    @State private var pastedCode: String = ""
    @State private var showError: Bool = false

    private static let templateText = """
Jag ritar flödesscheman i en iPhone-app som läser Mermaid-syntax.
Använd BARA dessa former:

Cirkel:      A(("text"))
Rektangel:   A["text"] eller A("text")
Romb:        A{"text"}
Oval/Pill:   A(["text"])

Pilar:
A --> B          pil åt höger
A <-- B          pil åt vänster
A <--> B         dubbelriktad
A --- B          linje utan pil
A -.-> B         streckad pil
A --"text"--> B  pil med label

Starta alltid med: flowchart TD

Max 15 noder. Undvik subgraphs.
"""

    var body: some View {
        NavigationStack {
            Form {
                if step == 1 {
                    Section("1. Ge den här mallen till din AI") {
                        Text(Self.templateText)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                        Button {
                            UIPasteboard.general.string = Self.templateText
                        } label: {
                            Label("Kopiera mall", systemImage: "doc.on.doc")
                        }
                    }
                    Section {
                        Button {
                            step = 2
                        } label: {
                            Label("Nästa — klistra in kod →", systemImage: "arrow.right")
                        }
                    }
                } else {
                    Section("2. Klistra in Mermaid-koden här") {
                        TextEditor(text: $pastedCode)
                            .font(.system(.caption, design: .monospaced))
                            .frame(minHeight: 180)
                    }
                    if showError {
                        Section {
                            Label("Ingen giltig Mermaid-kod. Börja med 'flowchart TD'.",
                                  systemImage: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                                .font(.caption)
                        }
                    }
                    Section {
                        Button {
                            importMermaid()
                        } label: {
                            Label("Importera till canvas", systemImage: "square.and.arrow.down")
                        }
                        .bold()
                    }
                    Section {
                        Button {
                            step = 1
                        } label: {
                            Label("← Tillbaka — visa mall", systemImage: "arrow.left")
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Importera Mermaid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Stäng", action: onClose)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func importMermaid() {
        let code = pastedCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else { showError = true; return }

        // Paketa i Mermaid-kodblock om det bara är diagrammet (inte markdown)
        let markdown: String
        if code.hasPrefix("flowchart") || code.hasPrefix("graph") {
            markdown = "```mermaid\n\(code)\n```"
        } else {
            markdown = code
        }

        let parsed = MermaidParser.parse(markdown)
        guard !parsed.shapes.isEmpty else { showError = true; return }

        showError = false
        model.replaceAll(
            shapes: parsed.shapes,
            edges: parsed.edges,
            title: parsed.title,
            specType: parsed.specType,
            platform: parsed.platform,
            activeShapePacks: parsed.activeShapePacks,
            collapsedIds: parsed.collapsedIds
        )
        onClose()
    }
}
