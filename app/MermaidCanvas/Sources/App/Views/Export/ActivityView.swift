import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

/// Steg H: exporterad bild som sheet-item (Identifiable → `.sheet(item:)`).
struct ExportImageItem: Identifiable {
    let id = UUID()
    let url: URL
}

#if os(iOS)
/// Steg H: tunn brygga till iOS delningsmeny (UIActivityViewController) så Kim
/// kan spara bilden i Foto/Filer eller skicka den vidare.
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
#else
/// 1.1 Fas 6: macOS-delning av exporterad bild — visa i Finder / kopiera sökväg.
struct ActivityView: View {
    let items: [Any]
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill").font(.largeTitle).foregroundStyle(.green)
            Text("Bilden är exporterad").font(.headline)
            if let url = items.first as? URL {
                Text(url.lastPathComponent).font(.caption).foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    Button("Visa i Finder") { NSWorkspace.shared.activateFileViewerSelecting([url]) }
                    Button("Kopiera sökväg") { Clipboard.copy(url.path) }
                }
            }
            Button("Klar") { dismiss() }.keyboardShortcut(.defaultAction)
        }
        .padding(30)
        .frame(minWidth: 360)
    }
}
#endif
