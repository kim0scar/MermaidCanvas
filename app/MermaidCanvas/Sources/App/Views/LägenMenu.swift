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
    var onShowRules: () -> Void
    /// v33: markerButton flyttad hit från primary toolbar för att rymma 44pt-knappar.
    var onToggleMarker: () -> Void
    /// v37: importera Mermaid-kod från AI.
    var onImportMermaid: () -> Void

    var body: some View {
        Menu {
            // Aktuell plattform — INFO, inte picker (låses vid Ny canvas)
            Section(header: Text("Plattform")) {
                Label("\(model.platform.displayName) (låst för denna canvas)",
                      systemImage: model.platform.badgeSystemImage)
                    .disabled(true)
                if model.platform == .godot {
                    Button(action: onShowRules) {
                        Label("Visa regler för Godot", systemImage: "book")
                    }
                }
            }
            // v36.1: Form-paketer flyttade till swatchpalette-knappen i toolbar
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
            Button { onNewCanvas() } label: {
                Label("Ny canvas (välj plattform)", systemImage: "doc.badge.plus")
            }
            Divider()
            // v33: markeringsläge flyttat hit från toolbar
            Button { onToggleMarker() } label: {
                Label(model.markerMode ? "Stäng markeringsläge" : "Markeringsläge",
                      systemImage: model.markerMode ? "pencil.slash" : "pencil.tip")
            }
            .accessibilityIdentifier("menu.toggleMarker")
            // v32: Preview-knapp borttagen — kommer tillbaka när Godot-flödet är moget.
            Button { onShowCode() } label: {
                Label("Visa Mermaid-kod", systemImage: "chevron.left.forwardslash.chevron.right")
            }
            .accessibilityIdentifier("menu.showCode")
            Divider()
            Button(action: {}) {
                Label(AppVersion.current, systemImage: "info.circle")
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
