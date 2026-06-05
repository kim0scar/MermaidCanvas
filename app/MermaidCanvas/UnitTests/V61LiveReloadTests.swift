import XCTest
import Combine
@testable import MermaidCanvas

/// v61: NSFilePresenter-baserad live-reload. En extern KOORDINERAD skrivning
/// (så skriver iCloud-synken och andra processer) ska bumpa reloadTick —
/// utan att vänta på datum-polling. Egna skrivningar ska INTE trigga.
@MainActor
final class V61LiveReloadTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    private func tempFile(_ content: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("livereload-\(UUID().uuidString).md")
        try content.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    func testExternKoordineradSkrivningTriggarReload() async throws {
        let url = try tempFile("# version 1")
        defer { try? FileManager.default.removeItem(at: url) }

        let manager = CanvasFileManager()
        XCTAssertEqual(manager.open(url: url), "# version 1")

        let exp = expectation(description: "reloadTick ska bumpa vid extern skrivning")
        manager.$reloadTick
            .dropFirst()
            .sink { _ in exp.fulfill() }
            .store(in: &cancellables)

        // Extern part (Claude Code / iCloud) skriver koordinerat
        let coordinator = NSFileCoordinator()
        coordinator.coordinate(writingItemAt: url, options: .forReplacing, error: nil) { u in
            try? "# version 2".write(to: u, atomically: true, encoding: .utf8)
        }

        await fulfillment(of: [exp], timeout: 5)
        XCTAssertEqual(manager.readCurrent(), "# version 2")
        manager.close()
    }

    func testEgenSkrivningTriggarInteReload() async throws {
        let url = try tempFile("# original")
        defer { try? FileManager.default.removeItem(at: url) }

        let manager = CanvasFileManager()
        _ = manager.open(url: url)

        var ticks = 0
        manager.$reloadTick
            .dropFirst()
            .sink { _ in ticks += 1 }
            .store(in: &cancellables)

        try manager.write("# egen ändring")
        // Ge presenter-kön tid att leverera eventuell (felaktig) notis
        try await Task.sleep(nanoseconds: 1_000_000_000)
        XCTAssertEqual(ticks, 0, "Egen skrivning får inte trigga reload-loop")
        manager.close()
    }
}
