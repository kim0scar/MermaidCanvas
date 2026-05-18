import Foundation
import SwiftUI

@MainActor
final class CanvasFileManager: ObservableObject {
    @Published private(set) var currentFileURL: URL?
    @Published private(set) var reloadTick: Int = 0

    private var lastModificationDate: Date?
    private var pollTimer: Timer?

    var fileName: String? { currentFileURL?.lastPathComponent }
    var hasOpenFile: Bool { currentFileURL != nil }

    /// Öppna en fil (security-scoped från fileImporter). Returnerar innehållet.
    func open(url: URL) -> String? {
        if let prev = currentFileURL, prev != url {
            prev.stopAccessingSecurityScopedResource()
        }
        _ = url.startAccessingSecurityScopedResource()
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            url.stopAccessingSecurityScopedResource()
            return nil
        }
        currentFileURL = url
        lastModificationDate = modificationDate(for: url)
        startPolling()
        return content
    }

    /// Skriv till aktuell öppen fil.
    func write(_ content: String) throws {
        guard let url = currentFileURL else {
            throw NSError(domain: "MermaidCanvas", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Ingen fil öppen"])
        }
        try content.write(to: url, atomically: true, encoding: .utf8)
        lastModificationDate = modificationDate(for: url)
    }

    /// v25: Skriv en sidecar `<basename>-regler.md` bredvid canvas-filen.
    /// Innehåller plattform-reglerna så Claude Code direkt har dem när
    /// Kim refererar till canvasen från Mac:en.
    func writeRulesSidecar(rulesText: String) {
        guard let url = currentFileURL else { return }
        let base = url.deletingPathExtension().lastPathComponent
        let sidecarName = "\(base)-regler.md"
        let sidecarURL = url.deletingLastPathComponent().appendingPathComponent(sidecarName)
        try? rulesText.write(to: sidecarURL, atomically: true, encoding: .utf8)
    }

    /// Hämta nuvarande innehåll i den öppna filen.
    func readCurrent() -> String? {
        guard let url = currentFileURL else { return nil }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    func close() {
        pollTimer?.invalidate()
        pollTimer = nil
        if let url = currentFileURL {
            url.stopAccessingSecurityScopedResource()
        }
        currentFileURL = nil
        lastModificationDate = nil
    }

    private func modificationDate(for url: URL) -> Date? {
        (try? FileManager.default.attributesOfItem(atPath: url.path))?[.modificationDate] as? Date
    }

    private func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tickIfChanged()
            }
        }
    }

    private func tickIfChanged() {
        guard let url = currentFileURL else { return }
        guard let date = modificationDate(for: url) else { return }
        if let last = lastModificationDate, date > last {
            lastModificationDate = date
            reloadTick &+= 1
        }
    }
}
