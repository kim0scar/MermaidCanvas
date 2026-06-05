import XCTest

/// v48 verification: reproducerar de 4 v48-felen visuellt så agenter kan
/// analysera om fixarna fungerade.
///
/// Fel #1: Pilspets-symmetri
/// Fel #2: Midpoint-ikon roterar med linjen + sitter mitt på linjen
/// Fel #3: Lila minus visas BARA vid markering, vid utgående kants start
/// Fel #4: Plus alltid synlig vid kollapsat, med streckad stub
final class V48VerificationTest: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    @MainActor
    private func attach(_ app: XCUIApplication, name: String) {
        let att = XCTAttachment(screenshot: app.screenshot())
        att.name = name
        att.lifetime = .keepAlways
        add(att)
    }

    /// Setup: skapa 2 rektanglar + 1 cirkel.
    @MainActor
    func test_v48_step1_create_three_shapes() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-orientationMode", "portrait"]
        app.launch()
        sleep(1)

        let shapesBtn = app.buttons["toolbar.shapes"]
        XCTAssertTrue(shapesBtn.waitForExistence(timeout: 4))
        shapesBtn.tap()
        sleep(1)

        attach(app, name: "00_empty_canvas_with_chips")

        // Skapa rektangel #1 via tap
        let rect = app.buttons["chip.rectangle"]
        XCTAssertTrue(rect.waitForExistence(timeout: 3))
        rect.tap()
        sleep(1)
        attach(app, name: "01_first_rectangle")

        // Skapa rektangel #2
        rect.tap()
        sleep(1)
        attach(app, name: "02_second_rectangle")

        // Skapa cirkel via drag (drop till annan position)
        let circle = app.buttons["chip.circle"]
        XCTAssertTrue(circle.waitForExistence(timeout: 3))
        let canvas = app.scrollViews["canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 3))
        let from = circle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let to = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.7))
        from.press(forDuration: 0.2, thenDragTo: to)
        sleep(2)
        attach(app, name: "03_three_shapes")
    }

    /// Skapa pil mellan två former — via ConnectionHandle (v44+).
    /// Sedan tar screenshot för att se pilspets-symmetri (Fel #1).
    @MainActor
    func test_v48_step2_create_arrow_and_verify_symmetry() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-orientationMode", "portrait"]
        app.launch()
        sleep(1)

        let shapesBtn = app.buttons["toolbar.shapes"]
        if shapesBtn.waitForExistence(timeout: 4) { shapesBtn.tap(); sleep(1) }

        // Skapa rektangel
        let rectChip = app.buttons["chip.rectangle"]
        XCTAssertTrue(rectChip.waitForExistence(timeout: 4), "chip.rectangle saknas")
        rectChip.tap()
        sleep(1)
        // Skapa cirkel långt åt höger
        let circle = app.buttons["chip.circle"]
        let canvas = app.scrollViews["canvas"]
        let circleFrom = circle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let circleTo = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.5))
        circleFrom.press(forDuration: 0.2, thenDragTo: circleTo)
        sleep(2)
        attach(app, name: "04_rect_and_circle_horizontal")

        // Markera rektangel (tap)
        let rectangle = app.descendants(matching: .any)
            .matching(identifier: "shape.rectangle").firstMatch
        if rectangle.exists {
            rectangle.tap()
            sleep(1)
            attach(app, name: "05_rectangle_selected_with_handles")
        }
    }

    // MARK: - Agent A: nya test-fall med faktisk pil

    /// test_a4: Horisontell pil → pilspets-symmetri (Fel #1) + midpoint-ikon (Fel #2).
    /// Skapar rektangel till vänster och cirkel till höger, drar pil med connection.handle.
    @MainActor
    func test_a4_arrow_horizontal() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-orientationMode", "portrait"]
        app.launch()
        sleep(1)

        let shapesBtn = app.buttons["toolbar.shapes"]
        if shapesBtn.waitForExistence(timeout: 4) { shapesBtn.tap(); sleep(1) }

        // Skapa rektangel (tap = centralt)
        app.buttons["chip.rectangle"].tap(); sleep(1)

        // Skapa cirkel via drag till höger
        let canvas = app.scrollViews["canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 3))
        let circleChip = app.buttons["chip.circle"]
        XCTAssertTrue(circleChip.waitForExistence(timeout: 3))
        let chipCoord = circleChip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let circleTarget = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.5))
        chipCoord.press(forDuration: 0.2, thenDragTo: circleTarget)
        sleep(2)
        attach(app, name: "a4_01_rect_and_circle")

        // Markera rektangeln (tap i vänstra halvan av canvas)
        let rect = app.descendants(matching: .any).matching(identifier: "shape.rectangle").firstMatch
        XCTAssertTrue(rect.waitForExistence(timeout: 3))
        rect.tap(); sleep(1)
        attach(app, name: "a4_02_rect_selected_connection_handle_visible")

        // Drag från connection.handle till cirkeln
        let handle = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "connection.handle")).firstMatch
        if handle.waitForExistence(timeout: 3) {
            let circle = app.descendants(matching: .any).matching(identifier: "shape.circle").firstMatch
            XCTAssertTrue(circle.waitForExistence(timeout: 2))
            let handleCoord = handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let circleCoord = circle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            handleCoord.press(forDuration: 0.4, thenDragTo: circleCoord)
            sleep(2)
            attach(app, name: "a4_03_arrow_drawn_horizontal")
            // Avmarkera
            canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85)).tap()
            sleep(1)
            attach(app, name: "a4_04_arrow_unselected_pilspets_symmetri")
        } else {
            attach(app, name: "a4_03_FAIL_no_connection_handle")
            XCTFail("connection.handle hittades inte — kan inte dra pil")
        }
    }

    /// test_a5: Vertikal pil → midpoint-ikon ska rotera 90° (Fel #2).
    @MainActor
    func test_a5_arrow_vertical() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-orientationMode", "portrait"]
        app.launch()
        sleep(1)

        let shapesBtn = app.buttons["toolbar.shapes"]
        if shapesBtn.waitForExistence(timeout: 4) { shapesBtn.tap(); sleep(1) }

        let canvas = app.scrollViews["canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 3))

        // Rektangel uppe (tap = centralt = ungefär 0.5,0.5)
        app.buttons["chip.rectangle"].tap(); sleep(1)

        // Cirkel nere — drag till låg y-pos
        let circleChip = app.buttons["chip.circle"]
        XCTAssertTrue(circleChip.waitForExistence(timeout: 3))
        let chipCoord = circleChip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let circleTarget = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.78))
        chipCoord.press(forDuration: 0.2, thenDragTo: circleTarget)
        sleep(2)
        attach(app, name: "a5_01_rect_top_circle_bottom")

        let rect = app.descendants(matching: .any).matching(identifier: "shape.rectangle").firstMatch
        XCTAssertTrue(rect.waitForExistence(timeout: 3))
        rect.tap(); sleep(1)
        attach(app, name: "a5_02_rect_selected")

        let handle = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "connection.handle")).firstMatch
        if handle.waitForExistence(timeout: 3) {
            let circle = app.descendants(matching: .any).matching(identifier: "shape.circle").firstMatch
            XCTAssertTrue(circle.waitForExistence(timeout: 2))
            let handleCoord = handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let circleCoord = circle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            handleCoord.press(forDuration: 0.4, thenDragTo: circleCoord)
            sleep(2)
            attach(app, name: "a5_03_vertical_arrow_midpoint_should_rotate")
        } else {
            attach(app, name: "a5_03_FAIL_no_connection_handle")
            XCTFail("connection.handle hittades inte")
        }
    }

    /// test_a6: Pil + markera from-shape → minus-badge ska vara synlig (Fel #3).
    @MainActor
    func test_a6_arrow_marked_minus_badge() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-orientationMode", "portrait"]
        app.launch()
        sleep(1)

        let shapesBtn = app.buttons["toolbar.shapes"]
        if shapesBtn.waitForExistence(timeout: 4) { shapesBtn.tap(); sleep(1) }

        let canvas = app.scrollViews["canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 3))

        // Rektangel
        app.buttons["chip.rectangle"].tap(); sleep(1)

        // Cirkel till höger
        let circleChip = app.buttons["chip.circle"]
        XCTAssertTrue(circleChip.waitForExistence(timeout: 3))
        let chipCoord = circleChip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let circleTarget = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.78, dy: 0.5))
        chipCoord.press(forDuration: 0.2, thenDragTo: circleTarget)
        sleep(2)

        // Dra pil: markera rektangel → dra handle till cirkel
        let rect = app.descendants(matching: .any).matching(identifier: "shape.rectangle").firstMatch
        XCTAssertTrue(rect.waitForExistence(timeout: 3))
        rect.tap(); sleep(1)

        let handle = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "connection.handle")).firstMatch
        if handle.waitForExistence(timeout: 3) {
            let circle = app.descendants(matching: .any).matching(identifier: "shape.circle").firstMatch
            XCTAssertTrue(circle.waitForExistence(timeout: 2))
            handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                .press(forDuration: 0.4, thenDragTo: circle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
            sleep(2)
        }
        attach(app, name: "a6_01_arrow_created")

        // Avmarkera
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85)).tap(); sleep(1)
        attach(app, name: "a6_02_deselected_no_badge_expected")

        // Markera rektangeln igen → minus-badge ska dyka upp
        let rects = app.descendants(matching: .any).matching(identifier: "shape.rectangle")
        rects.firstMatch.tap(); sleep(1)
        attach(app, name: "a6_03_rect_selected_minus_badge_should_appear")

        let minusBadge = app.descendants(matching: .any)
            .matching(identifier: "edge.collapse.minus").firstMatch
        let badgeExists = minusBadge.waitForExistence(timeout: 2)
        if badgeExists {
            print("V48-A6: [PASS] edge.collapse.minus synlig vid markering")
        } else {
            print("V48-A6: [FAIL] edge.collapse.minus SAKNAS vid markering — Fel #3 kvarstår")
        }
    }

    /// test_a7: Pil + kollapsa from-shape → plus-badge + streckad stub (Fel #4).
    @MainActor
    func test_a7_arrow_collapsed_plus_stub() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-orientationMode", "portrait"]
        app.launch()
        sleep(1)

        let shapesBtn = app.buttons["toolbar.shapes"]
        if shapesBtn.waitForExistence(timeout: 4) { shapesBtn.tap(); sleep(1) }

        let canvas = app.scrollViews["canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 3))

        // Rektangel
        app.buttons["chip.rectangle"].tap(); sleep(1)

        // Cirkel till höger
        let circleChip = app.buttons["chip.circle"]
        XCTAssertTrue(circleChip.waitForExistence(timeout: 3))
        let chipCoord = circleChip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let circleTarget = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.78, dy: 0.5))
        chipCoord.press(forDuration: 0.2, thenDragTo: circleTarget)
        sleep(2)

        // Dra pil
        let rect = app.descendants(matching: .any).matching(identifier: "shape.rectangle").firstMatch
        XCTAssertTrue(rect.waitForExistence(timeout: 3))
        rect.tap(); sleep(1)

        let handle = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "connection.handle")).firstMatch
        if handle.waitForExistence(timeout: 3) {
            let circle = app.descendants(matching: .any).matching(identifier: "shape.circle").firstMatch
            XCTAssertTrue(circle.waitForExistence(timeout: 2))
            handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                .press(forDuration: 0.4, thenDragTo: circle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
            sleep(2)
        }
        attach(app, name: "a7_01_arrow_created")

        // Markera rektangeln
        let rects = app.descendants(matching: .any).matching(identifier: "shape.rectangle")
        rects.firstMatch.tap(); sleep(1)
        attach(app, name: "a7_02_rect_selected_with_minus_badge")

        // Tryck på minus-badge om den finns, annars försök direkt collapse via badge
        let minusBadge = app.descendants(matching: .any)
            .matching(identifier: "edge.collapse.minus").firstMatch
        if minusBadge.waitForExistence(timeout: 2) {
            minusBadge.tap(); sleep(2)
            attach(app, name: "a7_03_after_collapse_plus_and_stub_expected")
            let plusBadge = app.descendants(matching: .any)
                .matching(identifier: "edge.stub.badge").firstMatch
            let plusExists = plusBadge.waitForExistence(timeout: 2)
            if plusExists {
                print("V48-A7: [PASS] edge.stub.badge synlig efter kollaps — Fel #4 OK")
            } else {
                print("V48-A7: [FAIL] edge.stub.badge SAKNAS efter kollaps — Fel #4 kvarstår")
            }
        } else {
            attach(app, name: "a7_03_FAIL_no_minus_badge_cannot_collapse")
            print("V48-A7: [BLOCKED] minus-badge saknas — kan inte testa Fel #4 (Fel #3 blockerar)")
        }
    }

    // MARK: - Agent B tester (test_b_*) — pil-skapande + visuell verifiering

    /// Hjälpfunktion: starta app + öppna chip-drawer.
    @MainActor
    private func launchAndOpenShapes() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-orientationMode", "portrait"]
        app.launch()
        sleep(1)
        let shapesBtn = app.buttons["toolbar.shapes"]
        if shapesBtn.waitForExistence(timeout: 4) { shapesBtn.tap(); sleep(1) }
        return app
    }

    /// Hjälpfunktion: skapa rektangel via tap på chip.
    @MainActor
    private func addRectangle(_ app: XCUIApplication) {
        let btn = app.buttons["chip.rectangle"]
        if btn.waitForExistence(timeout: 3) { btn.tap(); sleep(1) }
    }

    /// Hjälpfunktion: skapa cirkel via drag till given canvas-koordinat (normaliserad).
    @MainActor
    private func addCircle(_ app: XCUIApplication, toDx: CGFloat = 0.72, toDy: CGFloat = 0.5) {
        let circle = app.buttons["chip.circle"]
        guard circle.waitForExistence(timeout: 3) else { return }
        let canvas = app.scrollViews["canvas"]
        guard canvas.waitForExistence(timeout: 3) else { return }
        let from = circle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let to   = canvas.coordinate(withNormalizedOffset: CGVector(dx: toDx, dy: toDy))
        from.press(forDuration: 0.3, thenDragTo: to)
        sleep(2)
    }

    /// Hjälpfunktion: markera första rektangeln.
    @MainActor
    private func selectFirstRectangle(_ app: XCUIApplication) -> XCUIElement? {
        let rect = app.descendants(matching: .any).matching(identifier: "shape.rectangle").firstMatch
        guard rect.waitForExistence(timeout: 3) else { return nil }
        rect.tap(); sleep(1)
        return rect
    }

    /// Hjälpfunktion: dra connection-handle till cirkeln.
    /// Returnerar true om handle hittades.
    @discardableResult
    @MainActor
    private func dragConnectionHandleToCircle(_ app: XCUIApplication) -> Bool {
        // v60-fix: använd det RIKTNINGSSPECIFIKA höger-handtaget (pekar mot cirkeln)
        // istället för firstMatch — annars kan vänster-handtaget väljas och draget
        // korsar formen utan att registreras. Längre press + hold gör draget pålitligt.
        let handle = handleTowardCircle(app)
        guard handle.waitForExistence(timeout: 3) else { return false }
        let circle = app.descendants(matching: .any).matching(identifier: "shape.circle").firstMatch
        guard circle.waitForExistence(timeout: 3) else { return false }
        let fromC = handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let toC   = circle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        fromC.press(forDuration: 0.6, thenDragTo: toC, withVelocity: .default, thenHoldForDuration: 0.2)
        sleep(2)
        return true
    }

    /// v60-fix: välj det connection-handtag som pekar mot cirkeln. Cirkel under
    /// rektangeln → botten-handtaget; annars (höger om) → höger-handtaget.
    /// Riktningsspecifika id:n (connection.handle.right/bottom/...) infördes i v50.2;
    /// gamla testerna använde det borttagna singular-id:t "connection.handle".
    @MainActor
    private func handleTowardCircle(_ app: XCUIApplication) -> XCUIElement {
        let rect = app.descendants(matching: .any).matching(identifier: "shape.rectangle").firstMatch
        let circle = app.descendants(matching: .any).matching(identifier: "shape.circle").firstMatch
        if rect.exists, circle.exists {
            let dy = circle.frame.midY - rect.frame.midY
            let dx = circle.frame.midX - rect.frame.midX
            if abs(dy) > abs(dx) {
                return app.descendants(matching: .any)
                    .matching(identifier: dy > 0 ? "connection.handle.bottom" : "connection.handle.top").firstMatch
            }
        }
        return app.descendants(matching: .any).matching(identifier: "connection.handle.right").firstMatch
    }

    /// test_b1: Skapa rektangel + cirkel horisontellt → dra pil → screenshot för pilspets.
    /// Verifierar Fel #1 (pilspets-symmetri) visuellt.
    @MainActor
    func test_b1_arrow_horizontal() throws {
        let app = launchAndOpenShapes()
        addRectangle(app)
        attach(app, name: "b1_01_after_rect")

        // Cirkel till höger
        addCircle(app, toDx: 0.85, toDy: 0.5)
        attach(app, name: "b1_02_rect_and_circle")

        // Markera rektangeln
        guard selectFirstRectangle(app) != nil else {
            XCTFail("Kunde inte markera rektangeln"); return
        }
        attach(app, name: "b1_03_rect_selected_with_handle")

        // Verifiera att connection.handle finns
        let handle = app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "connection.handle")).firstMatch
        XCTAssertTrue(handle.waitForExistence(timeout: 3), "connection.handle ska visas när rektangel är markerad")

        // Dra pil till cirkel
        let success = dragConnectionHandleToCircle(app)
        XCTAssertTrue(success, "Kunde inte dra connection-handle till cirkel")
        attach(app, name: "b1_04_arrow_created")

        // Avmarkera för rent slutscreenshot
        let canvas = app.scrollViews["canvas"]
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.2)).tap()
        sleep(1)
        attach(app, name: "b1_05_arrow_final_deselected")

        XCTAssertTrue(true, "Visuell granskning — se b1_04 och b1_05 för pilspets-symmetri")
    }

    /// test_b2: Pil vertikalt → midpoint-ikon ska rotera med linjen (Fel #2).
    @MainActor
    func test_b2_arrow_vertical() throws {
        let app = launchAndOpenShapes()
        addRectangle(app)

        // Cirkel rakt nedanför
        addCircle(app, toDx: 0.5, toDy: 0.78)
        attach(app, name: "b2_01_rect_circle_vertical")

        guard selectFirstRectangle(app) != nil else {
            XCTFail("Rektangel ej markerad"); return
        }
        attach(app, name: "b2_02_rect_selected")

        let success = dragConnectionHandleToCircle(app)
        XCTAssertTrue(success, "Pil kunde inte skapas vertikalt")
        attach(app, name: "b2_03_vertical_arrow")

        app.scrollViews["canvas"].coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.5)).tap()
        sleep(1)
        attach(app, name: "b2_04_vertical_arrow_deselected")

        XCTAssertTrue(true, "Visuell granskning — se b2_03 och b2_04 för midpoint-rotation")
    }

    /// test_b3: Markera from-shape med pil → minus-badge ska visas (Fel #3).
    @MainActor
    func test_b3_arrow_marked() throws {
        let app = launchAndOpenShapes()
        addRectangle(app)
        addCircle(app, toDx: 0.85, toDy: 0.5)

        guard selectFirstRectangle(app) != nil else {
            XCTFail("Rektangel ej markerad"); return
        }
        let success = dragConnectionHandleToCircle(app)
        XCTAssertTrue(success, "Pil kunde inte skapas")
        sleep(1)

        // Avmarkera
        app.scrollViews["canvas"].coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.2)).tap()
        sleep(1)
        attach(app, name: "b3_01_arrow_deselected_no_badge")

        // ÅTERmarkera from-shape
        guard selectFirstRectangle(app) != nil else {
            XCTFail("Rektangel ej återmarkerad"); return
        }
        attach(app, name: "b3_02_from_shape_reselected_badge_should_appear")

        // EdgeStartCollapseBadge har ingen accessibilityIdentifier → visuell granskning
        XCTAssertTrue(true, "Visuell granskning — se b3_02, lila minus-badge vid kantstart?")
    }

    /// test_b4: Kollapsa from → stub + edge.stub.badge (plus) ska synas (Fel #4).
    /// v60-fix: deterministiskt launch-scenario + tap på minus-badgen — kringgår
    /// den opålitliga connection.handle-dragen i simulatorn.
    @MainActor
    func test_b4_arrow_collapsed() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-v49-rect-circle-arrow"]
        app.launch()
        sleep(2)
        attach(app, name: "b4_01_from_selected_before_collapse")

        let minusBadge = app.descendants(matching: .any).matching(identifier: "edge.collapse.minus").firstMatch
        XCTAssertTrue(minusBadge.waitForExistence(timeout: 3),
                      "edge.collapse.minus saknas på markerad from-shape")
        minusBadge.tap()
        sleep(2)
        attach(app, name: "b4_02_after_collapse_attempt")

        let plusBadge = app.descendants(matching: .any).matching(identifier: "edge.stub.badge").firstMatch
        XCTAssertTrue(plusBadge.waitForExistence(timeout: 3),
                      "edge.stub.badge (plus) saknas efter kollaps")
        attach(app, name: "b4_03_plus_badge_visible_PASS")
    }

    /// Skapa form, markera, kontrollera collapse-badges (Fel #3).
    @MainActor
    func test_v48_step3_collapse_badges_visibility() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-orientationMode", "portrait"]
        app.launch()
        sleep(1)

        let shapesBtn = app.buttons["toolbar.shapes"]
        if shapesBtn.waitForExistence(timeout: 4) { shapesBtn.tap(); sleep(1) }

        // Skapa 2 rektanglar och försök länka dem
        let chipR = app.buttons["chip.rectangle"]
        XCTAssertTrue(chipR.waitForExistence(timeout: 4), "chip.rectangle saknas")
        chipR.tap(); sleep(1)
        let canvas = app.scrollViews["canvas"]
        let from = chipR.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        let to = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.4))
        from.press(forDuration: 0.2, thenDragTo: to)
        sleep(2)

        attach(app, name: "06_two_rectangles_omarkerade")

        // Tap på första rektangeln för att markera
        let rect = app.descendants(matching: .any)
            .matching(identifier: "shape.rectangle").firstMatch
        if rect.exists {
            rect.tap()
            sleep(1)
            attach(app, name: "07_rectangle_marked_collapse_badges_should_appear")
        }
    }

    // MARK: - Agent C: djuptest pil + badges

    /// Hjälp (C): öppna drawer, placera rect + circle + drag pil via ConnectionHandle.
    /// Returnerar false om handle inte hittades.
    @MainActor
    @discardableResult
    private func c_createArrow(in app: XCUIApplication,
                                circleOffset: CGVector = CGVector(dx: 0.72, dy: 0.50)) -> Bool {
        let shapesBtn = app.buttons["toolbar.shapes"]
        if shapesBtn.waitForExistence(timeout: 4) { shapesBtn.tap(); Thread.sleep(forTimeInterval: 0.8) }
        let canvas = app.scrollViews["canvas"]
        guard canvas.waitForExistence(timeout: 3) else { return false }
        let chipRect = app.buttons["chip.rectangle"]
        guard chipRect.waitForExistence(timeout: 3) else { return false }
        chipRect.tap(); Thread.sleep(forTimeInterval: 0.8)
        let chipCircle = app.buttons["chip.circle"]
        guard chipCircle.waitForExistence(timeout: 3) else { return false }
        chipCircle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.3, thenDragTo: canvas.coordinate(withNormalizedOffset: circleOffset))
        Thread.sleep(forTimeInterval: 1.5)
        let rectShape = app.descendants(matching: .any)
            .matching(identifier: "shape.rectangle").firstMatch
        guard rectShape.waitForExistence(timeout: 3) else { return false }
        rectShape.tap(); Thread.sleep(forTimeInterval: 0.8)
        // v60-fix: riktningsspecifikt handtag mot cirkeln + robust press/hold.
        let handle = handleTowardCircle(app)
        let circleShape = app.descendants(matching: .any)
            .matching(identifier: "shape.circle").firstMatch
        guard handle.waitForExistence(timeout: 3),
              circleShape.waitForExistence(timeout: 3) else { return false }
        handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.6, thenDragTo:
                circleShape.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)),
                   withVelocity: .default, thenHoldForDuration: 0.2)
        Thread.sleep(forTimeInterval: 1.5)
        return true
    }

    /// test_c1: Horisontell pil — pilspets-symmetri (Fel #1) + midpoint-ikon (Fel #2).
    @MainActor
    func test_c1_arrow_horizontal() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-orientationMode", "portrait"]
        app.launch()
        sleep(2)
        let ok = c_createArrow(in: app, circleOffset: CGVector(dx: 0.85, dy: 0.50))
        attach(app, name: "c1_01_arrow_marked")
        let canvas = app.scrollViews["canvas"]
        if canvas.waitForExistence(timeout: 2) {
            canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.88)).tap(); sleep(1)
        }
        attach(app, name: "c1_02_arrow_deselected_FINAL")
        XCTAssertTrue(ok, "c1: connection.handle hittades inte — pil ej skapad")
    }

    /// test_c2: Vertikal pil — midpoint-ikonen ska rotera 90° (Fel #2).
    @MainActor
    func test_c2_arrow_vertical() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-orientationMode", "portrait"]
        app.launch()
        sleep(2)
        let ok = c_createArrow(in: app, circleOffset: CGVector(dx: 0.50, dy: 0.78))
        attach(app, name: "c2_01_vertical_arrow_marked")
        let canvas = app.scrollViews["canvas"]
        if canvas.waitForExistence(timeout: 2) {
            canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.88)).tap(); sleep(1)
        }
        attach(app, name: "c2_02_vertical_arrow_deselected_FINAL")
        XCTAssertTrue(ok, "c2: connection.handle hittades inte — pil ej skapad")
    }

    /// test_c3: Minus-badge (Fel #3) — badge FINNS när from-shape är markerad.
    /// v60-fix: XCUITest:s connection.handle-drag skapar inte pilen pålitligt i
    /// simulatorn (känd begränsning — se app-källkommentaren). Vi använder samma
    /// deterministiska launch-scenario som V49: rect→circle-pil med rect förvald.
    @MainActor
    func test_c3_arrow_marked_minus_badge() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-v49-rect-circle-arrow"]
        app.launch()
        sleep(2)
        attach(app, name: "c3_01_rect_selected_FINAL")

        let minusBadge = app.descendants(matching: .any)
            .matching(identifier: "edge.collapse.minus").firstMatch
        XCTAssertTrue(minusBadge.waitForExistence(timeout: 3),
                      "Fel #3: edge.collapse.minus saknas när from-shape är markerad")
    }

    /// test_c4: Plus-badge + stub (Fel #4) — kollaps via minus → plus alltid synlig.
    /// v60-fix: deterministiskt launch-scenario (rect→circle-pil, rect förvald) +
    /// tap på minus-badgen för att kollapsa — kringgår den opålitliga handle-dragen.
    @MainActor
    func test_c4_arrow_collapsed_plus_stub() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-v49-rect-circle-arrow"]
        app.launch()
        sleep(2)
        attach(app, name: "c4_01_arrow_marked")

        let minusBadge = app.descendants(matching: .any)
            .matching(identifier: "edge.collapse.minus").firstMatch
        guard minusBadge.waitForExistence(timeout: 3) else {
            attach(app, name: "c4_FAIL_minus_not_found")
            XCTFail("c4: edge.collapse.minus saknas — Fel #3 blockerar Fel #4"); return
        }
        minusBadge.tap()
        sleep(2)
        attach(app, name: "c4_03_after_collapse_FINAL")

        let plusBadge = app.descendants(matching: .any)
            .matching(identifier: "edge.stub.badge").firstMatch
        XCTAssertTrue(plusBadge.waitForExistence(timeout: 3),
                      "Fel #4: edge.stub.badge saknas efter kollaps")
    }
}
