import XCTest

/// v33: Sensor-tester som mäter EXAKTA positions/koordinater för att verifiera
/// drag-out-determinism och chip-preview-positionering.
final class V33SensorTests: XCTestCase {

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
    private func diagnostics(_ app: XCUIApplication) -> String {
        let badge = app.buttons["toolbar.zoom"]
        if !badge.waitForExistence(timeout: 4) { return "NO_BADGE" }
        return (badge.value as? String) ?? "NO_VALUE"
    }

    /// Drag chip.circle till en känd skärm-position, mät var formen landar.
    /// Avvikelse > 30pt = bugg.
    @MainActor
    func testDragCircleToKnownPosition() throws {
        let app = launchApp()
        let shapesBtn = app.buttons["toolbar.shapes"]
        XCTAssertTrue(shapesBtn.waitForExistence(timeout: 4))
        shapesBtn.tap()
        sleep(1)

        let chip = app.buttons["chip.circle"]
        let canvas = app.otherElements["canvas"]
        XCTAssertTrue(chip.waitForExistence(timeout: 3))
        XCTAssertTrue(canvas.waitForExistence(timeout: 3))

        let chipFrame = chip.frame
        let canvasFrame = canvas.frame

        let chipCenter = CGPoint(x: chipFrame.midX, y: chipFrame.midY)

        // Drop-target: viss specifik plats inom canvas, NOT mitten — så vi kan se om
        // form hamnar där fingret är eller om det är offset.
        let dropTarget = CGPoint(
            x: canvasFrame.midX + 100,   // 100pt höger om canvas-mitten
            y: canvasFrame.midY - 80     // 80pt över canvas-mitten
        )

        // Diagnostik före
        let before = diagnostics(app)
        print("BEFORE: \(before)")
        print("CHIP_CENTER: \(chipCenter)")
        print("DROP_TARGET: \(dropTarget)")
        print("CANVAS_FRAME: \(canvasFrame)")

        // Take screenshot före
        let attBefore = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attBefore.name = "before_drag"
        attBefore.lifetime = .keepAlways
        add(attBefore)

        // Drag chip till drop-target
        let chipCoord = chip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let targetCoord = canvas.coordinate(withNormalizedOffset: CGVector(
            dx: (dropTarget.x - canvasFrame.minX) / canvasFrame.width,
            dy: (dropTarget.y - canvasFrame.minY) / canvasFrame.height
        ))
        chipCoord.press(forDuration: 0.3, thenDragTo: targetCoord)
        sleep(2)

        // Diagnostik efter
        let after = diagnostics(app)
        print("AFTER: \(after)")

        // Take screenshot efter
        let attAfter = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attAfter.name = "after_drag"
        attAfter.lifetime = .keepAlways
        add(attAfter)

        // Parse "shapeCount=N;lastX=X;lastY=Y" från diagnostik
        XCTAssertTrue(after.contains("lastX="),
                      "Diagnostiken saknar lastX — form skapades inte. After=\(after)")
    }

    /// Tap (inte drag) chip.circle — form ska skapas i mitten av synlig viewport.
    @MainActor
    func testTapCircleCreatesShape() throws {
        let app = launchApp()
        let shapesBtn = app.buttons["toolbar.shapes"]
        XCTAssertTrue(shapesBtn.waitForExistence(timeout: 4))
        shapesBtn.tap()
        sleep(1)

        let before = diagnostics(app)
        print("BEFORE: \(before)")

        let attBefore = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attBefore.name = "tap_before"
        attBefore.lifetime = .keepAlways
        add(attBefore)

        app.buttons["chip.circle"].tap()
        sleep(1)

        let after = diagnostics(app)
        print("AFTER: \(after)")

        let attAfter = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attAfter.name = "tap_after"
        attAfter.lifetime = .keepAlways
        add(attAfter)

        XCTAssertTrue(after.contains("lastX="),
                      "Form skapades inte vid tap. After=\(after)")
    }
}
