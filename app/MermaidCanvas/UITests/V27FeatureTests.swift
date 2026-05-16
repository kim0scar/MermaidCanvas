import XCTest

/// v27: Tester för nya features — drag-ut för Tabell/Länk, plattform-refactor,
/// edge-stilar, expand-canvas, minikarta.
final class V27FeatureTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launch()
        return app
    }

    @MainActor
    private func openShapesRow(_ app: XCUIApplication) {
        let shapesBtn = app.buttons["toolbar.shapes"]
        XCTAssertTrue(shapesBtn.waitForExistence(timeout: 4))
        shapesBtn.tap()
    }

    @MainActor
    private func modelShapeCount(_ app: XCUIApplication) -> Int {
        let badge = app.buttons["toolbar.zoom"]
        guard badge.exists, let v = badge.value as? String else { return -1 }
        if let range = v.range(of: "shapeCount=") {
            return Int(v[range.upperBound...]) ?? -1
        }
        return -1
    }

    // MARK: - Etapp 1: Drag-ut för Tabell + Länk

    /// Tap på tabell-chip → modellen ska få 1 form.
    @MainActor
    func testTapTableChipAddsTable() throws {
        let app = launchApp()
        openShapesRow(app)
        let chip = app.buttons["chip.table"]
        XCTAssertTrue(chip.waitForExistence(timeout: 4), "chip.table saknas")
        chip.tap()
        sleep(1)
        XCTAssertEqual(modelShapeCount(app), 1, "Tap på chip.table ska ge 1 form")
    }

    /// Tap på länk-chip → modellen ska få 2 former (jump-link-par).
    @MainActor
    func testTapLinkChipAddsJumpLinkPair() throws {
        let app = launchApp()
        openShapesRow(app)
        let chip = app.buttons["chip.link"]
        XCTAssertTrue(chip.waitForExistence(timeout: 4))
        chip.tap()
        sleep(1)
        XCTAssertEqual(modelShapeCount(app), 2, "chip.link ska ge 2 former (par)")
    }

    /// Drag-ut tabell-chip till canvas → modellen ska få 1 form.
    @MainActor
    func testDragTableChipToCanvas() throws {
        let app = launchApp()
        openShapesRow(app)
        let chip = app.buttons["chip.table"]
        XCTAssertTrue(chip.waitForExistence(timeout: 4))
        let canvas = app.otherElements["canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 4))

        let chipCoord = chip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let target = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.5))
        chipCoord.press(forDuration: 0.2, thenDragTo: target)
        sleep(1)
        XCTAssertEqual(modelShapeCount(app), 1, "Drag av chip.table ska ge 1 form")
    }

    /// Drag-ut länk-chip till canvas → modellen ska få 2 former (par).
    @MainActor
    func testDragLinkChipToCanvas() throws {
        let app = launchApp()
        openShapesRow(app)
        let chip = app.buttons["chip.link"]
        XCTAssertTrue(chip.waitForExistence(timeout: 4))
        let canvas = app.otherElements["canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 4))

        // chip.link är längst till höger; drag till mitten ger korrekt avstånd.
        let chipCoord = chip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let target = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        chipCoord.press(forDuration: 0.3, thenDragTo: target)
        sleep(2)
        XCTAssertEqual(modelShapeCount(app), 2, "Drag av chip.link ska ge 2 former (par)")
    }

    // MARK: - Etapp 3: Plattform + form-paketer

    /// Öppna Lägen-menyn → kontrollera att form-paketer-toggles existerar.
    @MainActor
    func testShapePackTogglesExistInModesMenu() throws {
        let app = launchApp()
        let modesBtn = app.buttons["toolbar.modes"]
        XCTAssertTrue(modesBtn.waitForExistence(timeout: 4))
        modesBtn.tap()

        // Form-paketer-knappar har accessibilityIdentifier "pack.ui" / "pack.roadmap" etc.
        let uiPack = app.buttons["pack.ui"]
        let archPack = app.buttons["pack.architecture"]
        let flowPack = app.buttons["pack.flow"]
        let roadmapPack = app.buttons["pack.roadmap"]

        XCTAssertTrue(uiPack.waitForExistence(timeout: 4), "pack.ui ska finnas i Lägen-menyn")
        XCTAssertTrue(archPack.exists, "pack.architecture ska finnas")
        XCTAssertTrue(flowPack.exists, "pack.flow ska finnas")
        XCTAssertTrue(roadmapPack.exists, "pack.roadmap ska finnas")
    }

    // MARK: - Etapp 4: Minikarta

    /// Minikarta-knapp ska finnas, klick togglar minikartans synlighet.
    @MainActor
    func testMinimapButtonExistsAndToggles() throws {
        let app = launchApp()
        let mapBtn = app.buttons["toolbar.minimap"]
        XCTAssertTrue(mapBtn.waitForExistence(timeout: 4), "toolbar.minimap-knapp saknas")
        mapBtn.tap()
        sleep(1)
        // Efter tap ska minikartan finnas
        let canvasMap = app.otherElements["minimap.canvas"]
        XCTAssertTrue(canvasMap.waitForExistence(timeout: 2), "minimap.canvas ska synas efter klick")

        // Klick igen → minikartan försvinner
        mapBtn.tap()
        sleep(1)
        XCTAssertFalse(canvasMap.exists, "minikartan ska försvinna vid andra klick")
    }
}
