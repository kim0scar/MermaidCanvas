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
    /// V79-svep: visa "Funktionsöversikt"-vyn.
    var onShowCapabilities: () -> Void = {}
    var onShowRules: () -> Void
    /// v37: importera Mermaid-kod från AI.
    var onImportMermaid: () -> Void
    var onImportMultiple: () -> Void = {}   // v1.1: flera filer som containrar
    /// v66: visa/dölj legend-panelen på canvasen.
    var onToggleLegend: () -> Void = {}
    /// 1.2: zoom blev info (ej knapp) — återställ-funktionen bor här istället.
    var onResetZoom: () -> Void = {}
    /// 1.2: global lista över alla anteckningar (flyttad från det missvisande Notis-chippet).
    var onShowNotePopup: () -> Void = {}

    /// v51.2: speglar valt skärmläge för bock-markering.
    #if os(iOS)
    @AppStorage(OrientationStore.key) private var orientationMode: String = OrientationMode.portrait.rawValue
    #endif

    var body: some View {
        Menu {
            // 1.2: version ÖVERST så den ALLTID syns (menyn scrollar — version får ej hamna under fold).
            Button(action: {}) {
                Label("Visuali2e \(AppVersion.version)", systemImage: "info.circle")
            }
            .disabled(true)
            .accessibilityIdentifier("menu.version")
            // 1.2: namngivna sektioner (Kims order) — ersätter nakna Divider.
            Section("Skapa") {
                Button { onNewCanvas() } label: {
                    Label("Ny canvas (välj plattform)", systemImage: "doc.badge.plus")
                }
                #if os(macOS)
                .keyboardShortcut("n", modifiers: .command)   // 1.1 Fas 6: Mac-genvägar
                #endif
            }
            Section("Fil") {
                Button { onSave() } label: {
                    Label(hasOpenFile ? "Spara" : "Spara…", systemImage: "internaldrive")
                }
                #if os(macOS)
                .keyboardShortcut("s", modifiers: .command)
                #endif
                Button { onSaveAs() } label: {
                    Label("Spara som ny fil…", systemImage: "square.and.arrow.down")
                }
                #if os(macOS)
                .keyboardShortcut("s", modifiers: [.command, .shift])
                #endif
                Button { onOpen() } label: {
                    Label("Öppna fil…", systemImage: "folder")
                }
                #if os(macOS)
                .keyboardShortcut("o", modifiers: .command)
                #endif
                Button { onImportMermaid() } label: {
                    Label("Importera Mermaid (en fil)…", systemImage: "arrow.down.doc")
                }
                Button { onImportMultiple() } label: {
                    Label("Importera flera filer (jämför)…", systemImage: "doc.on.doc")
                }
            }
            Section("Kod & export") {
                Button { onShowCode() } label: {
                    Label("Visa Mermaid-kod", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                .accessibilityIdentifier("menu.showCode")
                Button { onCopyCode() } label: {
                    Label("Kopiera Mermaid-kod", systemImage: "doc.on.doc")
                }
                .accessibilityIdentifier("menu.copyCode")
                Menu {
                    Button { onExportImage(false) } label: { Label("PNG (skarp)", systemImage: "photo") }
                    Button { onExportImage(true) } label: { Label("JPG (mindre fil)", systemImage: "photo.fill") }
                } label: {
                    Label("Exportera som bild…", systemImage: "photo")
                }
                .accessibilityIdentifier("menu.exportImage")
            }
            Section("Visa") {
                Button { onToggleLegend() } label: {
                    Label("Legend", systemImage: "list.bullet.rectangle")
                }
                .accessibilityIdentifier("menu.legend")
                // 1.2: tydligare namn (var "Mermaid vs app-funktioner").
                Button { onShowCapabilities() } label: {
                    Label("Funktionsöversikt", systemImage: "rectangle.split.2x1")
                }
                .accessibilityIdentifier("menu.capabilities")
                // 1.2: global notis-lista (flyttad från det missvisande Notis-chippet).
                Button { onShowNotePopup() } label: {
                    Label("Alla anteckningar", systemImage: "note.text")
                }
                .accessibilityIdentifier("menu.allNotes")
                // 1.2: zoom är info i toppraden → återställ här.
                Button { onResetZoom() } label: {
                    Label("Återställ zoom (100 %)", systemImage: "1.magnifyingglass")
                }
                .accessibilityIdentifier("menu.resetZoom")
                // skärmläge porträtt/landskap — iOS-bara (Mac roterar ej).
                #if os(iOS)
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
                #endif
            }
            Section("Om appen") {
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
            }
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
