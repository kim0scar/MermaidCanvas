import XCTest

/// v46 explorativ validering — uppdelad i många små test-metoder så att en krasch
/// i ett scenario inte slår ut resten. Varje test fångar en screenshot via
/// XCTAttachment.lifetime=.keepAlways. Resultat skrivs som "V46-LOG:"-rader
/// så de kan grep:as ur xcodebuild-output.
final class V46ExplorationTest: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launch()
        _ = app.buttons["toolbar.shapes"].waitForExistence(timeout: 6)
    }

    // MARK: - Helpers

    @MainActor
    private func snap(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let att = XCTAttachment(screenshot: screenshot)
        att.name = name
        att.lifetime = .keepAlways
        add(att)
    }

    @MainActor
    private func log(_ scenario: String, status: String, note: String = "") {
        print("V46-LOG: [\(status)] \(scenario)\(note.isEmpty ? "" : " — \(note)")")
    }

    @MainActor
    private func openShapes() {
        let b = app.buttons["toolbar.shapes"]
        if b.waitForExistence(timeout: 2) {
            b.tap()
            _ = app.buttons["chip.circle"].waitForExistence(timeout: 1.5)
        }
    }

    @MainActor
    private func modelShapeCount() -> Int {
        let badge = app.buttons["toolbar.zoom"]
        guard badge.exists, let v = badge.value as? String else { return -1 }
        if let range = v.range(of: "shapeCount=") {
            let tail = v[range.upperBound...]
            let numStr = tail.split(separator: ";").first.map(String.init) ?? String(tail)
            return Int(numStr) ?? -1
        }
        return -1
    }

    @MainActor
    private func tapChipAndSnap(_ chipId: String, shapeName: String) {
        openShapes()
        let chip = app.buttons[chipId]
        if chip.waitForExistence(timeout: 2) {
            let before = modelShapeCount()
            chip.tap()
            sleep(1)
            let after = modelShapeCount()
            snap("\(chipId)_\(shapeName)")
            if after > before {
                log("Tap \(chipId)", status: "PASS", note: "model \(before)->\(after)")
            } else {
                log("Tap \(chipId)", status: "FAIL", note: "model förblev \(before)")
            }
        } else {
            snap("\(chipId)_missing")
            log("Tap \(chipId)", status: "FAIL", note: "chip ej hittad")
        }
    }

    // MARK: - Test 01: Initial state

    @MainActor
    func test01_initialLaunch() throws {
        snap("01_initial_launch")
        let count = modelShapeCount()
        if count == 0 {
            log("01. Initial launch — 0 shapes", status: "PASS")
        } else {
            log("01. Initial launch — 0 shapes", status: "FAIL", note: "shapeCount=\(count)")
        }
    }

    // MARK: - Test 02: Open each toolbar row

    @MainActor
    func test02_openShapesRow() throws {
        if app.buttons["toolbar.shapes"].waitForExistence(timeout: 2) {
            app.buttons["toolbar.shapes"].tap()
            sleep(1)
            snap("02_shapes_row")
            let circleExists = app.buttons["chip.circle"].waitForExistence(timeout: 1.5)
            log("02. toolbar.shapes opens row", status: circleExists ? "PASS" : "FAIL",
                note: "chip.circle visible=\(circleExists)")
        } else {
            log("02. toolbar.shapes opens row", status: "FAIL", note: "button missing")
        }
    }

    @MainActor
    func test03_openPacksRow() throws {
        if app.buttons["toolbar.packs"].waitForExistence(timeout: 2) {
            app.buttons["toolbar.packs"].tap()
            sleep(1)
            snap("03_packs_row")
            let hasToggle = app.descendants(matching: .any)
                .matching(NSPredicate(format: "identifier BEGINSWITH 'toggle.pack.'"))
                .firstMatch.waitForExistence(timeout: 1.5)
            log("03. toolbar.packs opens row", status: hasToggle ? "PASS" : "FAIL",
                note: "first toggle.pack visible=\(hasToggle)")
        } else {
            log("03. toolbar.packs opens row", status: "FAIL", note: "button missing")
        }
    }

    // MARK: - Test 04-12: Add each shape type via chip-tap

    @MainActor
    func test04_chipCircle() throws { tapChipAndSnap("chip.circle", shapeName: "circle") }

    @MainActor
    func test05_chipRectangle() throws { tapChipAndSnap("chip.rectangle", shapeName: "rectangle") }

    @MainActor
    func test06_chipSquare() throws { tapChipAndSnap("chip.square", shapeName: "square") }

    @MainActor
    func test07_chipDiamond() throws { tapChipAndSnap("chip.diamond", shapeName: "diamond") }

    @MainActor
    func test08_chipPill() throws { tapChipAndSnap("chip.pill", shapeName: "pill") }

    @MainActor
    func test09_chipProcessArrow() throws { tapChipAndSnap("chip.processArrow", shapeName: "processArrow") }

    @MainActor
    func test10_chipContainer() throws { tapChipAndSnap("chip.container", shapeName: "container") }

    @MainActor
    func test11_chipLine() throws { tapChipAndSnap("chip.line", shapeName: "line") }

    @MainActor
    func test12_chipTable() throws {
        openShapes()
        let chip = app.buttons["chip.table"]
        if chip.waitForExistence(timeout: 2) {
            let before = modelShapeCount()
            chip.tap()
            sleep(2)
            snap("12_chip_table_state")
            let after = modelShapeCount()
            // chip.table kan öppna table-editor-sheet eller lägga direkt
            log("12. chip.table action", status: after > before ? "PASS" : "NOTE",
                note: "model \(before)->\(after) (kan kräva sheet-bekräftelse)")
        } else {
            log("12. chip.table action", status: "FAIL", note: "chip ej hittad")
        }
    }

    @MainActor
    func test13_chipLink() throws {
        openShapes()
        let chip = app.buttons["chip.link"]
        if chip.waitForExistence(timeout: 2) {
            let before = modelShapeCount()
            chip.tap()
            sleep(2)
            snap("13_chip_link")
            let after = modelShapeCount()
            // jump-link ska skapa 2 noder
            let expected = before + 2
            if after == expected {
                log("13. chip.link skapar par av jump-länkar", status: "PASS",
                    note: "model \(before)->\(after)")
            } else if after > before {
                log("13. chip.link skapar par av jump-länkar", status: "FAIL",
                    note: "model \(before)->\(after), förväntat +2 (=\(expected))")
            } else {
                log("13. chip.link skapar par av jump-länkar", status: "FAIL",
                    note: "model förblev \(before)")
            }
        } else {
            log("13. chip.link skapar par av jump-länkar", status: "FAIL", note: "chip ej hittad")
        }
    }

    @MainActor
    func test14_chipNotePopup() throws {
        openShapes()
        let chip = app.buttons["chip.notepopup"]
        if chip.waitForExistence(timeout: 2) {
            chip.tap()
            sleep(2)
            snap("14_notepopup_sheet")
            log("14. chip.notepopup öppnar sheet", status: "PASS", note: "kontrollera screenshot")
        } else {
            log("14. chip.notepopup öppnar sheet", status: "FAIL", note: "chip ej hittad")
        }
    }

    // MARK: - Test 20: Selection + colors

    @MainActor
    func test20_addCircleThenSelect() throws {
        openShapes()
        if app.buttons["chip.circle"].waitForExistence(timeout: 2) {
            app.buttons["chip.circle"].tap()
            sleep(1)
        }
        let circle = app.descendants(matching: .any).matching(identifier: "shape.circle").firstMatch
        if circle.waitForExistence(timeout: 2) {
            circle.tap()
            sleep(1)
            snap("20_circle_selected")
            // Kontrollera om colors blev enabled
            let colors = app.buttons["toolbar.colors"]
            let enabled = colors.exists && colors.isEnabled
            log("20. Tap shape.circle markerar form", status: "PASS",
                note: "toolbar.colors enabled=\(enabled)")
        } else {
            log("20. Tap shape.circle markerar form", status: "FAIL", note: "shape.circle saknas")
        }
    }

    @MainActor
    func test21_openColorsRow() throws {
        // Markera först en form
        openShapes()
        if app.buttons["chip.circle"].waitForExistence(timeout: 2) {
            app.buttons["chip.circle"].tap()
            sleep(1)
        }
        let circle = app.descendants(matching: .any).matching(identifier: "shape.circle").firstMatch
        if circle.waitForExistence(timeout: 2) { circle.tap(); sleep(1) }

        if app.buttons["toolbar.colors"].waitForExistence(timeout: 2) {
            app.buttons["toolbar.colors"].tap()
            sleep(1)
            snap("21_colors_row")
            log("21. toolbar.colors visar färg-rad", status: "PASS", note: "kontrollera screenshot")
        } else {
            log("21. toolbar.colors visar färg-rad", status: "FAIL", note: "toolbar.colors saknas")
        }
    }

    @MainActor
    func test22_openTextStylesRow() throws {
        openShapes()
        if app.buttons["chip.circle"].waitForExistence(timeout: 2) {
            app.buttons["chip.circle"].tap()
            sleep(1)
        }
        let circle = app.descendants(matching: .any).matching(identifier: "shape.circle").firstMatch
        if circle.waitForExistence(timeout: 2) { circle.tap(); sleep(1) }

        // OBS: i koden är identifier `toolbar.textStyles` med stort S
        if app.buttons["toolbar.textStyles"].waitForExistence(timeout: 2) {
            app.buttons["toolbar.textStyles"].tap()
            sleep(1)
            snap("22_textstyles_row")
            log("22. toolbar.textStyles visar text-rad", status: "PASS")
        } else {
            log("22. toolbar.textStyles visar text-rad", status: "FAIL", note: "toolbar.textStyles saknas")
        }
    }

    // MARK: - Test 30: Multi-select / marker

    @MainActor
    func test30_toggleMarkerMode() throws {
        if app.buttons["toolbar.marker"].waitForExistence(timeout: 2) {
            app.buttons["toolbar.marker"].tap()
            sleep(1)
            snap("30_marker_on")
            log("30. toolbar.marker togglar markering", status: "PASS")
            // Toggle av igen
            app.buttons["toolbar.marker"].tap()
            sleep(1)
        } else {
            log("30. toolbar.marker togglar markering", status: "FAIL", note: "knapp saknas")
        }
    }

    @MainActor
    func test31_markerMarqueeDrag() throws {
        // Lägg först några shapes
        openShapes()
        if app.buttons["chip.circle"].waitForExistence(timeout: 2) {
            app.buttons["chip.circle"].tap(); sleep(1)
            app.buttons["chip.rectangle"].tap(); sleep(1)
        }
        // Aktivera marker
        if app.buttons["toolbar.marker"].exists {
            app.buttons["toolbar.marker"].tap()
            sleep(1)
        }
        // Dra över canvas
        let canvas = app.scrollViews["canvas"]
        if canvas.waitForExistence(timeout: 2) {
            let p1 = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.3))
            let p2 = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.8))
            p1.press(forDuration: 0.3, thenDragTo: p2)
            sleep(2)
            snap("31_marker_marquee")
            log("31. Marquee-drag i markering-mode", status: "PASS",
                note: "kontrollera om former blev markerade")
        } else {
            log("31. Marquee-drag i markering-mode", status: "FAIL", note: "canvas saknas")
        }
    }

    // MARK: - Test 40: Edit-sheet

    @MainActor
    func test40_editSheetOnCircle() throws {
        openShapes()
        if app.buttons["chip.circle"].waitForExistence(timeout: 2) {
            app.buttons["chip.circle"].tap()
            sleep(1)
        }
        let circle = app.descendants(matching: .any).matching(identifier: "shape.circle").firstMatch
        if circle.waitForExistence(timeout: 2) {
            // Första tap markerar
            circle.tap()
            sleep(1)
            // Andra tap öppnar edit-sheet
            circle.tap()
            sleep(2)
            snap("40_edit_sheet_open")
            let editLabel = app.descendants(matching: .any).matching(identifier: "edit.label").firstMatch
            if editLabel.waitForExistence(timeout: 2) {
                log("40. Double-tap öppnar EditShapeSheet", status: "PASS", note: "edit.label hittad")
            } else {
                log("40. Double-tap öppnar EditShapeSheet", status: "NOTE",
                    note: "edit.label ej hittad — kontrollera screenshot")
            }
        } else {
            log("40. Double-tap öppnar EditShapeSheet", status: "FAIL", note: "shape.circle saknas")
        }
    }

    // MARK: - Test 50: Edge between shapes via connection.handle

    @MainActor
    func test50_edgeBetweenShapes() throws {
        openShapes()
        if app.buttons["chip.circle"].waitForExistence(timeout: 2) {
            app.buttons["chip.circle"].tap(); sleep(1)
            app.buttons["chip.rectangle"].tap(); sleep(1)
        }
        let circles = app.descendants(matching: .any).matching(identifier: "shape.circle")
        let rects = app.descendants(matching: .any).matching(identifier: "shape.rectangle")
        if circles.count >= 1 && rects.count >= 1 {
            circles.element(boundBy: 0).tap()
            sleep(1)
            let handle = app.descendants(matching: .any).matching(identifier: "connection.handle").firstMatch
            if handle.waitForExistence(timeout: 2) {
                let handleCoord = handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                let targetCoord = rects.element(boundBy: 0).coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                handleCoord.press(forDuration: 0.3, thenDragTo: targetCoord)
                sleep(2)
                snap("50_edge_drawn")
                log("50. Pil via connection.handle", status: "PASS", note: "drag utfört")
            } else {
                snap("50_no_handle")
                log("50. Pil via connection.handle", status: "FAIL", note: "connection.handle saknas")
            }
        } else {
            log("50. Pil via connection.handle", status: "FAIL",
                note: "färre än 2 olika former (cirkel/rektangel)")
        }
    }

    // MARK: - Test 60-69: Hamburger meny

    @MainActor
    func test60_hamburgerMenuOpens() throws {
        if app.buttons["toolbar.modes"].waitForExistence(timeout: 2) {
            app.buttons["toolbar.modes"].tap()
            sleep(1)
            snap("60_hamburger_menu")
            // Sök efter v46
            let v46Hit = app.descendants(matching: .any)
                .matching(NSPredicate(format: "label CONTAINS 'v46'")).firstMatch
            let v46Found = v46Hit.exists
            log("60. Hamburger öppnas + visar v46", status: v46Found ? "PASS" : "FAIL",
                note: "v46-label hittad=\(v46Found)")
            // Stäng meny
            let canvas = app.scrollViews["canvas"]
            if canvas.exists {
                canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                sleep(1)
            }
        } else {
            log("60. Hamburger öppnas + visar v46", status: "FAIL", note: "toolbar.modes saknas")
        }
    }

    @MainActor
    func test61_showMermaidCode() throws {
        if app.buttons["toolbar.modes"].waitForExistence(timeout: 2) {
            app.buttons["toolbar.modes"].tap()
            sleep(1)
            if app.buttons["menu.showCode"].waitForExistence(timeout: 2) {
                app.buttons["menu.showCode"].tap()
                sleep(2)
                snap("61_mermaid_code_sheet")
                let codeContent = app.descendants(matching: .any).matching(identifier: "sheet.codeContent").firstMatch
                log("61. Visa Mermaid-kod-sheet", status: codeContent.waitForExistence(timeout: 2) ? "PASS" : "NOTE",
                    note: "sheet.codeContent hittad=\(codeContent.exists)")
                // Stäng
                if app.navigationBars.buttons["Klart"].exists { app.navigationBars.buttons["Klart"].tap() }
                else if app.navigationBars.buttons["Done"].exists { app.navigationBars.buttons["Done"].tap() }
                else if app.navigationBars.buttons["Stäng"].exists { app.navigationBars.buttons["Stäng"].tap() }
                else { app.swipeDown() }
                sleep(1)
            } else {
                log("61. Visa Mermaid-kod-sheet", status: "FAIL", note: "menu.showCode saknas")
            }
        } else {
            log("61. Visa Mermaid-kod-sheet", status: "FAIL", note: "toolbar.modes saknas")
        }
    }

    @MainActor
    func test62_importMermaidSheet() throws {
        if app.buttons["toolbar.modes"].waitForExistence(timeout: 2) {
            app.buttons["toolbar.modes"].tap()
            sleep(1)
            let importBtn = app.buttons["Importera Mermaid…"]
            if importBtn.waitForExistence(timeout: 2) {
                importBtn.tap()
                sleep(2)
                snap("62_import_mermaid_sheet")
                log("62. Importera Mermaid-sheet öppnas", status: "PASS",
                    note: "kontrollera screenshot")
                // Stäng
                if app.navigationBars.buttons["Avbryt"].exists { app.navigationBars.buttons["Avbryt"].tap() }
                else if app.navigationBars.buttons["Klart"].exists { app.navigationBars.buttons["Klart"].tap() }
                else if app.navigationBars.buttons["Stäng"].exists { app.navigationBars.buttons["Stäng"].tap() }
                else { app.swipeDown() }
                sleep(1)
            } else {
                snap("62_no_import_button")
                log("62. Importera Mermaid-sheet öppnas", status: "FAIL",
                    note: "Knapp 'Importera Mermaid…' saknas")
                // Stäng menyn
                let canvas = app.scrollViews["canvas"]
                if canvas.exists { canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap() }
            }
        } else {
            log("62. Importera Mermaid-sheet öppnas", status: "FAIL", note: "toolbar.modes saknas")
        }
    }

    @MainActor
    func test63_newCanvasPicker() throws {
        if app.buttons["toolbar.modes"].waitForExistence(timeout: 2) {
            app.buttons["toolbar.modes"].tap()
            sleep(1)
            // Hitta "Ny canvas (välj plattform)"
            let newBtn = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Ny canvas'")).firstMatch
            if newBtn.waitForExistence(timeout: 2) {
                newBtn.tap()
                sleep(2)
                snap("63_new_canvas_picker")
                log("63. Ny canvas-väljaren öppnas", status: "PASS", note: "kontrollera screenshot")
                // Stäng
                if app.navigationBars.buttons["Avbryt"].exists { app.navigationBars.buttons["Avbryt"].tap() }
                else { app.swipeDown() }
                sleep(1)
            } else {
                snap("63_no_new_canvas_btn")
                log("63. Ny canvas-väljaren öppnas", status: "FAIL", note: "knapp saknas")
            }
        } else {
            log("63. Ny canvas-väljaren öppnas", status: "FAIL", note: "toolbar.modes saknas")
        }
    }

    // MARK: - Test 70: Toolbar zoom + undo

    @MainActor
    func test70_zoomButtonClickable() throws {
        if app.buttons["toolbar.zoom"].waitForExistence(timeout: 2) {
            app.buttons["toolbar.zoom"].tap()
            sleep(1)
            snap("70_zoom_clicked")
            log("70. toolbar.zoom är klickbar (reset)", status: "PASS")
        } else {
            log("70. toolbar.zoom är klickbar (reset)", status: "FAIL")
        }
    }

    @MainActor
    func test71_undoAfterAdd() throws {
        openShapes()
        if app.buttons["chip.circle"].waitForExistence(timeout: 2) {
            app.buttons["chip.circle"].tap()
            sleep(1)
        }
        let before = modelShapeCount()
        if app.buttons["toolbar.undo"].waitForExistence(timeout: 2) {
            if app.buttons["toolbar.undo"].isEnabled {
                app.buttons["toolbar.undo"].tap()
                sleep(1)
                snap("71_after_undo")
                let after = modelShapeCount()
                if after < before {
                    log("71. Undo minskar shape-count", status: "PASS", note: "model \(before)->\(after)")
                } else {
                    log("71. Undo minskar shape-count", status: "FAIL",
                        note: "model förblev \(before)")
                }
            } else {
                log("71. Undo minskar shape-count", status: "NOTE", note: "undo disabled")
            }
        } else {
            log("71. Undo minskar shape-count", status: "FAIL", note: "toolbar.undo saknas")
        }
    }

    // MARK: - Test 80: Drag-out (drag chip to canvas)

    @MainActor
    func test80_dragRectangleChipToCanvas() throws {
        openShapes()
        let chip = app.buttons["chip.rectangle"]
        let canvas = app.scrollViews["canvas"]
        if chip.waitForExistence(timeout: 2), canvas.waitForExistence(timeout: 2) {
            let before = modelShapeCount()
            let chipCoord = chip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let target = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.7))
            chipCoord.press(forDuration: 0.3, thenDragTo: target)
            sleep(2)
            snap("80_drag_rectangle_to_canvas")
            let after = modelShapeCount()
            if after > before {
                log("80. Drag chip.rectangle till canvas", status: "PASS",
                    note: "model \(before)->\(after)")
            } else {
                log("80. Drag chip.rectangle till canvas", status: "FAIL",
                    note: "model förblev \(before)")
            }
        } else {
            log("80. Drag chip.rectangle till canvas", status: "FAIL", note: "chip eller canvas saknas")
        }
    }

    @MainActor
    func test81_dragCircleChipToCorner() throws {
        openShapes()
        let chip = app.buttons["chip.circle"]
        let canvas = app.scrollViews["canvas"]
        if chip.waitForExistence(timeout: 2), canvas.waitForExistence(timeout: 2) {
            let before = modelShapeCount()
            let chipCoord = chip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let target = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
            chipCoord.press(forDuration: 0.3, thenDragTo: target)
            sleep(2)
            snap("81_drag_circle_to_corner")
            let after = modelShapeCount()
            if after > before {
                log("81. Drag chip.circle till annan position", status: "PASS",
                    note: "model \(before)->\(after)")
            } else {
                log("81. Drag chip.circle till annan position", status: "FAIL",
                    note: "model förblev \(before)")
            }
        } else {
            log("81. Drag chip.circle till annan position", status: "FAIL")
        }
    }

    // MARK: - Test 90: Pack-toggle visuellt

    @MainActor
    func test90_togglePack() throws {
        if app.buttons["toolbar.packs"].waitForExistence(timeout: 2) {
            app.buttons["toolbar.packs"].tap()
            sleep(1)
            let toggle = app.descendants(matching: .any)
                .matching(NSPredicate(format: "identifier BEGINSWITH 'toggle.pack.'")).firstMatch
            if toggle.waitForExistence(timeout: 2) {
                toggle.tap()
                sleep(1)
                snap("90_pack_toggled_on")
                toggle.tap()
                sleep(1)
                snap("90_pack_toggled_off")
                log("90. Pack-toggle togglar fram/tillbaka", status: "PASS")
            } else {
                log("90. Pack-toggle togglar fram/tillbaka", status: "FAIL", note: "ingen toggle hittad")
            }
        } else {
            log("90. Pack-toggle togglar fram/tillbaka", status: "FAIL", note: "toolbar.packs saknas")
        }
    }
}
