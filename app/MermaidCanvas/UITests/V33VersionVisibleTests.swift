import XCTest

/// v33: Visuellt bevis att versionsnumret "v33" syns i Lägen-menyn.
/// Skapad efter att Kim klagade på att appen visade "v32" trots deploy.
/// Detta test öppnar menyn och tar screenshot — om "v33" inte syns visuellt
/// är det inte en deploy-bug utan en kod-bug i AppVersion.current.
final class V33VersionVisibleTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testVersionIsVisibleInLägenMenu() throws {
        let app = XCUIApplication()
        app.launch()
        sleep(1)

        // Steg 1: skärmdump av start-skärmen (toolbar synlig)
        let attHome = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attHome.name = "01_home"
        attHome.lifetime = .keepAlways
        add(attHome)

        // Steg 2: öppna Lägen-menyn (toolbar.modes)
        let modesBtn = app.buttons["toolbar.modes"]
        XCTAssertTrue(modesBtn.waitForExistence(timeout: 4),
                      "toolbar.modes-knappen finns inte — Lägen-menyn saknas i toolbarn")
        modesBtn.tap()
        sleep(1)

        // Steg 3: skärmdump med menyn öppen
        let attMenu = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attMenu.name = "02_menu_open"
        attMenu.lifetime = .keepAlways
        add(attMenu)

        // Steg 4: leta efter versionsraden — den ska innehålla "v33"
        let v33Label = app.staticTexts["v33"]
        let exists = v33Label.waitForExistence(timeout: 3)

        // Fallback: om staticText("v33") inte hittar exakt match, leta brett
        if !exists {
            let allTexts = app.descendants(matching: .any)
                .matching(NSPredicate(format: "label CONTAINS[c] %@", "v33"))
            let found = allTexts.firstMatch.waitForExistence(timeout: 2)
            XCTAssertTrue(found,
                          "v33 syns INTE i Lägen-menyn. AppVersion.current är troligen fel värde.")
        } else {
            XCTAssertTrue(exists)
        }

        print("V33_VERSION_VISIBLE: PASS")
    }
}
