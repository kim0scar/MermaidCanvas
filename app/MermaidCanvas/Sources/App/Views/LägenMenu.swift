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
    var onShowPreview: () -> Void
    var onShowRules: () -> Void

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
            // Form-paketer — togglar
            Section(header: Text("Form-paketer")) {
                ForEach(ShapePack.allCases) { pack in
                    if pack == .basic {
                        Label("Basformer (alltid på)", systemImage: pack.systemImage)
                            .disabled(true)
                    } else {
                        Button {
                            model.toggleShapePack(pack)
                        } label: {
                            if model.activeShapePacks.contains(pack) {
                                Label("\(pack.displayName) ✓", systemImage: pack.systemImage)
                            } else {
                                Label(pack.displayName, systemImage: pack.systemImage)
                            }
                        }
                        .accessibilityIdentifier("pack.\(pack.rawValue)")
                    }
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
            Button { onNewCanvas() } label: {
                Label("Ny canvas (välj plattform)", systemImage: "doc.badge.plus")
            }
            Divider()
            if model.platform == .godot {
                Button { onShowPreview() } label: {
                    Label("Preview (simulerad app)", systemImage: "eye")
                }
            }
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
        Image(systemName: systemImage)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(isActive ? Color.white : foregroundColor)
            .frame(width: 40, height: 40)
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
