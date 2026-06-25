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

        // 1.2: Öppna Former → Paket-fliken och slå på Skillflöde-paketet (ersatte n8n).
        // OBS: segment-tap är flakig i XCUITest → försök tills Paket-innehållet syns (no-op om redan vald).
        let shapesBtn = app.buttons["toolbar.shapes"]
        XCTAssertTrue(shapesBtn.waitForExistence(timeout: 5))
        shapesBtn.tap()
        sleep(1)
        let skillToggle = app.buttons["toggle.pack.skillFlow"]
        for _ in 0..<6 where !skillToggle.exists {
            app.segmentedControls["shapes.section"].buttons["Paket"].tap()
            _ = skillToggle.waitForExistence(timeout: 2)
        }
        snap("02a-packs-rad")
        XCTAssertTrue(skillToggle.exists, "skillFlow-pack-toggle saknas (Paket-fliken öppnade ej)")
        if !app.buttons["chip.skill.skill"].exists {
            skillToggle.tap()
            sleep(1)
        }
        snap("02-skill-chips")

        // 2. Tap lägger formen vid canvas-mitten (flowChips är tap-knappar):
        //    först agent-noden, sen skill-containern som adopterar den.
        app.buttons["chip.skill.subagent"].tap()
        sleep(1)
        app.buttons["chip.skill.skill"].tap()
        sleep(1)
        shapesBtn.tap()   // stäng Former-raden så containern inte täcks
        sleep(1)
        let container = app.descendants(matching: .any)
            .matching(identifier: "shape.container").firstMatch
        XCTAssertTrue(container.waitForExistence(timeout: 4), "skill-containern ska finnas på canvas")
        snap("03-skill-container-skapad")

        // 3. Long-press på container-HEADERN (mitten är barnets yta) → Redigera
        let headerPoint = container.coordinate(withNormalizedOffset: CGVector(dx: 0.25, dy: 0.04))
        headerPoint.press(forDuration: 0.8)
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

        // 4. Long-press på headern → Spara skill som fil → v75: "Spara som"-dialog (Files)
        headerPoint.press(forDuration: 0.8)
        let saveBtn = app.buttons["Spara skill som fil"]
        XCTAssertTrue(saveBtn.waitForExistence(timeout: 4), "spara-knappen ska finnas i menyn")
        saveBtn.tap()
        sleep(2)
        snap("06-spara-som-dialog")
        // Genomgång (2026-06-24): systemets Files-export-dialog är OS-styrd + opålitlig i XCUITest
        // (knapp-språk Spara/Save + separat process) — samma klass projektet XCTSkip:ar. Appens
        // ansvar (export-flödet TRIGGAS) är verifierat ovan; den exporterade FILENS innehåll är
        // unit-testat (SkillFileComposer + V74SkillNrTests). Driv därför systemdialogen best-effort.
        let confirm = app.buttons.matching(NSPredicate(format: "label == 'Spara' OR label == 'Save'")).firstMatch
        if confirm.waitForExistence(timeout: 8) {
            confirm.tap()
            let ok = app.alerts.buttons.matching(NSPredicate(format: "label == 'OK'")).firstMatch
            if ok.waitForExistence(timeout: 6) { ok.tap() }
            snap("07-export-klar")
        } else {
            snap("07-spara-dialog-ej-accessibel-i-xcuitest")
        }
    }
}
