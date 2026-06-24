import Foundation
import SwiftUI

@MainActor
final class CanvasFileManager: ObservableObject {
    @Published private(set) var currentFileURL: URL?
    @Published private(set) var reloadTick: Int = 0
    /// v65: true när aktuell fil är en BEFINTLIG fil som öppnats (inte en fil
    /// appen själv skapade). Då får autospar ALDRIG skriva över den — ändringar
    /// sparas till en kopia med nytt namn ("namn 2.md").
    private(set) var openedExisting: Bool = false

    private var lastModificationDate: Date?
    private var lastContentHash: Int?
    private var pollTimer: Timer?
    private var changeObserver: FileChangeObserver?

    var fileName: String? { currentFileURL?.lastPathComponent }
    var hasOpenFile: Bool { currentFileURL != nil }

    /// Öppna en fil (security-scoped från fileImporter). Returnerar innehållet.
    /// v65: `asExisting: false` när appen själv just skapat filen (fileExporter,
    /// kopia) — då skriver autospar direkt till filen som vanligt.
    func open(url: URL, asExisting: Bool = true) -> String? {
        if let prev = currentFileURL, prev != url {
            prev.stopAccessingSecurityScopedResource()
        }
        _ = url.startAccessingSecurityScopedResource()
        guard let content = try? String(contentsOf: url, encoding: .utf8) else {
            url.stopAccessingSecurityScopedResource()
            return nil
        }
        currentFileURL = url
        #if os(macOS)
        // 1.1 Fas 5: kom ihåg senaste filen så Mac-menyradsappen kan återöppna den.
        UserDefaults.standard.set(url.path, forKey: "mac.lastFilePath")
        #endif
        openedExisting = asExisting
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

    /// v65: spara innehållet som KOPIA med nästa lediga namn ("namn 2.md") och
    /// byt aktuell fil till kopian — originalet rörs aldrig. Faller tillbaka till
    /// appens egna Documents-mapp om mappen bredvid originalet inte går att skriva i.
    /// Returnerar kopians URL, eller nil om inget gick att skriva.
    func saveAsCopy(_ content: String) -> URL? {
        guard let url = currentFileURL else { return nil }
        let sibling = Self.nextFreeURL(for: url)
        if (try? content.write(to: sibling, atomically: true, encoding: .utf8)) != nil {
            _ = open(url: sibling, asExisting: false)
            return sibling
        }
        // Fallback: appens Documents (syns i Filer-appen under MermaidCanvas)
        guard let docs = FileManager.default.urls(for: .documentDirectory,
                                                  in: .userDomainMask).first else { return nil }
        let inDocs = Self.nextFreeURL(for: docs.appendingPathComponent(url.lastPathComponent))
        guard (try? content.write(to: inDocs, atomically: true, encoding: .utf8)) != nil else {
            return nil
        }
        _ = open(url: inDocs, asExisting: false)
        return inDocs
    }

    /// v65: nästa lediga "namn N.md" i samma mapp. Strippar befintligt
    /// siffersuffix så "flöde 2" blir "flöde 3", inte "flöde 2 2".
    static func nextFreeURL(for url: URL) -> URL {
        let ext = url.pathExtension
        var base = url.deletingPathExtension().lastPathComponent
        if let r = base.range(of: #" \d+$"#, options: .regularExpression) {
            base = String(base[..<r.lowerBound])
        }
        let dir = url.deletingLastPathComponent()
        var n = 2
        while true {
            let candidate = dir.appendingPathComponent("\(base) \(n).\(ext)")
            if !FileManager.default.fileExists(atPath: candidate.path) { return candidate }
            n += 1
        }
    }

    /// v70: spara en delmängd (en skill-container) som EGEN fil `<namn>.md` bredvid
    /// aktuell fil — UTAN att byta aktuell fil (Kim stannar kvar i pipeline-filen,
    /// helheten). Faller tillbaka till appens Documents om mappen inte går att skriva i.
    /// Returnerar den skapade filens URL, eller nil.
    func saveSkillFile(_ content: String, named rawName: String) -> URL? {
        let name = Self.sanitizeFileName(rawName)
        let dir: URL
        if let url = currentFileURL {
            dir = url.deletingLastPathComponent()
            let target = Self.freeURL(in: dir, name: name, ext: "md")
            if (try? content.write(to: target, atomically: true, encoding: .utf8)) != nil {
                return target
            }
        }
        // Fallback: appens Documents (syns i Filer-appen under MermaidCanvas)
        guard let docs = FileManager.default.urls(for: .documentDirectory,
                                                  in: .userDomainMask).first else { return nil }
        let inDocs = Self.freeURL(in: docs, name: name, ext: "md")
        return (try? content.write(to: inDocs, atomically: true, encoding: .utf8)) != nil ? inDocs : nil
    }

    /// Steg H: spara en exporterad bild (PNG) i appens Documents under ett stabilt
    /// namn (skriver över förra exporten av samma ritning → ingen filhög). Syns i
    /// Filer-appen under Visuali2e och kan delas vidare. Returnerar URL eller nil.
    func saveImage(_ data: Data, named rawName: String, ext: String = "png") -> URL? {
        let name = Self.sanitizeFileName(rawName)
        guard let docs = FileManager.default.urls(for: .documentDirectory,
                                                  in: .userDomainMask).first else { return nil }
        let target = docs.appendingPathComponent("\(name).\(ext)")
        return (try? data.write(to: target)) != nil ? target : nil
    }

    /// v70: `<dir>/<name>.md` om ledig, annars `<name> 2.md` osv.
    static func freeURL(in dir: URL, name: String, ext: String) -> URL {
        let first = dir.appendingPathComponent("\(name).\(ext)")
        if !FileManager.default.fileExists(atPath: first.path) { return first }
        return nextFreeURL(for: first)
    }

    /// v70: sanera ett container-namn till ett giltigt filnamn. Tomt → "skill".
    static func sanitizeFileName(_ raw: String) -> String {
        let bad = CharacterSet(charactersIn: "/\\:?%*|\"<>")
        let cleaned = raw.components(separatedBy: bad).joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "skill" : cleaned
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
        openedExisting = false
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
