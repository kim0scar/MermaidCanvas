import SwiftUI
import UIKit

/// V79-svep (Kims krav #2/#3): visar VAD som är ren mermaid och VILKA app-egna saker som
/// ändå finns + HUR de bärs i mermaid utan skada. Läser AppCapabilities (= single source of
/// truth, genererad ur koden → aldrig inaktuell). "Kopiera AI-ramverk" ger en AI exakt vad
/// den får rita för att appen ska kunna importera det.
struct MermaidVsAppSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    private var nativeShapes: [ShapeType] { ShapeType.allCases.filter { !AppCapabilities.shape($0).appOnly } }
    private var appShapes: [ShapeType] { ShapeType.allCases.filter { AppCapabilities.shape($0).appOnly } }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Appen är **två lager**: mermaid är transporten, appen lägger till ett eget lager via `%%`-rader + ett state-block. En vän kan öppna filen i mermaid.live ELLER importera den i appen — exakt samma bild.")
                        .font(.subheadline)
                }

                Section("✅ Native mermaid (renderas identiskt)") {
                    ForEach(nativeShapes, id: \.self) { t in
                        row(AppCapabilities.shape(t).displayName, AppCapabilities.shape(t).mermaidForm, ok: true)
                    }
                }

                Section("◐ Egna former (visas som närmaste mermaid-form)") {
                    ForEach(appShapes, id: \.self) { t in
                        row(AppCapabilities.shape(t).displayName, AppCapabilities.shape(t).mermaidForm, ok: true)
                    }
                }

                Section("⚙️ App-egna funktioner (bärs i mermaid utan skada)") {
                    ForEach(AppCapabilities.features, id: \.name) { f in
                        row(f.name, f.carrier, ok: f.survivesPureMermaid)
                    }
                }

                Section {
                    Button {
                        UIPasteboard.general.string = AppCapabilities.frameworkText()
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        copied = true
                    } label: {
                        Label(copied ? "Kopierat — klistra in hos en AI" : "Kopiera AI-ramverk",
                              systemImage: copied ? "checkmark.circle.fill" : "doc.on.clipboard")
                    }
                } footer: {
                    Text("Ger en AI exakt vad den får använda i mermaid (alltid aktuell — genereras ur appens kod).")
                }
            }
            .navigationTitle("Mermaid vs app")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Klar") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func row(_ name: String, _ carrier: String, ok: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name).font(.subheadline.weight(.medium))
            HStack(spacing: 4) {
                if !ok {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2).foregroundStyle(.orange)
                }
                Text(carrier)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 1)
    }
}
