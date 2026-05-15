import SwiftUI

/// Liten badge som visas på formens överhörn när det finns text i note-fältet.
/// Tap → onTap-callback (öppnar mini-note-sheet eller hela edit-sheet).
struct NoteBadge: View {
    var canvasScale: CGFloat
    var onTap: () -> Void

    var body: some View {
        let size: CGFloat = max(20, 22 / canvasScale)
        Button(action: onTap) {
            Image(systemName: "note.text")
                .font(.system(size: size * 0.6, weight: .semibold))
                .foregroundStyle(Color.white)
                .frame(width: size, height: size)
                .background(Color.yellow)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.black.opacity(0.15), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }
}
