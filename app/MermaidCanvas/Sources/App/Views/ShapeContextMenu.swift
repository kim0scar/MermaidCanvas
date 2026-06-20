import SwiftUI

/// v50.5 F4: Egen popover-meny som ersätter SwiftUI's `.contextMenu`.
///
/// `.contextMenu` triggar UIKit's `UIContextMenuInteraction` som visar en
/// snapshot-preview av target-vyn (mörk blurred overlay) innan menyn —
/// vilket gav den svarta flashen Kim såg. Egen popover undviker det helt.
struct ShapeContextMenu: View {
    let noteIsEmpty: Bool
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onShowNote: () -> Void
    let onDelete: () -> Void
    /// v66: bara för containrar — kopiera containern + barn + memory-noder
    /// som självbärande mermaid (= EN skill enligt SKILL-KEDJA-KONTRAKT).
    var onCopySkill: (() -> Void)? = nil
    /// v70: bara för containrar — spara containern + barn + memory-noder som EGEN
    /// canvas-fil (skill) i iCloud bredvid pipeline-filen.
    var onSaveSkillFile: (() -> Void)? = nil
    /// V79-svep: bara för containrar — spara formerna inuti som ren mermaid-fil.
    var onSaveContainerMermaid: (() -> Void)? = nil
    /// V79-svep: lås + lager.
    var locked: Bool = false
    var onToggleLock: () -> Void = {}
    var zLayer: Int = 0
    var onSetZLayer: (Int) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            menuItem(label: "Redigera",
                     systemImage: "pencil",
                     action: onEdit)
            menuItem(label: "Duplicera",
                     systemImage: "plus.square.on.square",
                     action: onDuplicate)
            menuItem(label: noteIsEmpty ? "Lägg till anteckning" : "Visa anteckning",
                     systemImage: "note.text",
                     action: onShowNote)
            menuItem(label: locked ? "Lås upp" : "Lås fast",
                     systemImage: locked ? "lock.open" : "lock.fill",
                     action: onToggleLock)
            if let copySkill = onCopySkill {
                menuItem(label: "Kopiera som skill",
                         systemImage: "square.and.arrow.up.on.square",
                         action: copySkill)
            }
            if let saveSkill = onSaveSkillFile {
                menuItem(label: "Spara skill som fil",
                         systemImage: "folder.badge.plus",
                         action: saveSkill)
            }
            if let saveMermaid = onSaveContainerMermaid {
                menuItem(label: "Spara Mermaid inom container",
                         systemImage: "square.and.arrow.down",
                         action: saveMermaid)
            }
            Divider().padding(.vertical, 4)
            // V79-svep: lager — underst / mellan / överst
            HStack(spacing: 6) {
                Image(systemName: "square.3.layers.3d").frame(width: 20)
                ForEach([(-1, "Underst"), (0, "Mellan"), (1, "Överst")], id: \.0) { z, name in
                    Button { onSetZLayer(z) } label: {
                        Text(name)
                            .font(.system(size: 13, weight: zLayer == z ? .bold : .regular))
                            .foregroundStyle(zLayer == z ? Color.accentColor : Color.primary)
                            .padding(.horizontal, 8).padding(.vertical, 5)
                            .background(zLayer == z ? Color.accentColor.opacity(0.12) : Color.clear,
                                        in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 6)
            Divider().padding(.vertical, 4)
            menuItem(label: "Ta bort",
                     systemImage: "trash",
                     destructive: true,
                     action: onDelete)
        }
        .padding(.vertical, 6)
        .frame(minWidth: 220)
    }

    @ViewBuilder
    private func menuItem(label: String,
                          systemImage: String,
                          destructive: Bool = false,
                          action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .frame(width: 20)
                Text(label)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .foregroundStyle(destructive ? Color.red : Color.primary)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
