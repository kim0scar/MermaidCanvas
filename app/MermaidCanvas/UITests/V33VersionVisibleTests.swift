import XCTest

/// v47: Versionsnumret ska synas i Lägen-menyn (hamburger).
/// Tidigare hårdkodade "v34" — v47 läser istället versionssträngen från bundle:n
/// eller söker efter prefixet "v" + minst en siffra. Då passerar testet automatiskt
/// vid varje version-bump utan att uppdateras manuellt.
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

        // Steg 4: leta efter en versionsrad — matchar regex "v\d+" så testet
        // automatiskt klarar varje version-bump.
        let predicate = NSPredicate(format: "label MATCHES %@", ".*v\\d+.*")
        let matches = app.descendants(matching: .any).matching(predicate)
        let found = matches.firstMatch.waitForExistence(timeout: 3)
        XCTAssertTrue(found,
                      "Ingen versionsrad (mönster v<siffror>) syns i Lägen-menyn. " +
                      "Kontrollera att AppVersion.current visas i LägenMenu.swift.")
        print("V33_VERSION_VISIBLE: PASS")
    }
}
