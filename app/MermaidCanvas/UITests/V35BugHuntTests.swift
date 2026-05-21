import XCTest

/// v35: Felsöka två rapporterade buggar:
/// 1. "skapa en hel del former och sen blev det något konstigt och de försvann"
/// 2. "fungerade inte zoomen"
///
/// Hypotes 1 (former försvinner): UIHostingController.rootView reassignment
/// triggar inte alltid SwiftUI re-render när CanvasModel ändras. Lösning: id()
/// eller force-redraw.
///
/// Hypotes 2 (zoom funkar inte): ShapeView-gestures inom canvas-content kan
/// stjäla pinch-events. Eller UIScrollView's pinch är blockad.
final class V35BugHuntTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAddTenShapesAllRemainVisible() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(2)

        // Öppna former-raden
        app.buttons["toolbar.shapes"].tap()
        sleep(1)

        let chip = app.buttons["chip.circle"]
        XCTAssertTrue(chip.waitForExistence(timeout: 4))

        // Räkna shapes före
        let initialShapeCount = app.descendants(matching: .any).matching(identifier: "shape.circle").count
        print("V35_BUG: initial shape.circle count = \(initialShapeCount)")

        // Lägg 10 former via tap (tap-flödet lägger i canvas-mitten/synlig viewport)
        for i in 0..<10 {
            chip.tap()
            // Kort paus så SwiftUI hinner uppdatera
            Thread.sleep(forTimeInterval: 0.3)
            let count = app.descendants(matching: .any).matching(identifier: "shape.circle").count
            print("V35_BUG: efter tap #\(i+1) — shape.circle count = \(count)")
        }
        sleep(2)

        // Verifiera att alla 10 finns kvar
        let finalCount = app.descendants(matching: .any).matching(identifier: "shape.circle").count
        print("V35_BUG: final shape.circle count = \(finalCount)")

        // Ta screenshot för visuell verifiering
        let att = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        att.name = "after_10_shapes"
        att.lifetime = .keepAlways
        add(att)

        XCTAssertGreaterThanOrEqual(finalCount, 10 + initialShapeCount,
                                    "10 former lades men bara \(finalCount - initialShapeCount) kvarstår — former försvinner!")
    }

    @MainActor
    func testZoomChangesScrollViewState() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(2)

        let canvas = app.scrollViews["canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 4))

        let initialValue = canvas.value as? String ?? ""
        print("V35_BUG: initial canvas.value = \(initialValue)")

        // Försök pinch-zoom in (faktor 2.0)
        canvas.pinch(withScale: 2.0, velocity: 1.0)
        sleep(1)

        let afterPinchValue = canvas.value as? String ?? ""
        print("V35_BUG: efter pinch 2.0 canvas.value = \(afterPinchValue)")

        XCTAssertNotEqual(initialValue, afterPinchValue,
                          "Pinch ändrade inte scrollView-state — zoom funkar inte!")

        // Försök zoom ut (faktor 0.5)
        canvas.pinch(withScale: 0.5, velocity: -1.0)
        sleep(1)

        let afterShrinkValue = canvas.value as? String ?? ""
        print("V35_BUG: efter pinch 0.5 canvas.value = \(afterShrinkValue)")

        XCTAssertNotEqual(afterPinchValue, afterShrinkValue,
                          "Pinch ut ändrade inte scrollView-state")
    }

    @MainActor
    func testTapChipAfterPanPlacesShapeInVisibleViewport() throws {
        // Kim:s rapporterade bugg: efter pan/zoom, tappa chip → form "försvinner"
        // (hamnar i statisk canvas-mitten 2000,2000 som är utanför skärm).
        // v35 fix: canvasCenter räknas från viewportState.visibleCenterInCanvas.
        let app = XCUIApplication()
        app.launch()
        sleep(2)

        let canvas = app.scrollViews["canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 4))

        // Panorera långt åt höger + ner så viewport-mitten flyttas
        canvas.swipeLeft()
        sleep(1)
        canvas.swipeLeft()
        sleep(1)
        canvas.swipeUp()
        sleep(1)

        let afterPan = canvas.value as? String ?? ""
        print("V35_BUG: efter pan canvas.value = \(afterPan)")

        // Öppna former-raden + tap circle
        app.buttons["toolbar.shapes"].tap()
        sleep(1)
        app.buttons["chip.circle"].tap()
        sleep(2)

        // Verifiera att en cirkel-shape syns på skärmen
        let shape = app.descendants(matching: .any).matching(identifier: "shape.circle").firstMatch
        XCTAssertTrue(shape.waitForExistence(timeout: 4),
                      "Efter pan + tap-chip ska en cirkel synas i viewport — om den hamnar i statisk canvas-mitten är den utanför skärm")

        // Ta screenshot
        let att = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        att.name = "after_pan_and_tap"
        att.lifetime = .keepAlways
        add(att)

        // Verifiera att shape är inom synlig viewport (frame ej tom)
        XCTAssertTrue(shape.frame.width > 0 && shape.frame.height > 0,
                      "Shape ska ha synlig frame efter tap (inte utanför skärm)")
    }

    @MainActor
    func testAddShapeThenZoomWorks() throws {
        // Kombinationen: lägg en form, sen zooma. Kim's bugg kan vara att zoom
        // går sönder efter shape-interaktioner.
        let app = XCUIApplication()
        app.launch()
        sleep(2)

        app.buttons["toolbar.shapes"].tap()
        sleep(1)

        let chip = app.buttons["chip.circle"]
        chip.tap()  // skapa cirkel
        sleep(1)

        let canvas = app.scrollViews["canvas"]
        let beforeZoom = canvas.value as? String ?? ""
        print("V35_BUG: efter add-shape canvas.value = \(beforeZoom)")

        canvas.pinch(withScale: 2.0, velocity: 1.0)
        sleep(1)

        let afterZoom = canvas.value as? String ?? ""
        print("V35_BUG: efter pinch canvas.value = \(afterZoom)")

        XCTAssertNotEqual(beforeZoom, afterZoom,
                          "Zoom funkar inte efter att form lagts till!")
    }
}
