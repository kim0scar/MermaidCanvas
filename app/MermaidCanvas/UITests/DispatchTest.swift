import XCTest

final class DispatchTest: XCTestCase {
    func testWriteDetGar() throws {
        // Starta Claude-appen
        let claude = XCUIApplication(bundleIdentifier: "com.anthropic.claude")
        claude.launch()
        sleep(3)

        // 01 - Startläge
        attachShot(claude, name: "01-start")

        // Försök hitta Dispatch-tabben i flera möjliga hierarkier
        var dispatchTapped = false
        let tabDispatch = claude.tabBars.buttons["Dispatch"]
        if tabDispatch.waitForExistence(timeout: 5) {
            tabDispatch.tap()
            dispatchTapped = true
        } else {
            let btnDispatch = claude.buttons["Dispatch"]
            if btnDispatch.waitForExistence(timeout: 3) {
                btnDispatch.tap()
                dispatchTapped = true
            } else {
                // Logga hierarkin för felsökning
                let dump = claude.debugDescription
                let data = Data(dump.utf8)
                let att = XCTAttachment(data: data, uniformTypeIdentifier: "public.plain-text")
                att.name = "hierarchy-no-dispatch"
                att.lifetime = .keepAlways
                add(att)
            }
        }
        sleep(2)

        // 02 - Efter Dispatch-tap
        attachShot(claude, name: "02-dispatch-screen")

        if !dispatchTapped {
            XCTFail("Dispatch-tabben hittades inte i UI-hierarkin.")
            return
        }

        // Hitta textfältet
        var typedOk = false
        let textView = claude.textViews.firstMatch
        if textView.waitForExistence(timeout: 5) {
            textView.tap()
            sleep(1)
            textView.typeText("Det går")
            typedOk = true
        } else {
            let textField = claude.textFields.firstMatch
            if textField.waitForExistence(timeout: 3) {
                textField.tap()
                sleep(1)
                textField.typeText("Det går")
                typedOk = true
            }
        }
        sleep(1)

        // 03 - Text skriven
        attachShot(claude, name: "03-typed")

        if !typedOk {
            XCTFail("Hittade inget textfält att skriva i.")
            return
        }

        // Skicka — prova vanliga knapp-labels
        let sendCandidates = ["Send", "Skicka", "Send message", "arrow.up", "arrow.up.circle.fill"]
        var sentOk = false
        for label in sendCandidates {
            let btn = claude.buttons[label]
            if btn.exists && btn.isHittable {
                btn.tap()
                sentOk = true
                break
            }
        }
        if !sentOk {
            // Sista utväg: tryck return på tangentbordet
            let returnKey = claude.keyboards.buttons["return"]
            if returnKey.exists {
                returnKey.tap()
                sentOk = true
            }
        }
        sleep(3)

        // 04 - Efter skickat
        attachShot(claude, name: "04-sent")

        XCTAssertTrue(sentOk, "Hittade ingen Send-knapp.")
    }

    private func attachShot(_ app: XCUIApplication, name: String) {
        let shot = app.screenshot()
        let attach = XCTAttachment(screenshot: shot)
        attach.name = name
        attach.lifetime = .keepAlways
        add(attach)
    }
}
