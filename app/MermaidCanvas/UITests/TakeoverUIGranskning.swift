import XCTest

/// iphone-takeover: inspektion på riktig iPhone — öppnar demo-skill-3-subagents
/// via Filer-väljaren, fotograferar canvasen i flera zoomlägen och dumpar
/// UI-trädet. Körs ENDAST manuellt via -only-testing (ändrar inget i appen).
final class TakeoverUIGranskning: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    @MainActor
    private func snap(_ name: String) {
        let att = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        att.name = name
        att.lifetime = .keepAlways
        add(att)
    }

    @MainActor
    func testOppnaDemoSkill3_GranskaGrafiken() {
        let app = XCUIApplication()
        app.launch()
        sleep(2)
        snap("01-start")

        // Lägen-menyn → Öppna fil…
        let modes = app.buttons["toolbar.modes"]
        XCTAssertTrue(modes.waitForExistence(timeout: 6), "lägen-menyn saknas")
        modes.tap()
        sleep(1)
        snap("02-meny")
        let openBtn = app.buttons["Öppna fil…"]
        XCTAssertTrue(openBtn.waitForExistence(timeout: 4), "Öppna fil…-knappen saknas")
        openBtn.tap()
        sleep(3)
        snap("03-filvaljare")
        NSLog("[TAKEOVER] picker-träd start: %@", app.debugDescription)

        // Filen kan synas direkt (väljaren öppnar i senast använda mappen).
        // Annars: Bläddra/Browse → På denna iPhone/On My iPhone → MermaidCanvas.
        func hittaFil() -> XCUIElement {
            let direkt = app.staticTexts["demo-skill-3-subagents"].firstMatch
            if direkt.exists { return direkt }
            return app.cells.containing(NSPredicate(format: "label CONTAINS 'demo-skill-3'")).firstMatch
        }
        func tappaOmFinns(_ namn: [String]) -> Bool {
            for n in namn {
                for q in [app.buttons[n], app.staticTexts[n], app.cells[n]] where q.firstMatch.exists {
                    q.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                    sleep(2)
                    return true
                }
            }
            return false
        }
        var fil = hittaFil()
        if !fil.waitForExistence(timeout: 4) {
            _ = tappaOmFinns(["Bläddra", "Browse"])
            _ = tappaOmFinns(["Bläddra", "Browse"])   // andra tryck → rotlistan
            snap("03b-bladdra")
            _ = tappaOmFinns(["På min iPhone", "På denna iPhone", "On My iPhone"])
            _ = tappaOmFinns(["Visuali2e", "MermaidCanvas"])
            snap("03c-i-mappen")
            fil = hittaFil()
        }
        if fil.waitForExistence(timeout: 3) {
            fil.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            sleep(3)
        } else {
            snap("03d-hittar-inte-filen")
            NSLog("[TAKEOVER] HITTADE INTE FILEN — träd: %@", app.debugDescription)
        }
        snap("04-efter-oppning")

        // Zooma ut i steg så hela flödet syns
        let canvas = app.scrollViews["canvas"]
        if canvas.waitForExistence(timeout: 4) {
            canvas.pinch(withScale: 0.5, velocity: -1)
            sleep(1)
            snap("05-utzoomad-50")
            canvas.pinch(withScale: 0.6, velocity: -1)
            sleep(1)
            snap("06-utzoomad-30")
        }
        NSLog("[TAKEOVER] slut-träd: %@", app.debugDescription)
    }

    /// Exporttest: öppna demo-skill-3-subagents → long-press containerrubriken →
    /// "Spara skill som fil" → Spara-dialogen → bekräftelse. Samma väg som Kim tar.
    @MainActor
    func testExporteraDemoSkill3_SparaSkillSomFil() {
        let app = XCUIApplication()
        app.launch()
        sleep(2)

        // Öppna filen (samma navigering som granskningstestet)
        let modes = app.buttons["toolbar.modes"]
        XCTAssertTrue(modes.waitForExistence(timeout: 6))
        modes.tap(); sleep(1)
        app.buttons["Öppna fil…"].tap(); sleep(3)
        var fil = app.staticTexts["demo-skill-3-subagents"].firstMatch
        if !fil.waitForExistence(timeout: 4) {
            for n in ["Bläddra", "Browse"] where app.buttons[n].exists { app.buttons[n].tap(); sleep(1); app.buttons[n].tap(); sleep(1) }
            for n in ["På min iPhone", "On My iPhone"] where app.staticTexts[n].firstMatch.exists {
                app.staticTexts[n].firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap(); sleep(2)
            }
            for n in ["Visuali2e", "MermaidCanvas"] where app.staticTexts[n].firstMatch.exists {
                app.staticTexts[n].firstMatch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap(); sleep(2)
                break
            }
            fil = app.staticTexts["demo-skill-3-subagents"].firstMatch
        }
        XCTAssertTrue(fil.waitForExistence(timeout: 4), "filen ska synas i väljaren")
        fil.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        sleep(3)
        // Rutnäts-läge: tap på namnet öppnar inte — tappa IKONEN ovanför namnet.
        if app.buttons["Bläddra"].exists || app.buttons["Browse"].exists {
            snap("03x-picker-kvar-provar-ikonen")
            fil.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: -1.5)).tap()
            sleep(3)
        }
        XCTAssertFalse(app.buttons["Bläddra"].exists || app.buttons["Browse"].exists,
                       "filväljaren ska vara stängd efter öppning")

        // Zooma ut så containerrubriken är på skärmen
        let canvas = app.scrollViews["canvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 4))
        canvas.pinch(withScale: 0.5, velocity: -1); sleep(1)
        canvas.pinch(withScale: 0.6, velocity: -1); sleep(1)
        snap("10-utzoomad-fore-export")

        // Long-press på container-HEADERN — sikta på rubrik-texten (alltid synlig
        // sedan v76-centreringen). Fallback: shape.container-elementet.
        try? app.debugDescription.write(toFile: "/tmp/takeover-tree.txt", atomically: true, encoding: .utf8)
        let rubrik = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'demo-skill-3-subagents'")).firstMatch
        let container = app.descendants(matching: .any).matching(identifier: "shape.container").firstMatch
        let mål: XCUIElement = rubrik.waitForExistence(timeout: 4) ? rubrik : container
        XCTAssertTrue(mål.exists, "containerrubriken ska finnas")
        mål.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 0.9)
        sleep(1)
        snap("11-contextmeny")
        let exportBtn = app.buttons["Spara skill som fil"]
        XCTAssertTrue(exportBtn.waitForExistence(timeout: 4), "menyn ska ha Spara skill som fil")
        sleep(1)   // låt menyn landa innan tap — mitt-i-animation träffar fel
        exportBtn.tap()

        // Spara som-dialogen (Files) → Spara. Presentationen kan flaka direkt
        // efter popovern — gör ETT omtag av long-press + menyval om den uteblir.
        var spara = app.buttons["Spara"]
        if !spara.waitForExistence(timeout: 12) {
            mål.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 0.9)
            let retryBtn = app.buttons["Spara skill som fil"]
            if retryBtn.waitForExistence(timeout: 4) { retryBtn.tap() }
            spara = app.buttons["Spara"]
        }
        XCTAssertTrue(spara.waitForExistence(timeout: 12), "Spara som-dialogen ska visas")
        snap("12-spara-dialog")
        spara.tap()
        sleep(2)
        snap("13-efter-spara")
        // Bekräftelse-alert ("Skill sparad")
        let alert = app.alerts.firstMatch
        if alert.waitForExistence(timeout: 6) {
            NSLog("[TAKEOVER] alert: %@", alert.label)
            alert.buttons.firstMatch.tap()
        }
        snap("14-klart")
    }
}
