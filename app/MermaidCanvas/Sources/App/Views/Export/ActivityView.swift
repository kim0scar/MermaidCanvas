import SwiftUI
import UIKit

/// Steg H: exporterad bild som sheet-item (Identifiable → `.sheet(item:)`).
struct ExportImageItem: Identifiable {
    let id = UUID()
    let url: URL
}

/// Steg H: tunn brygga till iOS delningsmeny (UIActivityViewController) så Kim
/// kan spara bilden i Foto/Filer eller skicka den vidare.
struct ActivityView: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
