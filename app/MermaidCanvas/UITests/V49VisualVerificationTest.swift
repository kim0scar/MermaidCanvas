import XCTest

/// v49: visuell verifiering av Fel #1-4 via launch-args som programmatiskt
/// sätter upp test-scenario (kringgår XCUITest:s connection.handle-bug).
final class V49VisualVerificationTest: XCTestCase {

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

    /// Fel #1: horisontell pil — pilspets-symmetri (efter v49 stroke-fix).
    /// Fel #3: rektangel markerad → minus-badge ska synas vid kantens start.
    @MainActor
    func test_v49_horizontal_arrow_with_minus_badge() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-v49-rect-circle-arrow"]
        app.launch()
        sleep(2)
        attach(app, name: "v49_horizontal_arrow_marked_minus_should_appear")
    }

    /// Fel #2: vertikal pil — midpoint-ikonen ska rotera 90° (peka nedåt).
    @MainActor
    func test_v49_vertical_arrow_midpoint_rotation() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-v49-vertical-arrow"]
        app.launch()
        sleep(2)
        attach(app, name: "v49_vertical_arrow_midpoint_should_rotate")
    }

    /// Fel #4: kollapsad form → streckad stub + lila plus ska synas där cirkeln var.
    @MainActor
    func test_v49_collapsed_stub_plus_visible() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-v49-collapsed"]
        app.launch()
        sleep(2)
        attach(app, name: "v49_after_collapse_stub_and_plus_should_appear")

        // Verifiera att plus-badge EXISTERAR i accessibility-trädet
        let plusBadge = app.descendants(matching: .any)
            .matching(identifier: "edge.stub.badge").firstMatch
        XCTAssertTrue(plusBadge.waitForExistence(timeout: 3),
                      "Fel #4: edge.stub.badge (plus) ska synas efter kollaps")
    }

    /// Fel #3: efter scenariot ska minus-badgen EXISTERA i accessibility-trädet.
    @MainActor
    func test_v49_minus_badge_visible_in_accessibility() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-v49-rect-circle-arrow"]
        app.launch()
        sleep(2)
        let minusBadge = app.descendants(matching: .any)
            .matching(identifier: "edge.collapse.minus").firstMatch
        XCTAssertTrue(minusBadge.waitForExistence(timeout: 3),
                      "Fel #3: edge.collapse.minus ska synas på markerad from-shape")
    }
}
