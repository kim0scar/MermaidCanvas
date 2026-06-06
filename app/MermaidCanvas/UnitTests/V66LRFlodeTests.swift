import XCTest
import CoreGraphics
@testable import MermaidCanvas

/// v66: LR-flödesfilerna (horisontella, n8n-lika) — verifierar layouten
/// genom att parsa de FAKTISKA filerna i Kims iCloud (simulatorn delar
/// Mac:ens filsystem). Hoppar över om filerna saknas (annan maskin).
final class V66LRFlodeTests: XCTestCase {

    private let mapp = "/Users/kim/Library/Mobile Documents/com~apple~CloudDocs/00000. Claude Code/1. Mermaid"

    private func las(_ namn: String) -> String? {
        try? String(contentsOfFile: "\(mapp)/\(namn)", encoding: .utf8)
    }

    func testWebbskrapLR_HorisontellLayout() throws {
        guard let md = las("webbskrap-flode-lr.md") else {
            throw XCTSkip("LR-filen finns inte på den här maskinen")
        }
        let p = MermaidParser.parse(md)
        func pos(_ label: String) -> CGPoint? {
            p.shapes.first { $0.label == label }?.position
        }
        guard let input = pos("Skrapa webbsida"),
              let router = pos("Vilket verktyg?"),
              let steg2 = pos("steg2-data.md"),
              let output = pos("Visa resultatet i chatten"),
              let kod = pos("Skrapa med kod"),
              let browser = pos("Skrapa med browser-MCP"),
              let llm = pos("LLM läser sidan") else {
            return XCTFail("Noder saknas i LR-filen")
        }
        // Horisontellt: x ökar längs kedjan
        XCTAssertLessThan(input.x, router.x)
        XCTAssertLessThan(router.x, steg2.x)
        XCTAssertLessThan(steg2.x, output.x)
        // Huvudraden ligger på samma y
        XCTAssertEqual(input.y, router.y, accuracy: 1)
        XCTAssertEqual(router.y, output.y, accuracy: 1)
        // Grenarna sprids VERTIKALT vid samma x (kod över, llm under)
        XCTAssertEqual(kod.x, browser.x, accuracy: 1)
        XCTAssertLessThan(kod.y, browser.y)
        XCTAssertLessThan(browser.y, llm.y)
        // Containrarnas barn ligger inom sina containrar (delta-fällan)
        for barn in p.shapes where barn.childOfContainerId != nil {
            guard let cont = p.shapes.first(where: { $0.id == barn.childOfContainerId }) else {
                return XCTFail("Container saknas för \(barn.label)")
            }
            XCTAssertLessThan(abs(barn.position.x - cont.position.x),
                              ShapeGeometry.width(for: cont) / 2 + 60,
                              "\(barn.label) ska ligga i \(cont.label)")
        }
        // Legenden följer med
        XCTAssertFalse(p.legend.isEmpty, "LR-filen har legend-rader")
    }

    func testMorgonkollLR_HorisontellLayout() throws {
        guard let md = las("morgonkoll-flode-lr.md") else {
            throw XCTSkip("LR-filen finns inte på den här maskinen")
        }
        let p = MermaidParser.parse(md)
        let xs = ["Kör morgonkoll", "Hämta olästa mejl", "steg1-mejl.md",
                  "Prioritera i 3 hinkar", "steg2-sammanfattning.md",
                  "Skriv Kims rapport", "Visa rapporten i chatten"]
            .compactMap { namn in p.shapes.first { $0.label == namn }?.position.x }
        XCTAssertEqual(xs.count, 7, "Alla 7 noder hittade")
        XCTAssertEqual(xs, xs.sorted(), "Kedjan går vänster → höger")
    }

    /// LR-default: flow-fil UTAN explicit riktning auto-layoutas horisontellt.
    func testFlowUtanRiktning_FarLRDefault() {
        let md = """
        ---
        title: T
        spec_type: flow
        ---
        ```mermaid
        flowchart
            a["Ett"] --> b["Två"]
            b --> c["Tre"]
        ```
        """
        let p = MermaidParser.parse(md)
        func x(_ label: String) -> CGFloat { p.shapes.first { $0.label == label }?.position.x ?? 0 }
        XCTAssertLessThan(x("Ett"), x("Två"), "LR-default för flow")
        XCTAssertLessThan(x("Två"), x("Tre"))
    }
}
