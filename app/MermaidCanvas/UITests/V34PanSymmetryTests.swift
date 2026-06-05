import XCTest

/// v34: Verifiera att pan fungerar SYMMETRISKT åt alla fyra håll.
/// Kim rapporterade att han inte kunde panorera UPP och VÄNSTER — vilket
/// betyder att canvasen startade i övre-vänstra hörnet (contentOffset=(0,0))
/// istället för centrerat på (2000,2000).
///
/// Detta test läser scrollView.accessibilityValue (format "x=<int>,y=<int>,s=<float>")
/// före och efter swipe, och verifierar att contentOffset ändras i förväntad riktning.
final class V34PanSymmetryTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCanvasStartsCenteredNotAtOrigin() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-orientationMode", "portrait"]
        app.launch()
        sleep(2)  // ge layoutSubviews + fitToScreen tid att köra

        let canvas = app.scrollViews["canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 4), "canvas-scrollView saknas")

        guard let value = canvas.value as? String, let offset = parseOffset(value) else {
            XCTFail("canvas.accessibilityValue saknas eller fel format: \(canvas.value ?? "nil")")
            return
        }

        // Canvas är 4000×4000. Vid scale 1.0 på iPhone 17 (~393×852pt) ska startoffset
        // vara nära (2000 - 196, 2000 - 426) = (1804, 1574) — alltså INTE (0,0).
        // Vi kollar att initialoffset är minst > 500 i båda axlar.
        XCTAssertGreaterThan(offset.x, 500,
                             "Initial contentOffset.x=\(offset.x) — canvasen startar inte centrerad")
        XCTAssertGreaterThan(offset.y, 500,
                             "Initial contentOffset.y=\(offset.y) — canvasen startar inte centrerad")
    }

    @MainActor
    func testPanWorksInAllFourDirections() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-orientationMode", "portrait"]
        app.launch()
        sleep(2)

        let canvas = app.scrollViews["canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 4))

        guard let v0 = canvas.value as? String, let initial = parseOffset(v0) else {
            XCTFail("Kunde inte läsa initial offset")
            return
        }
        print("V34_PAN: initial=\(initial)")

        // 1. Pan VÄNSTER (swipe right på skärmen → content rör sig vänster → offset.x minskar)
        canvas.swipeRight()
        sleep(1)
        guard let v1 = canvas.value as? String, let afterRight = parseOffset(v1) else {
            XCTFail("Kunde inte läsa offset efter swipeRight")
            return
        }
        print("V34_PAN: after swipeRight=\(afterRight)")
        XCTAssertLessThan(afterRight.x, initial.x,
                          "Pan VÄNSTER (swipeRight) ska minska offset.x. Initial=\(initial.x), efter=\(afterRight.x)")

        // 2. Pan HÖGER (swipe left → offset.x ökar)
        canvas.swipeLeft()
        sleep(1)
        guard let v2 = canvas.value as? String, let afterLeft = parseOffset(v2) else {
            XCTFail("Kunde inte läsa offset efter swipeLeft")
            return
        }
        print("V34_PAN: after swipeLeft=\(afterLeft)")
        XCTAssertGreaterThan(afterLeft.x, afterRight.x,
                             "Pan HÖGER (swipeLeft) ska öka offset.x. Före=\(afterRight.x), efter=\(afterLeft.x)")

        // 3. Pan UPP (swipe down → offset.y minskar)
        canvas.swipeDown()
        sleep(1)
        guard let v3 = canvas.value as? String, let afterDown = parseOffset(v3) else {
            XCTFail("Kunde inte läsa offset efter swipeDown")
            return
        }
        print("V34_PAN: after swipeDown=\(afterDown)")
        XCTAssertLessThan(afterDown.y, afterLeft.y,
                          "Pan UPP (swipeDown) ska minska offset.y. Före=\(afterLeft.y), efter=\(afterDown.y)")

        // 4. Pan NER (swipe up → offset.y ökar)
        canvas.swipeUp()
        sleep(1)
        guard let v4 = canvas.value as? String, let afterUp = parseOffset(v4) else {
            XCTFail("Kunde inte läsa offset efter swipeUp")
            return
        }
        print("V34_PAN: after swipeUp=\(afterUp)")
        XCTAssertGreaterThan(afterUp.y, afterDown.y,
                             "Pan NER (swipeUp) ska öka offset.y. Före=\(afterDown.y), efter=\(afterUp.y)")

        print("V34_PAN_SYMMETRY: PASS — alla 4 riktningar funkar")
    }

    // MARK: - Hjälpare

    private func parseOffset(_ value: String) -> (x: Int, y: Int, s: Double)? {
        // Format: "x=<int>,y=<int>,s=<float>"
        let parts = value.split(separator: ",")
        guard parts.count == 3 else { return nil }
        let xStr = parts[0].replacingOccurrences(of: "x=", with: "")
        let yStr = parts[1].replacingOccurrences(of: "y=", with: "")
        let sStr = parts[2].replacingOccurrences(of: "s=", with: "")
        guard let x = Int(xStr), let y = Int(yStr), let s = Double(sStr) else { return nil }
        return (x, y, s)
    }
}
