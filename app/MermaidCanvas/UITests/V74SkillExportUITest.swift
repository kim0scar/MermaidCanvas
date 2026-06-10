import XCTest

/// v74 Steg 9: Claude kör appen själv — skapar en skill-container via UI:t,
/// sätter namn + kedjenummer, och exporterar den portabla skill-filen via
/// long-press-menyn. Skärmdumpar sparas till /tmp/v74-ui/ för granskning.
final class V74SkillExportUITest: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        try? FileManager.default.createDirectory(atPath: "/tmp/v74-ui",
                                                 withIntermediateDirectories: true)
    }

    @MainActor
    private func snap(_ name: String) {
        let png = XCUIScreen.main.screenshot().pngRepresentation
        try? png.write(to: URL(fileURLWithPath: "/tmp/v74-ui/\(name).png"))
    }

    @MainActor
    private func dragChipToCanvas(_ app: XCUIApplication, chipId: String,
                                  to offset: CGVector) {
        let chip = app.buttons[chipId]
        let canvas = app.scrollViews["canvas"]
        XCTAssertTrue(chip.waitForExistence(timeout: 4), "chip \(chipId) saknas")
        XCTAssertTrue(canvas.waitForExistence(timeout: 4))
        let from = chip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let to = canvas.coordinate(withNormalizedOffset: offset)
        from.press(forDuration: 0.2, thenDragTo: to)
        sleep(1)
    }

    @MainActor
    func testSkapaSkillContainer_Nummer_ExporteraPortabelFil() {
        let app = XCUIApplication()
        app.launchArguments += ["-orientationMode", "portrait"]
        app.launch()
        snap("01-start")

        // 1. Öppna formpaket-raden och slå på n8n-paketet
        let packsBtn = app.buttons["toolbar.packs"]
        XCTAssertTrue(packsBtn.waitForExistence(timeout: 5))
        packsBtn.tap()
        sleep(1)
        snap("02a-packs-rad")
        let n8nToggle = app.buttons["toggle.pack.n8n"]
        if !n8nToggle.waitForExistence(timeout: 4) {
            try? app.debugDescription.write(toFile: "/tmp/v74-ui/tree.txt",
                                            atomically: true, encoding: .utf8)
        }
        XCTAssertTrue(n8nToggle.exists, "n8n-pack-toggle saknas")
        if !app.buttons["chip.flow.skill"].exists {
            n8nToggle.tap()
            sleep(1)
        }
        snap("02-n8n-chips")

        // 2. Tap lägger formen vid canvas-mitten (flowChips är tap-knappar):
        //    först agent-noden, sen skill-containern som adopterar den.
        app.buttons["chip.flow.agent"].tap()
        sleep(1)
        app.buttons["chip.flow.skill"].tap()
        sleep(1)
        packsBtn.tap()   // stäng panelen så containern inte täcks
        sleep(1)
        let container = app.descendants(matching: .any)
            .matching(identifier: "shape.container").firstMatch
        XCTAssertTrue(container.waitForExistence(timeout: 4), "skill-containern ska finnas på canvas")
        snap("03-skill-container-skapad")

        // 3. Long-press → Redigera: döp till demo-skill + sätt Skill-nummer 1
        container.press(forDuration: 0.7)
        let editBtn = app.buttons["Redigera"]
        XCTAssertTrue(editBtn.waitForExistence(timeout: 4), "context-menyn ska öppnas")
        editBtn.tap()
        let labelField = app.textFields["edit.label"]
        _ = labelField.waitForExistence(timeout: 4)
        let anyField: XCUIElement = labelField.exists ? labelField : app.textViews["edit.label"]
        XCTAssertTrue(anyField.exists, "namnfältet ska finnas")
        anyField.tap()
        // Rensa default-namnet ("Grupp"/"Skill") och skriv det nya
        if let current = anyField.value as? String, !current.isEmpty {
            let deletes = String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count + 2)
            anyField.typeText(deletes)
        }
        anyField.typeText("demo-skill")
        let nrToggle = app.switches["Har nummer"]
        XCTAssertTrue(nrToggle.waitForExistence(timeout: 3),
                      "skill-nummer-sektionen ska synas för skill-containrar")
        nrToggle.switches.firstMatch.tap()
        sleep(1)
        XCTAssertTrue(app.steppers.firstMatch.exists, "steppern 'Skill 1' ska synas")
        snap("04-edit-skillnummer")
        app.buttons["Klar"].tap()
        sleep(1)
        snap("05-skill1-header")

        // 4. Long-press → Spara skill som fil (portabel export)
        container.press(forDuration: 0.7)
        let saveBtn = app.buttons["Spara skill som fil"]
        XCTAssertTrue(saveBtn.waitForExistence(timeout: 4), "spara-knappen ska finnas i menyn")
        saveBtn.tap()
        sleep(2)
        snap("06-export-klar")
    }
}
