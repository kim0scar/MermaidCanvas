import XCTest

/// v28: Visuell verifiering — skapar former, pilar, selection och tar screenshots
/// som kan inspekteras manuellt för att granska layout (rundade hörn, svart stroke,
/// safe-area, padding, ikon-tydlighet).
final class V28VisualTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testTakeScreenshotsForVisualReview() throws {
        let app = XCUIApplication()
        app.launch()

        // Screenshot 1: tom canvas vid start (50% scale så hela papperet syns)
        let s1 = XCTAttachment(screenshot: app.screenshot())
        s1.name = "01-empty-canvas"
        s1.lifetime = .keepAlways
        add(s1)

        // Öppna shapes-rad
        let shapesBtn = app.buttons["toolbar.shapes"]
        XCTAssertTrue(shapesBtn.waitForExistence(timeout: 4))
        shapesBtn.tap()

        // Skapa 3 former via tap (cirkel, rektangel, diamant)
        app.buttons["chip.circle"].tap()
        sleep(1)
        app.buttons["chip.rectangle"].tap()
        sleep(1)
        app.buttons["chip.diamond"].tap()
        sleep(1)

        // Screenshot 2: canvas med 3 former (i mitten ovanpå varandra)
        let s2 = XCTAttachment(screenshot: app.screenshot())
        s2.name = "02-three-shapes"
        s2.lifetime = .keepAlways
        add(s2)

        // Skapa en till för pilar
        app.buttons["chip.rectangle"].tap()
        sleep(1)

        // Aktivera pilar och försök skapa en
        let arrowsBtn = app.buttons["toolbar.arrows"]
        if arrowsBtn.exists {
            arrowsBtn.tap()
            sleep(1)
            let s3 = XCTAttachment(screenshot: app.screenshot())
            s3.name = "03-arrows-row"
            s3.lifetime = .keepAlways
            add(s3)
        }

        // Öppna Lägen-meny för att se den
        let modes = app.buttons["toolbar.modes"]
        if modes.exists {
            modes.tap()
            sleep(1)
            let s4 = XCTAttachment(screenshot: app.screenshot())
            s4.name = "04-lagen-meny"
            s4.lifetime = .keepAlways
            add(s4)
        }

        // Tap minimap-knapp om finns
        let mapBtn = app.buttons["toolbar.minimap"]
        if mapBtn.exists {
            mapBtn.tap()
            sleep(1)
            let s5 = XCTAttachment(screenshot: app.screenshot())
            s5.name = "05-minimap-open"
            s5.lifetime = .keepAlways
            add(s5)
        }

        XCTAssertTrue(true, "Visuell granskning — se .xcresult-bundle för screenshots")
    }
}
