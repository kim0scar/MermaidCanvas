import SwiftUI
#if os(iOS)
import UIKit
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
/// 1.1 macOS-stub (Fas 3) — riktig delning (NSSharingServicePicker) byggs i Fas 6.
struct ActivityView: View {
    let items: [Any]
    var body: some View { EmptyView() }
}
#endif
