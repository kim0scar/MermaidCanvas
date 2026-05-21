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
            // shapeCount=N eller shapeCount=N;lastX=...
            let tail = v[range.upperBound...]
            let numStr = tail.split(separator: ";").first.map(String.init) ?? String(tail)
            return Int(numStr) ?? -1
        }
        return -1
    }

    /// v27: läs ut senaste form-position från toolbar.zoom.accessibilityValue.
    @MainActor
    private func lastShapePosition(_ app: XCUIApplication) -> CGPoint? {
        let badge = app.buttons["toolbar.zoom"]
        guard badge.exists, let v = badge.value as? String else { return nil }
        guard let xRange = v.range(of: "lastX="),
              let yRange = v.range(of: "lastY=") else { return nil }
        let xTail = v[xRange.upperBound...]
        let xStr = xTail.split(separator: ";").first.map(String.init) ?? String(xTail)
        let yTail = v[yRange.upperBound...]
        let yStr = yTail.split(separator: ";").first.map(String.init) ?? String(yTail)
        guard let x = Double(xStr), let y = Double(yStr) else { return nil }
        return CGPoint(x: x, y: y)
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
        let canvas = app.scrollViews["canvas"]
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
        let canvas = app.scrollViews["canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 4))

        // chip.link är längst till höger; drag till mitten ger korrekt avstånd.
        let chipCoord = chip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let target = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        chipCoord.press(forDuration: 0.3, thenDragTo: target)
        sleep(2)
        XCTAssertEqual(modelShapeCount(app), 2, "Drag av chip.link ska ge 2 former (par)")
    }

    // MARK: - Position-verifiering: drag landar nära drop-punkten

    /// Verifiera att en cirkel som dras ut till canvas-mitten faktiskt landar
    /// nära canvas-mitten (inom rimligt avstånd från där fingret släpptes).
    @MainActor
    func testCircleLandsNearDropPoint() throws {
        let app = launchApp()
        openShapesRow(app)
        let chip = app.buttons["chip.circle"]
        XCTAssertTrue(chip.waitForExistence(timeout: 4))
        let canvas = app.scrollViews["canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 4))

        let chipCoord = chip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let target = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        chipCoord.press(forDuration: 0.3, thenDragTo: target)
        sleep(2)

        XCTAssertEqual(modelShapeCount(app), 1)
        guard let pos = lastShapePosition(app) else {
            XCTFail("Kunde inte läsa senaste shape-position")
            return
        }
        // v47: canvas 4000×4000 sedan v34 → mitten ≈ (2000, 2000). Tolerans 600pt.
        XCTAssertLessThan(abs(pos.x - 2000), 600, "Cirkel landade för långt från drop-punkt X (pos=\(pos))")
        XCTAssertLessThan(abs(pos.y - 2000), 600, "Cirkel landade för långt från drop-punkt Y (pos=\(pos))")
    }

    /// Verifiera att en cirkel som dras nära kanten landar långt från mitten —
    /// detta bevisar att position varierar med drop-punkt (inte alltid mitten).
    @MainActor
    func testCircleLandsNearCanvasEdge() throws {
        let app = launchApp()
        openShapesRow(app)
        let chip = app.buttons["chip.circle"]
        XCTAssertTrue(chip.waitForExistence(timeout: 4))
        let canvas = app.scrollViews["canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 4))

        // Drop till vänster överkant
        let chipCoord = chip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let target = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.25))
        chipCoord.press(forDuration: 0.3, thenDragTo: target)
        sleep(2)

        XCTAssertEqual(modelShapeCount(app), 1)
        guard let pos = lastShapePosition(app) else {
            XCTFail("Kunde inte läsa senaste shape-position")
            return
        }
        // v47: canvas 4000×4000 sedan v34 → mitten ≈ (2000, 2000). Drop i hörnet ska INTE vara där.
        let distFromCenter = abs(pos.x - 2000) + abs(pos.y - 2000)
        XCTAssertGreaterThan(distFromCenter, 80,
                             "Drop i hörnet hade samma position som mitten — drag flyttar inte (pos=\(pos))")
    }

    // MARK: - Etapp 3: Plattform + form-paketer

    /// Öppna Lägen-menyn → kontrollera att form-paketer-toggles existerar.
    @MainActor
    func testShapePackTogglesExistInModesMenu() throws {
        // v32: pack-toggles flyttades från Lägen-menyn till toolbar.packs.
        // Detta test är obsolete. Pack-toggles testas via LayoutOverflowTests/EndToEndTests.
        throw XCTSkip("v32: pack-toggles flyttade till toolbar.packs — test obsolete")
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

}
