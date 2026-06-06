import XCTest
@testable import MermaidCanvas

/// v65: autospar får ALDRIG skriva över en öppnad befintlig fil —
/// ändringar sparas som kopia med nästa lediga namn ("namn 2.md").
@MainActor
final class V65AutosparTests: XCTestCase {

    private var dir: URL!

    override func setUp() async throws {
        dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("v65-autospar-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: dir)
    }

    private func skapa(_ namn: String, _ innehall: String = "x") throws -> URL {
        let url = dir.appendingPathComponent(namn)
        try innehall.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // MARK: - nextFreeURL

    func testNextFreeURL_ForstaKopianBlirTva() throws {
        let url = try skapa("flöde.md")
        XCTAssertEqual(CanvasFileManager.nextFreeURL(for: url).lastPathComponent, "flöde 2.md")
    }

    func testNextFreeURL_HopparUpptagnaNummer() throws {
        let url = try skapa("flöde.md")
        _ = try skapa("flöde 2.md")
        XCTAssertEqual(CanvasFileManager.nextFreeURL(for: url).lastPathComponent, "flöde 3.md")
    }

    func testNextFreeURL_StripparSiffersuffix() throws {
        _ = try skapa("flöde.md")
        let kopia = try skapa("flöde 2.md")
        // Öppnar man "flöde 2" ska nästa bli "flöde 3", inte "flöde 2 2"
        XCTAssertEqual(CanvasFileManager.nextFreeURL(for: kopia).lastPathComponent, "flöde 3.md")
    }

    // MARK: - saveAsCopy

    func testSaveAsCopy_OriginaletOrort() throws {
        let original = try skapa("flöde.md", "ORIGINAL")
        let fm = CanvasFileManager()
        XCTAssertEqual(fm.open(url: original), "ORIGINAL")
        XCTAssertTrue(fm.openedExisting, "Öppnad befintlig fil flaggas")

        let kopia = fm.saveAsCopy("ÄNDRAT")

        XCTAssertEqual(kopia?.lastPathComponent, "flöde 2.md")
        XCTAssertEqual(try String(contentsOf: original, encoding: .utf8), "ORIGINAL",
                       "ORIGINALET FÅR ALDRIG SKRIVAS ÖVER — Kims huvudkrav")
        XCTAssertEqual(try String(contentsOf: kopia!, encoding: .utf8), "ÄNDRAT")
        XCTAssertEqual(fm.currentFileURL, kopia, "Arbetet fortsätter i kopian")
        XCTAssertFalse(fm.openedExisting, "Kopian är appens egen → vanlig sparning hädanefter")
    }

    func testEgenSkapadFilSparasDirekt() throws {
        let egen = try skapa("ny.md", "A")
        let fm = CanvasFileManager()
        _ = fm.open(url: egen, asExisting: false)
        XCTAssertFalse(fm.openedExisting)
        try fm.write("B")
        XCTAssertEqual(try String(contentsOf: egen, encoding: .utf8), "B",
                       "Fil appen själv skapat skrivs över som vanligt")
    }
}
