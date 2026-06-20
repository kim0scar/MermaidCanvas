import XCTest

/// v32: Layout-tester som fångar buggar XCUITest tidigare missade —
/// element som ligger UTANFÖR skärm-bredd.
final class LayoutOverflowTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testToolbarFitsOnScreen() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-orientationMode", "portrait"]
        app.launch()
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 4))
        let screenW = window.frame.maxX

        // De element som ska vara inom skärm-bredd
        let elementsToCheck = [
            "toolbar.shapes",
            "toolbar.arrows",
            "toolbar.packs",
            "toolbar.colors",
            "toolbar.textStyles",
            "toolbar.zoom",
            "toolbar.undo",
            "toolbar.redo",
            "toolbar.modes"
        ]
        for id in elementsToCheck {
            let elem = app.buttons[id]
            if elem.exists {
                XCTAssertLessThanOrEqual(elem.frame.maxX, screenW,
                                         "Element \(id) sticker ut till höger om skärm (maxX=\(elem.frame.maxX), screenW=\(screenW))")
                XCTAssertGreaterThanOrEqual(elem.frame.minX, 0,
                                            "Element \(id) sticker ut till vänster (minX=\(elem.frame.minX))")
            }
        }
    }

    @MainActor
    func testShapesRowChipsFitOnScreen() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-orientationMode", "portrait"]
        app.launch()
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 4))
        let screenW = window.frame.maxX

        let shapesBtn = app.buttons["toolbar.shapes"]
        XCTAssertTrue(shapesBtn.waitForExistence(timeout: 3))
        shapesBtn.tap()
        sleep(1)

        let chipIds = [
            "chip.circle", "chip.rectangle", "chip.diamond", "chip.pill",
            "chip.text", "chip.table", "chip.link", "chip.line", "chip.arrow", "chip.notepopup"
        ]
        for id in chipIds {
            let chip = app.buttons[id]
            if chip.exists {
                XCTAssertLessThanOrEqual(chip.frame.maxX, screenW,
                                         "Chip \(id) sticker ut åt höger")
                XCTAssertGreaterThanOrEqual(chip.frame.minX, 0,
                                            "Chip \(id) sticker ut åt vänster")
            }
        }
    }
}
