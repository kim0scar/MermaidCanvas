import SwiftUI

/// Bottom sheet som visar genererad mermaid-kod för aktuell canvas.
/// Apple-design: scrollbar text, copy-knapp, stäng-knapp i nav-bar.
struct MermaidCodeSheet: View {
    let code: String
    var onClose: () -> Void

    @State private var copied = false

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
            .navigationTitle("Filinnehåll")
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
