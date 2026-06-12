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
            _ = tappaOmFinns(["MermaidCanvas"])
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
}
