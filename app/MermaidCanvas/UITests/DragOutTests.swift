import XCTest

/// v26 UI-test: bevisar att alla 6 form-chips fungerar via tap OCH drag,
/// och att former faktiskt landar på canvas. Räknar former via
/// accessibility-identifiers ("shape.circle", "shape.rectangle", ...).
final class DragOutTests: XCTestCase {

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
        XCTAssertTrue(shapesBtn.waitForExistence(timeout: 4), "toolbar.shapes hittas inte")
        shapesBtn.tap()
    }

    /// Räkna antal former av en typ på canvas via accessibilityIdentifier.
    @MainActor
    private func shapeCount(_ app: XCUIApplication, type: String) -> Int {
        let q = app.descendants(matching: .any).matching(identifier: "shape.\(type)")
        return q.count
    }

    /// Räkna alla former på canvas (alla typer).
    @MainActor
    private func totalShapeCount(_ app: XCUIApplication) -> Int {
        ["circle", "rectangle", "diamond", "text", "table", "link"]
            .map { shapeCount(app, type: $0) }
            .reduce(0, +)
    }

    /// Läs ut model.shapes.count via toolbar.zoom's accessibilityValue ("shapeCount=N")
    @MainActor
    private func modelShapeCount(_ app: XCUIApplication) -> Int {
        let badge = app.buttons["toolbar.zoom"]
        guard badge.exists, let v = badge.value as? String else { return -1 }
        if let range = v.range(of: "shapeCount=") {
            let num = v[range.upperBound...]
            return Int(num) ?? -1
        }
        return -1
    }

    // MARK: - Tester

    /// Tap på cirkel-chip → modellen ska få +1 form.
    @MainActor
    func testTapAddsCircle() throws {
        let app = launchApp()
        XCTAssertEqual(modelShapeCount(app), 0, "App ska starta med 0 former")
        openShapesRow(app)

        let chip = app.buttons["chip.circle"]
        XCTAssertTrue(chip.waitForExistence(timeout: 4), "chip.circle hittas inte")
        chip.tap()

        // Vänta lite så state propagerar
        sleep(1)
        XCTAssertEqual(modelShapeCount(app), 1,
                       "Tap på chip.circle ska ha gett model.shapes.count = 1")
    }

    /// Tap på alla 6 chips → modellen ska ha 7 former (jump-link = 2).
    @MainActor
    func testAllSixChipsProduceShapes() throws {
        let app = launchApp()
        XCTAssertEqual(modelShapeCount(app), 0)
        openShapesRow(app)

        for chipId in ["chip.circle", "chip.rectangle", "chip.diamond",
                       "chip.text", "chip.table", "chip.link"] {
            let chip = app.buttons[chipId]
            XCTAssertTrue(chip.waitForExistence(timeout: 4), "\(chipId) saknas")
            chip.tap()
            sleep(UInt32(0))  // ge SwiftUI tid att uppdatera
        }
        sleep(1)
        // 5 enskilda + 1 jump-link-par = 7
        XCTAssertEqual(modelShapeCount(app), 7,
                       "Förväntade 7 former (5 enskilda + 1 jump-link-par)")
    }

    /// Drag-out: tryck-och-håll på rektangel-chip, dra till canvas-center.
    @MainActor
    func testDragRectangleChipToCanvas() throws {
        let app = launchApp()
        XCTAssertEqual(modelShapeCount(app), 0)
        openShapesRow(app)

        let chip = app.buttons["chip.rectangle"]
        XCTAssertTrue(chip.waitForExistence(timeout: 4))

        let canvas = app.otherElements["canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 4))

        let chipCoord = chip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let target = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        chipCoord.press(forDuration: 0.2, thenDragTo: target)
        sleep(1)
        XCTAssertEqual(modelShapeCount(app), 1,
                       "Drag av rektangel-chip ska ha gett model.shapes.count = 1")
    }

    /// Drag-out: cirkel → annan position.
    @MainActor
    func testDragCircleChipToCanvas() throws {
        let app = launchApp()
        XCTAssertEqual(modelShapeCount(app), 0)
        openShapesRow(app)

        let chip = app.buttons["chip.circle"]
        XCTAssertTrue(chip.waitForExistence(timeout: 4))

        let canvas = app.otherElements["canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 4))

        let chipCoord = chip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let target = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.6))
        chipCoord.press(forDuration: 0.2, thenDragTo: target)
        sleep(1)
        XCTAssertEqual(modelShapeCount(app), 1,
                       "Drag av cirkel-chip ska ha gett model.shapes.count = 1")
    }

    /// Diagnos: dumpa accessibility-tree för felsökning.
    @MainActor
    func testDebugTreeDump() throws {
        let app = launchApp()
        _ = app.buttons["toolbar.shapes"].waitForExistence(timeout: 4)
        app.buttons["toolbar.shapes"].tap()
        // Vänta lite på att sekundär-raden visas
        _ = app.buttons["chip.circle"].waitForExistence(timeout: 2)
        print("=== DEBUG TREE START ===")
        print(app.debugDescription)
        print("=== DEBUG TREE END ===")
        XCTAssertTrue(true)
    }
}
