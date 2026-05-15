import SwiftUI

/// Special-former-meny i toolbar. Apple-design: popover med tabell + jump-link
/// (iPhone-ramen är redan ett canvas-overlay i UI-läge, så finns inte här som "form").
struct SpecialShapesMenu: View {
    var onAddTable: () -> Void
    var onAddJumpLink: () -> Void

    var body: some View {
        Menu {
            Button { onAddTable() } label: {
                Label("Tabell (3×3)", systemImage: "tablecells")
            }
            Button { onAddJumpLink() } label: {
                Label("Jump-link (par)", systemImage: "link")
            }
        } label: {
            Image(systemName: "plus.circle")
                .font(.title3)
                .foregroundStyle(Color.primary)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
    }
}
