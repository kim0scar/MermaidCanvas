import SwiftUI

/// "Lägen"-menyn — INTE plattform-byte (det görs vid Ny canvas).
/// Visar aktuell plattform + filhantering + visa regler + version.
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
            Section(header: Text("Aktuell plattform")) {
                Label("\(model.specType.displayName) (låst för denna canvas)",
                      systemImage: model.specType.badgeSystemImage)
                    .disabled(true)
                Button(action: onShowRules) {
                    Label("Visa regler för \(model.specType.displayName)", systemImage: "book")
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
            Button { onShowPreview() } label: {
                Label("Preview (simulerad app)", systemImage: "eye")
            }
            Button { onShowCode() } label: {
                Label("Visa filinnehåll", systemImage: "curlybraces")
            }
            Divider()
            Button(action: {}) {
                Label(AppVersion.current, systemImage: "info.circle")
            }
            .disabled(true)
        } label: {
            ToolbarIconButton(systemImage: "slider.horizontal.3", isActive: false)
        }
    }
}

/// Återanvänd toolbar-ikon-stil med glas-bubble.
struct ToolbarIconButton: View {
    var systemImage: String
    var isActive: Bool
    var foregroundColor: Color = .primary

    var body: some View {
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
