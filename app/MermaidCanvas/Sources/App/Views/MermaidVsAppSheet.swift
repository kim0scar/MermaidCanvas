import SwiftUI
import UIKit

/// V79-svep / v0.9 (Kims krav #2/#3): facit-menyn "Hur funkar appen / Mermaid vs app".
/// Läser AppCapabilities (single source of truth → kan inte glida från koden). Färg =
/// ÖVERLEVNAD: 🟢 native mermaid · 🟡 app-egen men överlever · 🟠 bara i appen. Visar
/// RIKTIGA form-glyfer, ren svenska först (syntax i grått), sök, och en alltid-nåbar
/// "Kopiera AI-ramverk".
struct MermaidVsAppSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false
    @State private var search = ""

    private var nativeShapes: [ShapeType] { ShapeType.allCases.filter { match($0.glyphName) && !AppCapabilities.shape($0).appOnly } }
    private var appShapes: [ShapeType]    { ShapeType.allCases.filter { match($0.glyphName) && AppCapabilities.shape($0).appOnly } }
    private var features: [AppCapabilities.FeatureCap] { AppCapabilities.features.filter { match($0.name) || match($0.carrier) } }

    private func match(_ s: String) -> Bool {
        search.isEmpty || s.localizedCaseInsensitiveContains(search)
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Appen är **två lager**: mermaid är transporten (en vän öppnar i mermaid.live), appen lägger till ett eget lager via `%%`-rader + ett state-block. Färgen visar om något **överlever** när du delar filen.")
                        .font(.subheadline)
                    legendRow(.nativeMermaid, "Native mermaid — funkar överallt")
                    legendRow(.appCarried, "App-egen, men överlever i mermaid")
                    legendRow(.appOnlyState, "Bara i appen (inte i ren mermaid)")
                }

                if !nativeShapes.isEmpty {
                    Section("Former — native mermaid") {
                        ForEach(nativeShapes, id: \.self) { shapeRow($0) }
                    }
                }
                if !appShapes.isEmpty {
                    Section("Former — egna (visas som närmaste mermaid-form)") {
                        ForEach(appShapes, id: \.self) { shapeRow($0) }
                    }
                }
                if !features.isEmpty {
                    Section("App-egna funktioner (bärs i mermaid)") {
                        ForEach(features, id: \.name) { featureRow($0) }
                    }
                }
            }
            .navigationTitle("Hur funkar appen")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Sök form eller funktion")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Klar") { dismiss() } }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    UIPasteboard.general.string = AppCapabilities.frameworkText()
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                    copied = true
                } label: {
                    Label(copied ? "Kopierat — klistra in hos en AI" : "Kopiera AI-ramverk",
                          systemImage: copied ? "checkmark.circle.fill" : "doc.on.clipboard")
                        .frame(maxWidth: .infinity).padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .padding()
                .background(.ultraThinMaterial)
            }
        }
    }

    // MARK: - Rader

    @ViewBuilder private func shapeRow(_ t: ShapeType) -> some View {
        let cap = AppCapabilities.shape(t)
        HStack(spacing: 12) {
            ShapeGlyph(type: t).frame(width: 30, height: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(cap.displayName).font(.subheadline.weight(.medium))
                Text(cap.mermaidForm).font(.caption.monospaced()).foregroundStyle(.secondary)
            }
            Spacer()
            survivalDot(AppCapabilities.level(forShape: t))
        }
    }

    @ViewBuilder private func featureRow(_ f: AppCapabilities.FeatureCap) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(f.name).font(.subheadline.weight(.medium))
                HStack(spacing: 4) {
                    if !f.survivesPureMermaid {
                        Image(systemName: "exclamationmark.triangle.fill").font(.caption2).foregroundStyle(.orange)
                    }
                    Text(f.carrier).font(.caption.monospaced()).foregroundStyle(.secondary)
                }
            }
            Spacer()
            survivalDot(AppCapabilities.level(forFeature: f))
        }
    }

    private func legendRow(_ level: AppCapabilities.SurvivalLevel, _ text: String) -> some View {
        HStack(spacing: 10) { survivalDot(level); Text(text).font(.footnote) }
    }

    private func survivalDot(_ level: AppCapabilities.SurvivalLevel) -> some View {
        Circle().fill(color(level)).frame(width: 11, height: 11)
    }
    private func color(_ level: AppCapabilities.SurvivalLevel) -> Color {
        switch level {
        case .nativeMermaid: return .green
        case .appCarried:    return .yellow
        case .appOnlyState:  return .orange
        }
    }
}

/// Riktig form-glyf per ShapeType (uttömmande switch → ny form måste få en glyf).
struct ShapeGlyph: View {
    let type: ShapeType
    var body: some View {
        let s = Color.primary
        switch type {
        case .circle:       Circle().stroke(s, lineWidth: 2)
        case .rectangle:    RoundedRectangle(cornerRadius: 4).stroke(s, lineWidth: 2)
        case .pill:         Capsule().stroke(s, lineWidth: 2)
        case .square:       SquareShape().stroke(s, lineWidth: 2)
        case .diamond:      DiamondShape().stroke(s, lineWidth: 2)
        case .processArrow: ProcessArrowShape().stroke(s, lineWidth: 2)
        case .octagon:      OctagonShape().stroke(s, lineWidth: 2)
        case .triangle:     TriangleShape().stroke(s, lineWidth: 2)
        case .cylinder:     CylinderShape().stroke(s, lineWidth: 2)
        case .container:    RoundedRectangle(cornerRadius: 4).stroke(s, style: StrokeStyle(lineWidth: 2, dash: [3]))
        case .phoneFrame:   Image(systemName: "iphone").font(.title3).foregroundStyle(s)
        case .table:        Image(systemName: "tablecells").font(.title3).foregroundStyle(s)
        case .link:         Image(systemName: "link").font(.title3).foregroundStyle(s)
        case .line:         Image(systemName: "minus").font(.title3).foregroundStyle(s)
        case .arrow:        Image(systemName: "arrow.right").font(.title3).foregroundStyle(s)
        case .emoji:        Text("🙂").font(.title3)
        }
    }
}

private extension ShapeType {
    /// Sök-nyckel för en form = dess facit-namn.
    var glyphName: String { AppCapabilities.shape(self).displayName }
}
