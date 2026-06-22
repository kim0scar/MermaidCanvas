import SwiftUI

/// v27 "Lägen"-menyn.
/// Plattform = info (Blank/Godot, låses per canvas).
/// Form-paketer = togglar för UI/Roadmap/Arkitektur/Flow (oberoende av platform).
struct LägenMenu: View {
    @ObservedObject var model: CanvasModel
    var hasOpenFile: Bool
    var onSave: () -> Void
    var onSaveAs: () -> Void
    var onOpen: () -> Void
    var onNewCanvas: () -> Void
    var onShowCode: () -> Void
    /// v61: kopiera hela dokumentet till urklipp direkt (1 tryck, ingen sheet).
    var onCopyCode: () -> Void
    /// Steg H: exportera ritade ytan som bild → delningsmeny. Bool = JPG (annars PNG).
    var onExportImage: (Bool) -> Void = { _ in }
    /// V79-svep: visa "Mermaid vs app-funktioner"-vyn.
    var onShowCapabilities: () -> Void = {}
    /// V79-svep: lägg en snabb-mall (AI-Skill / UI / Arkitektur).
    var onInsertTemplate: (CanvasModel.TemplateKind) -> Void = { _ in }
    var onShowRules: () -> Void
    /// V79-svep: används av "Markera flera"-posten nedan (flyttad hit ur huvudmenyn).
    var onToggleMarker: () -> Void
    /// v37: importera Mermaid-kod från AI.
    var onImportMermaid: () -> Void
    var onImportMultiple: () -> Void = {}   // v1.1: flera filer som containrar
    /// v66: visa/dölj legend-panelen på canvasen.
    var onToggleLegend: () -> Void = {}

    /// v51.2: speglar valt skärmläge för bock-markering.
    @AppStorage(OrientationStore.key) private var orientationMode: String = OrientationMode.portrait.rawValue

    var body: some View {
        Menu {
            // v40: Ny canvas överst + kompakt plattform-rad
            Button { onNewCanvas() } label: {
                Label("Ny canvas (välj plattform)", systemImage: "doc.badge.plus")
            }
            // V79-svep: snabb-mallar
            Menu {
                ForEach(CanvasModel.TemplateKind.allCases, id: \.self) { kind in
                    Button { onInsertTemplate(kind) } label: {
                        Label(kind.title, systemImage: kind.systemImage)
                    }
                }
            } label: {
                Label("Mallar", systemImage: "square.grid.2x2")
            }
            .accessibilityIdentifier("menu.templates")
            Button(action: {}) {
                Label("Aktuell plattform: \(model.platform.displayName)",
                      systemImage: model.platform.badgeSystemImage)
            }
            .disabled(true)
            if model.platform == .godot {
                Button(action: onShowRules) {
                    Label("Visa regler för Godot", systemImage: "book")
                }
            }
            Divider()
            Button { onSave() } label: {
                Label(hasOpenFile ? "Spara" : "Spara…", systemImage: "internaldrive")
            }
            Button { onSaveAs() } label: {
                Label("Spara som ny fil…", systemImage: "square.and.arrow.down")
            }
            Button { onOpen() } label: {
                Label("Öppna fil…", systemImage: "folder")
            }
            Button { onImportMermaid() } label: {
                Label("Importera Mermaid…", systemImage: "arrow.down.doc")
            }
            // v1.1: importera flera filer — var och en i en container (jämför varianter).
            Button { onImportMultiple() } label: {
                Label("Importera flera filer (jämför)…", systemImage: "doc.on.doc")
            }
            Divider()
            // v32: Preview-knapp borttagen — kommer tillbaka när Godot-flödet är moget.
            Button { onShowCode() } label: {
                Label("Visa Mermaid-kod", systemImage: "chevron.left.forwardslash.chevron.right")
            }
            .accessibilityIdentifier("menu.showCode")
            Button { onCopyCode() } label: {
                Label("Kopiera Mermaid-kod", systemImage: "doc.on.doc")
            }
            .accessibilityIdentifier("menu.copyCode")
            // Steg H + V79-svep: bild av ritade ytan → PNG (skarp) eller JPG (mindre fil)
            Menu {
                Button { onExportImage(false) } label: { Label("PNG (skarp)", systemImage: "photo") }
                Button { onExportImage(true) } label: { Label("JPG (mindre fil)", systemImage: "photo.fill") }
            } label: {
                Label("Exportera som bild…", systemImage: "photo")
            }
            .accessibilityIdentifier("menu.exportImage")
            // V79-svep: vad blir mermaid + app-egna funktioner + AI-ramverk
            Button { onShowCapabilities() } label: {
                Label("Mermaid vs app-funktioner", systemImage: "rectangle.split.2x1")
            }
            .accessibilityIdentifier("menu.capabilities")
            // v66: legend — skriv vad varje form/kategori betyder (följer med i koden)
            Button { onToggleLegend() } label: {
                Label("Legend", systemImage: "list.bullet.rectangle")
            }
            .accessibilityIdentifier("menu.legend")
            // V79-svep: "Markera flera" flyttad hit ur huvudmenyn.
            Button { onToggleMarker() } label: {
                Label("Markera flera", systemImage: model.markerMode ? "checkmark" : "rectangle.dashed")
            }
            .accessibilityIdentifier("menu.marker")
            Divider()
            // v51.2: skärmläge porträtt/landskap (äkta orientering)
            Menu {
                Button { OrientationStore.set(.portrait) } label: {
                    Label("Porträttläge", systemImage: orientationMode == OrientationMode.portrait.rawValue ? "checkmark" : "iphone")
                }
                Button { OrientationStore.set(.landscape) } label: {
                    Label("Landskapsläge", systemImage: orientationMode == OrientationMode.landscape.rawValue ? "checkmark" : "iphone.landscape")
                }
            } label: {
                Label("Skärmläge", systemImage: "rotate.right")
            }
            .accessibilityIdentifier("menu.orientation")
            Divider()
            Button(action: {}) {
                Label("\(AppVersion.milestone) · \(AppVersion.current)", systemImage: "info.circle")
            }
            .disabled(true)
        } label: {
            ToolbarIconButton(systemImage: "slider.horizontal.3", isActive: false)
        }
        .accessibilityIdentifier("toolbar.modes")
    }
}

/// Återanvänd toolbar-ikon-stil med glas-bubble.
struct ToolbarIconButton: View {
    var systemImage: String
    var isActive: Bool
    var foregroundColor: Color = .primary

    var body: some View {
        // v33 polish: 16→17pt font + 40→44pt frame. Större finger-träffyta på iPhone
        // och ikonen läses bättre vid samma kontrast. Matchar Apple HIG (min 44pt).
        Image(systemName: systemImage)
            .font(.system(size: 17, weight: .medium))
            .foregroundStyle(isActive ? Color.white : foregroundColor)
            .frame(width: 44, height: 44)
            .background(
                Circle().fill(isActive ? Color.accentColor : .clear)
            )
            .background(
                Circle()
                    .fill(.ultraThinMaterial)
                    .opacity(isActive ? 0 : 1)
            )
            .overlay(
                Circle().stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
            )
            .contentShape(Circle())
    }
}
