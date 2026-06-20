import XCTest
@testable import MermaidCanvas

/// V79-svep: tvingar att "vad appen kan visa"-ramverket hålls aktuellt (Kims krav #2).
/// `AppCapabilities.shape(_:)` är redan uttömmande (kompileringsfel om en ShapeType saknas);
/// detta fångar dessutom om ramverks-GENERERINGEN tappar en form.
final class AppCapabilitiesTests: XCTestCase {

    func test_aiFramework_coversEveryShape() {
        let fw = AppCapabilities.frameworkText()
        for t in ShapeType.allCases {
            XCTAssertTrue(fw.contains(AppCapabilities.shape(t).displayName),
                          "AI-ramverket saknar \(t.rawValue) — uppdatera AppCapabilities (CLAUDE.md regel 15)")
        }
    }

    func test_aiFramework_isNonTrivialAndMentionsBothLayers() {
        let fw = AppCapabilities.frameworkText()
        XCTAssertTrue(fw.contains("NATIVE"), "ramverket ska lista native-former")
        XCTAssertTrue(fw.contains("shape-type"), "ramverket ska förklara hur egna former bärs")
        XCTAssertTrue(fw.contains("state-blocket") || fw.contains("state-JSON"),
                      "ramverket ska nämna state-lagret")
        XCTAssertFalse(AppCapabilities.features.isEmpty)
    }
}
