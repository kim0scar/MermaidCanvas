import XCTest

/// v33 A9: Autonom test-loop som kör massa interaktioner i 60s och mäter alla
/// resultat. Output i JSON till /tmp/v33-autoloop-<UUID>.json så analyzer-agent
/// kan läsa.
final class V33AutoLoopTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true // fortsätt även vid avvikelser
    }

    @MainActor
    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-orientationMode", "portrait"]
        app.launch()
        return app
    }

    @MainActor
    private func diagnostics(_ app: XCUIApplication) -> String {
        let badge = app.buttons["toolbar.zoom"]
        if !badge.waitForExistence(timeout: 2) { return "NO_BADGE" }
        return (badge.value as? String) ?? "NO_VALUE"
    }

    /// Kör 60s av varierad användning. Per varje action: dumpa diagnostik + skärmdump.
    @MainActor
    func testAutoLoopRandomInteractions() throws {
        let app = launchApp()
        sleep(1)

        var events: [[String: Any]] = []
        let start = Date()
        var iter = 0

        // Hämta initial canvas-frame. v34: UIScrollView mappas till scrollViews i XCTest
        // istället för otherElements som SwiftUI-vy gjorde i v33.
        let canvas: XCUIElement = {
            let scroll = app.scrollViews["canvas"]
            if scroll.waitForExistence(timeout: 2) { return scroll }
            return app.otherElements["canvas"]
        }()
        XCTAssertTrue(canvas.waitForExistence(timeout: 4))
        let initialCanvasFrame = canvas.frame

        events.append([
            "iter": iter,
            "action": "launch",
            "diagnostics": diagnostics(app),
            "canvas_frame": "\(initialCanvasFrame)"
        ])

        // 8 olika action-typer, körs i sekvens × 6 = 48 actions inom 60s
        let actions: [(String, @MainActor () -> Void)] = [
            ("open_shapes_row", {
                let b = app.buttons["toolbar.shapes"]
                if b.exists { b.tap() }
            }),
            ("tap_chip_circle", {
                let chip = app.buttons["chip.circle"]
                if chip.exists { chip.tap() }
            }),
            ("tap_chip_rectangle", {
                let chip = app.buttons["chip.rectangle"]
                if chip.exists { chip.tap() }
            }),
            ("drag_chip_to_canvas_center", {
                let chip = app.buttons["chip.circle"]
                let cv = app.otherElements["canvas"]
                if chip.exists && cv.exists {
                    let from = chip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                    let to = cv.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                    from.press(forDuration: 0.3, thenDragTo: to)
                }
            }),
            ("drag_chip_to_canvas_topleft", {
                let chip = app.buttons["chip.rectangle"]
                let cv = app.otherElements["canvas"]
                if chip.exists && cv.exists {
                    let from = chip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                    let to = cv.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.2))
                    from.press(forDuration: 0.3, thenDragTo: to)
                }
            }),
            ("drag_chip_to_canvas_bottomright", {
                let chip = app.buttons["chip.diamond"]
                let cv = app.otherElements["canvas"]
                if chip.exists && cv.exists {
                    let from = chip.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                    let to = cv.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.8))
                    from.press(forDuration: 0.3, thenDragTo: to)
                }
            }),
            ("pan_canvas_right", {
                let cv = app.otherElements["canvas"]
                if cv.exists {
                    let a = cv.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.5))
                    let b = cv.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.5))
                    a.press(forDuration: 0.1, thenDragTo: b)
                }
            }),
            ("pan_canvas_up", {
                let cv = app.otherElements["canvas"]
                if cv.exists {
                    let a = cv.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
                    let b = cv.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
                    a.press(forDuration: 0.1, thenDragTo: b)
                }
            })
        ]

        while Date().timeIntervalSince(start) < 60 {
            for (name, action) in actions {
                if Date().timeIntervalSince(start) >= 60 { break }
                iter += 1
                action()
                sleep(1)
                events.append([
                    "iter": iter,
                    "action": name,
                    "diagnostics": diagnostics(app),
                    "elapsed_s": Date().timeIntervalSince(start)
                ])
                // Screenshot var 5:e iter
                if iter % 5 == 0 {
                    let att = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
                    att.name = "iter_\(iter)"
                    att.lifetime = .keepAlways
                    add(att)
                }
            }
        }

        // Slutligt diagnostik
        events.append([
            "iter": iter + 1,
            "action": "final",
            "diagnostics": diagnostics(app),
            "elapsed_s": Date().timeIntervalSince(start)
        ])

        // Skriv JSON till /tmp
        let output: [String: Any] = [
            "started_at": ISO8601DateFormatter().string(from: start),
            "total_events": events.count,
            "initial_canvas_frame": "\(initialCanvasFrame)",
            "events": events
        ]
        let data = try JSONSerialization.data(withJSONObject: output, options: [.prettyPrinted])
        let url = URL(fileURLWithPath: "/tmp/v33-autoloop-output.json")
        try? data.write(to: url)
        let att = XCTAttachment(data: data)
        att.name = "autoloop_output_json"
        att.lifetime = .keepAlways
        add(att)

        print("AUTOLOOP_COMPLETE events=\(events.count)")
    }
}
