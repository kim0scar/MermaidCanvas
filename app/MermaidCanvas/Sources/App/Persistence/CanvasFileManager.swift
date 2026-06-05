import Foundation
import SwiftUI

@MainActor
final class CanvasFileManager: ObservableObject {
    @Published private(set) var currentFileURL: URL?
    @Published private(set) var reloadTick: Int = 0

    private var lastModificationDate: Date?
    private var lastContentHash: Int?
    private var pollTimer: Timer?
    private var changeObserver: FileChangeObserver?

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
        lastContentHash = content.hashValue
        startPolling()
        // v61: NSFilePresenter — riktiga notiser när Claude Code/iCloud skriver i filen.
        changeObserver?.stop()
        changeObserver = FileChangeObserver(url: url) { [weak self] in
            Task { @MainActor in
                self?.externalChangeTick()
            }
        }
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
        lastContentHash = content.hashValue
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
        changeObserver?.stop()
        changeObserver = nil
        if let url = currentFileURL {
            url.stopAccessingSecurityScopedResource()
        }
        currentFileURL = nil
        lastModificationDate = nil
        lastContentHash = nil
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
            if let content = try? String(contentsOf: url, encoding: .utf8) {
                lastContentHash = content.hashValue
            }
            reloadTick &+= 1
        }
    }

    /// v61: NSFilePresenter-notis. Jämför INNEHÅLL (inte datum) — iCloud kan
    /// leverera nytt innehåll utan att modification-date hunnit uppdateras.
    /// Egna skrivningar triggar inte (write() uppdaterar lastContentHash).
    private func externalChangeTick() {
        guard let url = currentFileURL,
              let content = try? String(contentsOf: url, encoding: .utf8),
              content.hashValue != lastContentHash else { return }
        lastContentHash = content.hashValue
        lastModificationDate = modificationDate(for: url)
        reloadTick &+= 1
    }
}
